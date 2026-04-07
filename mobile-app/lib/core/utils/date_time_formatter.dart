class DateTimeFormatter {
  const DateTimeFormatter._();

  static String format(DateTime dateTime) {
    final String year = dateTime.year.toString().padLeft(4, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = _formatHour(dateTime.hour);
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$year-$month-$day $hour:$minute $period';
  }

  static String _formatHour(int hour) {
    final int normalized = hour % 12;
    final int displayHour = normalized == 0 ? 12 : normalized;

    return displayHour.toString().padLeft(2, '0');
  }
}
