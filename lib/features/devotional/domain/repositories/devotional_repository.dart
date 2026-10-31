import '../models/assigned_devotional.dart';
import '../models/devotional_completion.dart';
import '../models/devotional_reflection.dart';
import '../models/devotional_settings.dart';
import '../models/devotional_participation.dart';
import '../models/reader_preferences.dart';
import '../models/reflection_workspace.dart';
import '../models/text_highlight.dart';

/// Member-facing devotional operations.
///
/// Date arguments are date-only values in the Asia/Manila church calendar.
/// Implementations must rely on server enforcement for availability and limits;
/// client-side checks are presentation conveniences only.
abstract class DevotionalRepository {
  /// Returns the server-authoritative current date in the Manila calendar.
  Future<DateTime> getManilaToday();

  /// Returns the latest current published revision for the requested date.
  Future<AssignedDevotional?> getAssignmentForDate({
    required DateTime manilaDate,
  });

  /// Returns an assignment revision by identifier when RLS permits access.
  /// This is used to render the exact immutable revision referenced by a
  /// member's existing completion, even after the official date is replaced.
  Future<AssignedDevotional?> getAssignmentById({
    required String assignmentId,
  });

  /// Lists only the latest current published revision for each available date.
  /// Superseded revisions remain accessible through completion history.
  Future<List<AssignedDevotional>> listAvailableAssignments({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  });

  Future<List<DevotionalCompletion>> listMyCompletions({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  });

  /// Completes the official schedule date exactly once. The server rejects a
  /// second completion through any replacement assignment revision.
  Future<DevotionalCompletion> completeAssignment({
    required String assignmentId,
    String? reflectionText,
  });

  Future<DevotionalReflection?> getMyReflection({
    required String completionId,
  });

  Future<DevotionalReflection> saveMyReflection({
    required String completionId,
    required String text,
  });

  Future<void> deleteMyReflection({required String completionId});

  Future<DevotionalSettings> getSettings();

  /// Records an idempotent opening event. This is engagement metadata, not a
  /// claim that the member read every word and not a legacy completion.
  Future<DevotionalReadingState> recordOpening({
    required String assignmentId,
  });

  Future<DevotionalReadingState?> getReadingState({
    required DateTime scheduledDate,
  });

  Future<List<DevotionalReadingState>> listMyReadingStates({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  });

  Future<ReflectionWorkspace?> getReflectionWorkspace({
    required DateTime scheduledDate,
  });

  /// Atomically saves general and citation-specific private reflection
  /// documents and records Reflected/Read when at least one is nonempty.
  Future<ReflectionWorkspace> saveReflectionWorkspace({
    required String assignmentId,
    required ReflectionWorkspaceDraft workspace,
  });

  Future<void> deleteReflectionWorkspace({required DateTime scheduledDate});

  Future<List<DevotionalTextHighlight>> listDevotionalHighlights({
    required String devotionalVersionId,
  });

  Future<DevotionalTextHighlight> saveDevotionalHighlight({
    required String devotionalVersionId,
    required int startOffset,
    required int endOffset,
    required HighlightColor color,
    required String selectedText,
    String? prefixContext,
    String? suffixContext,
  });

  Future<void> deleteDevotionalHighlights({required List<String> ids});

  Future<List<BibleTextHighlight>> listBibleHighlights({
    required String translationId,
    required String passageKey,
  });

  Future<BibleTextHighlight> saveBibleHighlight({
    required String translationId,
    required String passageKey,
    String? verseIdentity,
    required int startOffset,
    required int endOffset,
    required HighlightColor color,
    required String selectedText,
  });

  Future<void> deleteBibleHighlights({required List<String> ids});

  Future<ReaderPreferences> getReaderPreferences();

  Future<ReaderPreferences> saveReaderPreferences({
    required ReaderLayoutPreference layout,
    required List<String> bibleTranslationIds,
  });
}
