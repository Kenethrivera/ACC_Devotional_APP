import 'package:flutter/foundation.dart';

import '../../domain/bible/bible_provider.dart';
import '../../domain/errors/devotional_repository_exception.dart';
import '../../domain/models/assigned_devotional.dart';
import '../../domain/models/devotional_participation.dart';
import '../../domain/models/reader_preferences.dart';
import '../../domain/models/reflection_workspace.dart';
import '../../domain/models/text_highlight.dart';
import '../../domain/repositories/devotional_repository.dart';

enum DevotionalReaderStatus { loading, unavailable, futureLocked, ready, failure }

class BibleSlotState {
  final String translationId;
  final BiblePassage? passage;
  final BibleProviderException? failure;
  final bool loading;

  const BibleSlotState({
    required this.translationId,
    this.passage,
    this.failure,
    this.loading = false,
  });
}

class DevotionalReaderController extends ChangeNotifier {
  final DevotionalRepository _repository;
  final BibleProvider _bibleProvider;
  final DateTime? requestedManilaDate;

  DevotionalReaderController(
    this._repository,
    this._bibleProvider, {
    this.requestedManilaDate,
  });

  DevotionalReaderStatus _status = DevotionalReaderStatus.loading;
  AssignedDevotional? _devotional;
  DevotionalReadingState? _readingState;
  ReflectionWorkspace? _reflection;
  ReaderPreferences _preferences = ReaderPreferences.defaults;
  List<DevotionalTextHighlight> _devotionalHighlights = const [];
  final Map<String, List<BibleTextHighlight>> _bibleHighlights = {};
  List<BibleSlotState> _bibleSlots = const [];
  DevotionalRepositoryException? _failure;
  DevotionalRepositoryException? _actionFailure;
  DevotionalRepositoryException? _persistenceWarning;
  bool _isSavingReflection = false;
  bool _isDeletingReflection = false;
  bool _isSavingHighlight = false;
  int _requestVersion = 0;
  bool _disposed = false;

  DevotionalReaderStatus get status => _status;
  AssignedDevotional? get devotional => _devotional;
  DevotionalReadingState? get readingState => _readingState;
  ReflectionWorkspace? get reflection => _reflection;
  ReaderPreferences get preferences => _preferences;
  List<DevotionalTextHighlight> get devotionalHighlights => _devotionalHighlights;
  List<BibleSlotState> get bibleSlots => _bibleSlots;
  List<BibleTranslation> get supportedTranslations => _bibleProvider.supportedTranslations;
  DevotionalRepositoryException? get failure => _failure;
  DevotionalRepositoryException? get actionFailure => _actionFailure;
  DevotionalRepositoryException? get persistenceWarning => _persistenceWarning;
  bool get isSavingReflection => _isSavingReflection;
  bool get isDeletingReflection => _isDeletingReflection;
  bool get isSavingHighlight => _isSavingHighlight;

  List<BibleTextHighlight> bibleHighlightsFor(String translationId) =>
      _bibleHighlights[translationId] ?? const [];

  Future<void> load() async {
    final requestVersion = ++_requestVersion;
    _status = DevotionalReaderStatus.loading;
    _devotional = null;
    _readingState = null;
    _reflection = null;
    _failure = null;
    _actionFailure = null;
    _persistenceWarning = null;
    _devotionalHighlights = const [];
    _bibleHighlights.clear();
    _bibleSlots = const [];
    _notify();

    try {
      final today = await _repository.getManilaToday();
      if (requestVersion != _requestVersion) return;
      final target = requestedManilaDate ?? today;
      if (_isAfter(target, today)) {
        _status = DevotionalReaderStatus.futureLocked;
        _failure = const DevotionalRepositoryException(
          kind: DevotionalFailureKind.futureLocked,
          message: 'This devotional will unlock on its scheduled Manila date.',
        );
        _notify();
        return;
      }

      final devotional = await _repository.getAssignmentForDate(manilaDate: target);
      if (requestVersion != _requestVersion) return;
      if (devotional == null) {
        _status = DevotionalReaderStatus.unavailable;
        _notify();
        return;
      }

      _devotional = devotional;
      _status = DevotionalReaderStatus.ready;
      _notify();
      await _loadPrivateState(devotional, requestVersion);
    } on DevotionalRepositoryException catch (error) {
      if (requestVersion != _requestVersion) return;
      _failure = error;
      _status = error.kind == DevotionalFailureKind.futureLocked
          ? DevotionalReaderStatus.futureLocked
          : DevotionalReaderStatus.failure;
      _notify();
    }
  }

