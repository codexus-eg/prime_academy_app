import 'package:flutter/foundation.dart';

import '../../../data/notifications/notification_models.dart';
import '../home_tab.dart';

class NotificationNavigationTarget {
  const NotificationNavigationTarget({
    required this.location,
    this.externalUrl,
    this.opensRanking = false,
  });

  final String location;
  final String? externalUrl;

  /// When true, [NotificationNavigator] calls the same path as the ranking tab
  /// (`go(/home/ranking)`) and ignores [location] params / course ids.
  final bool opensRanking;

  bool get isExternal => externalUrl != null && externalUrl!.isNotEmpty;
}

abstract final class NotificationLink {
  static NotificationNavigationTarget resolve({
    required NotificationType type,
    required NotificationData data,
    int? chatId,
  }) {
    final courseId = data.courseId;
    final moduleId = data.moduleId;
    final itemId = data.itemId ?? data.lessonId;

    switch (type) {
      case NotificationType.newLesson:
        if (courseId != null && moduleId != null && itemId != null) {
          return NotificationNavigationTarget(
            location: _lessonPath(
              courseId: courseId,
              moduleId: moduleId,
              itemId: itemId,
            ),
          );
        }
      case NotificationType.newQuiz:
        if (courseId != null && moduleId != null && itemId != null) {
          return NotificationNavigationTarget(
            location: _quizPath(
              courseId: courseId,
              moduleId: moduleId,
              quizId: itemId,
            ),
          );
        }
      case NotificationType.moduleMaterial:
        final materialUrl = data.url ?? data.link;
        if (materialUrl.isNotEmpty) {
          final normalized = normalizeAppPath(materialUrl);
          if (normalized != null) {
            return NotificationNavigationTarget(location: normalized);
          }
          if (_looksLikeExternalUrl(materialUrl)) {
            return NotificationNavigationTarget(
              location: '/',
              externalUrl: materialUrl,
            );
          }
        }
        if (courseId != null && moduleId != null && itemId != null) {
          return NotificationNavigationTarget(
            location: _lessonPath(
              courseId: courseId,
              moduleId: moduleId,
              itemId: itemId,
              query: const {'active_tab': 'files'},
            ),
          );
        }
      case NotificationType.chat:
        if (courseId != null && moduleId != null && itemId != null) {
          final resolvedChatId = chatId ?? data.chatId;
          final query = <String, String>{'active_tab': 'chat'};
          if (resolvedChatId != null && resolvedChatId > 0) {
            query['chat_id'] = '$resolvedChatId';
          }
          return NotificationNavigationTarget(
            location: _lessonPath(
              courseId: courseId,
              moduleId: moduleId,
              itemId: itemId,
              query: query,
            ),
          );
        }
      case NotificationType.externalSource:
        if (data.link.isNotEmpty) {
          return NotificationNavigationTarget(
            location: '/',
            externalUrl: data.link,
          );
        }
      case NotificationType.incompleteContent:
        return NotificationNavigationTarget(
          location: HomeTab.incompleteTasks.routePath,
        );
      case NotificationType.inactivityReminder:
        return NotificationNavigationTarget(
          location: HomeTab.reports.routePath,
        );
      case NotificationType.newQuizPoints:
      case NotificationType.newClassificationQuizPoints:
      case NotificationType.newLessonTrophy:
      case NotificationType.newQuestionPoint:
      case NotificationType.newLessonCardsCompleted:
      case NotificationType.newKnowledgeQuizPoints:
        // Same destination as HomeTabBar ranking tap — ignore data.link /
        // course_id entirely (web buildNotificationLink parity).
        return const NotificationNavigationTarget(
          location: '/home/ranking',
          opensRanking: true,
        );
      case NotificationType.unknown:
        break;
    }

    if (data.link.isNotEmpty) {
      final normalized = normalizeAppPath(data.link);
      if (normalized != null) {
        return NotificationNavigationTarget(location: normalized);
      }
      if (_looksLikeExternalUrl(data.link)) {
        return NotificationNavigationTarget(
          location: '/',
          externalUrl: data.link,
        );
      }
    }
    return NotificationNavigationTarget(
      location: HomeTab.defaultTab.routePath,
    );
  }

