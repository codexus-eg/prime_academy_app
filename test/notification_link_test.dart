import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/notifications/notification_models.dart';
import 'package:prime_flutter/presentation/home/home_tab.dart';
import 'package:prime_flutter/presentation/home/widgets/notification_link.dart';
import 'package:prime_flutter/presentation/home/widgets/notification_navigator.dart';

void main() {
  group('NotificationLink', () {
    test('NEW_QUIZ navigates to unit quiz route', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newQuiz,
        data: const NotificationData(
          title: 'اختبار جديد',
          link: '',
          courseId: 5,
          moduleId: 12,
          itemId: 99,
        ),
      );

      expect(target.location, '/course/5/units/12/quiz/99');
      expect(target.isExternal, isFalse);
    });

    test('NEW_LESSON navigates to lesson route', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newLesson,
        data: const NotificationData(
          title: 'درس جديد',
          link: '',
          courseId: 1,
          moduleId: 2,
          itemId: 3,
        ),
      );

      expect(target.location, '/course/1/units/2/lessons/3');
    });

    test('CHAT opens lesson chat tab with chat_id query', () {
      final target = NotificationLink.resolve(
        type: NotificationType.chat,
        data: const NotificationData(
          title: 'رسالة جديدة',
          link: '',
          courseId: 1,
          moduleId: 2,
          itemId: 3,
          chatId: 7,
        ),
      );

      expect(
        target.location,
        '/course/1/units/2/lessons/3?active_tab=chat&chat_id=7',
      );
    });

    test('normalizeAppPath converts web lesson links', () {
      expect(
        NotificationLink.normalizeAppPath(
          '/course/4/module/8/lesson/15?active_tab=chat&chat_id=3',
        ),
        '/course/4/units/8/lessons/15?active_tab=chat&chat_id=3',
      );
    });

    test('normalizeAppPath converts web quiz links', () {
      expect(
        NotificationLink.normalizeAppPath('/course/4/module/8/quiz/15'),
        '/course/4/units/8/quiz/15',
      );
    });

    test('normalizeAppPath maps profile tabs to home routes', () {
      expect(
        NotificationLink.normalizeAppPath('/my-profile/student?tab=2'),
        HomeTab.ranking.routePath,
      );
      expect(
        NotificationLink.normalizeAppPath('/my-profile/student?tab=4'),
        HomeTab.incompleteTasks.routePath,
      );
      expect(
        NotificationLink.normalizeAppPath('/my-profile/student?tab=0'),
        HomeTab.reports.routePath,
      );
    });

    test('MODULE_MATERIAL opens lesson files tab when ids exist', () {
      final target = NotificationLink.resolve(
        type: NotificationType.moduleMaterial,
        data: const NotificationData(
          title: 'مذكرة جديدة',
          link: '',
          courseId: 2,
          moduleId: 4,
          itemId: 9,
        ),
      );
      expect(
        target.location,
        '/course/2/units/4/lessons/9?active_tab=files',
      );
    });

    test('ranking point types open ranking tab', () {
      for (final type in [
        NotificationType.newQuizPoints,
        NotificationType.newClassificationQuizPoints,
        NotificationType.newLessonTrophy,
        NotificationType.newQuestionPoint,
        NotificationType.newLessonCardsCompleted,
        NotificationType.newKnowledgeQuizPoints,
      ]) {
        final target = NotificationLink.resolve(
          type: type,
          data: const NotificationData(title: 'نقاط', link: ''),
        );
        expect(target.location, HomeTab.ranking.routePath);
      }
    });

    test('missing lesson ids fall back to home, not a crash', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newLesson,
        data: const NotificationData(title: 'درس', link: ''),
      );
      expect(target.location, HomeTab.defaultTab.routePath);
    });

    test('fromPayload reads FCM string fields', () {
      final target = NotificationLink.fromPayload({
        'type': 'CHAT',
        'courseId': '1',
        'moduleId': '2',
        'itemId': '3',
        'chatId': '7',
        'link': '',
      });
      expect(
        target.location,
        '/course/1/units/2/lessons/3?active_tab=chat&chat_id=7',
      );
    });

    test('EXTERNAL_SOURCE uses the link as an external url', () {
      final target = NotificationLink.resolve(
        type: NotificationType.externalSource,
        data: const NotificationData(
          title: 'مصدر',
          link: 'https://example.com/resource',
        ),
      );
      expect(target.isExternal, isTrue);
      expect(target.externalUrl, 'https://example.com/resource');
    });
  });

  group('NotificationNavigator', () {
    test('same destination ignores query order', () {
      final current = Uri.parse(
        '/course/1/units/2/lessons/3?chat_id=7&active_tab=chat',
      );
      final dest = Uri.parse(
        '/course/1/units/2/lessons/3?active_tab=chat&chat_id=7',
      );
      expect(NotificationNavigator.isSameDestination(current, dest), isTrue);
    });

    test('different lesson is not the same destination', () {
      final current = Uri.parse('/course/1/units/2/lessons/3');
      final dest = Uri.parse('/course/1/units/2/lessons/4');
      expect(NotificationNavigator.isSameDestination(current, dest), isFalse);
    });
  });
}
