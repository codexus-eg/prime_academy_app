import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons/premium_interactive_surface.dart';
import '../../exam/exam_page.dart';
import '../lesson_detail_page.dart';
import '../models/course_lesson.dart';
import 'lesson_status_icon.dart';

class UnitLessonsSection extends StatelessWidget {
  const UnitLessonsSection({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.unitTitle,
    required this.progressPercent,
    required this.lessons,
    required this.currentLessonId,
  });

  final String courseId;
  final String unitId;
  final String unitTitle;
  final int progressPercent;
  final List<CourseLesson> lessons;
  final String currentLessonId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.lessonProgressCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.base,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    unitTitle,
                    textAlign: TextAlign.start,
                    style: AppTypography.headingDialog.copyWith(
                      color: AppColors.onDark,
                      fontWeight: AppFonts.bold,
                      height: 1.56,
                    ),
                  ),
                ),
                _CompactProgressRing(percent: progressPercent),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.base,
            ),
            child: Column(
              children: [
                for (var i = 0; i < lessons.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.smPlus),
                  _LessonListEntry(
                    courseId: courseId,
                    unitId: unitId,
                    lesson: lessons[i],
                    isCurrent: lessons[i].id == currentLessonId,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactProgressRing extends StatelessWidget {
  const _CompactProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.lessonProgressRing(AppTheme.lessonCompleted),
      ),
      alignment: Alignment.center,
      child: Text(
        '$percent%',
        style: AppTypography.size20.copyWith(
          color: AppColors.onDark,
          fontWeight: AppFonts.bold,
          height: 1.40,
        ),
      ),
    );
  }
}

class _LessonListEntry extends StatelessWidget {
  const _LessonListEntry({
    required this.courseId,
    required this.unitId,
    required this.lesson,
    required this.isCurrent,
  });

  final String courseId;
  final String unitId;
  final CourseLesson lesson;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (lesson.isChallenge) {
      return _ChallengeBanner(
        onTap: () {
          final quizId = int.tryParse(lesson.id) ?? 0;
          context.push(
            ExamPage.pathFor(
              courseId: courseId,
              unitId: unitId,
              quizId: quizId,
            ),
          );
        },
      );
    }
    return _LessonListTile(
      lesson: lesson,
      isCurrent: isCurrent,
      onTap: () => _openLesson(context),
    );
  }

  void _openLesson(BuildContext context) {
    if (isCurrent) return;
    context.go(
      LessonDetailPage.pathFor(
        courseId: courseId,
        unitId: unitId,
        lessonId: lesson.id,
      ),
    );
  }
}

class _LessonListTile extends StatelessWidget {
  const _LessonListTile({
    required this.lesson,
    required this.isCurrent,
    required this.onTap,
  });

  final CourseLesson lesson;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.status == LessonStatus.completed;

    return PremiumInteractiveSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      accentColor: isCurrent ? AppTheme.homeTabBarFill : AppTheme.lessonActionDark,
      showGlow: false,
      child: Ink(
        height: 60,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.homeTabBarFill
                : AppTheme.lessonActionDark,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: isCurrent
                ? Border.all(color: AppTheme.lessonTimelineLine.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            children: [
              if (isCompleted)
                LessonStatusIcon(
                  progressPercent: lesson.progressPercent,
                  hasTrophy: lesson.hasTrophy,
                  showProgressRing: true,
                )
              else
                _PlayCircle(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onDark,
                        fontWeight: AppFonts.semibold,
                      ),
                    ),
                    if (lesson.duration != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        lesson.duration!,
                        textAlign: TextAlign.start,
                        style: AppTypography.size11.copyWith(
                          color: AppColors.onDark.withValues(alpha: 0.85),
                          fontWeight: AppFonts.regular,
                          height: 1.82,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.amberAccent,
                  size: 28,
                ),
              ],
            ],
          ),
        ),
    );
  }
}

class _PlayCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.loginGradientEnd,
        border: Border.all(color: AppTheme.lessonTimelineLine, width: 1),
        boxShadow: AppShadows.lessonPlayCircle(AppTheme.lessonCompleted),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.onDark,
        size: 16,
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumInteractiveSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      accentColor: AppTheme.loginGradientStart,
      showGlow: true,
      child: Ink(
        height: 72,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.smPlus,
            AppSpacing.base,
            AppSpacing.smPlus,
          ),
          decoration: BoxDecoration(
            gradient: AppGradients.challengeBanner,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 59,
                height: 59,
                decoration: BoxDecoration(
                  color: AppColors.onDark.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderCard,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.onDark.withValues(alpha: 0.9),
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستعد للاختبار؟',
                      textAlign: TextAlign.start,
                      style: AppTypography.headingDialog.copyWith(
                        color: AppColors.onDark,
                        fontWeight: AppFonts.bold,
                        height: 1.56,
                      ),
                    ),
                    Text(
                      'كمل التحدي عشان ترفع مستواك',
                      textAlign: TextAlign.start,
                      style: AppTypography.size10.copyWith(
                        color: AppColors.lessonMutedLabel,
                        fontWeight: AppFonts.regular,
                        height: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
