import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../push/local_notification_details.dart';
import '../push/local_notifications_hub.dart';
import 'meeting_session.dart';
import 'meeting_sessions_cache.dart';

/// Schedules OS-level local alarms for cached student sessions so they still
/// fire when the device is offline / app is closed.
abstract final class MeetingSessionsLocalScheduler {
  /// Keep notification ids in a dedicated namespace to avoid collisions.
  static const _idNamespace = 0x53000000;

  static FlutterLocalNotificationsPlugin? _plugin;
  static final Set<int> _shownIds = <int>{};

  static void bind(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  static int notificationIdFor(int sessionId) =>
      _idNamespace | (sessionId & 0x00FFFFFF);

  static Future<void> rescheduleAll(List<MeetingSession> sessions) async {
    if (kIsWeb) return;
    final plugin = _plugin;
    if (plugin == null) {
      debugPrint('[MeetingSessions] schedule skipped — plugin not bound');
      return;
    }

    LocalNotificationsHub.ensureTimeZones();

    final previousIds = await MeetingSessionsCache.loadScheduledIds();
    final desiredIds = <int>{};
    final now = DateTime.now().toUtc();
    final scheduledIds = <int>[];

    for (final session in sessions) {
      if (!session.status.isSchedulable) continue;

      final start = session.startTime.toUtc();
      final delay = start.difference(now);

      // Too old to alert.
      if (delay < const Duration(minutes: -3)) continue;

      desiredIds.add(session.id);

      final title = 'حصة مباشرة';
      final body = session.displayTitle.trim().isNotEmpty
          ? session.displayTitle.trim()
          : 'بدأت حصتك الآن';
      final payload = jsonEncode(session.toSessionLivePayload());
      final notifId = notificationIdFor(session.id);

      // Due now / within a few seconds → show immediately (same as test path).
      if (delay <= const Duration(seconds: 5)) {
        final shown = await showNow(
          sessionId: session.id,
          title: title,
          body: body,
          payload: payload,
        );
        if (shown) scheduledIds.add(session.id);
        continue;
      }

      // Schedule relative to "now" — same approach as the working 15s test.
      final when = tz.TZDateTime.now(tz.local).add(delay);
      final ok = await _scheduleOne(
        plugin: plugin,
        notifId: notifId,
        title: title,
        body: body,
        when: when,
        payload: payload,
        sessionId: session.id,
      );
      if (ok) scheduledIds.add(session.id);
    }

    // Cancel only sessions that are no longer desired (avoid wipe-near-fire).
    for (final oldId in previousIds) {
      if (desiredIds.contains(oldId)) continue;
      try {
        await plugin.cancel(id: notificationIdFor(oldId));
      } catch (_) {}
    }

    await MeetingSessionsCache.saveScheduledIds(scheduledIds);
    debugPrint(
      '[MeetingSessions] scheduled ${scheduledIds.length}/${sessions.length} '
      'local alarm(s)',
    );

    try {
      final pending = await plugin.pendingNotificationRequests();
      debugPrint(
        '[MeetingSessions] OS pending notifications=${pending.length}',
      );
    } catch (_) {}
  }

  /// Immediate tray notification (foreground or just-due).
  static Future<bool> showNow({
    required int sessionId,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return false;
    final plugin = _plugin;
    if (plugin == null) return false;
    if (_shownIds.contains(sessionId)) return true;

    final notifId = notificationIdFor(sessionId);
    try {
      await plugin.cancel(id: notifId);
    } catch (_) {}

    try {
      await plugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: LocalNotificationDetailsFactory.live(),
        payload: payload,
      );
      _shownIds.add(sessionId);
      debugPrint('[MeetingSessions] showNow id=$sessionId');
      return true;
    } catch (error) {
      debugPrint('[MeetingSessions] showNow live failed: $error');
    }

    try {
      await plugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: LocalNotificationDetailsFactory.general(),
        payload: payload,
      );
      _shownIds.add(sessionId);
      debugPrint('[MeetingSessions] showNow general id=$sessionId');
      return true;
    } catch (error) {
      debugPrint('[MeetingSessions] showNow failed: $error');
      return false;
    }
  }

