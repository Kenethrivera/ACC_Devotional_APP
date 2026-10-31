import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/errors/devotional_repository_exception.dart';
import '../domain/models/assigned_devotional.dart';
import '../domain/models/devotional_completion.dart';
import '../domain/models/devotional_reflection.dart';
import '../domain/models/devotional_settings.dart';
import '../domain/models/devotional_participation.dart';
import '../domain/models/reader_preferences.dart';
import '../domain/models/reflection_workspace.dart';
import '../domain/models/text_highlight.dart';
import '../domain/repositories/devotional_repository.dart';
import 'devotional_error_mapper.dart';
import 'devotional_row_mapper.dart';

class SupabaseDevotionalRepository implements DevotionalRepository {
  static const _assignmentWithContent =
      '*, devotional_content_versions(*)';

  final SupabaseClient _client;

  SupabaseDevotionalRepository(this._client);

  @override
  Future<DateTime> getManilaToday() {
    return guardDevotionalOperation(() async {
      _requireUserId();
      return parseManilaDateKey(await _manilaTodayKey());
    });
  }

  @override
  Future<AssignedDevotional?> getAssignmentForDate({
    required DateTime manilaDate,
  }) {
    return guardDevotionalOperation(() async {
      _requireUserId();

      final requestedDate = manilaDateKey(manilaDate);
      final today = await _manilaTodayKey();
      if (requestedDate.compareTo(today) > 0) return null;

      final result = await _client
          .from('devotional_assignments')
          .select(_assignmentWithContent)
          .eq('scheduled_date', requestedDate)
          .not('published_at', 'is', null)
          .isFilter('superseded_at', null)
          .maybeSingle();

      if (result == null) return null;
      return mapAssignedDevotional(
        devotionalRow(result, 'devotional assignment'),
      );
    });
  }

  @override
  Future<AssignedDevotional?> getAssignmentById({
    required String assignmentId,
  }) {
    return guardDevotionalOperation(() async {
      _requireUserId();

      final result = await _client
          .from('devotional_assignments')
          .select(_assignmentWithContent)
          .eq('id', assignmentId)
          .maybeSingle();

      if (result == null) return null;
      return mapAssignedDevotional(
        devotionalRow(result, 'devotional assignment'),
      );
    });
  }

