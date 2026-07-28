import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'ranking_inline_icons.dart';

class RankingStudentCountHeader extends StatelessWidget {
  const RankingStudentCountHeader({
    super.key,
    required this.studentCount,
    this.isLoading = false,
  });

  final int studentCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(height: 40);
    }

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.reportIconBox,
            borderRadius: AppRadius.borderTailwindXl,
            border: Border.all(color: AppColors.rankBlueGlow20),
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: RankingMedalIcon(size: AppSpacing.lg),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Row(
          children: [
            const RankingUsersIcon(),
            const SizedBox(width: AppSpacing.xsPlus),
            Text(
              '$studentCount طالب',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