  /// FCM / SSE payload fields are strings (`buildFcmData` on the server).
  static NotificationNavigationTarget fromPayload(Map<String, String> data) {
    if (kDebugMode) {
      debugPrint('[Notification] Payload received type=${data['type']}');
    }
    return resolve(
      type: NotificationType.fromApi(data['type']),
      data: NotificationData(
        title: data['title'] ?? '',
        link: data['link'] ?? '',
        chatId: _parseId(data['chatId'] ?? data['chat_id']),
        itemId: _parseId(data['itemId'] ?? data['item_id']),
        lessonId: _parseId(data['lessonId'] ?? data['lesson_id']),
        courseId: _parseId(data['courseId'] ?? data['course_id']),
        moduleId: _parseId(data['moduleId'] ?? data['module_id']),
        url: data['url'],
      ),
    );
  }

  static int? _parseId(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  static NotificationNavigationTarget forItem(NotificationListItem item) {
    return switch (item) {
      GroupNotificationItem(:final group) => resolve(
          type: group.groupType,
          data: NotificationData(
            title: group.title,
            link: group.link,
            courseId:
                group.courseId ?? NotificationData.courseIdFromLink(group.link),
            moduleId: group.moduleId,
            itemId: group.itemId,
            chatId: group.groupId,
          ),
          chatId: group.groupId,
        ),
      IndividualNotificationItem(:final notification) => resolve(
          type: notification.type,
          data: notification.data,
        ),
    };
  }

  static String? normalizeAppPath(String link) {
    final uri = Uri.tryParse(link);
    final path = uri?.path ?? link;

    final lessonMatch = RegExp(
      r'^/course/(\d+)/module/(\d+)/lesson/(\d+)$',
    ).firstMatch(path);
    if (lessonMatch != null) {
      final query = Map<String, String>.from(uri?.queryParameters ?? {});
      if (query.containsKey('chat_id') && !query.containsKey('active_tab')) {
        query['active_tab'] = 'chat';
      }
      return _lessonPath(
        courseId: int.parse(lessonMatch.group(1)!),
        moduleId: int.parse(lessonMatch.group(2)!),
        itemId: int.parse(lessonMatch.group(3)!),
        query: query.isEmpty ? null : query,
      );
    }

    final quizMatch = RegExp(
      r'^/course/(\d+)/module/(\d+)/quiz/(\d+)$',
    ).firstMatch(path);
    if (quizMatch != null) {
      return _quizPath(
        courseId: int.parse(quizMatch.group(1)!),
        moduleId: int.parse(quizMatch.group(2)!),
        quizId: int.parse(quizMatch.group(3)!),
      );
    }

    final flutterLessonMatch = RegExp(
      r'^/course/(\d+)/units/(\d+)/lessons/(\d+)$',
    ).firstMatch(path);
    if (flutterLessonMatch != null) {
      final query = uri?.queryParameters;
      if (query == null || query.isEmpty) return path;
      return Uri(path: path, queryParameters: query).toString();
    }

    final flutterQuizMatch = RegExp(
      r'^/course/(\d+)/units/(\d+)/quiz/(\d+)$',
    ).firstMatch(path);
    if (flutterQuizMatch != null) return path;

    if (path.startsWith('/home/')) {
      final query = uri?.queryParameters;
      if (query != null && query.isNotEmpty) {
        return Uri(path: path, queryParameters: query).toString();
      }
      return path;
    }

    final profileTab = uri?.queryParameters['tab'];
    if (path.startsWith('/my-profile/student')) {
      return switch (profileTab) {
        '0' => HomeTab.reports.routePath,
        '2' => HomeTab.ranking.routePath,
        '4' => HomeTab.incompleteTasks.routePath,
        _ => HomeTab.defaultTab.routePath,
      };
    }

    return null;
  }

  static String _lessonPath({
    required int courseId,
    required int moduleId,
    required int itemId,
    Map<String, String>? query,
  }) {
    final path = '/course/$courseId/units/$moduleId/lessons/$itemId';
    if (query == null || query.isEmpty) return path;
    return Uri(path: path, queryParameters: query).toString();
  }

  static String _quizPath({
    required int courseId,
    required int moduleId,
    required int quizId,
  }) =>
      '/course/$courseId/units/$moduleId/quiz/$quizId';

  static bool _looksLikeExternalUrl(String link) {
    final lower = link.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:');
  }
}
