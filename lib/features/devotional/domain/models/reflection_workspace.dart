import 'text_highlight.dart';

enum ReflectionCitationSource { bible, devotion }

class ReflectionCitation {
  final ReflectionCitationSource source;
  final String selectedText;
  final int startOffset;
  final int endOffset;
  // Initially copied from the source highlight, then independently editable
  // as the cited reflection card color.
  final HighlightColor? highlightColor;
  final String? scriptureReference;
  final String? translationId;
  final String? verseIdentity;
  final String? passageKey;
  final String? devotionalVersionId;
  final String? devotionalTitle;

  const ReflectionCitation({
    required this.source,
    required this.selectedText,
    required this.startOffset,
    required this.endOffset,
    required this.highlightColor,
    this.scriptureReference,
    this.translationId,
    this.verseIdentity,
    this.passageKey,
    this.devotionalVersionId,
    this.devotionalTitle,
  });

  ReflectionCitation withHighlightColor(HighlightColor? color) =>
      ReflectionCitation(
        source: source,
        selectedText: selectedText,
        startOffset: startOffset,
        endOffset: endOffset,
        highlightColor: color,
        scriptureReference: scriptureReference,
        translationId: translationId,
        verseIdentity: verseIdentity,
        passageKey: passageKey,
        devotionalVersionId: devotionalVersionId,
        devotionalTitle: devotionalTitle,
      );

  String get identityKey => [
        source.name,
        translationId ?? devotionalVersionId ?? '',
        passageKey ?? '',
        startOffset,
        endOffset,
      ].join(':');
}

enum ReflectionBlockType { paragraph, citation }

abstract class ReflectionDocumentBlock {
  final String id;
  final List<dynamic> documentDelta;
  final String plainText;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReflectionDocumentBlock({
    required this.id,
    required this.documentDelta,
    required this.plainText,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  ReflectionBlockType get type;
}

class ReflectionParagraphDocument extends ReflectionDocumentBlock {
  const ReflectionParagraphDocument({
    required super.id,
    required super.documentDelta,
    required super.plainText,
    required super.displayOrder,
    super.createdAt,
    super.updatedAt,
  });

  @override
  ReflectionBlockType get type => ReflectionBlockType.paragraph;
}

class CitedReflectionDocument extends ReflectionDocumentBlock {
  final ReflectionCitation citation;

  const CitedReflectionDocument({
    required super.id,
    required this.citation,
    required super.documentDelta,
    required super.plainText,
    required super.displayOrder,
    super.createdAt,
    super.updatedAt,
  });

  @override
  ReflectionBlockType get type => ReflectionBlockType.citation;
}

class ReflectionWorkspace {
  final String memberId;
  final DateTime scheduledDate;
  final String assignmentId;
  final String devotionalVersionId;
  final List<ReflectionDocumentBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReflectionWorkspace({
    required this.memberId,
    required this.scheduledDate,
    required this.assignmentId,
    required this.devotionalVersionId,
    required this.blocks,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ReflectionWorkspaceDraft {
  final List<ReflectionDocumentBlock> blocks;

  const ReflectionWorkspaceDraft({
    required this.blocks,
  });

  bool get hasWrittenContent =>
      blocks.any((item) => item.plainText.trim().isNotEmpty);
}
