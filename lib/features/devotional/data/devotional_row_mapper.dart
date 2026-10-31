import '../domain/models/assigned_devotional.dart';
import '../domain/models/devotional_assignment.dart';
import '../domain/models/devotional_completion.dart';
import '../domain/models/devotional_content.dart';
import '../domain/models/devotional_reflection.dart';
import '../domain/models/devotional_settings.dart';
import '../domain/models/devotional_version.dart';
import '../domain/models/devotional_participation.dart';
import '../domain/models/reader_preferences.dart';
import '../domain/models/reflection_workspace.dart';
import '../domain/models/text_highlight.dart';

Map<String, dynamic> devotionalRow(Object? value, String context) {
  if (value is! Map) {
    throw FormatException('Expected an object for $context.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> devotionalRows(Object? value, String context) {
  if (value is! List) {
    throw FormatException('Expected a list for $context.');
  }
  return value
      .map((row) => devotionalRow(row, '$context row'))
      .toList(growable: false);
}

DevotionalContent mapDevotionalContent(Map<String, dynamic> row) {
  return DevotionalContent(
    id: _requiredString(row, 'id'),
    createdAt: _timestamp(row, 'created_at'),
    createdBy: _nullableString(row, 'created_by'),
  );
}

DevotionalVersion mapDevotionalVersion(Map<String, dynamic> row) {
  return DevotionalVersion(
    id: _requiredString(row, 'id'),
    devotionalId: _requiredString(row, 'devotional_id'),
    versionNumber: _requiredInt(row, 'version_number'),
    title: _requiredString(row, 'title'),
    scriptureReference: _requiredString(row, 'scripture_reference'),
    body: _requiredString(row, 'body'),
    createdAt: _timestamp(row, 'created_at'),
    createdBy: _nullableString(row, 'created_by'),
    publishedAt: _nullableTimestamp(row, 'published_at'),
    publishedBy: _nullableString(row, 'published_by'),
  );
}

DevotionalAssignment mapDevotionalAssignment(Map<String, dynamic> row) {
  return DevotionalAssignment(
    id: _requiredString(row, 'id'),
    scheduledDate: _date(row, 'scheduled_date'),
    devotionalVersionId: _requiredString(row, 'devotional_version_id'),
    revisionNumber: _requiredInt(row, 'revision_number'),
    createdAt: _timestamp(row, 'created_at'),
    createdBy: _nullableString(row, 'created_by'),
    publishedAt: _nullableTimestamp(row, 'published_at'),
    publishedBy: _nullableString(row, 'published_by'),
    supersededAt: _nullableTimestamp(row, 'superseded_at'),
    supersededBy: _nullableString(row, 'superseded_by'),
  );
}

AssignedDevotional mapAssignedDevotional(Map<String, dynamic> row) {
  final version = devotionalRow(
    row['devotional_content_versions'],
    'assigned devotional content version',
  );

  return AssignedDevotional(
    assignment: mapDevotionalAssignment(row),
    content: mapDevotionalVersion(version),
  );
}

DevotionalCompletion mapDevotionalCompletion(Map<String, dynamic> row) {
  return DevotionalCompletion(
    id: _requiredString(row, 'id'),
    memberId: _requiredString(row, 'member_id'),
    assignmentId: _requiredString(row, 'assignment_id'),
    scheduledDate: _date(row, 'scheduled_date'),
    devotionalVersionId: _requiredString(row, 'devotional_version_id'),
    completedAt: _timestamp(row, 'completed_at'),
    completedOnManilaDate: _date(row, 'completed_on_manila_date'),
  );
}

DevotionalReflection mapDevotionalReflection(Map<String, dynamic> row) {
  return DevotionalReflection(
    completionId: _requiredString(row, 'completion_id'),
    memberId: _requiredString(row, 'member_id'),
    text: _requiredString(row, 'reflection_text'),
    createdAt: _timestamp(row, 'created_at'),
    updatedAt: _timestamp(row, 'updated_at'),
  );
}

DevotionalSettings mapDevotionalSettings(Map<String, dynamic> row) {
  return DevotionalSettings(
    dailyCompletionLimit: _requiredInt(row, 'daily_completion_limit'),
    updatedAt: _timestamp(row, 'updated_at'),
    updatedBy: _nullableString(row, 'updated_by'),
  );
}

DevotionalReadingState mapDevotionalReadingState(Map<String, dynamic> row) {
  return DevotionalReadingState(
    memberId: _requiredString(row, 'member_id'),
    scheduledDate: _date(row, 'scheduled_date'),
    assignmentId: _requiredString(row, 'assignment_id'),
    devotionalVersionId: _requiredString(row, 'devotional_version_id'),
    firstOpenedAt: _timestamp(row, 'first_opened_at'),
    lastOpenedAt: _timestamp(row, 'last_opened_at'),
    reflectedAt: _nullableTimestamp(row, 'reflected_at'),
  );
}

ReflectionWorkspace mapReflectionWorkspace(
  Map<String, dynamic> row,
  List<Map<String, dynamic>> blockRows,
) {
  final blocks = blockRows.map(mapReflectionDocumentBlock).toList()
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return ReflectionWorkspace(
    memberId: _requiredString(row, 'member_id'),
    scheduledDate: _date(row, 'scheduled_date'),
    assignmentId: _requiredString(row, 'assignment_id'),
    devotionalVersionId: _requiredString(row, 'devotional_version_id'),
    blocks: blocks,
    createdAt: _timestamp(row, 'created_at'),
    updatedAt: _timestamp(row, 'updated_at'),
  );
}

ReflectionDocumentBlock mapReflectionDocumentBlock(
  Map<String, dynamic> row,
) {
  final delta = row['document_delta'];
  if (delta is! List) {
    throw const FormatException('Invalid reflection block Delta.');
  }
  final commonId = _requiredString(row, 'id');
  final commonPlainText = _stringAllowEmpty(row, 'plain_text');
  final commonOrder = _requiredInt(row, 'display_order');
  final commonCreatedAt = _timestamp(row, 'created_at');
  final commonUpdatedAt = _timestamp(row, 'updated_at');
  if (_requiredString(row, 'block_type') == 'paragraph') {
    return ReflectionParagraphDocument(
      id: commonId,
      documentDelta: List<dynamic>.from(delta),
      plainText: commonPlainText,
      displayOrder: commonOrder,
      createdAt: commonCreatedAt,
      updatedAt: commonUpdatedAt,
    );
  }
  final source = switch (_requiredString(row, 'source_type')) {
    'bible' => ReflectionCitationSource.bible,
    'devotion' => ReflectionCitationSource.devotion,
    _ => throw const FormatException('Invalid citation source.'),
  };
  final colorValue = _nullableString(row, 'highlight_color');
  return CitedReflectionDocument(
    id: commonId,
    citation: ReflectionCitation(
      source: source,
      selectedText: _requiredString(row, 'selected_text'),
      startOffset: _requiredInt(row, 'start_offset'),
      endOffset: _requiredInt(row, 'end_offset'),
      highlightColor:
          colorValue == null ? null : HighlightColor.fromHex(colorValue),
      scriptureReference: _nullableString(row, 'scripture_reference'),
      translationId: _nullableString(row, 'translation_id'),
      verseIdentity: _nullableString(row, 'verse_identity'),
      passageKey: _nullableString(row, 'passage_key'),
      devotionalVersionId: _nullableString(row, 'devotional_version_id'),
      devotionalTitle: _nullableString(row, 'devotional_title'),
    ),
    documentDelta: List<dynamic>.from(delta),
    plainText: commonPlainText,
    displayOrder: commonOrder,
    createdAt: commonCreatedAt,
    updatedAt: commonUpdatedAt,
  );
}

DevotionalTextHighlight mapDevotionalTextHighlight(Map<String, dynamic> row) {
  return DevotionalTextHighlight(
    id: _requiredString(row, 'id'),
    devotionalVersionId: _requiredString(row, 'devotional_version_id'),
    startOffset: _requiredInt(row, 'start_offset'),
    endOffset: _requiredInt(row, 'end_offset'),
    color: _highlightColor(row),
    selectedText: _requiredString(row, 'selected_text'),
    prefixContext: _nullableString(row, 'prefix_context'),
    suffixContext: _nullableString(row, 'suffix_context'),
  );
}

BibleTextHighlight mapBibleTextHighlight(Map<String, dynamic> row) {
  return BibleTextHighlight(
    id: _requiredString(row, 'id'),
    translationId: _requiredString(row, 'translation_id'),
    passageKey: _requiredString(row, 'passage_key'),
    verseIdentity: _nullableString(row, 'verse_identity'),
    startOffset: _requiredInt(row, 'start_offset'),
    endOffset: _requiredInt(row, 'end_offset'),
    color: _highlightColor(row),
    selectedText: _requiredString(row, 'selected_text'),
  );
}

ReaderPreferences mapReaderPreferences(Map<String, dynamic> row) {
  final translations = row['bible_translation_ids'];
  if (translations is! List || translations.any((value) => value is! String)) {
    throw const FormatException('Invalid Bible translation preferences.');
  }
  final layout = _requiredString(row, 'reader_layout');
  return ReaderPreferences(
    layout: layout == 'stacked'
        ? ReaderLayoutPreference.stacked
        : ReaderLayoutPreference.sideBySide,
    bibleTranslationIds: translations.cast<String>(),
    updatedAt: _nullableTimestamp(row, 'updated_at'),
  );
}

HighlightColor _highlightColor(Map<String, dynamic> row) {
  return HighlightColor.fromHex(_requiredString(row, 'highlight_color'));
}

String manilaDateKey(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseManilaDateKey(String value) {
  return _parseDate(value, 'Manila date');
}

String _requiredString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

String? _nullableString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid $key.');
  return value;
}

String _stringAllowEmpty(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String) throw FormatException('Missing or invalid $key.');
  return value;
}

int _requiredInt(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}

DateTime _timestamp(Map<String, dynamic> row, String key) {
  final value = _requiredString(row, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key timestamp.');
  return parsed;
}

DateTime? _nullableTimestamp(Map<String, dynamic> row, String key) {
  final value = _nullableString(row, key);
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key timestamp.');
  return parsed;
}

DateTime _date(Map<String, dynamic> row, String key) {
  final value = _requiredString(row, key);
  return _parseDate(value, key);
}

DateTime _parseDate(String value, String context) {
  final parts = value.split('-');
  if (parts.length != 3) throw FormatException('Invalid $context date.');

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw FormatException('Invalid $context date.');
  }

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Invalid $context date.');
  }
  return date;
}