  @override
  Future<List<AssignedDevotional>> listAvailableAssignments({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      _requireUserId();

      final from = manilaDateKey(fromManilaDate);
      final requestedThrough = manilaDateKey(throughManilaDate);
      if (from.compareTo(requestedThrough) > 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The devotional date range is invalid.',
        );
      }

      final today = await _manilaTodayKey();
      final through = requestedThrough.compareTo(today) > 0
          ? today
          : requestedThrough;
      if (from.compareTo(through) > 0) {
        return const <AssignedDevotional>[];
      }

      final result = await _client
          .from('devotional_assignments')
          .select(_assignmentWithContent)
          .gte('scheduled_date', from)
          .lte('scheduled_date', through)
          .not('published_at', 'is', null)
          .isFilter('superseded_at', null)
          .order('scheduled_date');

      return devotionalRows(result, 'devotional assignments')
          .map(mapAssignedDevotional)
          .toList(growable: false);
    });
  }

  @override
  Future<List<DevotionalCompletion>> listMyCompletions({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final from = manilaDateKey(fromManilaDate);
      final through = manilaDateKey(throughManilaDate);
      if (from.compareTo(through) > 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The devotional date range is invalid.',
        );
      }

      final result = await _client
          .from('member_devotional_completions')
          .select()
          .eq('member_id', userId)
          .gte('scheduled_date', from)
          .lte('scheduled_date', through)
          .order('scheduled_date', ascending: false);

      return devotionalRows(result, 'devotional completions')
          .map(mapDevotionalCompletion)
          .toList(growable: false);
    });
  }

  @override
  Future<DevotionalCompletion> completeAssignment({
    required String assignmentId,
    String? reflectionText,
  }) {
    return guardDevotionalOperation(() async {
      _requireUserId();
      final reflection = reflectionText?.trim();

      final result = await _client.rpc(
        'complete_devotional_assignment',
        params: {
          'p_assignment_id': assignmentId,
          if (reflection != null && reflection.isNotEmpty)
            'p_reflection_text': reflection,
        },
      );

      return mapDevotionalCompletion(
        devotionalRow(result, 'completed devotional'),
      );
    });
  }

  @override
  Future<DevotionalReflection?> getMyReflection({
    required String completionId,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final result = await _client
          .from('member_devotional_reflections')
          .select()
          .eq('completion_id', completionId)
          .eq('member_id', userId)
          .maybeSingle();

      if (result == null) return null;
      return mapDevotionalReflection(
        devotionalRow(result, 'devotional reflection'),
      );
    });
  }

  @override
  Future<DevotionalReflection> saveMyReflection({
    required String completionId,
    required String text,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final reflection = text.trim();
      if (reflection.isEmpty) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'A reflection cannot be empty.',
        );
      }

      final result = await _client
          .from('member_devotional_reflections')
          .upsert(
            {
              'completion_id': completionId,
              'member_id': userId,
              'reflection_text': reflection,
            },
            onConflict: 'completion_id',
          )
          .select()
          .single();

      return mapDevotionalReflection(
        devotionalRow(result, 'devotional reflection'),
      );
    });
  }

  @override
  Future<void> deleteMyReflection({required String completionId}) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      await _client
          .from('member_devotional_reflections')
          .delete()
          .eq('completion_id', completionId)
          .eq('member_id', userId);
    });
  }

  @override
  Future<DevotionalSettings> getSettings() {
    return guardDevotionalOperation(() async {
      _requireUserId();
      final result = await _client
          .from('devotional_settings')
          .select()
          .eq('singleton_key', true)
          .maybeSingle();

      if (result == null) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.configuration,
          message: 'Devotional completion settings are unavailable.',
        );
      }

      return mapDevotionalSettings(
        devotionalRow(result, 'devotional settings'),
      );
    });
  }

  @override
  Future<DevotionalReadingState> recordOpening({
    required String assignmentId,
  }) {
    return guardDevotionalOperation(() async {
      _requireUserId();
      final result = await _client.rpc(
        'record_devotional_opening',
        params: {'p_assignment_id': assignmentId},
      );
      return mapDevotionalReadingState(
        devotionalRow(result, 'devotional reading state'),
      );
    });
  }

  @override
  Future<DevotionalReadingState?> getReadingState({
    required DateTime scheduledDate,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final result = await _client
          .from('member_devotional_reading_states')
          .select()
          .eq('member_id', userId)
          .eq('scheduled_date', manilaDateKey(scheduledDate))
          .maybeSingle();
      return result == null
          ? null
          : mapDevotionalReadingState(
              devotionalRow(result, 'devotional reading state'),
            );
    });
  }

  @override
  Future<List<DevotionalReadingState>> listMyReadingStates({
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final from = manilaDateKey(fromManilaDate);
      final through = manilaDateKey(throughManilaDate);
      if (from.compareTo(through) > 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The devotional date range is invalid.',
        );
      }
      final result = await _client
          .from('member_devotional_reading_states')
          .select()
          .eq('member_id', userId)
          .gte('scheduled_date', from)
          .lte('scheduled_date', through)
          .order('scheduled_date', ascending: false);
      return devotionalRows(result, 'devotional reading states')
          .map(mapDevotionalReadingState)
          .toList(growable: false);
    });
  }

  @override
  Future<ReflectionWorkspace?> getReflectionWorkspace({
    required DateTime scheduledDate,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final workspaceResult = await _client
          .from('member_devotional_reflection_documents')
          .select()
          .eq('member_id', userId)
          .eq('scheduled_date', manilaDateKey(scheduledDate))
          .maybeSingle();
      if (workspaceResult == null) return null;
      final blockResult = await _client
          .from('member_devotional_reflection_blocks')
          .select()
          .eq('member_id', userId)
          .eq('scheduled_date', manilaDateKey(scheduledDate))
          .order('display_order');
      return mapReflectionWorkspace(
        devotionalRow(workspaceResult, 'reflection workspace'),
        devotionalRows(blockResult, 'reflection blocks'),
      );
    });
  }

  @override
  Future<ReflectionWorkspace> saveReflectionWorkspace({
    required String assignmentId,
    required ReflectionWorkspaceDraft workspace,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      if (!workspace.hasWrittenContent) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'Write a reflection before saving.',
        );
      }
      final result = await _client.rpc(
        'save_devotional_reflection_workspace',
        params: {
          'p_assignment_id': assignmentId,
          'p_blocks': workspace.blocks
              .map((item) => {
                    'id': item.id.startsWith('draft-') ? null : item.id,
                    'block_type': item.type.name,
                    'source_type': item is CitedReflectionDocument
                        ? item.citation.source.name
                        : null,
                    'scripture_reference': item is CitedReflectionDocument
                        ? item.citation.scriptureReference
                        : null,
                    'translation_id': item is CitedReflectionDocument
                        ? item.citation.translationId
                        : null,
                    'verse_identity': item is CitedReflectionDocument
                        ? item.citation.verseIdentity
                        : null,
                    'passage_key': item is CitedReflectionDocument
                        ? item.citation.passageKey
                        : null,
                    'devotional_version_id': item is CitedReflectionDocument
                        ? item.citation.devotionalVersionId
                        : null,
                    'devotional_title': item is CitedReflectionDocument
                        ? item.citation.devotionalTitle
                        : null,
                    'selected_text': item is CitedReflectionDocument
                        ? item.citation.selectedText
                        : null,
                    'start_offset': item is CitedReflectionDocument
                        ? item.citation.startOffset
                        : null,
                    'end_offset': item is CitedReflectionDocument
                        ? item.citation.endOffset
                        : null,
                    'highlight_color': item is CitedReflectionDocument
                        ? item.citation.highlightColor?.storageValue
                        : null,
                    'document_delta': item.documentDelta,
                    'plain_text': item.plainText.trim(),
                    'display_order': item.displayOrder,
                  })
              .toList(growable: false),
        },
      );
      final workspaceRow = devotionalRow(result, 'reflection workspace');
      final blockResult = await _client
          .from('member_devotional_reflection_blocks')
          .select()
          .eq('member_id', userId)
          .eq('scheduled_date', _requiredDateKey(workspaceRow))
          .order('display_order');
      return mapReflectionWorkspace(
        workspaceRow,
        devotionalRows(blockResult, 'reflection blocks'),
      );
    });
  }

  @override
  Future<void> deleteReflectionWorkspace({
    required DateTime scheduledDate,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      await _client
          .from('member_devotional_reflection_documents')
          .delete()
          .eq('member_id', userId)
          .eq('scheduled_date', manilaDateKey(scheduledDate));
    });
  }

  @override
  Future<List<DevotionalTextHighlight>> listDevotionalHighlights({
    required String devotionalVersionId,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final result = await _client
          .from('member_devotional_highlights')
          .select()
          .eq('member_id', userId)
          .eq('devotional_version_id', devotionalVersionId)
          .order('start_offset');
      return devotionalRows(result, 'devotional highlights')
          .map(mapDevotionalTextHighlight)
          .toList(growable: false);
    });
  }

  @override
  Future<DevotionalTextHighlight> saveDevotionalHighlight({
    required String devotionalVersionId,
    required int startOffset,
    required int endOffset,
    required HighlightColor color,
    required String selectedText,
    String? prefixContext,
    String? suffixContext,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      _validateSelection(startOffset, endOffset, selectedText);
      final result = await _client
          .from('member_devotional_highlights')
          .upsert({
            'member_id': userId,
            'devotional_version_id': devotionalVersionId,
            'start_offset': startOffset,
            'end_offset': endOffset,
            'highlight_color': color.storageValue,
            'selected_text': selectedText,
            'prefix_context': prefixContext,
            'suffix_context': suffixContext,
          }, onConflict:
              'member_id,devotional_version_id,start_offset,end_offset')
          .select()
          .single();
      return mapDevotionalTextHighlight(
        devotionalRow(result, 'devotional highlight'),
      );
    });
  }

  @override
  Future<void> deleteDevotionalHighlights({required List<String> ids}) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      if (ids.isEmpty) return;
      await _client
          .from('member_devotional_highlights')
          .delete()
          .eq('member_id', userId)
          .inFilter('id', ids);
    });
  }

  @override
  Future<List<BibleTextHighlight>> listBibleHighlights({
    required String translationId,
    required String passageKey,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final result = await _client
          .from('member_bible_highlights')
          .select()
          .eq('member_id', userId)
          .eq('translation_id', translationId)
          .eq('passage_key', passageKey)
          .order('start_offset');
      return devotionalRows(result, 'Bible highlights')
          .map(mapBibleTextHighlight)
          .toList(growable: false);
    });
  }

  @override
  Future<BibleTextHighlight> saveBibleHighlight({
    required String translationId,
    required String passageKey,
    String? verseIdentity,
    required int startOffset,
    required int endOffset,
    required HighlightColor color,
    required String selectedText,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      _validateSelection(startOffset, endOffset, selectedText);
      final result = await _client
          .from('member_bible_highlights')
          .upsert({
            'member_id': userId,
            'translation_id': translationId,
            'passage_key': passageKey,
            'verse_identity': verseIdentity,
            'start_offset': startOffset,
            'end_offset': endOffset,
            'highlight_color': color.storageValue,
            'selected_text': selectedText,
          }, onConflict:
              'member_id,translation_id,passage_key,start_offset,end_offset')
          .select()
          .single();
      return mapBibleTextHighlight(devotionalRow(result, 'Bible highlight'));
    });
  }

  @override
  Future<void> deleteBibleHighlights({required List<String> ids}) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      if (ids.isEmpty) return;
      await _client
          .from('member_bible_highlights')
          .delete()
          .eq('member_id', userId)
          .inFilter('id', ids);
    });
  }

  @override
  Future<ReaderPreferences> getReaderPreferences() {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final result = await _client
          .from('member_devotional_reader_preferences')
          .select()
          .eq('member_id', userId)
          .maybeSingle();
      return result == null
          ? ReaderPreferences.defaults
          : mapReaderPreferences(devotionalRow(result, 'reader preferences'));
    });
  }

  @override
  Future<ReaderPreferences> saveReaderPreferences({
    required ReaderLayoutPreference layout,
    required List<String> bibleTranslationIds,
  }) {
    return guardDevotionalOperation(() async {
      final userId = _requireUserId();
      final uniqueIds = bibleTranslationIds.toSet().toList(growable: false);
      if (uniqueIds.isEmpty) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'Keep at least one Bible translation displayed.',
        );
      }
      final result = await _client
          .from('member_devotional_reader_preferences')
          .upsert({
            'member_id': userId,
            'reader_layout': layout == ReaderLayoutPreference.stacked
                ? 'stacked'
                : 'side_by_side',
            'bible_translation_ids': uniqueIds,
          }, onConflict: 'member_id')
          .select()
          .single();
      return mapReaderPreferences(devotionalRow(result, 'reader preferences'));
    });
  }

  void _validateSelection(int start, int end, String text) {
    if (start < 0 || end <= start || text.isEmpty || end - start != text.length) {
      throw const DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidSelection,
        message: 'Select a valid text range and try again.',
      );
    }
  }

  String _requiredDateKey(Map<String, dynamic> row) {
    final value = row['scheduled_date'];
    if (value is! String || value.isEmpty) {
      throw const FormatException('Invalid reflection workspace date.');
    }
    return value;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const DevotionalRepositoryException(
        kind: DevotionalFailureKind.unauthenticated,
        message: 'Please sign in again to continue.',
      );
    }
    return userId;
  }

  Future<String> _manilaTodayKey() async {
    final result = await _client.rpc('devotional_manila_today');
    if (result is! String || result.isEmpty) {
      throw const FormatException('Invalid Manila date response.');
    }
    return result;
  }
}
