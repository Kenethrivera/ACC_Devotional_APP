class DevotionalCompletion {
  final String id;
  final String memberId;
  final String assignmentId;
  final DateTime scheduledDate;
  final String devotionalVersionId;
  final DateTime completedAt;
  final DateTime completedOnManilaDate;

  const DevotionalCompletion({
    required this.id,
    required this.memberId,
    required this.assignmentId,
    required this.scheduledDate,
    required this.devotionalVersionId,
    required this.completedAt,
    required this.completedOnManilaDate,
  });
}
