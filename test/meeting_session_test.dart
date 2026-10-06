import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/meeting_schedules/meeting_session.dart';

void main() {
  group('MeetingSession', () {
    test('parses student sessions payload', () {
      final session = MeetingSession.fromJson({
        'id': 63,
        'startTime': '2026-09-15T17:12:00.000Z',
        'status': 'UPCOMING',
        'title': 'انجليزي',
        'meetingLink': 'https://meet.example.com/abc',
        'groupName': 'مجموعة السبت',
        'courseName': 'English',
      });

      expect(session.id, 63);
      expect(session.status, MeetingSessionStatus.upcoming);
      expect(session.startTime.isUtc, isTrue);
      expect(session.hasMeetingLink, isTrue);
    });

    test('toSessionLivePayload mirrors FCM/SSE shape', () {
      final session = MeetingSession(
        id: 10,
        startTime: DateTime.utc(2026, 9, 15, 17, 12),
        status: MeetingSessionStatus.upcoming,
        title: 'حصة',
        meetingLink: 'https://meet.example.com/x',
        courseName: 'مادة',
        courseId: 4,
      );

      final payload = session.toSessionLivePayload();
      expect(payload['type'], 'SESSION_LIVE');
      expect(payload['sessionId'], '10');
      expect(payload['meetingLink'], 'https://meet.example.com/x');
      expect(payload['courseId'], '4');
      expect(payload['source'], 'local_schedule');
    });

    test('LIVE status is schedulable', () {
      expect(MeetingSessionStatus.live.isSchedulable, isTrue);
      expect(MeetingSessionStatus.ended.isSchedulable, isFalse);
    });
  });
}
