class DevotionalAssignment {
  final String id;
  final DateTime scheduledDate;
  final String devotionalVersionId;
  final int revisionNumber;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime? supersededAt;
  final String? supersededBy;

  const DevotionalAssignment({
    required this.id,
    required this.scheduledDate,
    required this.devotionalVersionId,
    required this.revisionNumber,
    required this.createdAt,
    required this.createdBy,
    required this.publishedAt,
    required this.publishedBy,
    required this.supersededAt,
    required this.supersededBy,
  });

  bool get isPublished => publishedAt != null;
  bool get isCurrentRevision => isPublished && supersededAt == null;
}
