import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../exam/exam_page.dart';
import '../lesson_detail_page.dart';
import '../models/course_lesson.dart';
import 'lesson_status_icon.dart';

class LessonTimeline extends StatelessWidget {
  const LessonTimeline({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessons,
    this.dotColor = AppColors.blue,
  });

  final String courseId;
  final String unitId;
  final List<CourseLesson> lessons;
  final Color dotColor;

  static const rowSpacing = AppSpacing.sm;
  static const iconSize = LessonStatusIcon.size;
  static const iconColumnWidth = LessonStatusIcon.size;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.courseTitleInner,
        0,
        AppSpacing.courseTitleInner,
        AppSpacing.courseTitleInner,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lessons.length; i++) ...[
            if (i > 0) const SizedBox(height: rowSpacing),
            _LessonTimelineRow(
              lesson: lessons[i],
              isLast: i == lessons.length - 1,
              dotColor: dotColor,
              onTap: () => _openLesson(context, lessons[i]),
            ),
          ],
        ],
      ),
    );
  }

  void _openLesson(BuildContext context, CourseLesson lesson) {

    if (lesson.locked) return;

    if (lesson.isExternal) {
      final url = lesson.externalUrl;
      if (url != null && url.isNotEmpty) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (lesson.isChallenge) {
      final quizId = int.tryParse(lesson.id) ?? 0;
      context.push(
        ExamPage.pathFor(
          courseId: courseId,
          unitId: unitId,
          quizId: quizId,
        ),
      );
      return;
    }
    context.push(
      LessonDetailPage.pathFor(
        courseId: courseId,
        unitId: unitId,
        lessonId: lesson.id,
      ),
    );
  }
}

class _LessonTimelineRow extends StatelessWidget {
  const _LessonTimelineRow({
    required this.lesson,
    required this.isLast,
    required this.dotColor,
    required this.onTap,
  });

  final CourseLesson lesson;
  final bool isLast;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderCard,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.courseLessonIconInset,
                AppSpacing.courseLessonVertical,
                AppSpacing.courseLessonLeading,
                AppSpacing.courseLessonVertical,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  lesson.title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onDark,
                    fontWeight: AppFonts.medium,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: LessonTimeline.iconColumnWidth,
              child: Center(
                child: LessonStatusIcon(
                  status: lesson.status,
                  progressColor: dotColor,
                ),
              ),
            ),
            if (!isLast)
              PositionedDirectional(
                start: AppSpacing.courseLessonConnector,
                top: AppSpacing.courseLessonVertical +
                    LessonTimeline.iconSize / 2 +
                    AppSpacing.xxs,
                bottom: -(AppSpacing.courseLessonVertical + LessonTimeline.rowSpacing),
                child: Container(
                  width: AppSpacing.courseLessonLineWidth,
                  color: dotColor.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
