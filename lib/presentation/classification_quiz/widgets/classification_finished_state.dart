import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../models/classification_level.dart';
import 'classification_char_glow.dart';

class ClassificationFinishedState extends StatelessWidget {
  const ClassificationFinishedState({
    super.key,
    required this.currentLevel,
    required this.onExit,
  });

  final ClassificationLevel currentLevel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final characterAsset =
        ClassificationAssets.characterImages[currentLevel.imageIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.mainBg,
        child: Padding(
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
                  color: AppColors.accentBg.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.accentBg.withValues(alpha: 0.8),
                  ),
                ),
                child: Text(
                  'تصنيفك: ${currentLevel.title}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.accentIconMuted400,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ClassificationCharGlow(imageAsset: characterAsset),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'اكتملت المهمة',
                textAlign: TextAlign.center,
                style: AppTypography.size24.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: onExit,
                  borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.onDark,
                          size: 15,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'العودة للدرس',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onDark,
                            fontWeight: AppFonts.semibold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
