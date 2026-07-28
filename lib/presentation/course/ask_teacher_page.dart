import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/lesson_chat_panel.dart';

class AskTeacherPage extends StatelessWidget {
  const AskTeacherPage({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
    required this.chatId,
  });

  final String courseId;
  final String unitId;
  final String lessonId;
  final int chatId;

  static const String routePath =
      '/course/:courseId/units/:unitId/lessons/:lessonId/ask-teacher';
  static const String routeName = 'ask-teacher';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId/ask-teacher';

  @override
  Widget build(BuildContext context) {
    final parsedCourseId = int.tryParse(courseId) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scrim80,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageContentHorizontal,
            vertical: AppSpacing.base,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderCard,
            child: ColoredBox(
              color: AppTheme.profileInner,
              child: LessonChatPanel(
                chatId: chatId,
                courseId: parsedCourseId,
                onClose: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
