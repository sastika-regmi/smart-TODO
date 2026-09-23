import 'package:intl/intl.dart';

/// Date formatting helpers.
///
/// `DateFormat` construction is not free and these run inside list item
/// builders, so each pattern is built once and reused.
class AppDateUtils {
  const AppDateUtils._();

  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy \'at\' h:mm a');
  static final DateFormat _shortDate = DateFormat('MM/dd/yyyy');
  static final DateFormat _weekday = DateFormat('EEE, MMM d');

  static String formatDate(DateTime date) => _date.format(date);

  static String formatDateTime(DateTime date) => _dateTime.format(date);

  static String formatShortDate(DateTime date) => _shortDate.format(date);

  /// Weekday included, because "Mar 4" alone is ambiguous for a deadline.
  static String formatDueDate(DateTime date) => _weekday.format(date);

  /// Human description of how far away a due date is.
  ///
  /// Handles future dates: the previous implementation returned "Just now" for
  /// anything less than a day in the future, so tomorrow's deadline read as if
  /// it had just happened.
  static String describeDueDate(DateTime dueDate, {DateTime? now}) {
    final days = daysUntil(dueDate, now: now);

    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days == -1) return 'Overdue by 1 day';
    if (days < -1) return 'Overdue by ${days.abs()} days';
    if (days <= 7) return 'Due in $days days';
    return 'Due ${formatDueDate(dueDate)}';
  }

  /// Whole calendar days from today to [dueDate]. Negative means past.
  static int daysUntil(DateTime dueDate, {DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final target = _startOfDay(dueDate);
    return target.difference(today).inDays;
  }

  /// Relative time for *past* events such as "created 3h ago".
  static String formatRelativeDate(DateTime date, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(date);

    if (difference.isNegative) {
      // A timestamp in the future (clock skew between device and server).
      return formatDate(date);
    }
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return formatDate(date);
  }

  /// Midnight of [date], used for calendar-day comparisons.
  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Strips the time component, for `showDatePicker` round-trips.
  static DateTime normalizeDate(DateTime date) => _startOfDay(date);
}
