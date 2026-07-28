import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/notification_styles.dart';
import '../../../core/widgets/icons/mystery_card_icon.dart';
import '../../../data/notifications/notification_models.dart';
import '../../course/widgets/lesson_action_icons.dart';

abstract final class NotificationIcons {
  static const titles = <NotificationType, String>{
    NotificationType.chat: 'رسالة جديدة',
    NotificationType.newQuestionPoint: 'نقاط جديدة',
    NotificationType.newLesson: 'درس جديد',
    NotificationType.newQuiz: 'اختبار جديد',
    NotificationType.newClassificationQuizPoints: 'نتيجة اختبار التصنيف',
    NotificationType.newLessonCardsCompleted: 'أتممت بطاقات الدرس',
    NotificationType.newKnowledgeQuizPoints: 'نتيجة كروت الحظ',
    NotificationType.externalSource: 'مصدر خارجي',
    NotificationType.moduleMaterial: 'محتوى جديد للماده',
    NotificationType.newLessonTrophy: 'دخول الدرس',
    NotificationType.newQuizPoints: 'نتيجة الاختبار',
    NotificationType.inactivityReminder: 'تذكير الدراسة',
    NotificationType.incompleteContent: 'محتوى غير مكتمل',
  };

  static Widget forItem(
    NotificationListItem item, {
    required bool isUnread,
  }) {
    final type = switch (item) {
      IndividualNotificationItem(:final notification) => notification.type,
      GroupNotificationItem(:final group) => group.groupType,
    };

    return forType(type, isUnread: isUnread);
  }

  static Widget forType(
    NotificationType type, {
    required bool isUnread,
  }) {
    final color =
        isUnread ? NotificationStyles.accentUnread : NotificationStyles.iconRead;
    const size = 20.0;

    switch (type) {
      case NotificationType.chat:
        return LessonActionIcons.svg(
          LessonActionIcons.comment,
          size: size,
          color: color,
        );
      case NotificationType.newQuestionPoint:
      case NotificationType.newLessonTrophy:
      case NotificationType.newQuizPoints:
        return LessonActionIcons.svg(
          LessonActionIcons.trophy,
          size: size,
          color: color,
        );
      case NotificationType.moduleMaterial:
        return LessonActionIcons.svg(
          LessonActionIcons.bookOpen,
          size: size,
          color: color,
        );
      case NotificationType.externalSource:
        return Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: color,
        );
      case NotificationType.newLesson:
        return SvgPicture.asset(
          'assets/icons/incomplete/youtube.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case NotificationType.newQuiz:
        return SvgPicture.asset(
          'assets/icons/incomplete/exam_fill.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case NotificationType.newClassificationQuizPoints:
        return LessonActionIcons.svg(
          LessonActionIcons.rankingStar,
          size: size,
          color: color,
        );
      case NotificationType.newLessonCardsCompleted:
        return LessonActionIcons.svg(
          LessonActionIcons.cards,
          size: size,
          color: color,
        );
      case NotificationType.newKnowledgeQuizPoints:
        return Opacity(
          opacity: isUnread ? 1 : 0.5,
          child: MysteryCardIcon(
            size: 25,
            cardColor: isUnread
                ? NotificationStyles.accentUnread
                : NotificationStyles.textBody,
            symbolColor: const Color(0xB3000000),
          ),
        );
      case NotificationType.incompleteContent:
        return LessonActionIcons.svg(
          LessonActionIcons.checkmark,
          size: size,
          color: color,
        );
      case NotificationType.inactivityReminder:
        return Icon(
          Icons.schedule_rounded,
          size: size,
          color: color,
        );
      case NotificationType.unknown:
        return Icon(
          Icons.notifications_rounded,
          size: size,
          color: color,
        );
    }
  }
}
