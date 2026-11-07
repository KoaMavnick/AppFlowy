import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/domain/group_service.dart';
import 'package:appflowy/plugins/database/domain/select_option_cell_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/columns/simple_column_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/columns/simple_columns_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

const _projectPages = <(String, String)>[
  ('Aiden Project', '📁'),
  ('Starting A Software Company', '🚀'),
  ('Project OGC/08/23', '📌'),
  ('Journal', '📓'),
  ('Building the Body', '💪'),
];

const _ideaPages = <(String, String)>[
  ('Software ideas to create', '💡'),
  ('Hardware Ideas', '🔧'),
  ('Benefits Policies', '📋'),
];

/// Bottom actions on a blank page, in the same place Notion puts
/// "Get started with". Database replaces the page with a table, board, or
/// calendar. Wiki keeps the page, so the title, icon, and cover stay, and
/// fills it with the sample wiki: an intro, a tip, and Project Notes beside
/// a card view that can switch to a table.
class EmptyPageStarter extends StatefulWidget {
  const EmptyPageStarter({
    super.key,
    required this.view,
    required this.editorState,
    required this.child,
  });

  final ViewPB view;
  final EditorState editorState;
  final Widget child;

  @override
  State<EmptyPageStarter> createState() => _EmptyPageStarterState();
}

