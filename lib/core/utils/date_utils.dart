import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);
  static String formatMonth(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String weekdayShort(DateTime d) => DateFormat('E').format(d); // Mon, Tue...
  static String dayOfMonth(DateTime d) => DateFormat('d').format(d);

  /// Start of today (midnight)
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Start of the week (Monday)
  static DateTime get startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// List of the last [n] days as DateTime (midnight)
  static List<DateTime> lastNDays(int n) {
    final today = startOfToday;
    return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
  }

  /// Whether two DateTimes fall on the same calendar day
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Season name for current month in South Asia context
  static String season(int month) {
    if (month >= 3 && month <= 5)   return 'Spring';
    if (month >= 6 && month <= 8)   return 'Summer';
    if (month >= 9 && month <= 11)  return 'Autumn';
    return 'Winter';
  }

  /// Relative label: "Today", "Yesterday", or "Mon 12 Apr"
  static String relativeLabel(DateTime d) {
    final today = startOfToday;
    if (isSameDay(d, today)) return 'Today';
    if (isSameDay(d, today.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('EEE d MMM').format(d);
  }
}
