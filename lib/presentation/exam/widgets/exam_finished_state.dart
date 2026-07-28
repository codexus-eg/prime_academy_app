import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'exam_graduation_badge.dart';

class ExamFinishedState extends StatelessWidget {
  const ExamFinishedState({
    super.key,
    required this.correctCount,
    required this.inCorrectCount,
    required this.earnedPoints,
    required this.totalPoints,
    required this.hasLastChance,
    required this.onExit,
    required this.onRestart,
    this.onLastChance,
    this.isActivatingLastChance = false,
    this.errorMessage,
    this.onReview,
  });

  final int correctCount;
  final int inCorrectCount;
  final int earnedPoints;
  final int totalPoints;
  final bool hasLastChance;
  final VoidCallback onExit;
  final VoidCallback onRestart;
  final Future<void> Function()? onLastChance;
  final bool isActivatingLastChance;
  final String? errorMessage;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final totalQuestions = correctCount + inCorrectCount;
    final accuracy =
        totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageContentHorizontal,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 56, 40, 40),
                decoration: BoxDecoration(
                  color: AppColors.examPanelBg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.examPanelBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26007BFF),
                      blurRadius: 80,
                      spreadRadius: -20,
                    ),
                  ],
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'انتهى الاختبار',
                        style: AppTypography.size36.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.extrabold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'الإجابات الخطأ',
                              value: '$inCorrectCount',
                              icon: Icons.cancel_rounded,
                              color: const Color(0xFFF87171),
                              background: const Color(0xFF1A0D12),
                              border: const Color(0x4DEF4444),
                              glow: const Color(0x26F87171),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: _StatCard(
                              label: 'الإجابات الصحيحة',
                              value: '$correctCount',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF4ADE80),
                              background: const Color(0xFF0A1A12),
                              border: const Color(0x4D22C55E),
                              glow: const Color(0x264ADE80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'النقاط',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.tabInactive,
                            ),
                          ),
                          Text(
                            '$earnedPoints / $totalPoints',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onDark,
                              fontWeight: AppFonts.semibold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: SizedBox(
                          height: 24,
                          child: Stack(
                            children: [
                              const ColoredBox(
                                color: AppColors.examTrackNavy,
                                child: SizedBox.expand(),
                              ),
                              FractionallySizedBox(
                                widthFactor: (accuracy / 100).clamp(0.0, 1.0),
                                child: const ColoredBox(
                                  color: AppColors.examAccentBlue,
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _SecondaryButton(
                        label: 'مراجعة الإجابات',
                        onTap: onReview ?? () {},
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            color: const Color(0xFFF87171),
                            fontWeight: AppFonts.semibold,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              label: 'خروج',
                              onTap: onExit,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: _PrimaryButton(
                              label: hasLastChance ? 'الفرصة الأخيرة' : 'إعادة الاختبار',
                              loading: isActivatingLastChance,
                              onTap: hasLastChance
                                  ? () => onLastChance?.call()
                                  : onRestart,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(top: 0, child: ExamGraduationBadge()),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.glow,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: glow, blurRadius: 15)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.badge.copyWith(color: AppColors.tabInactive),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.size28.copyWith(
              color: color,
              fontWeight: AppFonts.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: AppRadius.borderMd,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppFonts.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.overlayWhite5,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.overlayWhite10),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onDark,
                fontWeight: AppFonts.semibold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
