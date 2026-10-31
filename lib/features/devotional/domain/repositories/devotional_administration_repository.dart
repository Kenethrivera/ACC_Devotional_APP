import '../models/devotional_assignment.dart';
import '../models/devotional_completion.dart';
import '../models/devotional_content.dart';
import '../models/devotional_settings.dart';
import '../models/devotional_version.dart';
import '../models/devotional_participation.dart';

/// Administrative contract for future publishing and progress features.
///
/// Private reflection data is intentionally absent from this interface.
abstract class DevotionalAdministrationRepository {
  Future<DevotionalContent> createDevotional();

  Future<DevotionalVersion> createDraftVersion({
    required String devotionalId,
    required String title,
    required String scriptureReference,
    required String body,
  });

  Future<DevotionalVersion> publishVersion({required String versionId});

  /// Publishes for any past, current, or future Manila calendar date.
  /// Replacements supersede the previous current published revision without
  /// changing existing completions or their original content versions.
  Future<DevotionalAssignment> publishAssignmentRevision({
    required DateTime scheduledManilaDate,
    required String devotionalVersionId,
  });

  /// Withdraws the current assignment for any schedule date without deleting
  /// its published revision or any completion that references it.
  Future<DevotionalAssignment> retireAssignment({
    required DateTime scheduledManilaDate,
  });

  Future<DevotionalSettings> setDailyCompletionLimit({
    required int limit,
  });

  Future<List<DevotionalCompletion>> listMemberCompletions({
    String? memberId,
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  });

  /// Module 2C participation metadata only. Reflection and highlight content
  /// are deliberately absent from the administrative contract.
  Future<List<DevotionalReadingState>> listMemberReadingStates({
    String? memberId,
    required DateTime fromManilaDate,
    required DateTime throughManilaDate,
  });
}