  Future<void> _loadPrivateState(AssignedDevotional devotional, int requestVersion) async {
    try {
      _preferences = await _repository.getReaderPreferences();
    } on DevotionalRepositoryException catch (error) {
      _rememberPersistenceWarning(error);
      _preferences = ReaderPreferences.defaults;
    }
    if (requestVersion != _requestVersion) return;

    final supportedIds = supportedTranslations.map((item) => item.id).toSet();
    final ids = _preferences.bibleTranslationIds
        .where(supportedIds.contains)
        .toSet()
        .toList(growable: false);
    final displayIds = ids.isEmpty ? const <String>['ASV'] : ids;
    _preferences = ReaderPreferences(
      layout: _preferences.layout,
      bibleTranslationIds: displayIds,
      updatedAt: _preferences.updatedAt,
    );
    _bibleSlots = displayIds
        .map((id) => BibleSlotState(translationId: id, loading: true))
        .toList(growable: false);
    _notify();

    try {
      _readingState = await _repository.recordOpening(
        assignmentId: devotional.assignment.id,
      );
    } on DevotionalRepositoryException catch (error) {
      _rememberPersistenceWarning(error);
    }
    if (requestVersion != _requestVersion) return;

    try {
      _reflection = await _repository.getReflectionWorkspace(
        scheduledDate: devotional.assignment.scheduledDate,
      );
    } on DevotionalRepositoryException catch (error) {
      _rememberPersistenceWarning(error);
    }
    if (requestVersion != _requestVersion) return;

    try {
      _devotionalHighlights = await _repository.listDevotionalHighlights(
        devotionalVersionId: devotional.content.id,
      );
    } on DevotionalRepositoryException catch (error) {
      _rememberPersistenceWarning(error);
    }
    if (requestVersion != _requestVersion) return;

    await _loadBibleSlots(
      devotional.content.scriptureReference,
      requestVersion: requestVersion,
    );
    if (requestVersion == _requestVersion) _notify();
  }

  Future<void> _loadBibleSlots(
    String reference, {
    int? requestVersion,
  }) async {
    final slots = <BibleSlotState>[];
    for (final id in _preferences.bibleTranslationIds) {
      if (requestVersion != null && requestVersion != _requestVersion) return;
      try {
        final passage = await _bibleProvider.getPassage(
          reference: reference,
          translationId: id,
        );
        if (requestVersion != null && requestVersion != _requestVersion) return;
        slots.add(BibleSlotState(translationId: id, passage: passage));
        try {
          _bibleHighlights[id] = await _repository.listBibleHighlights(
            translationId: id,
            passageKey: passage.normalizedReference,
          );
        } on DevotionalRepositoryException catch (error) {
          _rememberPersistenceWarning(error);
        }
        if (requestVersion != null && requestVersion != _requestVersion) return;
      } on BibleProviderException catch (error) {
        slots.add(BibleSlotState(translationId: id, failure: error));
      }
    }
    if (requestVersion != null && requestVersion != _requestVersion) return;
    _bibleSlots = slots;
  }

  Future<bool> saveReflection({
    required ReflectionWorkspaceDraft workspace,
  }) async {
    final devotional = _devotional;
    if (devotional == null || _isSavingReflection) return false;
    if (!workspace.hasWrittenContent) {
      _actionFailure = const DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidData,
        message: 'Write a reflection before saving.',
      );
      _notify();
      return false;
    }

