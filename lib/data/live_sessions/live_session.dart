class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.courseName,
    required this.startTime,
    this.meetingLink,
    this.notificationId,
  });

  final int id;
  final String title;
  final String courseName;
  final String startTime;
  final String? meetingLink;
  final int? notificationId;

  bool get hasMeetingLink =>
      meetingLink != null && meetingLink!.trim().isNotEmpty;
}
