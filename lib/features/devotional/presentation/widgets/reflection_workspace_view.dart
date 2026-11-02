import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/reflection_workspace.dart';
import '../../domain/models/text_highlight.dart';
import '../reader_design_tokens.dart';
import 'reader_color_picker_dialog.dart';

class ReflectionWorkspaceView extends StatefulWidget {
  final ReflectionWorkspace? initialWorkspace;
  final ValueChanged<bool> onDirtyChanged;

  const ReflectionWorkspaceView({
    super.key,
    required this.initialWorkspace,
    required this.onDirtyChanged,
  });

  @override
  State<ReflectionWorkspaceView> createState() =>
      ReflectionWorkspaceViewState();
}

class ReflectionWorkspaceViewState extends State<ReflectionWorkspaceView> {
  final List<_BlockHandle> _blocks = [];
  _BlockHandle? _active;
  String _savedSnapshot = '';
  String? _seedKey;
  bool _dirty = false;
  bool _hasDocumentText = false;
  bool _dragOverlayDismissalScheduled = false;
  double? _dragProxyHeight;

  static const _fontSizes = <String, String>{
    '10': '10', '12': '12', '14': '14', '16': '16', '18': '18',
    '20': '20', '24': '24', '28': '28', '32': '32', 'Default': '0',
  };

  @override
  void initState() {
    super.initState();
    _seedFrom(widget.initialWorkspace, notify: false);
  }

  @override
  void didUpdateWidget(covariant ReflectionWorkspaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _workspaceKey(widget.initialWorkspace);
    if (!_dirty && nextKey != _seedKey) _seedFrom(widget.initialWorkspace);
  }

  @override
  void dispose() {
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }

  ReflectionWorkspaceDraft buildDraft() => ReflectionWorkspaceDraft(
        blocks: [
          for (var index = 0; index < _blocks.length; index++)
            _blocks[index].toDocument(index),
        ],
      );

  void markSaved(ReflectionWorkspace workspace) => _seedFrom(workspace);
  void clearWorkspace() => _seedFrom(null);

  void addCitation(ReflectionCitation citation) {
    for (final block in _blocks) {
      if (block.citation?.identityKey == citation.identityKey) {
        _focusBlock(block);
        return;
      }
    }
    _dismissEditingOverlays();
    final block = _createBlock(citation: citation);
    final activeIndex = _active == null ? -1 : _blocks.indexOf(_active!);
    final insertionIndex = activeIndex < 0 ? _blocks.length : activeIndex + 1;
    setState(() {
      _blocks.insert(insertionIndex, block);
      final followingIndex = insertionIndex + 1;
      final needsFollowingParagraph = followingIndex >= _blocks.length ||
          _blocks[followingIndex].isCitation;
      if (needsFollowingParagraph) {
        _blocks.insert(followingIndex, _createBlock());
      }
      _ensureTrailingParagraph();
      _active = block;
    });
    _notifyChanged();
    _focusBlock(block);
  }

  void _seedFrom(ReflectionWorkspace? workspace, {bool notify = true}) {
    for (final block in _blocks) {
      block.dispose();
    }
    _blocks.clear();
    for (final item in workspace?.blocks ?? const <ReflectionDocumentBlock>[]) {
      _blocks.add(_createBlock(document: item));
    }
    _ensureTrailingParagraph();
    _active = _blocks.first;
    _seedKey = _workspaceKey(workspace);
    _hasDocumentText = _containsDocumentText;
    _savedSnapshot = _snapshot();
    _dirty = false;
    if (notify && mounted) {
      setState(() {});
      widget.onDirtyChanged(false);
    }
  }

