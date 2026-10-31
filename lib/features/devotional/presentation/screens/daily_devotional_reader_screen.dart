import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/widgets/acc_brand_mark.dart';
import '../../data/local_bible_provider.dart';
import '../../domain/bible/bible_provider.dart';
import '../../domain/models/reflection_workspace.dart';
import '../../domain/models/reader_preferences.dart';
import '../../domain/models/text_highlight.dart';
import '../../domain/repositories/devotional_repository.dart';
import '../controllers/devotional_reader_controller.dart';
import '../reader_design_tokens.dart';
import '../widgets/contextual_highlight_toolbar.dart';
import '../widgets/reflection_workspace_view.dart';

class DailyDevotionalReaderScreen extends StatefulWidget {
  final DevotionalRepository repository;
  final BibleProvider bibleProvider;
  final DateTime? requestedManilaDate;

  const DailyDevotionalReaderScreen({
    super.key,
    required this.repository,
    this.bibleProvider = const LocalBibleProvider(),
    this.requestedManilaDate,
  });

  @override
  State<DailyDevotionalReaderScreen> createState() =>
      _DailyDevotionalReaderScreenState();
}

class _DailyDevotionalReaderScreenState
    extends State<DailyDevotionalReaderScreen> {
  static const _sideBySideMinimumWidth = ReaderDesign.desktopBreakpoint;
  static const _phoneBreakpoint = ReaderDesign.mobileBreakpoint;

  late final DevotionalReaderController _controller;
  final GlobalKey<ReflectionWorkspaceViewState> _workspaceKey = GlobalKey();
  final ValueNotifier<int> _highlightToolbarDismissal = ValueNotifier(0);
  bool _reflectionDirty = false;
  bool _allowPop = false;
  final Map<String, TextSelectionAnchor> _bibleSelections = {};

  @override
  void initState() {
    super.initState();
    _controller = DevotionalReaderController(
      widget.repository,
      widget.bibleProvider,
      requestedManilaDate: widget.requestedManilaDate,
    );
    _controller.load();
  }

  @override
  void dispose() {
    ContextMenuController.removeAny();
    _dismissHighlightToolbar();
    _highlightToolbarDismissal.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _dismissHighlightToolbar();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: _allowPop || !_reflectionDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) _popAfterDiscard();
      },
      child: Scaffold(
        backgroundColor: ReaderDesign.canvas,
        body: Stack(
          children: [
            const Positioned.fill(child: _ReaderBackground()),
            SafeArea(
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => _ReaderNavigationBar(
                      mobile: width < _phoneBreakpoint,
                      showBack: kIsWeb || width >= _phoneBreakpoint,
                      sideBySideAvailable:
                          width >= _sideBySideMinimumWidth,
                      horizontalPadding: width < _phoneBreakpoint
                          ? 8
                          : width > _sideBySideMinimumWidth
                              ? 48
                              : 28,
                      selectedLayout: _controller.preferences.layout,
                      onBack: _requestBack,
                      onLayoutSelected: _controller.setLayout,
                    ),
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => _buildBody(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.status) {
      case DevotionalReaderStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DevotionalReaderStatus.unavailable:
        return _ReaderMessage(
          icon: Icons.menu_book_outlined,
          title: 'No devotion is available',
          message: 'There is no published assignment for this Manila date.',
          action: _controller.load,
        );
      case DevotionalReaderStatus.futureLocked:
        return _ReaderMessage(
          icon: Icons.lock_clock_outlined,
          title: 'This devotion is still locked',
          message: _controller.failure?.message ?? 'Please return on its scheduled date.',
          action: _requestBack,
        );
      case DevotionalReaderStatus.failure:
        return _ReaderMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to open this devotion',
          message: _controller.failure?.message ?? 'Please try again.',
          action: _controller.load,
        );
      case DevotionalReaderStatus.ready:
        return _buildReader(context);
    }
  }

  Widget _buildReader(BuildContext context) {
    final devotional = _controller.devotional;
    if (devotional == null) {
      return _ReaderMessage(
        icon: Icons.error_outline_rounded,
        title: 'Devotion unavailable',
        message: 'The devotional content could not be loaded.',
        action: _controller.load,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final phone = constraints.maxWidth < _phoneBreakpoint;
        final sideBySideAvailable =
            constraints.maxWidth >= _sideBySideMinimumWidth;
        final sideBySide = sideBySideAvailable &&
            _controller.preferences.layout ==
                ReaderLayoutPreference.sideBySide;
        final padding = _readerHorizontalGutter(constraints.maxWidth);

        return NotificationListener<ScrollNotification>(
          onNotification: (_) {
            _dismissHighlightToolbar();
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, phone ? 16 : 24, padding, 52),
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ReaderDesign.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DevotionalHeader(
                    title: devotional.content.title,
                    scriptureReference: devotional.content.scriptureReference,
                    scheduledDate: devotional.assignment.scheduledDate,
                  ),
                  if (_controller.persistenceWarning != null) ...[
                    const SizedBox(height: 14),
                    _PersistenceNotice(
                      message: _controller.persistenceWarning!.message,
                    ),
                  ],
                  SizedBox(height: phone ? 24 : 24),
                  _BiblePassageContainer(
                    reference: devotional.content.scriptureReference,
                    slots: _controller.bibleSlots,
                    supportedTranslations: _controller.supportedTranslations,
                    selectedTranslationIds:
                        _controller.preferences.bibleTranslationIds,
                    highlightsFor: _controller.bibleHighlightsFor,
                    toolbarDismissal: _highlightToolbarDismissal,
                    onSelection: _captureBibleSelection,
                    onHighlight: _highlightBibleSelection,
                    onRemoveHighlight: _removeBibleHighlight,
                    onMoreColors: _chooseBibleCustomHighlightColor,
                    onCite: _citeBibleSelection,
                    onAddVersion: (translationId) {
                      ContextMenuController.removeAny();
                      _dismissHighlightToolbar();
                      return _controller.addBibleVersion(translationId);
                    },
                    onChangeVersion: (index, translationId) {
                      ContextMenuController.removeAny();
                      _dismissHighlightToolbar();
                      return _controller.changeBibleVersion(
                        index,
                        translationId,
                      );
                    },
                  ),
                  SizedBox(height: phone ? 24 : 24),
                  if (sideBySide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDevotionCard(devotional.content.body)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildReflectionCard()),
                      ],
                    )
                  else ...[
                    _buildDevotionCard(devotional.content.body),
                    const SizedBox(height: 24),
                    _buildReflectionCard(),
                  ],
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  double _readerHorizontalGutter(double width) {
    if (width < _phoneBreakpoint) return 20;
    if (width <= _sideBySideMinimumWidth) return 28;
    const targetDesktopWidth = 1366.0;
    const targetDesktopGutter = 80.0;
    final progress = ((width - _sideBySideMinimumWidth) /
            (targetDesktopWidth - _sideBySideMinimumWidth))
        .clamp(0.0, 1.0)
        .toDouble();
    return 28 + ((targetDesktopGutter - 28) * progress);
  }

  Widget _buildDevotionCard(String body) {
    final mobile = MediaQuery.sizeOf(context).width < _phoneBreakpoint;
    return _SectionCard(
      eyebrow: 'DEVOTION',
      title: 'A thought for today',
      icon: mobile ? Icons.lightbulb_outline_rounded : Icons.menu_book_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HighlightableText(
            text: body,
            toolbarDismissal: _highlightToolbarDismissal,
            textAlign: TextAlign.justify,
            highlights: _controller.devotionalHighlights
                .map((item) => _PaintedRange(
                      start: item.startOffset,
                      end: item.endOffset,
                      color: item.color,
                    ))
                .toList(growable: false),
            style: ReaderDesign.ui(
              mobile: mobile,
              color: ReaderDesign.body,
              fontSize: 17,
              height: mobile ? 1.65 : 1.7,
              letterSpacing: mobile ? 0.17 : null,
            ),
            onSelection: (_) {},
            onSelectionDismissed: () {},
            onColor: _applyDevotionalHighlight,
            onMoreColors: (selection) async {
              final color = await _chooseCustomHighlightColor();
              if (color != null && mounted) {
                unawaited(_applyDevotionalHighlight(selection, color));
              }
            },
            onRemove: _removeDevotionalHighlight,
            onCite: _citeDevotionalSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard() {
    final mobile = MediaQuery.sizeOf(context).width < _phoneBreakpoint;
    return _SectionCard(
      eyebrow: 'PRIVATE REFLECTION',
      title: 'What is God showing you?',
      icon: Icons.edit_note_rounded,
      trailing: _reflectionDirty
          ? const _UnsavedBadge()
          : _controller.reflection == null
              ? null
              : const _SavedBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReflectionWorkspaceView(
            key: _workspaceKey,
            initialWorkspace: _controller.reflection,
            onDirtyChanged: (dirty) {
              if (mounted && dirty != _reflectionDirty) {
                setState(() => _reflectionDirty = dirty);
              }
            },
          ),
          SizedBox(height: mobile ? 12 : 18),
          if (!mobile) ...[
            const Divider(color: ReaderDesign.outline),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            children: [
              if (_controller.reflection != null)
                TextButton.icon(
                  onPressed: _controller.isDeletingReflection ? null : _deleteReflection,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: mobile
                      ? ReaderDesign.mobilePrimary
                      : ReaderDesign.brand,
                  foregroundColor: Colors.white,
                  minimumSize: Size(
                    mobile
                        ? (MediaQuery.sizeOf(context).width - 88)
                            .clamp(0, double.infinity)
                            .toDouble()
                        : 0,
                    48,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      mobile ? 999 : 12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                onPressed: !_reflectionDirty || _controller.isSavingReflection
                    ? null
                    : _saveReflection,
                icon: _controller.isSavingReflection
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_controller.isSavingReflection ? 'Saving…' : 'Save Reflection'),
              ),
            ],
          ),
          if (_controller.actionFailure != null) ...[
            const SizedBox(height: 10),
            Text(
              _controller.actionFailure!.message,
              style: const TextStyle(color: Color(0xFFA23A3A), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _captureBibleSelection(BiblePassage passage, TextSelectionAnchor anchor) {
    _bibleSelections[passage.translation.id] = anchor;
  }

  void _dismissHighlightToolbar() {
    _highlightToolbarDismissal.value++;
  }

  Future<void> _highlightBibleSelection(BiblePassage passage, HighlightColor color) async {
    final selection = _bibleSelections.remove(passage.translation.id);
    if (selection != null) {
      final success = await _controller.saveBibleHighlight(passage, selection, color);
      if (mounted) _showHighlightFailure(success);
    }
  }

  Future<void> _removeBibleHighlight(BiblePassage passage) async {
    final selection = _bibleSelections.remove(passage.translation.id);
    if (selection != null) {
      final success = await _controller.removeBibleHighlights(passage.translation.id, selection);
      if (mounted) _showHighlightFailure(success);
    }
  }

  Future<void> _chooseBibleCustomHighlightColor(
    BiblePassage passage,
    TextSelectionAnchor selection,
  ) async {
    _captureBibleSelection(passage, selection);
    final color = await _chooseCustomHighlightColor();
    if (color != null && mounted) {
      unawaited(_highlightBibleSelection(passage, color));
    } else {
      _bibleSelections.remove(passage.translation.id);
    }
  }

  Future<HighlightColor?> _chooseCustomHighlightColor() =>
      showCustomHighlightColorPicker(context);

  void _citeBibleSelection(
    BiblePassage passage,
    TextSelectionAnchor selection,
  ) {
    _bibleSelections.remove(passage.translation.id);
    final highlight = _matchingHighlight(
      _controller.bibleHighlightsFor(passage.translation.id),
      selection,
    );
    _workspaceKey.currentState?.addCitation(
      ReflectionCitation(
        source: ReflectionCitationSource.bible,
        selectedText: selection.selectedText,
        startOffset: selection.startOffset,
        endOffset: selection.endOffset,
        highlightColor: highlight?.color,
        scriptureReference: passage.reference,
        translationId: passage.translation.id,
        verseIdentity: null,
        passageKey: passage.normalizedReference,
      ),
    );
  }

  void _citeDevotionalSelection(TextSelectionAnchor selection) {
    final devotional = _controller.devotional;
    if (devotional == null) return;
    final highlight = _matchingHighlight(
      _controller.devotionalHighlights,
      selection,
    );
    _workspaceKey.currentState?.addCitation(
      ReflectionCitation(
        source: ReflectionCitationSource.devotion,
        selectedText: selection.selectedText,
        startOffset: selection.startOffset,
        endOffset: selection.endOffset,
        highlightColor: highlight?.color,
        devotionalVersionId: devotional.content.id,
        devotionalTitle: devotional.content.title,
      ),
    );
  }

  T? _matchingHighlight<T>(
    List<T> highlights,
    TextSelectionAnchor selection,
  ) {
    T? firstOverlap;
    int? firstStart;
    int? firstEnd;
    for (final item in highlights) {
      final start = item is BibleTextHighlight
          ? item.startOffset
          : (item as DevotionalTextHighlight).startOffset;
      final end = item is BibleTextHighlight
          ? item.endOffset
          : (item as DevotionalTextHighlight).endOffset;
      if (start == selection.startOffset && end == selection.endOffset) {
        return item;
      }
      final overlaps = start < selection.endOffset &&
          end > selection.startOffset;
      final comesFirst = firstStart == null ||
          start < firstStart ||
          (start == firstStart && (firstEnd == null || end < firstEnd));
      if (overlaps && comesFirst) {
        firstOverlap = item;
        firstStart = start;
        firstEnd = end;
      }
    }
    return firstOverlap;
  }

  void _showHighlightFailure(bool success) {
    if (success) return;
    AppFeedback.show(
      context,
      message: _controller.actionFailure?.message ?? 'The highlight could not be saved.',
      type: AppMessageType.error,
    );
  }

  Future<void> _applyDevotionalHighlight(
    TextSelectionAnchor selection,
    HighlightColor color,
  ) async {
    final success =
        await _controller.saveDevotionalHighlight(selection, color);
    if (mounted) {
      _showHighlightFailure(success);
    }
  }

  Future<void> _removeDevotionalHighlight(
    TextSelectionAnchor selection,
  ) async {
    final success = await _controller.removeDevotionalHighlights(selection);
    if (mounted) {
      _showHighlightFailure(success);
    }
  }

  Future<void> _saveReflection() async {
    FocusScope.of(context).unfocus();
    final draft = _workspaceKey.currentState?.buildDraft();
    if (draft == null) return;
    final success = await _controller.saveReflection(workspace: draft);
    if (!mounted) return;
    if (success) {
      final saved = _controller.reflection;
      if (saved != null) _workspaceKey.currentState?.markSaved(saved);
      AppFeedback.show(context, message: 'Private reflection saved.', type: AppMessageType.success);
    } else {
      AppFeedback.show(
        context,
        message: _controller.actionFailure?.message ?? 'Reflection could not be saved.',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _deleteReflection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete private reflection?'),
        content: const Text('This removes the saved journal document. It does not erase reading engagement history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await _controller.deleteReflection();
    if (!mounted || !success) return;
    _workspaceKey.currentState?.clearWorkspace();
  }

  Future<void> _requestBack() async {
    if (!_reflectionDirty || await _confirmDiscard()) {
      if (mounted) _popAfterDiscard();
    }
  }

  void _popAfterDiscard() {
    setState(() => _allowPop = true);
    Navigator.of(context).maybePop();
  }

  Future<bool> _confirmDiscard() async {
    if (!_reflectionDirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave without saving?'),
            content: const Text('Your latest reflection changes have not been saved.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep writing')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard changes')),
            ],
          ),
        ) ??
        false;
  }
}

class _ReaderBackground extends StatelessWidget {
  const _ReaderBackground();

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          mobile ? 'asset/bg/mobile_poster.jpg' : 'asset/bg/web_poster.jpg',
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.18),
          filterQuality: FilterQuality.medium,
        ),
        const ColoredBox(color: Color(0xB8E8E8E8)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x26FFFFFF), Color(0x66FFFFFF)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderNavigationBar extends StatelessWidget {
  final bool mobile;
  final bool showBack;
  final bool sideBySideAvailable;
  final double horizontalPadding;
  final ReaderLayoutPreference selectedLayout;
  final VoidCallback onBack;
  final ValueChanged<ReaderLayoutPreference> onLayoutSelected;

  const _ReaderNavigationBar({
    required this.mobile,
    required this.showBack,
    required this.sideBySideAvailable,
    required this.horizontalPadding,
    required this.selectedLayout,
    required this.onBack,
    required this.onLayoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: mobile ? 64 : 60,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(bottom: BorderSide(color: ReaderDesign.outline)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ReaderDesign.maxContentWidth,
          ),
          child: Row(
            children: [
          if (showBack && !mobile) ...[
            IconButton(
              tooltip: 'Back to dashboard',
              onPressed: onBack,
              color: ReaderDesign.body,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
            const SizedBox(width: 4),
          ],
          AccBrandMark(
            height: mobile ? 36 : 32,
            maxWidth: mobile ? 36 : 32,
          ),
          SizedBox(width: mobile ? 7 : 14),
          Expanded(
            child: mobile
                ? const _MobileReaderTitle()
                : Text(
              'Power of 4+ · The Fresh Page',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ReaderDesign.editorial(
                color: ReaderDesign.navy,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (mobile) ...[
            Semantics(
              label: 'Signed-in member',
              image: true,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: ReaderDesign.mobilePrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              ),
            ),
          ] else if (sideBySideAvailable) ...[
            _ReaderLayoutToggle(
              sideBySideAvailable: sideBySideAvailable,
              selectedLayout: selectedLayout,
              onLayoutSelected: onLayoutSelected,
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileReaderTitle extends StatelessWidget {
  const _MobileReaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADELINA CHRISTIAN CHURCH',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReaderDesign.ui(
            mobile: true,
            color: ReaderDesign.brand,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
          ),
        ),
        Text(
          'Power Of 4+ · The Fresh Page',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReaderDesign.editorial(
            color: ReaderDesign.navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReaderLayoutToggle extends StatelessWidget {
  final bool sideBySideAvailable;
  final ReaderLayoutPreference selectedLayout;
  final ValueChanged<ReaderLayoutPreference> onLayoutSelected;

  const _ReaderLayoutToggle({
    required this.sideBySideAvailable,
    required this.selectedLayout,
    required this.onLayoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: ReaderDesign.outline),
      ),
      child: Row(
        children: [
          _LayoutSegment(
            label: 'Side-by-side',
            icon: Icons.view_column_outlined,
            selected: selectedLayout == ReaderLayoutPreference.sideBySide,
            enabled: sideBySideAvailable,
            onPressed: () => onLayoutSelected(ReaderLayoutPreference.sideBySide),
          ),
          _LayoutSegment(
            label: 'Stacked',
            icon: Icons.view_agenda_outlined,
            selected: selectedLayout == ReaderLayoutPreference.stacked,
            enabled: true,
            onPressed: () => onLayoutSelected(ReaderLayoutPreference.stacked),
          ),
        ],
      ),
    );
  }
}

class _LayoutSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  const _LayoutSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: selected ? ReaderDesign.brand : ReaderDesign.muted,
        backgroundColor: selected ? Colors.white : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: ReaderDesign.ui(
          mobile: false,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _DevotionalHeader extends StatelessWidget {
  final String title;
  final String scriptureReference;
  final DateTime scheduledDate;

  const _DevotionalHeader({
    required this.title,
    required this.scriptureReference,
    required this.scheduledDate,
  });

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Container(
      width: double.infinity,
      padding: ReaderDesign.cardPadding(mobile),
      decoration: ReaderDesign.cardDecoration(mobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: mobile
                          ? ReaderDesign.surfaceContainer
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(mobile ? 999 : 6),
                    ),
                    child: Text(
                      'DAILY DEVOTION',
                      style: ReaderDesign.ui(
                        mobile: mobile,
                        color: ReaderDesign.brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.85,
                      ),
                    ),
                  ),
                ),
              ),
              _DateBadge(date: scheduledDate),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: ReaderDesign.editorial(
              color: ReaderDesign.navy,
              fontSize: mobile ? 26 : 42,
              height: mobile ? 1.3 : 1.12,
              fontWeight: FontWeight.w500,
              letterSpacing: mobile ? -0.39 : -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: ReaderDesign.brand,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scriptureReference,
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    color: mobile ? ReaderDesign.brand : ReaderDesign.body,
                    fontSize: mobile ? 14 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BiblePassageContainer extends StatelessWidget {
  final String reference;
  final List<BibleSlotState> slots;
  final List<BibleTranslation> supportedTranslations;
  final List<String> selectedTranslationIds;
  final List<BibleTextHighlight> Function(String translationId) highlightsFor;
  final ValueListenable<int> toolbarDismissal;
  final void Function(BiblePassage, TextSelectionAnchor) onSelection;
  final Future<void> Function(BiblePassage, HighlightColor) onHighlight;
  final Future<void> Function(BiblePassage) onRemoveHighlight;
  final Future<void> Function(BiblePassage, TextSelectionAnchor) onMoreColors;
  final void Function(BiblePassage, TextSelectionAnchor) onCite;
  final Future<void> Function(String) onAddVersion;
  final Future<void> Function(int, String) onChangeVersion;

  const _BiblePassageContainer({
    required this.reference,
    required this.slots,
    required this.supportedTranslations,
    required this.selectedTranslationIds,
    required this.highlightsFor,
    required this.toolbarDismissal,
    required this.onSelection,
    required this.onHighlight,
    required this.onRemoveHighlight,
    required this.onMoreColors,
    required this.onCite,
    required this.onAddVersion,
    required this.onChangeVersion,
  });

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Container(
      width: double.infinity,
      padding: ReaderDesign.cardPadding(mobile),
      decoration: ReaderDesign.cardDecoration(mobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: mobile ? 32 : 36,
                height: mobile ? 32 : 36,
                decoration: BoxDecoration(
                  color: mobile
                      ? ReaderDesign.surfaceContainer
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(mobile ? 999 : 12),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: ReaderDesign.brand,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bible Passage',
                      style: ReaderDesign.editorial(
                        color: ReaderDesign.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reference,
                      style: mobile
                          ? ReaderDesign.ui(
                              mobile: true,
                              color: ReaderDesign.muted,
                              fontSize: 14,
                            )
                          : ReaderDesign.editorial(
                              color: ReaderDesign.muted,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: ReaderDesign.brand,
                  backgroundColor: mobile
                      ? ReaderDesign.surfaceLow
                      : const Color(0xFFF0F9FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: mobile
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFFD9EEFB)),
                  ),
                ),
                onPressed: selectedTranslationIds.length >= supportedTranslations.length
                    ? null
                    : () => _chooseVersion(context, add: true),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  'Add Version',
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (slots.isEmpty)
            const LinearProgressIndicator()
          else
            ...List.generate(slots.length, (index) {
              final slot = slots[index];
              if (slot.loading) return const Padding(padding: EdgeInsets.all(18), child: LinearProgressIndicator());
              if (slot.failure != null) {
                return _BibleFailureCard(
                  translationId: slot.translationId,
                  message: slot.failure!.message,
                  onChange: () => _chooseVersion(context, slotIndex: index),
                );
              }
              final passage = slot.passage!;
              return Padding(
                padding: EdgeInsets.only(bottom: index == slots.length - 1 ? 0 : 14),
                child: _BibleTranslationCard(
                  passage: passage,
                  toolbarDismissal: toolbarDismissal,
                  highlights: highlightsFor(passage.translation.id),
                  onSelection: (selection) => onSelection(passage, selection),
                  onHighlight: (selection, color) {
                    onSelection(passage, selection);
                    return onHighlight(passage, color);
                  },
                  onMoreColors: (selection) => onMoreColors(passage, selection),
                  onRemoveHighlight: (selection) {
                    onSelection(passage, selection);
                    return onRemoveHighlight(passage);
                  },
                  onCite: (selection) => onCite(passage, selection),
                  onChange: () => _chooseVersion(context, slotIndex: index),
                ),
              );
            }),
          const SizedBox(height: 12),
          const Text(
            'Initial local test catalog · no external Bible API is connected',
            style: TextStyle(color: AppColors.mutedText, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseVersion(BuildContext context, {bool add = false, int? slotIndex}) async {
    final available = supportedTranslations
        .where((item) => add || !selectedTranslationIds.contains(item.id) || selectedTranslationIds[slotIndex!] == item.id)
        .toList(growable: false);
    List<Widget> versionTiles(BuildContext routeContext) => [
          for (final item in available)
            ListTile(
              title: Text(item.name),
              subtitle: Text(item.licenseLabel),
              enabled: add ? !selectedTranslationIds.contains(item.id) : true,
              onTap: () => Navigator.pop(routeContext, item.id),
            ),
        ];

    final useDialog = MediaQuery.sizeOf(context).width >= 700;
    String? selected;
    if (useDialog) {
      selected = await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Choose Bible version'),
              content: SizedBox(
                width: 420,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Only public-domain local test versions are available.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 12),
                    ...versionTiles(dialogContext),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
    } else {
      selected = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  const ListTile(
                    title: Text('Choose Bible version'),
                    subtitle: Text(
                      'Only public-domain local test versions are available.',
                    ),
                  ),
                  ...versionTiles(sheetContext),
                ],
              ),
            ),
          );
    }
    if (selected == null) return;
    if (add) {
      await onAddVersion(selected);
    } else if (slotIndex != null) {
      await onChangeVersion(slotIndex, selected);
    }
  }
}

class _BibleTranslationCard extends StatelessWidget {
  final BiblePassage passage;
  final ValueListenable<int> toolbarDismissal;
  final List<BibleTextHighlight> highlights;
  final ValueChanged<TextSelectionAnchor> onSelection;
  final Future<void> Function(TextSelectionAnchor, HighlightColor) onHighlight;
  final Future<void> Function(TextSelectionAnchor) onMoreColors;
  final Future<void> Function(TextSelectionAnchor) onRemoveHighlight;
  final ValueChanged<TextSelectionAnchor> onCite;
  final VoidCallback onChange;

  const _BibleTranslationCard({
    required this.passage,
    required this.toolbarDismissal,
    required this.highlights,
    required this.onSelection,
    required this.onHighlight,
    required this.onMoreColors,
    required this.onRemoveHighlight,
    required this.onCite,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mobile
                ? ReaderDesign.surfaceLow
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(mobile ? 0 : 999),
          ),
          child: Row(
            children: [
              Text(
                passage.translation.id,
                style: ReaderDesign.ui(
                  mobile: mobile,
                  color: ReaderDesign.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  passage.translation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    color: ReaderDesign.muted,
                    fontSize: mobile ? 13 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change',
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    color: ReaderDesign.brand,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: mobile ? 14 : 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(mobile ? 0 : 20),
          decoration: BoxDecoration(
            color: mobile ? Colors.transparent : ReaderDesign.amberSurface,
            borderRadius: BorderRadius.circular(12),
            border: mobile
                ? null
                : Border.all(color: ReaderDesign.amberOutline),
          ),
          child: _HighlightableText(
            text: passage.text,
            toolbarDismissal: toolbarDismissal,
            highlights: highlights
                .map(
                  (item) => _PaintedRange(
                    start: item.startOffset,
                    end: item.endOffset,
                    color: item.color,
                  ),
                )
                .toList(growable: false),
            style: ReaderDesign.editorial(
              color: ReaderDesign.navy,
              fontSize: mobile ? 18 : 20,
              height: mobile ? 1.67 : 1.6,
            ),
            onSelection: onSelection,
            onSelectionDismissed: () {},
            onColor: onHighlight,
            onMoreColors: onMoreColors,
            onRemove: onRemoveHighlight,
            onCite: onCite,
          ),
        ),
        if (passage.translation.licenseLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            passage.translation.licenseLabel,
            style: ReaderDesign.ui(
              mobile: mobile,
              color: ReaderDesign.muted,
              fontSize: 9.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightableText extends StatefulWidget {
  final String text;
  final ValueListenable<int> toolbarDismissal;
  final List<_PaintedRange> highlights;
  final TextStyle style;
  final TextAlign textAlign;
  final ValueChanged<TextSelectionAnchor> onSelection;
  final VoidCallback onSelectionDismissed;
  final Future<void> Function(TextSelectionAnchor, HighlightColor) onColor;
  final Future<void> Function(TextSelectionAnchor) onMoreColors;
  final Future<void> Function(TextSelectionAnchor) onRemove;
  final ValueChanged<TextSelectionAnchor> onCite;

  const _HighlightableText({
    required this.text,
    required this.toolbarDismissal,
    required this.highlights,
    required this.style,
    this.textAlign = TextAlign.start,
    required this.onSelection,
    required this.onSelectionDismissed,
    required this.onColor,
    required this.onMoreColors,
    required this.onRemove,
    required this.onCite,
  });

  @override
  State<_HighlightableText> createState() => _HighlightableTextState();
}

enum _SelectionToolbarPhase { none, selectionFinalized, visible }

class _HighlightableTextState extends State<_HighlightableText>
    with WidgetsBindingObserver {
  static const _maximumToolbarLayoutAttempts = 3;

  TextSelectionAnchor? _selection;
  OverlayEntry? _toolbarEntry;
  bool _pointerIsDown = false;
  int _toolbarRequestGeneration = 0;
  _SelectionToolbarPhase _toolbarPhase = _SelectionToolbarPhase.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.toolbarDismissal.addListener(_dismissToolbar);
  }

  @override
  void didUpdateWidget(covariant _HighlightableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolbarDismissal != widget.toolbarDismissal) {
      oldWidget.toolbarDismissal.removeListener(_dismissToolbar);
      widget.toolbarDismissal.addListener(_dismissToolbar);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.toolbarDismissal.removeListener(_dismissToolbar);
    _dismissToolbar();
    super.dispose();
  }

  @override
  void deactivate() {
    _dismissToolbar();
    super.deactivate();
  }

  @override
  void didChangeMetrics() => _dismissToolbar();

  void _dismissToolbar() {
    _toolbarRequestGeneration++;
    _toolbarPhase = _SelectionToolbarPhase.none;
    _removeToolbarEntry();
  }

  void _removeToolbarEntry() {
    final entry = _toolbarEntry;
    if (entry != null && entry.mounted) entry.remove();
    _toolbarEntry = null;
  }

  void _requestToolbarAfterPointerRelease(PointerUpEvent _) {
    _pointerIsDown = false;
    final selection = _selection;
    if (selection != null) _finalizeSelection(selection);
  }

  void _cancelPointerSelection(PointerCancelEvent _) {
    _pointerIsDown = false;
    _dismissToolbar();
  }

  void _finalizeSelection(TextSelectionAnchor selection) {
    if (!identical(_selection, selection)) return;
    final requestGeneration = ++_toolbarRequestGeneration;
    _toolbarPhase = _SelectionToolbarPhase.selectionFinalized;
    _scheduleToolbarPresentation(
      selection: selection,
      requestGeneration: requestGeneration,
      attempt: 0,
    );
  }

  void _scheduleToolbarPresentation({
    required TextSelectionAnchor selection,
    required int requestGeneration,
    required int attempt,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          requestGeneration != _toolbarRequestGeneration ||
          _toolbarPhase != _SelectionToolbarPhase.selectionFinalized ||
          !identical(_selection, selection)) {
        return;
      }
      if (_tryShowToolbar(selection)) {
        _toolbarPhase = _SelectionToolbarPhase.visible;
        return;
      }
      final nextAttempt = attempt + 1;
      if (nextAttempt >= _maximumToolbarLayoutAttempts) {
        _toolbarPhase = _SelectionToolbarPhase.none;
        return;
      }
      _scheduleToolbarPresentation(
        selection: selection,
        requestGeneration: requestGeneration,
        attempt: nextAttempt,
      );
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  EditableTextState? _findEditableTextState() {
    EditableTextState? result;
    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement) {
        final state = element.state;
        if (state is EditableTextState) {
          result = state;
          return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  void _clearActiveSelection(TextSelectionAnchor capturedSelection) {
    _dismissToolbar();
    ContextMenuController.removeAny();
    final editable = _findEditableTextState();
    if (editable != null && editable.renderEditable.attached) {
      editable.hideToolbar();
      final currentValue = editable.textEditingValue;
      final collapseOffset = capturedSelection.endOffset
          .clamp(0, currentValue.text.length)
          .toInt();
      // A user selection update schedules EditableText.showCaret, which can
      // scroll the reader when the toolbar action collapses the selection.
      // This read-only selection change needs no caret reveal or keyboard focus.
      editable.widget.controller.selection =
          TextSelection.collapsed(offset: collapseOffset);
    }
    _selection = null;
    widget.onSelectionDismissed();
  }

  void _performSelectionAction(
    TextSelectionAnchor capturedSelection,
    VoidCallback action,
  ) {
    _dismissToolbar();
    action();
    _clearActiveSelection(capturedSelection);
  }

  Future<void> _performCustomColorAction(
    TextSelectionAnchor capturedSelection,
  ) async {
    _dismissToolbar();
    await widget.onMoreColors(capturedSelection);
    if (!mounted) return;
    _clearActiveSelection(capturedSelection);
  }

  bool _tryShowToolbar(TextSelectionAnchor selection) {
    _removeToolbarEntry();
    final editable = _findEditableTextState();
    if (editable == null || !editable.renderEditable.attached) return false;
    final renderEditable = editable.renderEditable;
    final textSelection = editable.textEditingValue.selection;
    if (!textSelection.isValid || textSelection.isCollapsed) return false;
    if (textSelection.start != selection.startOffset ||
        textSelection.end != selection.endOffset) {
      return false;
    }
    final endpoints = renderEditable.getEndpointsForSelection(textSelection);
    if (endpoints.isEmpty) return false;
    final lineHeight = renderEditable.preferredLineHeight;
    final selectionRect = TextSelectionToolbarAnchors.getSelectionRect(
      renderEditable,
      lineHeight,
      lineHeight,
      endpoints,
    );
    if (selectionRect == Rect.zero || selectionRect.hasNaN) return false;

    final media = MediaQuery.of(context);
    final viewport = media.size;
    const margin = 8.0;
    const gap = 10.0;
    const toolbarHeight = 46.0;
    final toolbarWidth = viewport.width > 372
        ? 356.0
        : (viewport.width - 16).clamp(1.0, 356.0).toDouble();
    final left = (selectionRect.center.dx - toolbarWidth / 2)
        .clamp(margin, viewport.width - toolbarWidth - margin)
        .toDouble();
    final safeTop = media.padding.top + margin;
    final safeBottom = viewport.height - media.padding.bottom - margin;
    final above = selectionRect.top - toolbarHeight - gap;
    final below = selectionRect.bottom + gap;
    final preferredTop = above >= safeTop ? above : below;
    final maximumTop = safeBottom - toolbarHeight;
    final top = maximumTop <= safeTop
        ? safeTop
        : preferredTop.clamp(safeTop, maximumTop).toDouble();
    final overlay = Overlay.of(context, rootOverlay: true);
    _toolbarEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: left,
        top: top,
        width: toolbarWidth,
        height: toolbarHeight,
        child: ContextualHighlightToolbar(
          onColor: (color) {
            _performSelectionAction(
              selection,
              () => widget.onColor(selection, color),
            );
          },
          onMoreColors: () {
            _performCustomColorAction(selection);
          },
          onRemove: () {
            _performSelectionAction(
              selection,
              () => widget.onRemove(selection),
            );
          },
          onCite: () {
            _performSelectionAction(
              selection,
              () => widget.onCite(selection),
            );
          },
        ),
      ),
    );
    overlay.insert(_toolbarEntry!);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ranges = [...widget.highlights]
      ..sort((a, b) {
        final startComparison = a.start.compareTo(b.start);
        return startComparison != 0
            ? startComparison
            : a.end.compareTo(b.end);
      });
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      final start = range.start.clamp(cursor, widget.text.length).toInt();
      final end = range.end.clamp(start, widget.text.length).toInt();
      if (start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, start)));
      }
      if (end > start) {
        spans.add(TextSpan(
          text: widget.text.substring(start, end),
          style: TextStyle(backgroundColor: _highlightPaint(range.color)),
        ));
      }
      cursor = end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _pointerIsDown = true;
        _dismissToolbar();
      },
      onPointerUp: _requestToolbarAfterPointerRelease,
      onPointerCancel: _cancelPointerSelection,
      child: SelectableText.rich(
        TextSpan(style: widget.style, children: spans),
        textAlign: widget.textAlign,
        onSelectionChanged: (selection, cause) {
          if (selection.isCollapsed) {
            _selection = null;
            _dismissToolbar();
            widget.onSelectionDismissed();
            return;
          }
          _dismissToolbar();
          final start =
              selection.start.clamp(0, widget.text.length).toInt();
          final end =
              selection.end.clamp(start, widget.text.length).toInt();
          final anchor = TextSelectionAnchor(
            startOffset: start,
            endOffset: end,
            selectedText: widget.text.substring(start, end),
          );
          _selection = anchor;
          widget.onSelection(anchor);
          if (!_pointerIsDown || cause == SelectionChangedCause.longPress) {
            _finalizeSelection(anchor);
          }
        },
        contextMenuBuilder: null,
      ),
    );
  }
}

class _PaintedRange {
  final int start;
  final int end;
  final HighlightColor color;
  const _PaintedRange({required this.start, required this.end, required this.color});
}

Color _highlightPaint(HighlightColor color) => highlightColorValue(color);

class _SectionCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.eyebrow, required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Container(
      width: double.infinity,
      padding: ReaderDesign.cardPadding(mobile),
      decoration: ReaderDesign.cardDecoration(mobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: mobile ? 32 : 40,
                height: mobile ? 32 : 40,
                decoration: BoxDecoration(
                  color: mobile
                      ? ReaderDesign.surfaceHigh
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(mobile ? 999 : 12),
                ),
                child: Icon(icon, color: ReaderDesign.brand, size: mobile ? 18 : 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: ReaderDesign.ui(
                        mobile: mobile,
                        color: ReaderDesign.brand,
                        fontSize: mobile ? 11 : 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.85,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: ReaderDesign.editorial(
                        color: ReaderDesign.navy,
                        fontSize: mobile ? 20 : 24,
                        fontWeight: mobile ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailingWidget,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PersistenceNotice extends StatelessWidget {
  final String message;
  const _PersistenceNotice({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.goldSoft.withAlpha(90), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gold)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(child: Text('$message Reading remains available, but saves and synced preferences are not active.', style: const TextStyle(color: AppColors.navy, fontSize: 12, height: 1.4))),
        ]),
      );
}

class _ReaderMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  const _ReaderMessage({required this.icon, required this.title, required this.message, required this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.primary, size: 44),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.lora(color: AppColors.navy, fontSize: 25, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, height: 1.45)),
            const SizedBox(height: 18),
            FilledButton(onPressed: action, child: const Text('Try again')),
          ]),
        ),
      );
}

class _BibleFailureCard extends StatelessWidget {
  final String translationId;
  final String message;
  final VoidCallback onChange;
  const _BibleFailureCard({required this.translationId, required this.message, required this.onChange});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.menu_book_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(child: Text('$translationId · $message', style: const TextStyle(color: AppColors.mutedText, height: 1.4))),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ]),
      );
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});
  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: mobile ? ReaderDesign.surfaceLow : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: mobile ? null : Border.all(color: ReaderDesign.outline),
      ),
      child: Text(
        '${_month(date.month)} ${date.day}, ${date.year}',
        style: ReaderDesign.ui(
          mobile: mobile,
          color: ReaderDesign.body,
          fontSize: mobile ? 12 : 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _UnsavedBadge extends StatelessWidget {
  const _UnsavedBadge();
  @override
  Widget build(BuildContext context) => Text(
        'Unsaved changes',
        style: ReaderDesign.ui(
          mobile: MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint,
          color: AppColors.peachInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: AppColors.sageInk, size: 15),
        SizedBox(width: 4),
        Text('Saved', style: TextStyle(color: AppColors.sageInk, fontSize: 10, fontWeight: FontWeight.w800)),
      ]);
}

String _month(int month) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month - 1];
