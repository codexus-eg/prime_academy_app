import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'report_icons.dart';

class ReportsSectionHeader extends StatelessWidget {
  const ReportsSectionHeader({
    super.key,
    required this.reportCount,
  });

  final int reportCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.reportHeaderIconBox,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.tailwind2xl),
                  ),
                  border: Border.all(color: AppColors.rankBlueGlow20),
                  boxShadow: AppShadows.reportHeaderIcon,
                ),
                child: const SizedBox(
                  width: AppSpacing.reportIconBox,
                  height: AppSpacing.reportIconBox,
                  child: Center(
                    child: ReportAwardIcon(size: AppSpacing.xl),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقارير الاختبارات',
                      style: AppTypography.size20.copyWith(
                        color: AppColors.onDark,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ReportClockIcon(),
                        const SizedBox(width: AppSpacing.xsPlus),
                        Text(
                          '$reportCount تقرير',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
