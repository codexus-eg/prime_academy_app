import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/painting/css_lesson_action_gradient_painter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../exam/exam_page.dart';
import '../lesson_detail_page.dart';
import '../models/course_lesson.dart';
import 'lesson_action_icons.dart';
import 'wobbly_circle.dart';

class LessonVideosAside extends StatefulWidget {
  const LessonVideosAside({
    super.key,
    required this.height,
    required this.courseId,
    required this.unitId,
    required this.unitTitle,
    required this.lessons,
    required this.currentLessonId,
    required this.isEnrolled,
    required this.showStudentProgress,
    this.liveProgressPercent,
  });

  final double height;
  final String courseId;
  final String unitId;
  final String unitTitle;
  final List<CourseLesson> lessons;
  final String currentLessonId;
  final bool isEnrolled;

  final bool showStudentProgress;

  final int? liveProgressPercent;

  @override
  State<LessonVideosAside> createState() => _LessonVideosAsideState();
}

class _LessonVideosAsideState extends State<LessonVideosAside> {
  static const _headerAnimation = Duration(milliseconds: 300);
  static const _scrollCollapseThreshold = 10.0;

  final _wobblyKey = GlobalKey();

  bool _isCollapsed = false;
  bool _isAdjustingScroll = false;
  double _touchStartY = 0;
  final _scrollController = ScrollController();

  double get _headerDiff =>
      AppSpacing.lessonAsideHeaderExpanded -
      AppSpacing.lessonAsideHeaderCollapsed;

  int get _trophyScore {
    if (!widget.showStudentProgress) return 0;
    final lessonItems = widget.lessons.where((l) => !l.isChallenge).toList();
    if (lessonItems.isEmpty) return 0;
    final trophied = lessonItems.where((l) => l.hasTrophy).length;
    return ((trophied / lessonItems.length) * 100).round();
  }

