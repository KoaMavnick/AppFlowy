import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
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

/// Bottom actions on a blank page, in the same place Notion puts
/// "Get started with". Database replaces the page with a table, board, or
/// calendar. Wiki keeps the page, so the title, icon, and cover stay, and
/// drops in a starter note plus a table that can switch to a board.
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
              'Keep notes, references, and pages together. Each row below is a page you can open.',
            ),
        ),
        calloutNode(
          delta: Delta()
            ..insert(
              'Add a status and tags so important pages stay easy to find. Replace these sample pages with your own.',
            ),
          emoji: EmojiIconData.emoji('💡'),
        ),
        headingNode(
          level: 2,
          delta: Delta()..insert('Pages'),
        ),
      ]);
    await editor.apply(intro);

    final grid = await ViewBackendService.createView(
      parentViewId: page.id,
      name: 'Table',
      layoutType: ViewLayoutPB.Grid,
    ).then((result) => result.toNullable());
    if (grid == null) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }

    try {
      await _applyWikiTemplate(grid.id);
      final databaseId = await DatabaseViewBackendService(viewId: grid.id)
          .getDatabaseId()
          .then((result) => result.toNullable());
      if (databaseId != null) {
        await ViewBackendService.createDatabaseLinkedView(
          parentViewId: grid.id,
          databaseId: databaseId,
          layoutType: ViewLayoutPB.Board,
          name: 'Board',
        );
      }
    } catch (error) {
      Log.error('Wiki template was only partly applied: $error');
    }

    final block = editor.transaction
      ..insertNode(
        [3],
        Node(
          type: DatabaseBlockKeys.gridType,
          attributes: {
            DatabaseBlockKeys.parentID: page.id,
            DatabaseBlockKeys.viewID: grid.id,
          },
        ),
      );
    await editor.apply(block);
    if (mounted) {
      setState(() => _busy = false);
    }
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

  Future<void> _applyWikiTemplate(String viewId) async {
    final primary = await FieldBackendService.getPrimaryField(viewId: viewId);
    final primaryField = primary.toNullable();
    if (primaryField != null) {
      await FieldBackendService(viewId: viewId, fieldId: primaryField.id)
          .updateField(name: 'Title');
    }

    await FieldBackendService.createField(
      viewId: viewId,
      fieldType: FieldType.SingleSelect,
      fieldName: 'Status',
      typeOptionData: (SingleSelectTypeOptionPB()
            ..options.addAll([
              _option('Draft', SelectOptionColorPB.Yellow),
              _option('In progress', SelectOptionColorPB.Blue),
              _option('Verified', SelectOptionColorPB.Green),
            ]))
          .writeToBuffer(),
    );
    await FieldBackendService.createField(
      viewId: viewId,
      fieldType: FieldType.MultiSelect,
      fieldName: 'Tags',
      typeOptionData: (MultiSelectTypeOptionPB()
            ..options.addAll([
              _option('Guide', SelectOptionColorPB.Purple),
              _option('Reference', SelectOptionColorPB.Orange),
              _option('How-to', SelectOptionColorPB.Aqua),
            ]))
          .writeToBuffer(),
    );
    await FieldBackendService.createField(
      viewId: viewId,
      fieldType: FieldType.LastEditedTime,
      fieldName: 'Updated',
    );

    if (primaryField != null) {
      final title = FieldInfo.initial(primaryField);
      for (final page in const [
        'Welcome',
        'How to use this wiki',
        'Team notes',
      ]) {
        await RowBackendService.createRow(
          viewId: viewId,
          withCells: (builder) => builder.insertText(title, page),
        );
      }
    }

    final fields =
        (await FieldBackendService.getFields(viewId: viewId)).toNullable();
    if (fields == null) {
      return;
    }
    const kept = {'Title', 'Status', 'Tags', 'Updated'};
    for (final field in fields) {
      if (!field.isPrimary && !kept.contains(field.name)) {
        await FieldBackendService.deleteField(
          viewId: viewId,
          fieldId: field.id,
        );
      }
    }
  }

  SelectOptionPB _option(String name, SelectOptionColorPB color) {
    return SelectOptionPB()
      ..id = nanoid(6)
      ..name = name
      ..color = color;
  }
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
