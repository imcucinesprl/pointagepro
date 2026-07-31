import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _hour =
      DateFormat('HH:mm', 'fr_BE');

  static final DateFormat _dayMonth =
      DateFormat('dd-MM', 'fr_BE');

  static final DateFormat _full =
      DateFormat('dd-MM-yyyy', 'fr_BE');

  static final DateFormat _fullSeconds =
      DateFormat('dd-MM-yyyy à HH:mm:ss', 'fr_BE');

  static String chat(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final value = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference = today.difference(value).inDays;

    if (difference == 0) {
      return _hour.format(date);
    }

    if (difference == 1) {
      return "Hier ${_hour.format(date)}";
    }

    if (date.year == now.year) {
      return "${_dayMonth.format(date)} ${_hour.format(date)}";
    }

    return "${_full.format(date)} ${_hour.format(date)}";
  }

  static String complete(DateTime? date) {
    if (date == null) return "";
    return _fullSeconds.format(date);
  }

  static String date(DateTime? date) {
    if (date == null) return "";
    return _full.format(date);
  }

  static String hour(DateTime? date) {
    if (date == null) return "";
    return _hour.format(date);
  }
}