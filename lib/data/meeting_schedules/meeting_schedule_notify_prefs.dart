import 'package:shared_preferences/shared_preferences.dart';

/// Who local session alarms should cover.
enum MeetingScheduleNotifyScope {
  /// Only the logged-in student (`/meeting-schedules/student`).
  personal,

  /// Every student sharing the same phone (`/meeting-schedules/student/family`).
  family,
}

/// Persists the user's personal-vs-family notification choice.
abstract final class MeetingScheduleNotifyPrefs {
  static const _key = 'meeting_schedule_notify_scope_v1';

  static Future<MeetingScheduleNotifyScope> load({
    required bool canUseFamily,
  }) async {
    if (!canUseFamily) return MeetingScheduleNotifyScope.personal;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == MeetingScheduleNotifyScope.personal.name) {
      return MeetingScheduleNotifyScope.personal;
    }
    // Default for multi-account phone: family (all subscribers).
    if (raw == MeetingScheduleNotifyScope.family.name || raw == null) {
      return MeetingScheduleNotifyScope.family;
    }
    return MeetingScheduleNotifyScope.personal;
  }

  static Future<void> save(MeetingScheduleNotifyScope scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, scope.name);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
