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
  });

  final String title;
  final String link;
  final int? chatId;
  final int? itemId;
  final int? lessonId;
  final int? courseId;
  final int? moduleId;
  final String? url;

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      title: json['title'] as String? ??
          json['message'] as String? ??
          '',
      link: json['link'] as String? ?? '',
      chatId: _intOrNull(json['chatId'] ?? json['chat_id']),
      itemId: _intOrNull(json['itemId'] ?? json['item_id']),
      lessonId: _intOrNull(json['lessonId'] ?? json['lesson_id']),
      courseId: _intOrNull(json['courseId'] ?? json['course_id']),
      moduleId: _intOrNull(json['moduleId'] ?? json['module_id']),
      url: json['url'] as String?,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final NotificationType type;
  final NotificationData data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
