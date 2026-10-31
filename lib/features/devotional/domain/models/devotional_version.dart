class DevotionalVersion {
  final String id;
  final String devotionalId;
  final int versionNumber;
  final String title;
  final String scriptureReference;
  final String body;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? publishedAt;
  final String? publishedBy;

  const DevotionalVersion({
    required this.id,
    required this.devotionalId,
    required this.versionNumber,
    required this.title,
    required this.scriptureReference,
    required this.body,
    required this.createdAt,
    required this.createdBy,
    required this.publishedAt,
    required this.publishedBy,
  });

  bool get isPublished => publishedAt != null;
}
