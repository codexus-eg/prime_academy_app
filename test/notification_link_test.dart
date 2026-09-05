import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/notifications/notification_models.dart';
import 'package:prime_flutter/presentation/home/home_tab.dart';
import 'package:prime_flutter/presentation/home/ranking/ranking_open_signal.dart';
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

    test('normalizeAppPath maps profile tabs to home routes without course_id', () {
      expect(
        NotificationLink.normalizeAppPath('/my-profile/student?tab=2'),
        HomeTab.ranking.routePath,
      );
      expect(
        NotificationLink.normalizeAppPath(
          '/my-profile/student?tab=2&course_id=42',
        ),
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

    test('normalizeAppPath preserves home ranking query params for manual URLs', () {
      expect(
        NotificationLink.normalizeAppPath('/home/ranking?course_id=42'),
        '/home/ranking?course_id=42',
      );
    });

    test('ranking point types open ranking tab like HomeTabBar', () {
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
        expect(target.opensRanking, isTrue);
      }
    });

    test('point notifications ignore course_id in data', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newQuestionPoint,
        data: const NotificationData(
          title: 'نقطة جديدة',
          link: '',
          courseId: 9,
        ),
      );
      expect(target.location, HomeTab.ranking.routePath);
      expect(target.opensRanking, isTrue);
    });

    test('lesson trophy notification ignores course_id in link', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newLessonTrophy,
        data: const NotificationData(
          title: 'تم الحصول على نقطة من دخول الدرس',
          link: '/my-profile/student?tab=2&course_id=17',
        ),
      );
      expect(target.location, HomeTab.ranking.routePath);
      expect(target.opensRanking, isTrue);
    });

    test('NotificationData still parses course_id embedded in link for other uses', () {
      final data = NotificationData.fromJson({
        'title': 'تم الحصول على نقطة من دخول الدرس',
        'link': '/my-profile/student?tab=2&course_id=17',
      });
      expect(data.courseId, 17);
    });

    test('classification points ignore course_id in link', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newClassificationQuizPoints,
        data: const NotificationData(
          title: 'نتيجة التصنيف',
          link: '/my-profile/student?tab=2&course_id=17',
        ),
      );
      expect(target.location, HomeTab.ranking.routePath);
      expect(target.opensRanking, isTrue);
    });

    test('in-session SSE trophy payload opens ranking tab path', () {
      final notification = AppNotification.fromJson({
        'id': 99,
        'type': 'NEW_LESSON_TROPHY',
        'data': {
          'title': 'تم الحصول على نقطة من دخول الدرس',
          'link': '/my-profile/student?tab=2&course_id=17',
        },
        'is_read': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
      final target = NotificationLink.forItem(
        IndividualNotificationItem(notification),
      );
      expect(target.location, HomeTab.ranking.routePath);
      expect(target.opensRanking, isTrue);
    });

    test('missing lesson ids fall back to home, not a crash', () {
      final target = NotificationLink.resolve(
        type: NotificationType.newLesson,
        data: const NotificationData(title: 'درس', link: ''),
      );
      expect(target.location, HomeTab.defaultTab.routePath);
      expect(target.opensRanking, isFalse);
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

    test('fromPayload ranking type ignores course_id', () {
      final target = NotificationLink.fromPayload({
        'type': 'NEW_LESSON_TROPHY',
        'courseId': '17',
        'link': '/my-profile/student?tab=2&course_id=17',
        'title': 'نقطة',
      });
      expect(target.location, HomeTab.ranking.routePath);
      expect(target.opensRanking, isTrue);
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

    test('different ranking course is not the same destination', () {
      final current = Uri.parse('/home/ranking?course_id=1');
      final dest = Uri.parse('/home/ranking?course_id=2');
      expect(NotificationNavigator.isSameDestination(current, dest), isFalse);
    });

    test('ranking tab path matches HomeTab.ranking.routePath', () {
      expect(HomeTab.ranking.routePath, '/home/ranking');
    });

    test('openRankingTabDirectly bumps RankingOpenSignal before go', () {
      RankingOpenSignal.instance.reset();
      expect(RankingOpenSignal.instance.generation, 0);
      RankingOpenSignal.instance.requestOpen();
      expect(RankingOpenSignal.instance.generation, 1);
    });
  });
}
