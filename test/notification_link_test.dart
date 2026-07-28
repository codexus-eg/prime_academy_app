import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/notifications/notification_models.dart';
import 'package:prime_flutter/presentation/home/home_tab.dart';
import 'package:prime_flutter/presentation/home/widgets/notification_link.dart';

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
    });
  });
}
