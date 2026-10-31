enum DevotionalParticipationLevel { notOpened, read, reflected }

class DevotionalReadingState {
  final String memberId;
  final DateTime scheduledDate;
  final String assignmentId;
  final String devotionalVersionId;
  final DateTime firstOpenedAt;
  final DateTime lastOpenedAt;
  final DateTime? reflectedAt;

  const DevotionalReadingState({
    required this.memberId,
    required this.scheduledDate,
    required this.assignmentId,
    required this.devotionalVersionId,
    required this.firstOpenedAt,
    required this.lastOpenedAt,
    required this.reflectedAt,
  });

  DevotionalParticipationLevel get level => reflectedAt == null
      ? DevotionalParticipationLevel.read
      : DevotionalParticipationLevel.reflected;
}
