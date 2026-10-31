import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/errors/devotional_repository_exception.dart';

Future<T> guardDevotionalOperation<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on DevotionalRepositoryException {
    rethrow;
  } catch (error) {
    throw mapDevotionalError(error);
  }
}

DevotionalRepositoryException mapDevotionalError(Object error) {
  if (error is DevotionalRepositoryException) return error;

  if (error is AuthException) {
    return DevotionalRepositoryException(
      kind: DevotionalFailureKind.unauthenticated,
      message: 'Please sign in again to continue.',
      cause: error,
    );
  }

  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    final code = (error.code ?? '').toUpperCase();

    if (code == '42P01' ||
        code == 'PGRST202' ||
        code == 'PGRST205' ||
        message.contains('record_devotional_opening') ||
        message.contains('save_devotional_reflection_workspace')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.migrationRequired,
        message: 'Private reading tools are awaiting the Module 2C database migration.',
        cause: error,
      );
    }

    if (message.contains('daily completion limit is not configured')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.configuration,
        message: 'Devotional completion settings are unavailable.',
        cause: error,
      );
    }

    if (message.contains('daily devotional completion limit') ||
        message.contains('daily limit')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.dailyLimitReached,
        message: 'Today\'s devotional completion limit has been reached.',
        cause: error,
      );
    }

    if (message.contains('official devotional date is already complete') ||
        message.contains('already complete')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.alreadyCompleted,
        message: 'This devotional date is already complete.',
        cause: error,
      );
    }

    if (message.contains('future devotional')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.futureLocked,
        message: 'This devotional will unlock on its scheduled Manila date.',
        cause: error,
      );
    }

    if (message.contains('assignment is unavailable') ||
        message.contains('no current published assignment') ||
        message.contains('content version must be published first')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.unavailable,
        message: 'This devotional assignment is not available.',
        cause: error,
      );
    }

    if (code == 'PGRST301' ||
        code == 'PGRST302' ||
        message.contains('jwt') ||
        message.contains('authentication is required')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.unauthenticated,
        message: 'Please sign in again to continue.',
        cause: error,
      );
    }

    if (message.contains('reflection block') ||
        message.contains('cited reflection') ||
        message.contains('cited passage') ||
        message.contains('citation anchor') ||
        message.contains('reflection document is invalid')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidData,
        message: 'A reflection citation is invalid. Select the passage again.',
        cause: error,
      );
    }

    if (code == '22P02') {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.invalidData,
        message: 'A devotional identifier or date is invalid.',
        cause: error,
      );
    }

    if (code == '42501' ||
        message.contains('row-level security') ||
        message.contains('permission denied') ||
        message.contains('administrative access is required')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.permissionDenied,
        message: 'You do not have access to this devotional action.',
        cause: error,
      );
    }

    if (code == '23505') {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.conflict,
        message: 'This devotional record changed. Please refresh and retry.',
        cause: error,
      );
    }

    if (message.contains('immutable')) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.conflict,
        message: 'Published devotional history cannot be changed.',
        cause: error,
      );
    }

    if (_looksLikeNetworkFailure(message)) {
      return DevotionalRepositoryException(
        kind: DevotionalFailureKind.network,
        message: 'Check your connection and try again.',
        cause: error,
      );
    }

    return DevotionalRepositoryException(
      kind: DevotionalFailureKind.unknown,
      message: 'The devotional service could not complete this request.',
      cause: error,
    );
  }

  if (error is FormatException || error is TypeError) {
    return DevotionalRepositoryException(
      kind: DevotionalFailureKind.invalidData,
      message: 'The devotional service returned unexpected data.',
      cause: error,
    );
  }

  final message = error.toString().toLowerCase();
  if (_looksLikeNetworkFailure(message)) {
    return DevotionalRepositoryException(
      kind: DevotionalFailureKind.network,
      message: 'Check your connection and try again.',
      cause: error,
    );
  }

  return DevotionalRepositoryException(
    kind: DevotionalFailureKind.unknown,
    message: 'The devotional service is temporarily unavailable.',
    cause: error,
  );
}

bool _looksLikeNetworkFailure(String message) {
  return message.contains('network') ||
      message.contains('connection') ||
      message.contains('socket') ||
      message.contains('failed host lookup') ||
      message.contains('failed to fetch') ||
      message.contains('xmlhttprequest') ||
      message.contains('timed out') ||
      message.contains('timeout');
}
