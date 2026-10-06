import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'meeting_session.dart';

abstract final class MeetingSessionsCache {
  static const _sessionsKey = 'meeting_sessions_cache_v1';
  static const _syncedAtKey = 'meeting_sessions_synced_at_v1';
  static const _scheduledIdsKey = 'meeting_sessions_scheduled_ids_v1';

  static Future<List<MeetingSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => MeetingSession.fromJson(Map<String, dynamic>.from(item)))
          .where((session) => session.id > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<MeetingSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
    await prefs.setString(
      _syncedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<DateTime?> syncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static Future<List<int>> loadScheduledIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scheduledIdsKey) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toList();
  }

  static Future<void> saveScheduledIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledIdsKey,
      ids.map((id) => '$id').toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_syncedAtKey);
    await prefs.remove(_scheduledIdsKey);
  }
}
