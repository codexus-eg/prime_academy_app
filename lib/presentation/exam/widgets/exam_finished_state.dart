import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'exam_glass_panel.dart';
import 'exam_graduation_badge.dart';
import 'exam_ready_icons.dart';

/// Matches web `QuizFinalState.tsx` pixel-for-pixel where possible.
class ExamFinishedState extends StatefulWidget {
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
  State<ExamFinishedState> createState() => _ExamFinishedStateState();
}

class _ExamFinishedStateState extends State<ExamFinishedState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    // Web QuizFinalState: duration 0.3s (0.15s mobile), ease [0,0,0.2,1]
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 768;
    final totalQuestions = widget.correctCount + widget.inCorrectCount;
    final accuracy =
        totalQuestions > 0 ? (widget.correctCount / totalQuestions) * 100 : 0.0;

    // Web Card: py-6 + CardHeader pt-12 → ~72 top; CardContent px-10 pb-10.
    final panel = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageContentHorizontal,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Badge sits at -top-8 (-32) relative to card; pad card down by 32.
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ExamGlassPanel(
                padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // CardTitle: text-4xl font-extrabold + drop-shadow
                      Text(
                        'انتهى الاختبار',
                        textAlign: TextAlign.center,
                        style: AppTypography.size36.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.extrabold,
                          height: 1.1,
                          shadows: const [
                            Shadow(
                              color: Color(0x1AFFFFFF),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8), // CardHeader pb-2
                      const SizedBox(height: 24), // Card gap-6 header→content
                      // Stats: flex gap-4
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'الإجابات الخطأ',
                                value: '${widget.inCorrectCount}',
                                icon: const ExamXCircleFillIcon(),
                                color: const Color(0xFFF87171), // red-400
                                background: const Color(0xFF1A0D12),
                                border: const Color(0x4DEF4444), // red-500/30
                                glow: const Color(0x26F87171),
                              ),
                            ),
                            const SizedBox(width: 16), // gap-4
                            Expanded(
                              child: _StatCard(
                                label: 'الإجابات الصحيحة',
                                value: '${widget.correctCount}',
                                icon: const ExamCheckCircleFillIcon(),
                                color: const Color(0xFF4ADE80), // green-400
                                background: const Color(0xFF0A1A12),
                                border: const Color(0x4D22C55E), // green-500/30
                                glow: const Color(0x264ADE80),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // CardContent gap-8 + progress mt-2
                      const SizedBox(height: 40),
                      // Points row: text-sm text-gray-400, score white semibold
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'النقاط',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.tabInactive, // gray-400
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${widget.earnedPoints} / ${widget.totalPoints}',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onDark,
                                fontWeight: AppFonts.semibold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8), // space-y-2
                      _AccuracyProgressBar(value: accuracy),
                      const SizedBox(height: 32), // gap-8
                      _ReviewButton(onTap: widget.onReview ?? () {}),
                      if (widget.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Transform.translate(
                          offset: const Offset(0, -16), // -mt-4
                          child: Text(
                            widget.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(
                              color: const Color(0xFFF87171),
                              fontWeight: AppFonts.semibold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40), // gap-8 + actions mt-2
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryActionButton(
                              label: 'خروج',
                              icon: const ExamBoxArrowRightIcon(size: 20),
                              onTap: widget.onExit,
                            ),
                          ),
                          const SizedBox(width: 16), // gap-4
                          Expanded(
                            child: _PrimaryActionButton(
                              label: widget.hasLastChance
                                  ? 'الفرصة الأخيرة'
                                  : 'إعادة الاختبار',
                              showPlayIcon: !widget.hasLastChance,
                              loading: widget.isActivatingLastChance,
                              onTap: widget.hasLastChance
                                  ? () => widget.onLastChance?.call()
                                  : widget.onRestart,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Web: absolute -top-8 → badge top aligns with stack top (card at +32).
            const Positioned(
              top: 0,
              child: ExamGraduationBadge(),
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _enterController,
      child: panel,
      builder: (context, child) {
        if (_enterController.isCompleted) return child!;
        final t = Curves.easeOut.transform(_enterController.value);
        return Opacity(
          opacity: t,
          child: mobile
              ? child
              : Transform.translate(
                  offset: Offset(0, -10 * (1 - t)),
                  child: child,
                ),
        );
      },
    );
  }
}

/// Web Progress: h-6, track `#1a2342`, border `#007bff/10`, fill `#007bff` + glow.
class _AccuracyProgressBar extends StatelessWidget {
  const _AccuracyProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = (value / 100).clamp(0.0, 1.0);
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.examTrackNavy,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.examAccentBlue.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        // Radix Progress grows from the physical left edge.
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped,
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.examAccentBlue,
              boxShadow: [
                BoxShadow(
                  color: AppColors.examAccentBlue.withValues(alpha: 0.8),
                  blurRadius: 15,
                ),
                BoxShadow(
                  color: AppColors.examAccentBlue.withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const SizedBox.expand(),
          ),
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
  final Widget icon;
  final Color color;
  final Color background;
  final Color border;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl), // rounded-xl
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: glow, blurRadius: 15)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 8), // mb-2
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppTypography.badge.copyWith(
                color: AppColors.tabInactive, // text-xs text-gray-400
                fontWeight: AppFonts.regular,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4), // mb-1
          Text(
            value,
            style: AppTypography.custom(
              fontSize: 30, // text-3xl
              fontWeight: AppFonts.bold,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        child: Ink(
          width: double.infinity,
          // Web: py-6 → ~24 vertical padding + text ≈ 56–64h
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.overlayWhite5,
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
            border: Border.all(color: AppColors.overlayWhite10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'مراجعة الإجابات',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onDark,
              fontWeight: AppFonts.semibold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.showPlayIcon = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showPlayIcon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        child: Ink(
          height: 56, // h-14
          decoration: BoxDecoration(
            color: AppColors.blue, // bg-accent-bg
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
            boxShadow: [
              BoxShadow(
                color: const Color(0x332072E0), // shadow accent 0.2
                blurRadius: 20,
              ),
            ],
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPlayIcon) ...[
                        const ExamPlayFillIcon(size: 24),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.primary, // text-primary
                          fontWeight: AppFonts.bold,
                          fontSize: 18, // text-lg
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.overlayWhite5,
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
            border: Border.all(color: AppColors.overlayWhite10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.semibold,
                  fontSize: 18, // text-lg
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
