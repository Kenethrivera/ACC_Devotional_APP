import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/reflection_workspace.dart';
import '../reader_design_tokens.dart';

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
    _dismissEditingOverlays();
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    setState(() {
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
      _ensureTrailingParagraph();
    });
    _notifyChanged();
  }

  void _move(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _blocks.length) return;
    _dismissEditingOverlays();
    setState(() {
      final block = _blocks.removeAt(index);
      _blocks.insert(next, block);
      _ensureTrailingParagraph();
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
                onReorderStart: (_) => _dismissEditingOverlays(),
                onReorder: _reorder,
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
                      canMoveUp: index > 0,
                      canMoveDown: index < _blocks.length - 1,
                      onPrepareDrag: _dismissEditingOverlays,
                      onMoveUp: () => _move(index, -1),
                      onMoveDown: () => _move(index, 1),
                      onToggleCollapsed: () => setState(
                        () => block.collapsed = !block.collapsed,
                      ),
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
  final ReflectionCitation? citation;
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
}

class _ReflectionBlockView extends StatelessWidget {
  final _BlockHandle handle;
  final int index;
  final bool showGeneralPlaceholder;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onPrepareDrag;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onRemove;

  const _ReflectionBlockView({
    required this.handle,
    required this.index,
    required this.showGeneralPlaceholder,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onPrepareDrag,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onToggleCollapsed,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final citation = handle.citation;
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    final citationTint = citation?.source == ReflectionCitationSource.bible
        ? const Color(0xFFF1F8F3)
        : ReaderDesign.surfaceLow;
    return Container(
      key: handle.blockKey,
      decoration: citation == null
          ? null
          : BoxDecoration(
              color: citationTint,
              borderRadius: BorderRadius.circular(mobile ? 16 : 12),
              border: mobile
                  ? null
                  : Border.all(
                      color: citation.source == ReflectionCitationSource.bible
                          ? const Color(0xFFB9DEC6)
                          : const Color(0xFFBAE1F7),
                    ),
              boxShadow: mobile ? ReaderDesign.cardShadow : null,
            ),
      clipBehavior: citation == null ? Clip.none : Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (citation != null)
            _BlockControls(
              index: index,
              label: 'Reflection Paragraph',
              canMoveUp: canMoveUp,
              canMoveDown: canMoveDown,
              onPrepareDrag: onPrepareDrag,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
              collapsible: true,
              collapsed: handle.collapsed,
              onToggleCollapsed: onToggleCollapsed,
              onRemove: onRemove,
            ),
          if (citation != null && !handle.collapsed) ...[
            _CitationHeader(citation: citation),
            const Divider(height: 1),
          ],
          if (!handle.collapsed)
            _EditorSurface(
              handle: handle,
              minimumHeight: citation == null ? 44 : 88,
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
  const _CitationHeader({required this.citation});

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    final bible = citation.source == ReflectionCitationSource.bible;
    final tint = citation.highlightColor == null
        ? (bible ? const Color(0xFFF7FBF8) : const Color(0xF7FFFFFF))
        : _colorFromHex(citation.highlightColor!.hex).withAlpha(70);
    final source = citation.source == ReflectionCitationSource.bible
        ? [citation.scriptureReference, citation.translationId]
            .whereType<String>()
            .join(' · ')
        : citation.devotionalTitle ?? 'Daily devotion';
    return Container(
      width: double.infinity,
      color: tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            citation.source == ReflectionCitationSource.bible
                ? 'BIBLE CITATION'
                : 'DEVOTION CITATION',
            style: ReaderDesign.ui(
              mobile: mobile,
              color: bible ? ReaderDesign.secondary : ReaderDesign.brand,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.85,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            source,
            style: ReaderDesign.ui(
              mobile: mobile,
              color: bible ? ReaderDesign.secondary : ReaderDesign.brand,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '“${citation.selectedText}”',
            style: ReaderDesign.editorial(
              color: ReaderDesign.muted,
              fontSize: mobile ? 14 : 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockControls extends StatelessWidget {
  final int index;
  final String label;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onPrepareDrag;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool collapsible;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onRemove;

  const _BlockControls({
    required this.index,
    required this.label,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onPrepareDrag,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.collapsible,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Row(
      children: [
        Listener(
          onPointerDown: (_) => onPrepareDrag(),
          child: ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Tooltip(
                message: 'Drag to move block',
                child: Icon(Icons.drag_indicator_rounded,
                    color: AppColors.mutedText, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: ReaderDesign.ui(
              mobile: mobile,
              color: ReaderDesign.brand,
              fontSize: mobile ? 13 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!mobile) ...[
          IconButton(
            tooltip: 'Move up',
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Move down',
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ),
        ],
        if (collapsible)
          IconButton(
            tooltip: collapsed ? 'Expand block' : 'Collapse block',
            onPressed: onToggleCollapsed,
            icon: Icon(
              collapsed
                  ? Icons.expand_more_rounded
                  : Icons.expand_less_rounded,
              size: 20,
            ),
          ),
        IconButton(
          tooltip: 'Remove block',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ],
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
            ? const EdgeInsets.all(14)
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
    return ColoredBox(color: const Color(0xBFFFFFFF), child: editor);
  }
}

Color _colorFromHex(String hex) {
  final value = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}