  static Future<bool> showSession(MeetingSession session) {
    final title = 'حصة مباشرة';
    final body = session.displayTitle.trim().isNotEmpty
        ? session.displayTitle.trim()
        : 'بدأت حصتك الآن';
    return showNow(
      sessionId: session.id,
      title: title,
      body: body,
      payload: jsonEncode(session.toSessionLivePayload()),
    );
  }

  static Future<bool> _scheduleOne({
    required FlutterLocalNotificationsPlugin plugin,
    required int notifId,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    required int sessionId,
  }) async {
    // Replace any previous alarm for this session only.
    try {
      await plugin.cancel(id: notifId);
    } catch (_) {}

    Future<void> attempt(
      NotificationDetails details,
      AndroidScheduleMode mode,
    ) {
      return plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    // alarmClock matches user-visible alarms (most reliable on Android).
    final attempts = <(NotificationDetails, AndroidScheduleMode)>[
      (LocalNotificationDetailsFactory.live(), AndroidScheduleMode.alarmClock),
      (
        LocalNotificationDetailsFactory.general(),
        AndroidScheduleMode.alarmClock,
      ),
      (
        LocalNotificationDetailsFactory.live(),
        AndroidScheduleMode.exactAllowWhileIdle,
      ),
      (
        LocalNotificationDetailsFactory.general(),
        AndroidScheduleMode.exactAllowWhileIdle,
      ),
      (
        LocalNotificationDetailsFactory.general(),
        AndroidScheduleMode.inexactAllowWhileIdle,
      ),
    ];

    for (final attemptPair in attempts) {
      try {
        await attempt(attemptPair.$1, attemptPair.$2);
        debugPrint(
          '[MeetingSessions] scheduled id=$sessionId mode=${attemptPair.$2} '
          'at ${when.toIso8601String()}',
        );
        return true;
      } catch (error) {
        debugPrint(
          '[MeetingSessions] schedule attempt failed id=$sessionId '
          'mode=${attemptPair.$2}: $error',
        );
      }
    }
    return false;
  }

  static Future<void> cancelAllScheduled() async {
    if (kIsWeb) return;
    final plugin = _plugin;
    if (plugin == null) return;

    final ids = await MeetingSessionsCache.loadScheduledIds();
    for (final sessionId in ids) {
      try {
        await plugin.cancel(id: notificationIdFor(sessionId));
      } catch (_) {}
    }
    await MeetingSessionsCache.saveScheduledIds(const []);
    _shownIds.clear();
  }

  static Future<void> requestExactAlarmPermissionIfNeeded() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final plugin = _plugin;
    if (plugin == null) return;

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final canExact = await android?.canScheduleExactNotifications();
      debugPrint('[MeetingSessions] canScheduleExactNotifications=$canExact');
      if (canExact == false) {
        await android?.requestExactAlarmsPermission();
      }
    } catch (error) {
      debugPrint('[MeetingSessions] exact alarm permission failed: $error');
    }
  }

  /// TEMP debug: OS pending notification ids for session alarms.
  static Future<Set<int>> loadPendingSessionIds() async {
    if (kIsWeb) return {};
    final plugin = _plugin;
    if (plugin == null) return {};
    try {
      final pending = await plugin.pendingNotificationRequests();
      final sessionIds = <int>{};
      for (final request in pending) {
        if ((request.id & 0xFF000000) == _idNamespace) {
          sessionIds.add(request.id & 0x00FFFFFF);
        }
      }
      // Also count sessions we already showed this process.
      sessionIds.addAll(_shownIds);
      return sessionIds;
    } catch (error) {
      debugPrint('[MeetingSessions] pending lookup failed: $error');
      return {..._shownIds};
    }
  }
}
