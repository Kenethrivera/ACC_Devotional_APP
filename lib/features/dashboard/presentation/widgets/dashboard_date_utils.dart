DateTime manilaNow() {
  return DateTime.now().toUtc().add(const Duration(hours: 8));
}

String fullManilaDate([DateTime? value]) {
  final date = value ?? manilaNow();
  return '${weekdayNames[date.weekday - 1]}, '
      '${longMonthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String shortManilaDate([DateTime? value]) {
  final date = value ?? manilaNow();
  return '${shortWeekdayNames[date.weekday - 1]}, '
      '${shortMonthNames[date.month - 1]} ${date.day}';
}

String manilaGreeting() {
  final hour = manilaNow().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

bool isSameCalendarDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const shortWeekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const longMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
