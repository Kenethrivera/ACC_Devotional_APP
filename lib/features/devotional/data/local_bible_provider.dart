import '../domain/bible/bible_provider.dart';

/// Small, explicitly local test catalog. This is not an external Bible API.
/// Text is limited to public-domain ASV (1901) and WEB (2020 stable text)
/// samples. A production provider should replace this catalog after licensing
/// and API review.
class LocalBibleProvider implements BibleProvider {
  const LocalBibleProvider();

  static const _asv = BibleTranslation(
    id: 'ASV',
    name: 'American Standard Version (1901)',
    licenseLabel: 'Public domain',
  );
  static const _web = BibleTranslation(
    id: 'WEB',
    name: 'World English Bible',
    licenseLabel: 'Public domain; World English Bible is an eBible.org trademark',
  );

  @override
  List<BibleTranslation> get supportedTranslations => const [_asv, _web];

  static const Map<String, Map<String, String>> _passages = {
    'genesis 1:1': {
      'ASV': 'In the beginning God created the heavens and the earth.',
      'WEB': 'In the beginning, God created the heavens and the earth.',
    },
    'psalm 23:1': {
      'ASV': 'Jehovah is my shepherd; I shall not want.',
      'WEB': 'Yahweh is my shepherd; I shall lack nothing.',
    },
    'john 3:16': {
      'ASV': 'For God so loved the world, that he gave his only begotten Son, '
          'that whosoever believeth on him should not perish, but have eternal life.',
      'WEB': 'For God so loved the world, that he gave his only born Son, that '
          'whoever believes in him should not perish, but have eternal life.',
    },
    'matthew 6:33': {
      'ASV': 'But seek ye first his kingdom, and his righteousness; and all '
          'these things shall be added unto you.',
      'WEB': 'But seek first God\u2019s Kingdom and his righteousness; and all '
          'these things will be given to you as well.',
    },
    'romans 8:28': {
      'ASV': 'And we know that to them that love God all things work together '
          'for good, even to them that are called according to his purpose.',
      'WEB': 'We know that all things work together for good for those who love '
          'God, for those who are called according to his purpose.',
    },
  };

  @override
  Future<BiblePassage> getPassage({
    required String reference,
    required String translationId,
  }) async {
    final normalized = _normalize(reference);
    if (normalized.isEmpty || !RegExp(r'^[a-z0-9 ]+ \d+:\d+(?:-\d+)?$').hasMatch(normalized)) {
      throw const BibleProviderException(
        BibleFailureKind.invalidReference,
        'The Scripture reference is not in a supported book chapter:verse format.',
      );
    }

    BibleTranslation? translation;
    for (final item in supportedTranslations) {
      if (item.id == translationId) {
        translation = item;
        break;
      }
    }
    if (translation == null) {
      throw BibleProviderException(
        BibleFailureKind.unsupportedTranslation,
        '$translationId is not available from the local Bible provider.',
      );
    }

    final text = _passages[normalized]?[translationId];
    if (text == null) {
      throw BibleProviderException(
        BibleFailureKind.missingPassage,
        '$reference is not included in the limited local test catalog.',
      );
    }

    return BiblePassage(
      reference: reference,
      normalizedReference: normalized,
      translation: translation,
      text: text,
      sourceLabel: 'Local public-domain test data',
    );
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*:\s*'), ':')
      .replaceAll(RegExp(r'\s*-\s*'), '-');
}