class _EmptyPageStarterState extends State<EmptyPageStarter> {
  StreamSubscription<dynamic>? _transactions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _transactions = widget.editorState.transactionStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _transactions?.cancel();
    super.dispose();
  }

  bool get _isBlank {
    final children = widget.editorState.document.root.children;
    if (children.isEmpty) {
      return true;
    }
    for (final node in children) {
      if (node.type != ParagraphBlockKeys.type) {
        return false;
      }
      final delta = node.delta;
      if (delta != null && delta.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBlank)
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: IgnorePointer(
              ignoring: _busy,
              child: _GetStartedBar(
                onDatabase: _openDatabaseMenu,
                onWiki: _fillWikiDocument,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openDatabaseMenu(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) {
      return;
    }

    final origin = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final completer = Completer<ViewLayoutPB?>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  entry.remove();
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: origin.dx,
              top: origin.dy - 132,
              child: Material(
                elevation: 8,
                color: Theme.of(overlayContext).cardColor,
                borderRadius: BorderRadius.circular(4),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _layoutChoice(entry, completer, ViewLayoutPB.Grid, 'Table', FlowySvgs.icon_grid_s),
                      _layoutChoice(entry, completer, ViewLayoutPB.Board, 'Board', FlowySvgs.icon_board_s),
                      _layoutChoice(entry, completer, ViewLayoutPB.Calendar, 'Calendar', FlowySvgs.icon_calendar_s),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(entry);
    final layout = await completer.future;
    if (layout == null) {
      return;
    }
    await _replacePage(layout);
  }

  Widget _layoutChoice(
    OverlayEntry entry,
    Completer<ViewLayoutPB?> completer,
    ViewLayoutPB layout,
    String label,
    FlowySvgData icon,
  ) {
    return InkWell(
      onTap: () {
        entry.remove();
        if (!completer.isCompleted) {
          completer.complete(layout);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _MenuRow(icon: icon, label: label),
      ),
    );
  }

  Future<void> _fillWikiDocument() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);

    final page = widget.view;
    if (page.name.trim().isEmpty) {
      await ViewBackendService.updateView(viewId: page.id, name: 'Wiki');
    }
    await ViewBackendService.updateViewIcon(
      view: page,
      viewIcon: EmojiIconData.emoji('📖'),
    );

    final editor = widget.editorState;
    final intro = editor.transaction
      ..insertNodes([0], [
        paragraphNode(
          delta: Delta()
            ..insert(
              'Convert all those scattered pages into a Notion database with one click — while keeping the easy-to-read page format.',
            ),
        ),
        calloutNode(
          delta: Delta()
            ..insert(
              'Notion Tip: Use this template to organize information for your company. Add an owner, a verification status, and tags so the right pages stay easy to find. Replace these sample pages with your own.',
            ),
          emoji: EmojiIconData.emoji('💡'),
        ),
      ]);
    await editor.apply(intro);

    try {
      final notes = await _wikiPages(page.id, _projectPages);
      final ideas = await _wikiPages(page.id, _ideaPages);
      final built = await _buildWikiDatabase(page.id);
      final columns = editor.transaction
        ..insertNode(
          [2],
          _wikiColumns(
            pageId: page.id,
            notes: notes,
            ideas: ideas,
            boardId: built?.boardId,
          ),
        );
      await editor.apply(columns);
      if (built != null) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await _hideDefaultGroup(built.boardId, wait: true);
        if (built.secondBoardId != null) {
          await _hideDefaultGroup(built.secondBoardId!, wait: true);
        }
      }
    } catch (error) {
      Log.error('Wiki template was only partly applied: $error');
    }

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<List<Node>> _wikiPages(
    String parentId,
    List<(String, String)> pages,
  ) async {
    final nodes = <Node>[];
    for (final (name, emoji) in pages) {
      final view = await ViewBackendService.createView(
        parentViewId: parentId,
        name: name,
        layoutType: ViewLayoutPB.Document,
      ).then((result) => result.toNullable());
      if (view == null) {
        continue;
      }
      await ViewBackendService.updateViewIcon(
        view: view,
        viewIcon: EmojiIconData.emoji(emoji),
      );
      nodes.add(subPageNode(viewId: view.id));
    }
    return nodes;
  }

  Future<({String boardId, String? secondBoardId})?> _buildWikiDatabase(
    String parentId,
  ) async {
    final board = await ViewBackendService.createView(
      parentViewId: parentId,
      name: 'Company Updates',
      layoutType: ViewLayoutPB.Grid,
    ).then((result) => result.toNullable());
    if (board == null) {
      return null;
    }

    final setup = await _applyWikiTemplate(board.id);
    final databaseId = await DatabaseViewBackendService(viewId: board.id)
        .getDatabaseId()
        .then((result) => result.toNullable());
    if (databaseId == null) {
      return (boardId: board.id, secondBoardId: null);
    }

    final secondBoard = await ViewBackendService.createDatabaseLinkedView(
      parentViewId: board.id,
      databaseId: databaseId,
      layoutType: ViewLayoutPB.Board,
      name: 'Company Updates',
    ).then((result) => result.toNullable());
    final table = await ViewBackendService.createDatabaseLinkedView(
      parentViewId: board.id,
      databaseId: databaseId,
      layoutType: ViewLayoutPB.Grid,
      name: 'Table',
    ).then((result) => result.toNullable());

    if (setup != null) {
      if (secondBoard != null) {
        await _finishWikiView(
          secondBoard.id,
          titleFieldId: setup.titleFieldId,
          tagsFieldId: setup.tagsFieldId,
          grouped: true,
        );
      }
      if (table != null) {
        await _finishWikiView(
          table.id,
          titleFieldId: setup.titleFieldId,
          tagsFieldId: setup.tagsFieldId,
          grouped: false,
        );
      }
    }
    await DatabaseViewBackendService.updateLayout(
      viewId: board.id,
      layout: DatabaseLayoutPB.Board,
    );
    return (boardId: board.id, secondBoardId: secondBoard?.id);
  }

  Node _wikiColumns({
    required String pageId,
    required List<Node> notes,
    required List<Node> ideas,
    required String? boardId,
  }) {
    return simpleColumnsNode(
      children: [
        simpleColumnNode(
          ratio: 0.34,
          children: [
            headingNode(
              level: 2,
              delta: Delta()..insert('Project Notes'),
            ),
            ...notes,
            headingNode(
              level: 2,
              delta: Delta()..insert('Ideas'),
            ),
            ...ideas,
          ],
        ),
        simpleColumnNode(
          ratio: 0.66,
          children: [
            if (boardId == null)
              paragraphNode()
            else
              Node(
                type: DatabaseBlockKeys.gridType,
                attributes: {
                  DatabaseBlockKeys.parentID: pageId,
                  DatabaseBlockKeys.viewID: boardId,
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _replacePage(ViewLayoutPB layout) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);

    final source = widget.view;
    final name = source.nameOrDefault;
    final result = await ViewBackendService.createView(
      parentViewId: source.parentViewId,
      name: name,
      layoutType: layout,
    );

    final created = result.fold(
      (view) => view,
      (error) {
        Log.error('Failed to turn the page into a database: $error');
        return null;
      },
    );
    if (created == null) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }

    final tabs = getIt<TabsBloc>();
    tabs.openPlugin(created);
    tabs.add(TabsEvent.closeTab(source.id));
    await ViewBackendService.deleteView(viewId: source.id);
  }

  Future<({String titleFieldId, String? tagsFieldId})?> _applyWikiTemplate(
    String viewId,
  ) async {
    final primary = await FieldBackendService.getPrimaryField(viewId: viewId);
    final primaryField = primary.toNullable();
    if (primaryField != null) {
      await FieldBackendService(viewId: viewId, fieldId: primaryField.id)
          .updateField(name: 'Title');
    }

    final company = _option('Company Updates', SelectOptionColorPB.Purple);
    final policies = _option('Policies', SelectOptionColorPB.Pink);
    final tags = await FieldBackendService.createField(
      viewId: viewId,
      fieldType: FieldType.SingleSelect,
      fieldName: 'Tags',
      typeOptionData: (SingleSelectTypeOptionPB()
            ..options.addAll([company, policies]))
          .writeToBuffer(),
    ).then((result) => result.toNullable());
    final updated = await FieldBackendService.createField(
      viewId: viewId,
      fieldType: FieldType.DateTime,
      fieldName: 'Updated',
      typeOptionData: (DateTypeOptionPB()
            ..dateFormat = DateFormatPB.Friendly)
          .writeToBuffer(),
    ).then((result) => result.toNullable());

    if (primaryField != null) {
      final title = FieldInfo.initial(primaryField);
      final updatedInfo = updated == null ? null : FieldInfo.initial(updated);
      const cards = [
        _WikiCard(
          'New Page With Tags',
          '0xffd3e5ef',
          2023,
          8,
          29,
        ),
        _WikiCard('Benefits Policies', '0xfff5e0e9', 2023, 9, 12),
        _WikiCard('Software ideas to create', '0xffe8deee', 2023, 10, 3),
        _WikiCard('Hardware Ideas', '0xfffadec9', 2023, 11, 18),
      ];
      final tagIds = [company.id, policies.id, company.id, policies.id];
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final row = await RowBackendService.createRow(
          viewId: viewId,
          withCells: (builder) {
            builder.insertText(title, card.title);
            if (updatedInfo != null) {
              builder.insertDate(
                updatedInfo,
                DateTime(card.year, card.month, card.day),
              );
            }
          },
        ).then((result) => result.toNullable());
        if (row == null) {
          continue;
        }
        if (tags != null) {
          final selected = await SelectOptionCellBackendService(
            viewId: viewId,
            fieldId: tags.id,
            rowId: row.id,
          ).select(optionIds: [tagIds[i]]);
          selected.fold((_) {}, (error) => Log.error(error));
        }
        final cover = await RowBackendService(viewId: viewId).updateMeta(
          rowId: row.id,
          cover: RowCoverPB(
            data: card.cover,
            uploadType: FileUploadTypePB.LocalFile,
            coverType: CoverTypePB.ColorCover,
          ),
        );
        cover.fold((_) {}, (error) => Log.error(error));
      }
    }

    final fields =
        (await FieldBackendService.getFields(viewId: viewId)).toNullable();
    if (fields != null) {
      const kept = {'Title', 'Tags', 'Updated'};
      for (final field in fields) {
        if (!field.isPrimary && !kept.contains(field.name)) {
          await FieldBackendService.deleteField(
            viewId: viewId,
            fieldId: field.id,
          );
        }
      }
    }

    if (primaryField == null) {
      return null;
    }
    await _finishWikiView(
      viewId,
      titleFieldId: primaryField.id,
      tagsFieldId: tags?.id,
      grouped: true,
    );
    return (titleFieldId: primaryField.id, tagsFieldId: tags?.id);
  }

  Future<void> _finishWikiView(
    String viewId, {
    required String titleFieldId,
    required String? tagsFieldId,
    required bool grouped,
  }) async {
    final hidden = await FilterBackendService(viewId: viewId).insertTextFilter(
      fieldId: titleFieldId,
      condition: TextFilterConditionPB.TextIsNotEmpty,
      content: '',
    );
    hidden.fold((_) {}, (error) => Log.error(error));
    if (!grouped || tagsFieldId == null) {
      return;
    }
    final groupedBy = await GroupBackendService(viewId).groupByField(
      fieldId: tagsFieldId,
      settingContent: const [],
    );
    groupedBy.fold((_) {}, (error) => Log.error(error));
    await _hideDefaultGroup(viewId);
  }

  Future<void> _hideDefaultGroup(String viewId, {bool wait = false}) async {
    final attempts = wait ? 8 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final groups = await DatabaseViewBackendService(viewId: viewId)
          .loadGroups()
          .then((result) => result.toNullable());
      final defaults =
          groups?.items.where((group) => group.isDefault).toList() ?? [];
      if (defaults.isEmpty) {
        if (!wait) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 350));
        continue;
      }
      for (final group in defaults) {
        if (!group.isVisible) {
          continue;
        }
        final hidden = await GroupBackendService(viewId).updateGroup(
          groupId: group.groupId,
          visible: false,
        );
        hidden.fold((_) {}, (error) => Log.error(error));
      }
      return;
    }
  }

  SelectOptionPB _option(String name, SelectOptionColorPB color) {
    return SelectOptionPB()
      ..id = nanoid(6)
      ..name = name
      ..color = color;
  }
}

class _WikiCard {
  const _WikiCard(this.title, this.cover, this.year, this.month, this.day);

  final String title;
  final String cover;
  final int year;
  final int month;
  final int day;
}

class _GetStartedBar extends StatelessWidget {
  const _GetStartedBar({
    required this.onDatabase,
    required this.onWiki,
  });

  final void Function(BuildContext buttonContext) onDatabase;
  final VoidCallback onWiki;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Get started with',
          style: TextStyle(fontSize: 12, height: 1.2, color: muted),
        ),
        const VSpace(10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (buttonContext) => _StarterButton(
                icon: FlowySvgs.icon_grid_s,
                label: 'Database',
                onTap: () => onDatabase(buttonContext),
              ),
            ),
            const HSpace(8),
            _StarterButton(
              icon: FlowySvgs.icon_document_s,
              label: 'Wiki',
              onTap: onWiki,
            ),
          ],
        ),
        const VSpace(4),
        Text(
          LocaleKeys.editor_slashPlaceHolder.tr(),
          style: TextStyle(fontSize: 12, height: 1.2, color: muted),
        ),
      ],
    );
  }
}

class _StarterButton extends StatelessWidget {
  const _StarterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FlowySvgData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: theme.colorScheme.secondary,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowySvg(icon, size: const Size.square(16)),
              const HSpace(6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final FlowySvgData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowySvg(icon, size: const Size.square(16)),
        const HSpace(8),
        Text(label),
      ],
    );
  }
}
