enum ReaderLayoutPreference { sideBySide, stacked }

class ReaderPreferences {
  final ReaderLayoutPreference layout;
  final List<String> bibleTranslationIds;
  final DateTime? updatedAt;

  const ReaderPreferences({
    required this.layout,
    required this.bibleTranslationIds,
    required this.updatedAt,
  });

  static const defaults = ReaderPreferences(
    layout: ReaderLayoutPreference.sideBySide,
    bibleTranslationIds: <String>['ASV'],
    updatedAt: null,
  );
}