    _isSavingReflection = true;
    _actionFailure = null;
    _notify();
    try {
      _reflection = await _repository.saveReflectionWorkspace(
        assignmentId: devotional.assignment.id,
        workspace: workspace,
      );
      try {
        _readingState = await _repository.getReadingState(
          scheduledDate: devotional.assignment.scheduledDate,
        );
      } on DevotionalRepositoryException catch (error) {
        // The save RPC already returned the persisted document and atomically
        // recorded Reflected/Read. A follow-up metadata refresh failure must
        // not be reported as a failed save.
        _rememberPersistenceWarning(error);
      }
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      return false;
    } finally {
      _isSavingReflection = false;
      _notify();
    }
  }

  Future<bool> deleteReflection() async {
    final devotional = _devotional;
    if (devotional == null || _isDeletingReflection) return false;
    _isDeletingReflection = true;
    _actionFailure = null;
    _notify();
    try {
      await _repository.deleteReflectionWorkspace(
        scheduledDate: devotional.assignment.scheduledDate,
      );
      _reflection = null;
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      return false;
    } finally {
      _isDeletingReflection = false;
      _notify();
    }
  }

  Future<void> setLayout(ReaderLayoutPreference layout) async {
    _preferences = ReaderPreferences(
      layout: layout,
      bibleTranslationIds: _preferences.bibleTranslationIds,
      updatedAt: _preferences.updatedAt,
    );
    _notify();
    await _savePreferences();
  }

  Future<void> addBibleVersion(String translationId) async {
    if (_preferences.bibleTranslationIds.contains(translationId)) return;
    _preferences = ReaderPreferences(
      layout: _preferences.layout,
      bibleTranslationIds: [..._preferences.bibleTranslationIds, translationId],
      updatedAt: _preferences.updatedAt,
    );
    final reference = _devotional?.content.scriptureReference;
    if (reference != null) await _loadBibleSlots(reference);
    _notify();
    await _savePreferences();
  }

  Future<void> changeBibleVersion(int slotIndex, String translationId) async {
    if (slotIndex < 0 || slotIndex >= _preferences.bibleTranslationIds.length) return;
    final existingIndex = _preferences.bibleTranslationIds.indexOf(translationId);
    if (existingIndex >= 0 && existingIndex != slotIndex) return;
    final ids = [..._preferences.bibleTranslationIds];
    ids[slotIndex] = translationId;
    _preferences = ReaderPreferences(
      layout: _preferences.layout,
      bibleTranslationIds: ids,
      updatedAt: _preferences.updatedAt,
    );
    final reference = _devotional?.content.scriptureReference;
    if (reference != null) await _loadBibleSlots(reference);
    _notify();
    await _savePreferences();
  }

  Future<void> _savePreferences() async {
    try {
      _preferences = await _repository.saveReaderPreferences(
        layout: _preferences.layout,
        bibleTranslationIds: _preferences.bibleTranslationIds,
      );
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
    }
    _notify();
  }

  Future<bool> saveDevotionalHighlight(
    TextSelectionAnchor anchor,
    HighlightColor color,
  ) async {
    final devotional = _devotional;
    if (devotional == null || !anchor.isValid || _isSavingHighlight) return false;
    final body = devotional.content.body;
    if (anchor.endOffset > body.length ||
        body.substring(anchor.startOffset, anchor.endOffset) != anchor.selectedText) {
      _actionFailure = const DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidSelection,
        message: 'The selected devotional text changed. Select it again.',
      );
      _notify();
      return false;
    }
    _isSavingHighlight = true;
    _notify();
    try {
      final saved = await _repository.saveDevotionalHighlight(
        devotionalVersionId: devotional.content.id,
        startOffset: anchor.startOffset,
        endOffset: anchor.endOffset,
        color: color,
        selectedText: anchor.selectedText,
        prefixContext: body.substring(
          (anchor.startOffset - 24).clamp(0, body.length).toInt(),
          anchor.startOffset,
        ),
        suffixContext: body.substring(
          anchor.endOffset,
          (anchor.endOffset + 24).clamp(0, body.length).toInt(),
        ),
      );
      _devotionalHighlights = [
        ..._devotionalHighlights.where((item) =>
            item.startOffset != saved.startOffset ||
            item.endOffset != saved.endOffset),
        saved,
      ];
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      return false;
    } finally {
      _isSavingHighlight = false;
      _notify();
    }
  }

  Future<bool> removeDevotionalHighlights(TextSelectionAnchor anchor) async {
    final overlapping = _devotionalHighlights
        .where((item) => item.startOffset < anchor.endOffset && item.endOffset > anchor.startOffset)
        .toList()
      ..sort((a, b) {
        final start = a.startOffset.compareTo(b.startOffset);
        return start != 0 ? start : a.endOffset.compareTo(b.endOffset);
      });
    final exact = overlapping
        .where((item) => item.startOffset == anchor.startOffset && item.endOffset == anchor.endOffset)
        .toList(growable: false);
    final matches = exact.isNotEmpty
        ? exact
        : (overlapping.isEmpty ? <DevotionalTextHighlight>[] : <DevotionalTextHighlight>[overlapping.first]);
    if (matches.isEmpty) return true;
    try {
      await _repository.deleteDevotionalHighlights(
        ids: matches.map((item) => item.id).toList(growable: false),
      );
      final ids = matches.map((item) => item.id).toSet();
      _devotionalHighlights = _devotionalHighlights
          .where((item) => !ids.contains(item.id))
          .toList(growable: false);
      _notify();
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      _notify();
      return false;
    }
  }

  Future<bool> saveBibleHighlight(
    BiblePassage passage,
    TextSelectionAnchor anchor,
    HighlightColor color,
  ) async {
    if (!anchor.isValid ||
        anchor.endOffset > passage.text.length ||
        passage.text.substring(anchor.startOffset, anchor.endOffset) !=
            anchor.selectedText) {
      _actionFailure = const DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidSelection,
        message: 'The selected Bible text changed. Select it again.',
      );
      _notify();
      return false;
    }
    try {
      final saved = await _repository.saveBibleHighlight(
        translationId: passage.translation.id,
        passageKey: passage.normalizedReference,
        // The local provider exposes a passage reference, not per-verse IDs.
        // Keep this nullable rather than presenting a range as a verse anchor.
        verseIdentity: null,
        startOffset: anchor.startOffset,
        endOffset: anchor.endOffset,
        color: color,
        selectedText: anchor.selectedText,
      );
      _bibleHighlights[passage.translation.id] = [
        ...bibleHighlightsFor(passage.translation.id).where((item) =>
            item.startOffset != saved.startOffset ||
            item.endOffset != saved.endOffset),
        saved,
      ];
      _notify();
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      _notify();
      return false;
    }
  }

  Future<bool> removeBibleHighlights(
    String translationId,
    TextSelectionAnchor anchor,
  ) async {
    final overlapping = bibleHighlightsFor(translationId)
        .where((item) => item.startOffset < anchor.endOffset && item.endOffset > anchor.startOffset)
        .toList()
      ..sort((a, b) {
        final start = a.startOffset.compareTo(b.startOffset);
        return start != 0 ? start : a.endOffset.compareTo(b.endOffset);
      });
    final exact = overlapping
        .where((item) => item.startOffset == anchor.startOffset && item.endOffset == anchor.endOffset)
        .toList(growable: false);
    final matches = exact.isNotEmpty
        ? exact
        : (overlapping.isEmpty ? <BibleTextHighlight>[] : <BibleTextHighlight>[overlapping.first]);
    if (matches.isEmpty) return true;
    try {
      await _repository.deleteBibleHighlights(
        ids: matches.map((item) => item.id).toList(growable: false),
      );
      final ids = matches.map((item) => item.id).toSet();
      _bibleHighlights[translationId] = bibleHighlightsFor(translationId)
          .where((item) => !ids.contains(item.id))
          .toList(growable: false);
      _notify();
      return true;
    } on DevotionalRepositoryException catch (error) {
      _actionFailure = error;
      _notify();
      return false;
    }
  }

  void clearActionFailure() {
    _actionFailure = null;
    _notify();
  }

  void _rememberPersistenceWarning(DevotionalRepositoryException error) {
    _persistenceWarning ??= error;
  }

  bool _isAfter(DateTime first, DateTime second) =>
      DateTime(first.year, first.month, first.day)
          .isAfter(DateTime(second.year, second.month, second.day));

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
