import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Title, icon, and cover for a full-page database.
///
/// A table or board otherwise opens straight into the view tabs, so the page
/// name and the icon and cover controls disappear. This puts them back above
/// the view switcher.
class DatabasePageHeader extends StatelessWidget {
  const DatabasePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewBloc, ViewState>(
      builder: (context, state) {
        return _DatabasePageHeaderBody(view: state.view);
      },
    );
  }
}

class _DatabasePageHeaderBody extends StatefulWidget {
  const _DatabasePageHeaderBody({required this.view});

  final ViewPB view;

  @override
  State<_DatabasePageHeaderBody> createState() =>
      _DatabasePageHeaderBodyState();
}

class _DatabasePageHeaderBodyState extends State<_DatabasePageHeaderBody> {
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  bool _hovered = false;
  bool _pickingCover = false;
  ViewPB? _latest;

  ViewPB get _view => _latest ?? widget.view;

  static const _coverColors = <String>[
    '0xfff7f6f3',
    '0xffe8e7e4',
    '0xfff4eeee',
    '0xffe7f0ea',
    '0xff37352f',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.view.name;
  }

  @override
  void didUpdateWidget(covariant _DatabasePageHeaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_titleFocus.hasFocus && oldWidget.view.name != widget.view.name) {
      _titleController.text = widget.view.name;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final icon = EmojiIconData.fromViewIconPB(view.icon);
    final cover = _coverColor(view);
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(
          alpha: 0.55,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover != null)
            Container(
              height: 180,
              width: double.infinity,
              color: cover,
            ),
          if (_hovered || icon.isEmpty || cover == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (icon.isEmpty)
                    _TextAction(
                      label: LocaleKeys.document_plugins_cover_addIcon.tr(),
                      onTap: () => _openIconPicker(context, icon),
                    ),
                  if (cover == null) ...[
                    if (icon.isEmpty) const HSpace(8),
                    _TextAction(
                      label: LocaleKeys.document_plugins_cover_addCover.tr(),
                      onTap: () =>
                          setState(() => _pickingCover = !_pickingCover),
                    ),
                  ] else
                    _TextAction(
                      label: 'Change cover',
                      onTap: () =>
                          setState(() => _pickingCover = !_pickingCover),
                    ),
                ],
              ),
            ),
          if (_pickingCover)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (final value in _coverColors) ...[
                    _CoverSwatch(
                      color: _parseColor(value),
                      onTap: () => _setCover(value),
                    ),
                    const HSpace(8),
                  ],
                  if (cover != null)
                    _TextAction(
                      label: 'Remove',
                      onTap: _clearCover,
                    ),
                ],
              ),
            ),
          if (icon.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: GestureDetector(
                    onTap: () => _openIconPicker(context, icon),
                    child: EmojiIconWidget(
                      emoji: icon,
                      emojiSize: 48,
                    ),
                  ),
                ),
              ),
            ),
          TextField(
            controller: _titleController,
            focusNode: _titleFocus,
            style: TextStyle(
              fontSize: 40,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            decoration: InputDecoration(
              hintText: view.nameOrDefault,
              hintStyle: TextStyle(
                fontSize: 40,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onSubmitted: _rename,
            onTapOutside: (_) => _rename(_titleController.text),
          ),
        ],
      ),
    );
  }

  Future<void> _openIconPicker(BuildContext context, EmojiIconData icon) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: origin.dx,
              top: origin.dy + 28,
              width: 360,
              height: 380,
              child: Material(
                elevation: 8,
                color: Theme.of(dialogContext).cardColor,
                borderRadius: BorderRadius.circular(4),
                child: FlowyIconEmojiPicker(
                  onSelectedEmoji: (result) async {
                    await ViewBackendService.updateViewIcon(
                      view: _view,
                      viewIcon: result.data,
                    );
                    await _refresh();
                    if (dialogContext.mounted && !result.keepOpen) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _view.name) {
      return;
    }
    await ViewBackendService.updateView(
      viewId: _view.id,
      name: trimmed,
    );
    await _refresh();
  }

  Future<void> _setCover(String value) async {
    await _writeCover(
      PageStyleCoverImageType.pureColor.toString(),
      value,
    );
    if (mounted) {
      setState(() => _pickingCover = false);
    }
  }

  Future<void> _clearCover() async {
    await _writeCover(
      PageStyleCoverImageType.none.toString(),
      '',
    );
    if (mounted) {
      setState(() => _pickingCover = false);
    }
  }

  Future<void> _writeCover(String type, String value) async {
    final current = _view.extra.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(_view.extra) as Map);
    current[ViewExtKeys.coverKey] = {
      ViewExtKeys.coverTypeKey: type,
      ViewExtKeys.coverValueKey: value,
    };
    await ViewBackendService.updateView(
      viewId: _view.id,
      extra: jsonEncode(current),
    );
    await _refresh();
  }

  Future<void> _refresh() async {
    final next = (await ViewBackendService.getView(_view.id)).toNullable();
    if (next != null && mounted) {
      setState(() => _latest = next);
    }
  }

  Color? _coverColor(ViewPB view) {
    if (view.extra.isEmpty) {
      return null;
    }
    try {
      final extra = jsonDecode(view.extra);
      final cover = extra[ViewExtKeys.coverKey];
      if (cover is! Map) {
        return null;
      }
      final type = cover[ViewExtKeys.coverTypeKey]?.toString() ?? '';
      if (type != PageStyleCoverImageType.pureColor.toString()) {
        return null;
      }
      final value = cover[ViewExtKeys.coverValueKey]?.toString() ?? '';
      if (value.isEmpty) {
        return null;
      }
      return _parseColor(value);
    } catch (_) {
      return null;
    }
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
    return Color(int.parse(hex, radix: 16));
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(
          alpha: 0.55,
        );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, height: 1.2, color: muted),
        ),
      ),
    );
  }
}

class _CoverSwatch extends StatelessWidget {
  const _CoverSwatch({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}
