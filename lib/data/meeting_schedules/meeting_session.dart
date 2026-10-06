enum MeetingSessionStatus {
  upcoming('UPCOMING'),
  live('LIVE'),
  ended('ENDED'),
  cancelled('CANCELLED'),
  unknown('');

  const MeetingSessionStatus(this.apiValue);

  final String apiValue;

  static MeetingSessionStatus fromApi(String? value) {
    return MeetingSessionStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => MeetingSessionStatus.unknown,
    );
  }

  bool get isSchedulable =>
      this == MeetingSessionStatus.upcoming || this == MeetingSessionStatus.live;
}

/// One occurrence from student or family meeting-schedule APIs.
class MeetingSession {
  const MeetingSession({
    required this.id,
    required this.startTime,
    required this.status,
    required this.title,
    this.meetingLink,
    this.groupName,
    this.courseName,
    this.courseId,
    this.studentId,
    this.studentName,
  });

  final int id;
  final DateTime startTime;
  final MeetingSessionStatus status;
  final String title;
  final String? meetingLink;
  final String? groupName;
  final String? courseName;
  final int? courseId;
  final int? studentId;
  final String? studentName;

  bool get hasMeetingLink =>
      meetingLink != null && meetingLink!.trim().isNotEmpty;

  bool get hasStudentLabel =>
      studentName != null && studentName!.trim().isNotEmpty;

  String get displayTitle {
    final base = title.trim().isNotEmpty
        ? title.trim()
        : (courseName?.trim().isNotEmpty == true
            ? courseName!.trim()
            : 'حصة مباشرة');
    if (!hasStudentLabel) return base;
    return '${studentName!.trim()} · $base';
  }

  factory MeetingSession.fromJson(
    Map<String, dynamic> json, {
    int? studentId,
    String? studentName,
  }) {
    final startRaw = json['startTime'] ?? json['start_time'];
    final start = DateTime.tryParse('$startRaw')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return MeetingSession(
      id: asInt(json['id']),
      startTime: start,
      status: MeetingSessionStatus.fromApi(json['status'] as String?),
      title: (json['title'] as String?)?.trim() ?? '',
      meetingLink: nullableString(json['meetingLink'] ?? json['meeting_link']),
      groupName: nullableString(json['groupName'] ?? json['group_name']),
      courseName: nullableString(json['courseName'] ?? json['course_name']),
      courseId: asIntOrNull(json['courseId'] ?? json['course_id']),
      studentId: studentId ??
          asIntOrNull(json['studentId'] ?? json['student_id']),
      studentName: studentName ??
          nullableString(json['studentName'] ?? json['student_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toUtc().toIso8601String(),
        'status': status.apiValue,
        'title': title,
        'meetingLink': meetingLink,
        'groupName': groupName,
        'courseName': courseName,
        'courseId': courseId,
        'studentId': studentId,
        'studentName': studentName,
      };

  /// Payload shaped like FCM/SSE `SESSION_LIVE` data for shared handlers.
  Map<String, String> toSessionLivePayload() {
    return {
      'type': 'SESSION_LIVE',
      'sessionId': '$id',
      'title': displayTitle,
      'courseName': courseName ?? '',
      'courseId': courseId?.toString() ?? '',
      'meetingLink': meetingLink ?? '',
      'startTime': startTime.toUtc().toIso8601String(),
      'groupName': groupName ?? '',
      'studentId': studentId?.toString() ?? '',
      'studentName': studentName ?? '',
      'source': 'local_schedule',
    };
  }

  static int asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static int? asIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static String? nullableString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}
