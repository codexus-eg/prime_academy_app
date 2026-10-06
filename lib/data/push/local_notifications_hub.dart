import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Shared local-notifications plugin + timezone bootstrap.
abstract final class LocalNotificationsHub {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static var _timezoneReady = false;

  static void ensureTimeZones() {
    if (_timezoneReady) return;
    tzdata.initializeTimeZones();
    // App audience is Kuwait; absolute UTC instants still schedule correctly
    // when the location matches a real IANA zone known to the OS.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kuwait'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timezoneReady = true;
  }

  static tz.TZDateTime tzFromUtc(DateTime utc) {
    ensureTimeZones();
    return tz.TZDateTime.from(utc.toUtc(), tz.local);
  }

  static tz.TZDateTime tzNowPlus(Duration offset) {
    ensureTimeZones();
    return tz.TZDateTime.now(tz.local).add(offset);
  }
}
