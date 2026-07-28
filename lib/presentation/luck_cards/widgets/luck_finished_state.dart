import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glowing_trophy.dart';
import '../data/luck_assets.dart';

class LuckFinishedState extends StatefulWidget {
  const LuckFinishedState({
    super.key,
    required this.onExit,
    this.totalPointsAwarded,
  });

  final VoidCallback onExit;
  final int? totalPointsAwarded;

  @override
  State<LuckFinishedState> createState() => _LuckFinishedStateState();
}

class _LuckFinishedStateState extends State<LuckFinishedState> {
  var _showCelebration = false;

  @override
  void initState() {
    super.initState();
    if ((widget.totalPointsAwarded ?? 0) > 0) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showCelebration = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.totalPointsAwarded;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_showCelebration)
            IgnorePointer(
              child: Center(
                child: Lottie.asset(
                  LuckAssets.celebrationLottie,
                  repeat: false,
                  width: 280,
                  height: 280,
                  onLoaded: (composition) {
                    Future.delayed(composition.duration, () {
                      if (mounted) setState(() => _showCelebration = false);
                    });
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.blue),
                  ),
                  child: Text(
                    'اكتملت المهمة',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.blue,
                      fontWeight: AppFonts.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const GlowingTrophy(asset: LuckAssets.trophyImage),
                const SizedBox(height: AppSpacing.base),
                if (points != null && points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x26FBBF24),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: const Color(0x66FBBF24)),
                    ),
                    child: Text(
                      'حصلت على $points نقطة',
                      style: AppTypography.bodyLg.copyWith(
                        color: const Color(0xFFFDE68A),
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                  ),
                if (points == 0)
                  Text(
                    'لم تحصل على نقاط هذه المرة',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onDark.withValues(alpha: 0.4),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
                FilledButton.icon(
                  onPressed: widget.onExit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 15),
                  label: Text(
                    'العودة للدرس',
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: AppFonts.semibold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
