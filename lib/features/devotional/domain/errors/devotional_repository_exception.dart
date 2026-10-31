enum DevotionalFailureKind {
  unauthenticated,
  unavailable,
  futureLocked,
  alreadyCompleted,
  dailyLimitReached,
  permissionDenied,
  conflict,
  configuration,
  network,
  invalidData,
  invalidSelection,
  migrationRequired,
  unsupportedBibleVersion,
  unavailableBiblePassage,
  unknown,
}

class DevotionalRepositoryException implements Exception {
  final DevotionalFailureKind kind;
  final String message;
  final Object? cause;

  const DevotionalRepositoryException({
    required this.kind,
    required this.message,
    this.cause,
  });

  @override
  String toString() => message;
}
