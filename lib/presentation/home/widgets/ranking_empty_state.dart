import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'ranking_inline_icons.dart';

class RankingEmptyState extends StatelessWidget {
  const RankingEmptyState({
    super.key,
    required this.message,
    this.onClearSearch,
  });

  final String message;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.reportEmptyIconShell,
              borderRadius: BorderRadius.all(
                Radius.circular(AppRadius.tailwind2xl),
              ),
              border: Border.all(color: AppColors.rankBlueGlow20),
            ),
            child: SizedBox(
              width: AppSpacing.massive,
              height: AppSpacing.massive,
              child: Center(
                child: RankingMedalIcon(
                  size: AppSpacing.xxl,
                  color: AppColors.blueLight.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              fontSize: 18,
              fontWeight: AppFonts.medium,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          if (onClearSearch != null) ...[
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: onClearSearch,
              child: Text(
                'مسح البحث',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.blueLight,
                  fontWeight: AppFonts.medium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
