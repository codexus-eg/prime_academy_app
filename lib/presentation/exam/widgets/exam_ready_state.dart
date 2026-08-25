import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'exam_glass_panel.dart';
import 'exam_graduation_badge.dart';
import 'exam_ready_icons.dart';

class ExamReadyState extends StatefulWidget {
  const ExamReadyState({
    super.key,
    required this.progressPercent,
    required this.isContinue,
    required this.isLastChance,
    required this.onStart,
    required this.onExit,
    this.startDateLabel,
  });

  final int progressPercent;
  final bool isContinue;
  final bool isLastChance;
  final VoidCallback onStart;
  final VoidCallback onExit;
  final String? startDateLabel;

  @override
  State<ExamReadyState> createState() => _ExamReadyStateState();
}

class _ExamReadyStateState extends State<ExamReadyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    // Web QuizReadyState: duration 0.3s, ease [0,0,0.2,1], y: -10
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

  String get _title {
    if (widget.isLastChance) return 'الفرصة الأخيرة';
    if (widget.isContinue) return 'متابعة الاختبار';
    return 'بدء الاختبار';
  }

  String get _subtitle {
    if (widget.isLastChance) return 'أجب عن الأسئلة الخاطئة';
    if (widget.isContinue) return 'أكمل رحلة التحدي';
    return 'جاهز لبدء التحدي ؟';
  }

  String get _startLabel {
    if (widget.isLastChance) return 'بدء';
    if (widget.isContinue) return 'متابعة';
    return 'بدء';
  }

  @override
  Widget build(BuildContext context) {
    final panel = Padding(
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
              child: ExamGlassPanel(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: AppTypography.size36.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.extrabold,
                          height: 1.15,
                          shadows: const [
                            Shadow(
                              color: Color(0x1AFFFFFF),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.tabInactive,
                          fontWeight: AppFonts.medium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ReadyTrackBar(
                        progressPercent: widget.progressPercent,
                      ),
                      if (widget.startDateLabel != null) ...[
                        const SizedBox(height: AppSpacing.base),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ExamClockIcon(),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'تاريخ البدء: ${widget.startDateLabel}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.tabInactive,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              label: 'خروج',
                              onTap: widget.onExit,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: _PrimaryButton(
                              label: _startLabel,
                              onTap: widget.onStart,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        'تأكد من استقرار اتصال الإنترنت قبل بدء الاختبار',
                        textAlign: TextAlign.center,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.gray500.withValues(alpha: 0.8),
                          fontWeight: AppFonts.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              child: ExamGraduationBadge(),
            ),
          ],
        ),
      ),
    );

    // Opacity/Transform layers break BackdropFilter — unwrap after enter.
    return AnimatedBuilder(
      animation: _enterController,
      child: panel,
      builder: (context, child) {
        if (_enterController.isCompleted) return child!;
        final t = Curves.easeOut.transform(_enterController.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class _ReadyTrackBar extends StatelessWidget {
  const _ReadyTrackBar({required this.progressPercent});

  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final clamped = progressPercent.clamp(0, 100) / 100.0;
    return Row(
      children: [
        const ExamCheckeredFlagIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
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
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped.clamp(0.0, 1.0),
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
          ),
        ),
        const SizedBox(width: 12),
        const ExamRunningIcon(),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: AppRadius.borderMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ExamPlayFillIcon(),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppFonts.bold,
                ),
              ),
            ],
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
          decoration: BoxDecoration(
            color: AppColors.overlayWhite5,
            borderRadius: AppRadius.borderMd,
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
              const ExamBoxArrowRightIcon(),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.semibold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
