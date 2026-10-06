import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_session.dart';
import '../live_sessions/live_sessions_watcher.dart';
import 'meeting_schedule_notify_prefs.dart';
import 'meeting_schedules_api.dart';
import 'meeting_session.dart';
import 'meeting_sessions_cache.dart';
import 'meeting_sessions_local_scheduler.dart';

/// Fetches student/family sessions while online, caches them, schedules local
/// alarms (bell_alarm), and surfaces due sessions when the app is open.
class MeetingSessionsSync with WidgetsBindingObserver {
  MeetingSessionsSync._();

  static final MeetingSessionsSync instance = MeetingSessionsSync._();

  var _attached = false;
  var _syncing = false;
  Timer? _dueTimer;

  void attach() {
    if (kIsWeb || _attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _dueTimer?.cancel();
    _dueTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(checkDueSessions());
    });
    unawaited(sync());
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _dueTimer?.cancel();
    _dueTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(sync());
      unawaited(checkDueSessions());
    }
  }

  /// Online: refresh from the selected API, cache, reschedule.
  /// Offline: keep cache and ensure schedules still match it.
  Future<void> sync() async {
    if (kIsWeb || _syncing) return;
    _syncing = true;
    try {
      final user = await AuthSession.load();
      if (user == null || user.id <= 0) {
        debugPrint('[MeetingSessions] sync skipped — no authenticated user');
        return;
      }

      await MeetingSessionsLocalScheduler.requestExactAlarmPermissionIfNeeded();

      final canUseFamily = user.canSwitch;
      final scope = await MeetingScheduleNotifyPrefs.load(
        canUseFamily: canUseFamily,
      );

      try {
        final sessions = await _fetchForScope(scope, canUseFamily: canUseFamily);
        debugPrint(
          '[MeetingSessions] fetched ${sessions.length} session(s) '
          'scope=${scope.name}',
        );
        await MeetingSessionsCache.save(sessions);
        await MeetingSessionsLocalScheduler.rescheduleAll(sessions);
        await checkDueSessions(sessions: sessions);
      } catch (error, stack) {
        debugPrint('[MeetingSessions] sync fetch failed: $error\n$stack');
        final cached = await MeetingSessionsCache.load();
        debugPrint(
          '[MeetingSessions] using cache (${cached.length} session(s))',
        );
        await MeetingSessionsLocalScheduler.rescheduleAll(cached);
        await checkDueSessions(sessions: cached);
      }
    } finally {
      _syncing = false;
    }
  }

  Future<List<MeetingSession>> _fetchForScope(
    MeetingScheduleNotifyScope scope, {
    required bool canUseFamily,
  }) async {
    if (scope == MeetingScheduleNotifyScope.family && canUseFamily) {
      return MeetingSchedulesApi.fetchFamilySessions();
    }
    return MeetingSchedulesApi.fetchStudentSessions();
  }

  /// Applies a new preference, persists it, then re-syncs + reschedules.
  Future<void> applyNotifyScope(MeetingScheduleNotifyScope scope) async {
    await MeetingScheduleNotifyPrefs.save(scope);
    // Wait out any in-flight sync so the new scope is not skipped.
    while (_syncing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await sync();
  }

  /// Fires OS tray notification + live dialog for sessions that just started.
  Future<void> checkDueSessions({List<MeetingSession>? sessions}) async {
    final list = sessions ?? await MeetingSessionsCache.load();
    if (list.isEmpty) return;

    final now = DateTime.now().toUtc();
    for (final session in list) {
      if (!session.status.isSchedulable) continue;
      final age = now.difference(session.startTime.toUtc());

      if (age.isNegative && age.abs() > const Duration(seconds: 5)) continue;
      if (age >= LiveSessionsWatcher.missedWindow) continue;

      await MeetingSessionsLocalScheduler.showSession(session);

      LiveSessionsWatcher.surfaceFromPayload(
        session.toSessionLivePayload(),
        playAlarm: true,
      );
    }
  }

  Future<void> clear() async {
    await MeetingSessionsLocalScheduler.cancelAllScheduled();
    await MeetingSessionsCache.clear();
  }
}
