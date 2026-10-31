import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/errors/devotional_repository_exception.dart';
import '../domain/models/devotional_assignment.dart';
import '../domain/models/devotional_completion.dart';
import '../domain/models/devotional_content.dart';
import '../domain/models/devotional_settings.dart';
import '../domain/models/devotional_version.dart';
import '../domain/models/devotional_participation.dart';
import '../domain/repositories/devotional_administration_repository.dart';
import 'devotional_error_mapper.dart';
import 'devotional_row_mapper.dart';

class SupabaseDevotionalAdministrationRepository
    implements DevotionalAdministrationRepository {
  final SupabaseClient _client;

  SupabaseDevotionalAdministrationRepository(this._client);

  @override
  Future<DevotionalContent> createDevotional() {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final result = await _client
          .from('devotional_contents')
          .insert(<String, dynamic>{})
          .select()
          .single();

      return mapDevotionalContent(
        devotionalRow(result, 'devotional content'),
      );
    });
  }

  @override
  Future<DevotionalVersion> createDraftVersion({
    required String devotionalId,
    required String title,
    required String scriptureReference,
    required String body,
  }) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final cleanTitle = title.trim();
      final cleanReference = scriptureReference.trim();
      final cleanBody = body.trim();
      if (cleanTitle.isEmpty || cleanReference.isEmpty || cleanBody.isEmpty) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'Title, Scripture reference, and devotional text are required.',
        );
      }

      for (var attempt = 0; attempt < 3; attempt++) {
        final versionNumber = await _nextVersionNumber(devotionalId);
        try {
          final result = await _client
              .from('devotional_content_versions')
              .insert({
                'devotional_id': devotionalId,
                'version_number': versionNumber,
                'title': cleanTitle,
                'scripture_reference': cleanReference,
                'body': cleanBody,
              })
              .select()
              .single();

          return mapDevotionalVersion(
            devotionalRow(result, 'devotional content version'),
          );
        } on PostgrestException catch (error) {
          if (error.code != '23505' || attempt == 2) rethrow;
        }
      }

      throw const DevotionalRepositoryException(
        kind: DevotionalFailureKind.conflict,
        message: 'A devotional version could not be reserved. Please retry.',
      );
    });
  }

  @override
  Future<DevotionalVersion> publishVersion({required String versionId}) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final result = await _client
          .from('devotional_content_versions')
          .update({'published_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', versionId)
          .isFilter('published_at', null)
          .select()
          .maybeSingle();

      if (result == null) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.unavailable,
          message: 'The draft devotional version is unavailable.',
        );
      }

      return mapDevotionalVersion(
        devotionalRow(result, 'published devotional version'),
      );
    });
  }

  @override
  Future<DevotionalAssignment> publishAssignmentRevision({
    required DateTime scheduledManilaDate,
    required String devotionalVersionId,
  }) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final result = await _client.rpc(
        'publish_devotional_assignment_revision',
        params: {
          'p_scheduled_date': manilaDateKey(scheduledManilaDate),
          'p_devotional_version_id': devotionalVersionId,
        },
      );

      return mapDevotionalAssignment(
        devotionalRow(result, 'published devotional assignment'),
      );
    });
  }

  @override
  Future<DevotionalAssignment> retireAssignment({
    required DateTime scheduledManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final result = await _client.rpc(
        'retire_devotional_assignment',
        params: {'p_scheduled_date': manilaDateKey(scheduledManilaDate)},
      );

      return mapDevotionalAssignment(
        devotionalRow(result, 'retired devotional assignment'),
      );
    });
  }

  @override
  Future<DevotionalSettings> setDailyCompletionLimit({required int limit}) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      if (limit <= 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The daily completion limit must be positive.',
        );
      }

      final result = await _client
          .from('devotional_settings')
          .upsert(
            {
              'singleton_key': true,
              'daily_completion_limit': limit,
            },
            onConflict: 'singleton_key',
          )
          .select()
          .single();

      return mapDevotionalSettings(
        devotionalRow(result, 'devotional settings'),
      );
    });
  }

  @override
  Future<List<DevotionalCompletion>> listMemberCompletions({
    String? memberId,
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final from = manilaDateKey(fromManilaDate);
      final through = manilaDateKey(throughManilaDate);
      if (from.compareTo(through) > 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The devotional date range is invalid.',
        );
      }

      var query = _client
          .from('member_devotional_completions')
          .select()
          .gte('scheduled_date', from)
          .lte('scheduled_date', through);
      final requestedMember = memberId?.trim();
      if (requestedMember != null && requestedMember.isNotEmpty) {
        query = query.eq('member_id', requestedMember);
      }

      final result = await query.order(
        'scheduled_date',
        ascending: false,
      );

      return devotionalRows(result, 'member devotional completions')
          .map(mapDevotionalCompletion)
          .toList(growable: false);
    });
  }

  @override
  Future<List<DevotionalReadingState>> listMemberReadingStates({
    String? memberId,
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  }) {
    return guardDevotionalOperation(() async {
      await _requireAdministrator();
      final from = manilaDateKey(fromManilaDate);
      final through = manilaDateKey(throughManilaDate);
      if (from.compareTo(through) > 0) {
        throw const DevotionalRepositoryException(
          kind: DevotionalFailureKind.invalidData,
          message: 'The devotional date range is invalid.',
        );
      }

      var query = _client
          .from('member_devotional_reading_states')
          .select()
          .gte('scheduled_date', from)
          .lte('scheduled_date', through);
      final requestedMember = memberId?.trim();
      if (requestedMember != null && requestedMember.isNotEmpty) {
        query = query.eq('member_id', requestedMember);
      }
      final result = await query.order('scheduled_date', ascending: false);
      return devotionalRows(result, 'member devotional reading states')
          .map(mapDevotionalReadingState)
          .toList(growable: false);
    });
  }

  Future<int> _nextVersionNumber(String devotionalId) async {
    final result = await _client
        .from('devotional_content_versions')
        .select('version_number')
        .eq('devotional_id', devotionalId)
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (result == null) return 1;
    final row = devotionalRow(result, 'latest devotional version');
    final value = row['version_number'];
    if (value is! int) {
      throw const FormatException('Invalid devotional version number.');
    }
    return value + 1;
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

  Future<void> _requireAdministrator() async {
    _requireUserId();
    final result = await _client.rpc('is_devotional_admin');
    if (result != true) {
      throw const DevotionalRepositoryException(
        kind: DevotionalFailureKind.permissionDenied,
        message: 'Administrative devotional access is required.',
      );
    }
  }
}