  bool get _showWobblyCircle =>
      widget.isEnrolled && widget.showStudentProgress;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setCollapsed(bool collapsed) {
    if (_isCollapsed == collapsed) return;
    setState(() => _isCollapsed = collapsed);

    _isAdjustingScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        _isAdjustingScroll = false;
        return;
      }
      if (collapsed) {
        final target = (_scrollController.offset + _headerDiff)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
      } else {
        _scrollController.jumpTo(0);
      }
      Future.delayed(const Duration(milliseconds: 50), () {
        _isAdjustingScroll = false;
      });
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isAdjustingScroll) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final atTop = notification.metrics.pixels <= 0;

      if (atTop && delta > _scrollCollapseThreshold && !_isCollapsed) {
        _setCollapsed(true);
      } else if (atTop && delta < -_scrollCollapseThreshold && _isCollapsed) {
        _setCollapsed(false);
      }
    }

    return false;
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    if (_isAdjustingScroll) return;

    if (event.scrollDelta.dy > 0 && !_isCollapsed) {
      _setCollapsed(true);
    } else if (event.scrollDelta.dy < 0 && _isCollapsed) {
      _setCollapsed(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handlePointerScroll(event);
        }
      },
      onPointerDown: (event) => _touchStartY = event.position.dy,
      onPointerMove: (event) {
        if (_isAdjustingScroll) return;
        final deltaY = _touchStartY - event.position.dy;
        final atTop =
            !_scrollController.hasClients || _scrollController.offset <= 0;
        if (deltaY > _scrollCollapseThreshold && atTop && !_isCollapsed) {
          _setCollapsed(true);
        } else if (deltaY < -_scrollCollapseThreshold && atTop && _isCollapsed) {
          _setCollapsed(false);
        }
      },
      child: SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.tailwind3xl),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.tailwind3xl),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.lessonAsideBottomPadding,
              ),
              child: Column(
                children: [
                  _AsideHeader(
                    unitTitle: widget.unitTitle,
                    score: _trophyScore,
                    isCollapsed: _isCollapsed,
                    showCircle: _showWobblyCircle,
                    wobblyKey: _wobblyKey,
                  ),
                  const SizedBox(height: AppSpacing.lessonAsideInnerGap),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: widget.lessons.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpacing.base),
                        itemBuilder: (context, index) {
                          final lesson = widget.lessons[index];
                          return _LessonAsideItem(
                            courseId: widget.courseId,
                            unitId: widget.unitId,
                            lesson: lesson,
                            isActive: lesson.id == widget.currentLessonId,
                            showProgressRing: widget.showStudentProgress,
                            liveProgressPercent:
                                lesson.id == widget.currentLessonId
                                    ? widget.liveProgressPercent
                                    : null,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AsideHeader extends StatelessWidget {
  const _AsideHeader({
    required this.unitTitle,
    required this.score,
    required this.isCollapsed,
    required this.showCircle,
    required this.wobblyKey,
  });

  final String unitTitle;
  final int score;
  final bool isCollapsed;
  final bool showCircle;
  final Key wobblyKey;

  @override
  Widget build(BuildContext context) {
    final circleSize = isCollapsed
        ? AppSpacing.wobblyCircleSizeCollapsed
        : AppSpacing.wobblyCircleSize;
    final headerHeight = isCollapsed
        ? AppSpacing.lessonAsideHeaderCollapsed
        : showCircle
            ? AppSpacing.lessonAsideHeaderExpanded
            : AppSpacing.lessonAsideHeaderCompact;

    return AnimatedContainer(
      duration: _LessonVideosAsideState._headerAnimation,
      curve: Curves.easeInOut,
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.lessonAsideHeader,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: isCollapsed
            ? _CollapsedHeaderContent(
                unitTitle: unitTitle,
                score: score,
                circleSize: circleSize,
                showCircle: showCircle,
                wobblyKey: wobblyKey,
              )
            : _ExpandedHeaderContent(
                unitTitle: unitTitle,
                score: score,
                circleSize: circleSize,
                showCircle: showCircle,
                wobblyKey: wobblyKey,
              ),
      ),
    );
  }
}

class _ExpandedHeaderContent extends StatelessWidget {
  const _ExpandedHeaderContent({
    required this.unitTitle,
    required this.score,
    required this.circleSize,
    required this.showCircle,
    required this.wobblyKey,
  });

  final String unitTitle;
  final int score;
  final double circleSize;
  final bool showCircle;
  final Key wobblyKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showCircle)
          AnimatedSize(
            duration: _LessonVideosAsideState._headerAnimation,
            curve: Curves.easeInOut,
            child: WobblyCircle(
              key: wobblyKey,
              score: score,
              size: circleSize,
              staticWobble: true,
            ),
          ),
        Text(
          unitTitle,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headingCourseLg.copyWith(
            fontSize: 24,
            fontWeight: AppFonts.bold,
            color: AppColors.onDark,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CollapsedHeaderContent extends StatelessWidget {
  const _CollapsedHeaderContent({
    required this.unitTitle,
    required this.score,
    required this.circleSize,
    required this.showCircle,
    required this.wobblyKey,
  });

  final String unitTitle;
  final int score;
  final double circleSize;
  final bool showCircle;
  final Key wobblyKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showCircle)
          AnimatedSize(
            duration: _LessonVideosAsideState._headerAnimation,
            curve: Curves.easeInOut,
            child: WobblyCircle(
              key: wobblyKey,
              score: score,
              size: circleSize,
              staticWobble: true,
            ),
          ),
        Expanded(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              unitTitle,
              textAlign: TextAlign.start,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headingCourseLg.copyWith(
                fontSize: 24,
                fontWeight: AppFonts.bold,
                color: AppColors.onDark,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonAsideItem extends StatelessWidget {
  const _LessonAsideItem({
    required this.courseId,
    required this.unitId,
    required this.lesson,
    required this.isActive,
    required this.showProgressRing,
    this.liveProgressPercent,
  });

  final String courseId;
  final String unitId;
  final CourseLesson lesson;
  final bool isActive;
  final bool showProgressRing;
  final int? liveProgressPercent;

  @override
  Widget build(BuildContext context) {
    if (lesson.isChallenge) {
      return _QuizAsideItem(
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isActive ? AppColors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
      ),
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
      child: InkWell(
        onTap: isActive
            ? null
            : () => context.go(
                  LessonDetailPage.pathFor(
                    courseId: courseId,
                    unitId: unitId,
                    lessonId: lesson.id,
                  ),
                ),
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        hoverColor: AppColors.selectionHover,
        child: SizedBox(
          height: AppSpacing.lessonListItemHeight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _LessonPlayBadge(
                  lesson: lesson,
                  showProgressRing: showProgressRing,
                  liveProgressPercent: liveProgressPercent,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: AppFonts.semibold,
                          color: AppColors.onDark,
                        ),
                      ),
                      if (lesson.duration != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          lesson.duration!,
                          textDirection: TextDirection.rtl,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.lessonDurationMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Keep trophy in-flow so title/duration never paint over it.
                if (lesson.hasTrophy && showProgressRing) ...[
                  const SizedBox(width: AppSpacing.sm),
                  LessonActionIcons.svg(
                    LessonActionIcons.trophy,
                    size: 24,
                    color: AppColors.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _LessonPlayBadge extends StatelessWidget {
  const _LessonPlayBadge({
    required this.lesson,
    required this.showProgressRing,
    this.liveProgressPercent,
  });

  final CourseLesson lesson;
  final bool showProgressRing;
  final int? liveProgressPercent;

  @override
  Widget build(BuildContext context) {
    const outer = 48.0;
    const radius = 17.0;
    const circumference = 2 * 3.141592653589793 * radius;
    final percent = liveProgressPercent ?? lesson.progressPercent;
    final progress = showProgressRing ? (percent / 100).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progress > 0)
            CustomPaint(
              size: const Size(outer, outer),
              painter: _RingPainter(
                progress: progress,
                circumference: circumference,
                radius: radius,
              ),
            ),
          Container(
            width: outer,
            height: outer,
            decoration: const BoxDecoration(
              color: AppTheme.courseModuleSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: lesson.hasTrophy
                ? LessonActionIcons.svg(
                    LessonActionIcons.checkmark,
                    size: 35,
                    color: AppColors.blue,
                  )
                : LessonActionIcons.svg(
                    LessonActionIcons.play,
                    size: 24,
                    color: AppColors.lessonPlayIconMuted,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.circumference,
    required this.radius,
  });

  final double progress;
  final double circumference;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final sweep = circumference * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweep / radius,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _QuizAsideItem extends StatefulWidget {
  const _QuizAsideItem({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_QuizAsideItem> createState() => _QuizAsideItemState();
}

class _QuizAsideItemState extends State<_QuizAsideItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.tailwind3xl);
    final gradientEnd = _hovered
        ? AppColors.quizCardGradientEndHover
        : AppColors.secondaryBg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashColor: AppColors.blue.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: _hovered
                  ? Border.all(color: AppColors.blue, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.tailwind3xl - 2),
              child: SizedBox(
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CssLessonActionGradientLayer(
                      accent: AppColors.blue,
                      background: gradientEnd,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'مستعد للأختبار ؟',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodyLg.copyWith(
                                      fontWeight: AppFonts.extrabold,
                                      color: AppColors.onDark,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    'كمل التحدي عشان ترفع مستواك',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.tabInactive,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            LessonActionIcons.svg(
                              LessonActionIcons.dumbbell,
                              size: 70,
                              color: const Color.fromRGBO(255, 255, 255, 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
