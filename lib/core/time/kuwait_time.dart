import 'package:intl/intl.dart';

/// Kuwait has no DST — always UTC+3.
abstract final class KuwaitTime {
  static const Duration offset = Duration(hours: 3);
  static const String timeZoneLabel = 'بتوقيت الكويت';

  static DateTime? parseUtc(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toUtc();
  }

  static DateTime toKuwait(DateTime utc) => utc.toUtc().add(offset);

  /// 12-hour clock in Kuwait wall time, e.g. `06:12 PM`.
  static String formatTime12h(String? iso) {
    final utc = parseUtc(iso);
    if (utc == null) return '';
    return DateFormat('hh:mm a', 'en_US').format(toKuwait(utc));
  }

  static String formatTimeWithLabel(String? iso) {
    final time = formatTime12h(iso);
    if (time.isEmpty) return '';
    return '$time ($timeZoneLabel)';
  }
}
