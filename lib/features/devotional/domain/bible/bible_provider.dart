class BibleTranslation {
  final String id;
  final String name;
  final String licenseLabel;

  const BibleTranslation({
    required this.id,
    required this.name,
    required this.licenseLabel,
  });
}

class BiblePassage {
  final String reference;
  final String normalizedReference;
  final BibleTranslation translation;
  final String text;
  final String sourceLabel;

  const BiblePassage({
    required this.reference,
    required this.normalizedReference,
    required this.translation,
    required this.text,
    required this.sourceLabel,
  });
}

enum BibleFailureKind {
  unsupportedTranslation,
  missingPassage,
  invalidReference,
  network,
  unknown,
}

class BibleProviderException implements Exception {
  final BibleFailureKind kind;
  final String message;

  const BibleProviderException(this.kind, this.message);

  @override
  String toString() => message;
}

abstract class BibleProvider {
  List<BibleTranslation> get supportedTranslations;

  Future<BiblePassage> getPassage({
    required String reference,
    required String translationId,
  });
}
