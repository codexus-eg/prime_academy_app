import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/report_attempt.dart';
import 'report_icons.dart';

String formatReportGrade(double grade) {
  final safe = grade.isNaN ? 0.0 : grade.clamp(0, 100);
  if (safe == safe.roundToDouble()) {
    return '${safe.round()}%';
  }
  final text = safe.toStringAsFixed(2);
  return '${text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}%';
}

class ReportSummaryCard extends StatefulWidget {
  const ReportSummaryCard({
    super.key,
    required this.attempt,
    required this.isFirst,
    this.onStudentReportTap,
  });

  final ReportAttempt attempt;
  final bool isFirst;
  final VoidCallback? onStudentReportTap;

  @override
  State<ReportSummaryCard> createState() => _ReportSummaryCardState();
}

class _ReportSummaryCardState extends State<ReportSummaryCard>
    with SingleTickerProviderStateMixin {
  var _buttonHovered = false;
  late final AnimationController _ribbonController;

  _ReportGradeCategory get _category {
    final grade = widget.attempt.grade;
    if (grade >= 100) return _ReportGradeCategory.excellent;
    if (grade >= 80) return _ReportGradeCategory.good;
    return _ReportGradeCategory.poor;
  }

  @override
  void initState() {
    super.initState();
    _ribbonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isFirst) {
      _ribbonController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ReportSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFirst && !_ribbonController.isAnimating) {
      _ribbonController.repeat();
    } else if (!widget.isFirst && _ribbonController.isAnimating) {
      _ribbonController.stop();
      _ribbonController.value = 0;
    }
  }

  @override
  void dispose() {
    _ribbonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    final style = _ReportGradeStyle.forCategory(category);
    final moduleName = widget.attempt.moduleName.trim();
    final quizName = widget.attempt.quizName.trim();
    final showModuleSubtitle =
        quizName.isNotEmpty && quizName != moduleName;
    final title = quizName.isNotEmpty ? quizName : moduleName;

    return Material(
      color: AppColors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: AppRadius.borderRankingCard,
          border: Border.all(color: AppColors.overlayWhite3),
          boxShadow: AppShadows.lg,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: AppRadius.borderRankingCard,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue.withValues(alpha: 0.8),
                            AppColors.blueLight.withValues(alpha: 0.8),
                            AppColors.blue.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: const SizedBox(height: 4),
                    ),
                  ),
                  if (widget.isFirst)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.reportCardOverlay,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.massive,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppGradients.reportIconBox,
                                borderRadius: AppRadius.borderTailwindXl,
                                boxShadow: AppShadows.reportHeaderIcon,
                              ),
                              child: SizedBox(
                                width: AppSpacing.reportIconBox,
                                height: AppSpacing.reportIconBox,
                                child: const Center(
                                  child: ReportExamFillIcon(),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showModuleSubtitle) ...[
                                    Text(
                                      moduleName,
                                      style: AppTypography.custom(
                                        fontSize: 12,
                                        fontWeight: AppFonts.regular,
                                        height: 1.33,
                                        color: AppColors.textMuted.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xsPlus),
                                  ],
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.onDark,
                                      fontWeight: AppFonts.semibold,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(
                          color: AppColors.overlayWhite4,
                          height: 1,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AccuracySection(
                          grade: widget.attempt.grade,
                          color: style.gradeColor,
                          category: category,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _GradePercentTile(
                                  grade: widget.attempt.grade,
                                  style: style,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _TrophyTile(
                                  label: style.label,
                                  style: style,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        MouseRegion(
                          onEnter: (_) => setState(() => _buttonHovered = true),
                          onExit: (_) => setState(() => _buttonHovered = false),
                          child: Material(
                            color: AppColors.transparent,
                            child: InkWell(
                              onTap: widget.onStudentReportTap,
                              borderRadius: AppRadius.borderTailwindXl,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.base,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _buttonHovered
                                      ? AppGradients.reportCtaHover
                                      : AppGradients.reportCta,
                                  borderRadius: AppRadius.borderTailwindXl,
                                  border: Border.all(
                                    color: _buttonHovered
                                        ? AppColors.rankBlueBorder30
                                        : AppColors.rankBlueGlow20,
                                    width: 2,
                                  ),
                                  boxShadow: _buttonHovered
                                      ? AppShadows.xl
                                      : AppShadows.reportHeaderIcon,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'تقرير الطالب',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onDark,
                                        fontWeight: AppFonts.medium,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    AnimatedSlide(
                                      duration: const Duration(milliseconds: 200),
                                      offset: _buttonHovered
                                          ? const Offset(-0.08, 0)
                                          : Offset.zero,
                                      child: ReportChevronLeftIcon(
                                        color: _buttonHovered
                                            ? AppColors.blueLight
                                            : AppColors.accentSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isFirst)
              Positioned(
                top: AppSpacing.base,
                right: AppSpacing.base,
                child: AnimatedBuilder(
                  animation: _ribbonController,
                  builder: (context, child) {
                    final t = _ribbonController.value;
                    final angle = math.sin(t * math.pi * 2) * 5 * math.pi / 180;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: const ReportRibbonIcon(),
                ),
              ),
            Positioned(
              top: AppSpacing.base,
              left: AppSpacing.base,
              child: _StatusBadge(isLatest: widget.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportGradeCategory { excellent, good, poor }

class _ReportGradeStyle {
  const _ReportGradeStyle({
    required this.label,
    required this.gradeColor,
    required this.gradeGradient,
    required this.trophyColor,
    required this.trophyBackground,
    required this.trophyGlow,
  });

  final String label;
  final Color gradeColor;
  final LinearGradient gradeGradient;
  final Color trophyColor;
  final Color trophyBackground;
  final Color trophyGlow;

  static LinearGradient accuracyBar(_ReportGradeCategory category) {
    const begin = Alignment.centerLeft;
    const end = Alignment.centerRight;
    return switch (category) {
      _ReportGradeCategory.excellent => const LinearGradient(
            begin: begin,
            end: end,
            colors: [AppColors.reportEmerald400, AppColors.reportEmerald500],
          ),
      _ReportGradeCategory.good => const LinearGradient(
            begin: begin,
            end: end,
            colors: [AppColors.reportSky400, AppColors.reportSky500],
          ),
      _ReportGradeCategory.poor => const LinearGradient(
            begin: begin,
            end: end,
            colors: [AppColors.reportOrange400, AppColors.reportOrange500],
          ),
    };
  }

  static _ReportGradeStyle forCategory(_ReportGradeCategory category) {
    return switch (category) {
      _ReportGradeCategory.excellent => _ReportGradeStyle(
          label: 'طالب مثالي',
          gradeColor: AppColors.reportEmerald400,
          gradeGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.reportEmerald500_10,
              AppColors.reportEmerald600_5,
            ],
          ),
          trophyColor: AppColors.reportAmber400,
          trophyBackground: AppColors.reportAmber400_10,
          trophyGlow: AppColors.reportAmber400Glow40,
        ),
      _ReportGradeCategory.good => _ReportGradeStyle(
          label: 'طالب شبه مثالي',
          gradeColor: AppColors.reportSky400,
          gradeGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.reportSky500_10, AppColors.reportSky600_5],
          ),
          trophyColor: AppColors.reportSlate300,
          trophyBackground: AppColors.reportSlate300_10,
          trophyGlow: AppColors.reportSlate300Glow30,
        ),
      _ReportGradeCategory.poor => _ReportGradeStyle(
          label: 'طالب ضعيف',
          gradeColor: AppColors.reportOrange400,
          gradeGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.reportOrange500_10,
              AppColors.reportOrange600_5,
            ],
          ),
          trophyColor: AppColors.reportAmber600,
          trophyBackground: AppColors.reportAmber700_10,
          trophyGlow: AppColors.reportAmber700Glow30,
        ),
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isLatest});

  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.shadcnLg);
    final textColor = isLatest
        ? AppColors.accentSoft
        : AppColors.textMuted.withValues(alpha: 0.6);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isLatest
            ? AppShadows.reportLatestBadge
            : AppShadows.tailwindLgBlack,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isLatest ? AppColors.accentBg20 : AppColors.overlayWhite5,
              borderRadius: radius,
              border: Border.all(
                width: 1,
                color: isLatest ? AppColors.accentBg40 : AppColors.overlayWhite6,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.reportStatusBadgePaddingX,
                vertical: AppSpacing.reportStatusBadgePaddingY,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: AppSpacing.reportStatusBadgeDot,
                      height: AppSpacing.reportStatusBadgeDot,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.reportStatusBadgeGap),
                    Text(
                      isLatest ? 'آخر اختبار' : 'قديم',
                      style: AppTypography.reportStatusBadge.copyWith(
                        color: textColor,
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

class _AccuracySection extends StatelessWidget {
  const _AccuracySection({
    required this.grade,
    required this.color,
    required this.category,
  });

  final double grade;
  final Color color;
  final _ReportGradeCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الدقة',
              style: AppTypography.bodySm.copyWith(
                height: 1.2,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            Text(
              formatReportGrade(grade),
              style: AppTypography.bodyMd.copyWith(
                color: color,
                fontWeight: AppFonts.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xsPlus),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillWidth = constraints.maxWidth *
                    (grade.clamp(0, 100) / 100);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: AppColors.reportWhite5),
                    ),
                    if (fillWidth > 0)
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        width: fillWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _ReportGradeStyle.accuracyBar(category),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GradePercentTile extends StatelessWidget {
  const _GradePercentTile({
    required this.grade,
    required this.style,
  });

  final double grade;
  final _ReportGradeStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: style.gradeGradient,
        borderRadius: AppRadius.borderTailwindXl,
        border: Border.all(color: Colors.transparent),
        boxShadow: AppShadows.tailwindLgBlack,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            ReportGradeIcon(color: style.gradeColor),
            const SizedBox(height: AppSpacing.xsPlus),
            Text(
              formatReportGrade(grade),
              textAlign: TextAlign.center,
              style: AppTypography.size24.copyWith(
                color: style.gradeColor,
                fontWeight: AppFonts.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({
    required this.label,
    required this.style,
  });

  final String label;
  final _ReportGradeStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.trophyBackground,
        borderRadius: AppRadius.borderTailwindXl,
        border: Border.all(color: Colors.transparent),
        boxShadow: AppShadows.tailwindLgBlack,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: style.trophyGlow,
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ReportTrophyFillIcon(color: style.trophyColor),
            ),
            const SizedBox(height: AppSpacing.xsPlus),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: style.trophyColor,
                fontWeight: AppFonts.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
