import '../../core/network/api_client.dart';
import 'meeting_session.dart';

abstract final class MeetingSchedulesApi {
  static Future<List<MeetingSession>> fetchStudentSessions() async {
    final raw = await ApiClient.getJsonList('/meeting-schedules/student');
    return raw
        .whereType<Map>()
        .map((item) => MeetingSession.fromJson(Map<String, dynamic>.from(item)))
        .where((session) => session.id > 0)
        .toList();
  }

  /// Upcoming sessions for every student sharing the authenticated phone.
  static Future<List<MeetingSession>> fetchFamilySessions() async {
    final raw =
        await ApiClient.getJsonList('/meeting-schedules/student/family');
    final sessions = <MeetingSession>[];

    for (final item in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final studentId = MeetingSession.asIntOrNull(
        map['studentId'] ?? map['student_id'],
      );
      final studentName = MeetingSession.nullableString(
            map['name'] ?? map['studentName'] ?? map['student_name'],
          ) ??
          '';
      final nested = map['sessions'];
      if (nested is! List) continue;

      for (final sessionRaw in nested.whereType<Map>()) {
        final session = MeetingSession.fromJson(
          Map<String, dynamic>.from(sessionRaw),
          studentId: studentId,
          studentName: studentName,
        );
        if (session.id > 0) sessions.add(session);
      }
    }

    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }
}
