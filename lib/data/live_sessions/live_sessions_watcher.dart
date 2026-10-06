import 'dart:async';

import '../notifications/notification_models.dart';
import '../notifications/notification_store.dart';
import '../notifications/notifications_api.dart';
import 'live_session.dart';
import 'live_session_alarm.dart';
import 'live_sessions_store.dart';

/// Surfaces [SESSION_LIVE] the same way web `useLiveSessionsWatcher` does:
/// play alarm + open the live-session dialog, mark as read, and catch
/// unread sessions that started less than 3 minutes ago.
abstract final class LiveSessionsWatcher {
  static const missedWindow = Duration(minutes: 3);

  static final Set<int> _processedSessionIds = <int>{};
  static var _listening = false;

  static void attach() {
    if (_listening) return;
    _listening = true;
    NotificationStore.instance.addListener(_onStoreChanged);
    checkMissed();
  }

  static void detach() {
    if (!_listening) return;
    _listening = false;
    NotificationStore.instance.removeListener(_onStoreChanged);
  }

  static void _onStoreChanged() {
    final store = NotificationStore.instance;
    for (final notif in store.notifications) {
      if (notif.type != NotificationType.sessionLive) continue;
      if (!notif.fromSse) continue;
      final sessionId = notif.data.sessionId;
      if (sessionId == null) continue;
      if (_processedSessionIds.contains(sessionId)) continue;
      surface(notif, playAlarm: true);
    }
  }

  /// One-time / on-hydrate check for unread live sessions started < 3m ago.
  static void checkMissed() {
    final now = DateTime.now().toUtc();
    for (final notif in NotificationStore.instance.notifications) {
      if (notif.type != NotificationType.sessionLive) continue;
      if (notif.isRead) continue;
      final sessionId = notif.data.sessionId;
      if (sessionId == null) continue;
      if (_processedSessionIds.contains(sessionId)) continue;

      final start = DateTime.tryParse(notif.data.startTime ?? '');
      if (start == null) continue;
      final age = now.difference(start.toUtc());
      if (age.isNegative || age >= missedWindow) continue;

      surface(notif, playAlarm: true);
    }
  }

  static void surface(
    AppNotification notif, {
    required bool playAlarm,
  }) {
    final sessionId = notif.data.sessionId;
    if (sessionId == null) return;
    if (_processedSessionIds.contains(sessionId)) return;
    _processedSessionIds.add(sessionId);

    final title = notif.data.title.trim().isEmpty
        ? (notif.data.courseName ?? 'حصة مباشرة')
        : notif.data.title;

    LiveSessionsStore.instance.addLiveSession(
      LiveSession(
        id: sessionId,
        title: title,
        courseName: notif.data.courseName ?? title,
        meetingLink: notif.data.meetingLink,
        startTime: notif.data.startTime ?? '',
        notificationId: notif.id > 0 ? notif.id : null,
      ),
    );

    if (playAlarm) {
      unawaited(LiveSessionAlarm.play());
    }

    if (notif.id > 0 && !notif.isRead) {
      NotificationStore.instance.markAsRead([notif.id]);
      unawaited(_markReadSafe(notif.id));
    }
  }

  static Future<void> _markReadSafe(int id) async {
    try {
      await NotificationsApi.markRead([id]);
    } catch (_) {}
  }

  /// FCM foreground / cold-start payload (all string values).
  static void surfaceFromPayload(
    Map<String, String> data, {
    bool playAlarm = true,
  }) {
    if (data['type'] != 'SESSION_LIVE') return;

    final sessionId = int.tryParse(data['sessionId'] ?? data['session_id'] ?? '');
    if (sessionId == null || sessionId <= 0) return;
    if (_processedSessionIds.contains(sessionId)) return;

    final title = (data['title'] ?? data['courseName'] ?? '').trim();
    final notif = AppNotification(
      id: int.tryParse(data['id'] ?? '') ?? 0,
      type: NotificationType.sessionLive,
      data: NotificationData(
        title: title.isEmpty ? 'حصة مباشرة' : title,
        link: data['link'] ?? '',
        courseId: int.tryParse(data['courseId'] ?? data['course_id'] ?? ''),
        sessionId: sessionId,
        meetingLink: _nullable(data['meetingLink'] ?? data['meeting_link']),
        startTime: _nullable(data['startTime'] ?? data['start_time']),
        courseName: _nullable(data['courseName'] ?? data['course_name']),
        groupName: _nullable(data['groupName'] ?? data['group_name']),
      ),
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fromSse: false,
    );

    // Keep the bell list in sync when FCM arrives while the app is open.
    if (notif.id > 0) {
      NotificationStore.instance.addIncoming(notif);
    }

    surface(notif, playAlarm: playAlarm);
  }

  static String? _nullable(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
