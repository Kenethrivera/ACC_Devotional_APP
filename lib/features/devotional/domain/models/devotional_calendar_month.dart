import 'assigned_devotional.dart';

class DevotionalCalendarSummary {
  final int allTimeRead;
  final int allTimeReflected;
  final int monthRead;
  final int monthPublishedThroughToday;
  final int currentStreak;

  const DevotionalCalendarSummary({
    required this.allTimeRead,
    required this.allTimeReflected,
    required this.monthRead,
    required this.monthPublishedThroughToday,
    required this.currentStreak,
  });
}

class DevotionalCalendarDay {
  final AssignedDevotional devotional;
  final bool isRead;
  final bool isReflected;

  const DevotionalCalendarDay({
    required this.devotional,
    required this.isRead,
    required this.isReflected,
  });

  DateTime get scheduledDate => devotional.assignment.scheduledDate;
}

class DevotionalCalendarMonth {
  final DateTime manilaToday;
  final DateTime monthStart;
  final DateTime monthEnd;
  final DevotionalCalendarSummary summary;
  final List<DevotionalCalendarDay> days;

  const DevotionalCalendarMonth({
    required this.manilaToday,
    required this.monthStart,
    required this.monthEnd,
    required this.summary,
    required this.days,
  });
}
