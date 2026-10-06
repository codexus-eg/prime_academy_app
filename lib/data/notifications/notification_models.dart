enum NotificationType {
  chat('CHAT'),
  newQuestionPoint('NEW_QUESTION_POINT'),
  newLesson('NEW_LESSON'),
  newQuiz('NEW_QUIZ'),
  newClassificationQuizPoints('NEW_CLASSIFICATION_QUIZ_POINTS'),
  newLessonCardsCompleted('NEW_LESSON_CARDS_COMPLETED'),
  newKnowledgeQuizPoints('NEW_KNOWLEDGE_QUIZ_POINTS'),
  externalSource('EXTERNAL_SOURCE'),
  moduleMaterial('MODULE_MATERIAL'),
  newLessonTrophy('NEW_LESSON_TROPHY'),
  newQuizPoints('NEW_QUIZ_POINTS'),
  inactivityReminder('INACTIVITY_REMINDER'),
  incompleteContent('INCOMPLETE_CONTENT'),
  sessionLive('SESSION_LIVE'),
  unknown('');

  const NotificationType(this.apiValue);

  final String apiValue;

  static NotificationType fromApi(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => NotificationType.unknown,
    );
  }
}

class NotificationData {
  const NotificationData({
    required this.title,
    required this.link,
    this.chatId,
    this.itemId,
    this.lessonId,
    this.courseId,
    this.moduleId,
    this.url,
    this.sessionId,
    this.meetingLink,
    this.startTime,
    this.courseName,
    this.groupName,
  });

  final String title;
  final String link;
  final int? chatId;
  final int? itemId;
  final int? lessonId;
  final int? courseId;
  final int? moduleId;
  final String? url;
  final int? sessionId;
  final String? meetingLink;
  final String? startTime;
  final String? courseName;
  final String? groupName;

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final link = json['link'] as String? ?? '';
    return NotificationData(
      title: json['title'] as String? ??
          json['message'] as String? ??
          '',
      link: link,
      chatId: _intOrNull(json['chatId'] ?? json['chat_id']),
      itemId: _intOrNull(json['itemId'] ?? json['item_id']),
      lessonId: _intOrNull(json['lessonId'] ?? json['lesson_id']),
      courseId: _intOrNull(json['courseId'] ?? json['course_id']) ??
          courseIdFromLink(link),
      moduleId: _intOrNull(json['moduleId'] ?? json['module_id']),
      url: json['url'] as String?,
      sessionId: _intOrNull(json['sessionId'] ?? json['session_id']),
      meetingLink: _stringOrNull(json['meetingLink'] ?? json['meeting_link']),
      startTime: _stringOrNull(json['startTime'] ?? json['start_time']),
      courseName: _stringOrNull(json['courseName'] ?? json['course_name']),
      groupName: _stringOrNull(json['groupName'] ?? json['group_name']),
    );
  }

  static int? courseIdFromLink(String link) => _courseIdFromLink(link);
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.fromSse = false,
  });

  final int id;
  final NotificationType type;
  final NotificationData data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when this row arrived over the live SSE channel (not a hydrate).
  final bool fromSse;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _int(json['id']),
      type: NotificationType.fromApi(json['type'] as String?),
      data: NotificationData.fromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      ),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AppNotification copyWith({bool? isRead, bool? fromSse}) {
    return AppNotification(
      id: id,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fromSse: fromSse ?? this.fromSse,
    );
  }
}

class GroupedNotification {
  const GroupedNotification({
    required this.groupType,
    required this.groupId,
    required this.title,
    required this.link,
    required this.notificationIds,
    required this.unreadCount,
    required this.latestTimestamp,
    required this.isRead,
    this.courseId,
    this.moduleId,
    this.itemId,
  });

  final NotificationType groupType;
  final int groupId;
  final String title;
  final String link;
  final int? courseId;
  final int? moduleId;
  final int? itemId;
  final List<int> notificationIds;
  final int unreadCount;
  final DateTime latestTimestamp;
  final bool isRead;
}

sealed class NotificationListItem {
  const NotificationListItem();
}

class IndividualNotificationItem extends NotificationListItem {
  const IndividualNotificationItem(this.notification);

  final AppNotification notification;
}

class GroupNotificationItem extends NotificationListItem {
  const GroupNotificationItem(this.group);

  final GroupedNotification group;
}

int _int(Object? value) {
  if (value is int) return value;
  return int.parse(value.toString());
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  return text;
}

int? _courseIdFromLink(String link) {
  if (link.isEmpty) return null;
  final uri = Uri.tryParse(link);
  final raw = uri?.queryParameters['course_id'];
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}