  _BlockHandle _createBlock({
    ReflectionDocumentBlock? document,
    ReflectionCitation? citation,
  }) {
    final controller = quill.QuillController(
      document: document == null
          ? quill.Document()
          : quill.Document.fromJson(document.documentDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    final focusNode = FocusNode();
    late final _BlockHandle handle;
    handle = _BlockHandle(
      id: document?.id ?? 'draft-${DateTime.now().microsecondsSinceEpoch}',
      citation: document is CitedReflectionDocument
          ? document.citation
          : citation,
      citationFontColor: document is CitedReflectionDocument
          ? _citationFontColorFromDelta(document.documentDelta)
          : null,
      controller: controller,
      focusNode: focusNode,
      scrollController: ScrollController(),
      blockKey: GlobalKey(),
      createdAt: document?.createdAt,
      updatedAt: document?.updatedAt,
    );
    controller.addListener(_notifyChanged);
    focusNode.addListener(() {
      if (!mounted) return;
      if (focusNode.hasFocus && _active != handle) {
        setState(() => _active = handle);
      } else if (_active == handle) {
        setState(() {});
      }
    });
    return handle;
  }

  void _notifyChanged() {
    if (!mounted) return;
    final nextDirty = _snapshot() != _savedSnapshot;
    final nextHasDocumentText = _containsDocumentText;
    final dirtyChanged = nextDirty != _dirty;
    if (dirtyChanged || nextHasDocumentText != _hasDocumentText) {
      _dirty = nextDirty;
      _hasDocumentText = nextHasDocumentText;
      if (dirtyChanged) widget.onDirtyChanged(nextDirty);
      setState(() {});
    }
  }

  bool get _containsDocumentText => _blocks.any(
        (block) => block.controller.document.toPlainText().trim().isNotEmpty,
      );

  void _ensureTrailingParagraph() {
    if (_blocks.isEmpty || _blocks.last.isCitation) {
      _blocks.add(_createBlock());
    }
  }

  _BlockHandle? get _generalPlaceholderBlock {
    if (_hasDocumentText) return null;
    final active = _active;
    if (active != null && !active.isCitation && active.focusNode.hasFocus) {
      return active;
    }
    if (_blocks.any((block) => block.isCitation)) return null;
    for (final block in _blocks) {
      if (!block.isCitation) return block;
    }
    return null;
  }

  String _snapshot() => jsonEncode({
        'blocks': [
          for (final block in buildDraft().blocks)
            {
              'id': block.id,
              'type': block.type.name,
              'identity': block is CitedReflectionDocument
                  ? block.citation.identityKey
                  : null,
              'color': block is CitedReflectionDocument
                  ? block.citation.highlightColor?.storageValue
                  : null,
              'delta': block.documentDelta,
              'order': block.displayOrder,
            },
        ],
      });

  String? _workspaceKey(ReflectionWorkspace? workspace) => workspace == null
      ? null
      : '${workspace.updatedAt.toIso8601String()}:${workspace.blocks.length}';

  void _dismissEditingOverlays() {
    ContextMenuController.removeAny();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _prepareReorderDrag() {
    if (_dragOverlayDismissalScheduled) return;
    _dragOverlayDismissalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dragOverlayDismissalScheduled = false;
      if (mounted) _dismissEditingOverlays();
    });
  }

  void _startReorderDrag(int index) {
    final blockContext = _blocks[index].blockKey.currentContext;
    _dragProxyHeight = blockContext?.size?.height;
    _prepareReorderDrag();
  }

  Widget _buildReorderProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final block = _blocks[index];
    final citation = block.citation;
    final cardColor = citation?.highlightColor == null
        ? const Color(0xFFEFF8FD)
        : _colorFromHex(citation!.highlightColor!.hex);
    final textColor = cardColor.computeLuminance() < 0.35
        ? Colors.white
        : ReaderDesign.brand;
    final reflectionText = block.controller.document.toPlainText().trim();
    return Material(
      color: cardColor,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: (_dragProxyHeight ?? 100) + (citation == null ? 0 : 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                citation?.source == ReflectionCitationSource.bible
                    ? 'Bible Citation'
                    : 'Devotion Citation',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (citation != null && !block.collapsed) ...[
                const SizedBox(height: 6),
                Text(
                  '“${citation.selectedText}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                ),
              ],
              if (reflectionText.isNotEmpty && !block.collapsed) ...[
                const SizedBox(height: 6),
                Text(
                  reflectionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _focusBlock(_BlockHandle block) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final blockContext = block.blockKey.currentContext;
      if (blockContext != null) {
        await Scrollable.ensureVisible(
          blockContext,
          alignment: 0.2,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted && _blocks.contains(block)) block.focusNode.requestFocus();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    _prepareReorderDrag();
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    setState(() {
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _ensureTrailingParagraph();
    });
    _notifyChanged();
  }

  Future<void> _changeCitationColor(
    _BlockHandle block,
    _CitationColorTarget target,
  ) async {
    final citation = block.citation;
    if (citation == null) return;
    if (target == _CitationColorTarget.font) {
      final choice = await showReaderColorPicker(
        context,
        title: 'Citation font color',
        initialColor: block.citationFontColor ??
            _editorColorFromAttribute(
              block.controller.getSelectionStyle().attributes['color']?.value,
            ),
        allowClear: true,
      );
      if (!mounted || !_blocks.contains(block) || choice == null) return;
      final color = choice.color;
      final hex = color == null
          ? null
          : '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
              .toUpperCase();
      // Apply to this cited reflection's Quill text; the Delta saves the color.
      final textLength = block.controller.document.length - 1;
      block.controller.formatText(
        0,
        textLength < 0 ? 0 : textLength,
        quill.ColorAttribute(hex),
      );
      setState(() => block.citationFontColor = color);
      return;
    }
    // The saved citation color is separate from the source text highlight.
    final choice = await showReaderColorPicker(
      context,
      title: 'Citation color',
      initialColor: citation.highlightColor == null
          ? const Color(0xFFEFF8FD)
          : _colorFromHex(citation.highlightColor!.hex),
      allowClear: true,
    );
    if (!mounted || !_blocks.contains(block) || choice == null) return;
    final color = choice.color;
    final highlightColor = color == null
        ? null
        : HighlightColor.fromHex(
            '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          );
    setState(() {
      block.citation = citation.withHighlightColor(highlightColor);
    });
    _notifyChanged();
  }

  Future<void> _removeBlock(_BlockHandle block) async {
    final hasText = block.controller.document.toPlainText().trim().isNotEmpty;
    final requiresConfirmation =
        hasText || block.isCitation || !block.id.startsWith('draft-');
    final confirmed = !requiresConfirmation ||
        await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(block.isCitation
                    ? 'Remove cited reflection?'
                    : 'Remove reflection paragraph?'),
                content: Text(block.isCitation
                    ? 'The citation and its reflection will be removed. The original highlight will remain.'
                    : 'This paragraph and its formatting will be removed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Keep'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ) ==
            true;
    if (!confirmed || !mounted) return;
    _dismissEditingOverlays();
    setState(() {
      _blocks.remove(block);
      _ensureTrailingParagraph();
      if (_active == block) _active = _blocks.first;
    });
    block.dispose();
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final active = _active ?? _blocks.first;
    final generalPlaceholderBlock = _generalPlaceholderBlock;
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormattingToolbar(controller: active.controller),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(mobile ? 0 : 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(mobile ? 0 : 12),
            border: mobile ? null : Border.all(color: ReaderDesign.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _blocks.length,
                onReorderStart: _startReorderDrag,
                onReorder: _reorder,
                proxyDecorator: _buildReorderProxy,
                itemBuilder: (context, index) {
                  final block = _blocks[index];
                  return Padding(
                    key: ValueKey(block.id),
                    padding: EdgeInsets.only(bottom: block.isCitation ? 12 : 0),
                    child: _ReflectionBlockView(
                      handle: block,
                      index: index,
                      showGeneralPlaceholder:
                          identical(block, generalPlaceholderBlock),
                      onToggleCollapsed: () => setState(
                        () => block.collapsed = !block.collapsed,
                      ),
                      onChangeCitationColor: (target) =>
                          _changeCitationColor(block, target),
                      onRemove: () => _removeBlock(block),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockHandle {
  final String id;
  ReflectionCitation? citation;
  Color? citationFontColor;
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final GlobalKey blockKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool collapsed = false;

  _BlockHandle({
    required this.id,
    required this.citation,
    required this.citationFontColor,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.blockKey,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCitation => citation != null;

  ReflectionDocumentBlock toDocument(int order) {
    final delta = controller.document.toDelta().toJson();
    final text = controller.document.toPlainText();
    return citation == null
        ? ReflectionParagraphDocument(
            id: id,
            documentDelta: delta,
            plainText: text,
            displayOrder: order,
            createdAt: createdAt,
            updatedAt: updatedAt,
          )
        : CitedReflectionDocument(
            id: id,
            citation: citation!,
            documentDelta: delta,
            plainText: text,
            displayOrder: order,
            createdAt: createdAt,
            updatedAt: updatedAt,
          );
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }
}

class _FormattingToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const _FormattingToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return ClipRRect(
      borderRadius: BorderRadius.circular(mobile ? 16 : 12),
      child: ColoredBox(
        color: mobile ? ReaderDesign.surfaceLow : const Color(0xFFF8FAFC),
        child: SizedBox(
          width: double.infinity,
          child: quill.QuillSimpleToolbar(
            controller: controller,
            config: quill.QuillSimpleToolbarConfig(
              axis: Axis.horizontal,
              multiRowsDisplay: false,
              buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                fontSize: quill.QuillToolbarFontSizeButtonOptions(
                  items: ReflectionWorkspaceViewState._fontSizes,
                  defaultDisplayText: mobile ? 'Body' : 'Size',
                ),
                color: quill.QuillToolbarColorButtonOptions(
                  customOnPressedCallback: (controller, isBackground) =>
                      _showEditorColorPicker(context, controller, isBackground),
                ),
                backgroundColor: quill.QuillToolbarColorButtonOptions(
                  customOnPressedCallback: (controller, isBackground) =>
                      _showEditorColorPicker(context, controller, isBackground),
                ),
              ),
              showDividers: !mobile,
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: !mobile,
              showClearFormat: !mobile,
              showAlignmentButtons: !mobile,
              showJustifyAlignment: false,
              showHeaderStyle: false,
              showListNumbers: !mobile,
              showListBullets: true,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showUndo: true,
              showRedo: true,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditorColorPicker(
    BuildContext context,
    quill.QuillController controller,
    bool isBackground,
  ) async {
    final attribute = controller.getSelectionStyle().attributes[
      isBackground ? 'background' : 'color'
    ]?.value;
    final choice = await showReaderColorPicker(
      context,
      title: isBackground ? 'Background Color' : 'Font Color',
      initialColor: _editorColorFromAttribute(attribute),
      allowClear: true,
    );
    if (!context.mounted) return;
    if (choice == null) return;
    final color = choice.color;
    if (color == null) {
      controller.formatSelection(isBackground
          ? const quill.BackgroundAttribute(null)
          : const quill.ColorAttribute(null));
      return;
    }
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();
    controller.formatSelection(isBackground
        ? quill.BackgroundAttribute(hex)
        : quill.ColorAttribute(hex));
  }
}

Color _editorColorFromAttribute(Object? value) {
  if (value is String) {
    final hex = value.replaceFirst('#', '');
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return Color(0xFF000000 | int.parse(hex, radix: 16));
    }
    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  return Colors.black;
}

Color? _citationFontColorFromDelta(List<dynamic> delta) {
  for (final operation in delta) {
    if (operation is! Map) continue;
    final text = operation['insert'];
    if (text is! String || text.trim().isEmpty) continue;
    final attributes = operation['attributes'];
    final color = attributes is Map ? attributes['color'] : null;
    return color is String ? _editorColorFromAttribute(color) : null;
  }
  return null;
}

enum _CitationColorTarget { font, card }

class _ReflectionBlockView extends StatelessWidget {
  final _BlockHandle handle;
  final int index;
  final bool showGeneralPlaceholder;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<_CitationColorTarget> onChangeCitationColor;
  final VoidCallback onRemove;

  const _ReflectionBlockView({
    required this.handle,
    required this.index,
    required this.showGeneralPlaceholder,
    required this.onToggleCollapsed,
    required this.onChangeCitationColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final citation = handle.citation;
    final citationColor = citation?.highlightColor == null
        ? const Color(0xFFEFF8FD)
        : _colorFromHex(citation!.highlightColor!.hex);
    final citationForeground = citationColor.computeLuminance() < 0.35
        ? Colors.white
        : ReaderDesign.brand;
    final citationTextColor = handle.citationFontColor ?? citationForeground;
    final citationBorder = citation?.highlightColor == null
        ? const Color(0xFF9ED8FA)
        : citationForeground.withAlpha(150);
    return Container(
      key: handle.blockKey,
      decoration: citation == null
          ? null
          : BoxDecoration(
              color: citationColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: citationBorder),
            ),
      clipBehavior: citation == null ? Clip.none : Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (citation != null)
            _BlockControls(
              index: index,
              label: citation.source == ReflectionCitationSource.bible
                  ? 'Bible Citation'
                  : 'Devotion Citation',
              foreground: citationForeground,
              titleColor: citationTextColor,
              collapsed: handle.collapsed,
              onToggleCollapsed: onToggleCollapsed,
              onChangeColor: onChangeCitationColor,
              onRemove: onRemove,
            ),
          if (citation != null && !handle.collapsed) ...[
            Divider(height: 1, thickness: 1, color: citationBorder),
            _CitationHeader(citation: citation, foreground: citationTextColor),
            Divider(height: 1, thickness: 1, color: citationBorder),
          ],
          if (!handle.collapsed)
            _EditorSurface(
              handle: handle,
              minimumHeight: citation == null ? 44 : 64,
              citation: citation != null,
              showGeneralPlaceholder: showGeneralPlaceholder,
            ),
        ],
      ),
    );
  }
}

class _CitationHeader extends StatelessWidget {
  final ReflectionCitation citation;
  final Color foreground;
  const _CitationHeader({required this.citation, required this.foreground});

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    final bible = citation.source == ReflectionCitationSource.bible;
    final bibleReference = [
      citation.scriptureReference,
      citation.translationId,
    ].whereType<String>().join(' · ');
    final source = bible ? 'Bible $bibleReference: ' : 'Devotion: ';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: source,
              style: ReaderDesign.ui(
                mobile: mobile,
                color: foreground,
                fontSize: mobile ? 12.5 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: '“${citation.selectedText}”',
              style: ReaderDesign.editorial(
                color: foreground,
                fontSize: mobile ? 13 : 14,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockControls extends StatelessWidget {
  final int index;
  final String label;
  final Color foreground;
  final Color titleColor;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<_CitationColorTarget> onChangeColor;
  final VoidCallback onRemove;

  const _BlockControls({
    required this.index,
    required this.label,
    required this.foreground,
    required this.titleColor,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onChangeColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Tooltip(
                message: 'Drag to move block',
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: foreground.withAlpha(150),
                  size: 17,
                ),
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: collapsed ? 'Expand citation' : 'Collapse citation',
              child: InkWell(
                onTap: onToggleCollapsed,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    color: titleColor,
                    fontSize: mobile ? 12.5 : 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<_CitationColorTarget>(
            tooltip: 'Citation color',
            onSelected: onChangeColor,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _CitationColorTarget.font,
                child: Text('Font color'),
              ),
              PopupMenuItem(
                value: _CitationColorTarget.card,
                child: Text('Card color'),
              ),
            ],
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.palette_outlined,
                size: 17,
                color: foreground,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove citation',
            onPressed: onRemove,
            constraints: const BoxConstraints.tightFor(width: 34, height: 38),
            padding: EdgeInsets.zero,
            color: foreground,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
          const SizedBox(width: 7),
        ],
      ),
    );
  }
}

class _EditorSurface extends StatelessWidget {
  final _BlockHandle handle;
  final double minimumHeight;
  final bool citation;
  final bool showGeneralPlaceholder;
  const _EditorSurface({
    required this.handle,
    required this.minimumHeight,
    required this.citation,
    required this.showGeneralPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final editor = quill.QuillEditor.basic(
      controller: handle.controller,
      focusNode: handle.focusNode,
      scrollController: handle.scrollController,
      config: quill.QuillEditorConfig(
        scrollable: false,
        expands: false,
        minHeight: minimumHeight,
        padding: citation
            ? const EdgeInsets.fromLTRB(18, 10, 18, 10)
            : const EdgeInsets.fromLTRB(14, 6, 14, 8),
        placeholder: citation
            ? 'Reflect on this passage…'
            : showGeneralPlaceholder
                ? 'Write your private reflection…'
                : null,
        disableClipboard: true,
        enableSelectionToolbar: false,
      ),
    );
    if (!citation) return editor;
    return ColoredBox(color: Colors.white, child: editor);
  }
}

Color _colorFromHex(String hex) {
  final value = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}
