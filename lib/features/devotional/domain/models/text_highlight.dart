class HighlightColor {
  final String hex;
  final String label;

  const HighlightColor._(this.hex, this.label);

  static const yellow = HighlightColor._('#FFE79A', 'Yellow');
  static const pink = HighlightColor._('#F4C6D7', 'Pink');
  static const blue = HighlightColor._('#BFDDF6', 'Blue');
  static const green = HighlightColor._('#BFE8C8', 'Green');

  static const values = <HighlightColor>[yellow, pink, blue, green];

  factory HighlightColor.fromHex(String value, {String label = 'Custom'}) {
    final normalized = value.trim().toUpperCase();
    final hex = normalized.startsWith('#') ? normalized : '#$normalized';
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(hex)) {
      throw const FormatException('Invalid highlight color.');
    }
    for (final preset in values) {
      if (preset.hex == hex) return preset;
    }
    return HighlightColor._(hex, label);
  }

  String get storageValue => hex;

  @override
  bool operator ==(Object other) =>
      other is HighlightColor && other.hex == hex;

  @override
  int get hashCode => hex.hashCode;
}

class DevotionalTextHighlight {
  final String id;
  final String devotionalVersionId;
  final int startOffset;
  final int endOffset;
  final HighlightColor color;
  final String selectedText;
  final String? prefixContext;
  final String? suffixContext;

  const DevotionalTextHighlight({
    required this.id,
    required this.devotionalVersionId,
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.selectedText,
    required this.prefixContext,
    required this.suffixContext,
  });
}

class BibleTextHighlight {
  final String id;
  final String translationId;
  final String passageKey;
  final String? verseIdentity;
  final int startOffset;
  final int endOffset;
  final HighlightColor color;
  final String selectedText;

  const BibleTextHighlight({
    required this.id,
    required this.translationId,
    required this.passageKey,
    required this.verseIdentity,
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.selectedText,
  });
}

class TextSelectionAnchor {
  final int startOffset;
  final int endOffset;
  final String selectedText;

  const TextSelectionAnchor({
    required this.startOffset,
    required this.endOffset,
    required this.selectedText,
  });

  bool get isValid => startOffset >= 0 && endOffset > startOffset;
}
