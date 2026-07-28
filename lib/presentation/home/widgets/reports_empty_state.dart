import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'report_icons.dart';

class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.reportEmptyPaddingY),
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
              boxShadow: AppShadows.xl,
            ),
            child: SizedBox(
              width: AppSpacing.reportEmptyIconShell,
              height: AppSpacing.reportEmptyIconShell,
              child: const Center(
                child: ReportDocumentTextIcon(
                  size: AppSpacing.xxxl,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              fontSize: 18,
              fontWeight: AppFonts.medium,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.base),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportsErrorState extends StatelessWidget {
  const ReportsErrorState({
    super.key,
    this.message = 'حدث خطأ أثناء تحميل البيانات',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.reportEmptyPaddingY),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.errorGlow10,
              borderRadius: BorderRadius.all(
                Radius.circular(AppRadius.tailwind2xl),
              ),
              border: Border.all(color: AppColors.errorGlow20),
            ),
            child: SizedBox(
              width: AppSpacing.reportEmptyIconShell,
              height: AppSpacing.reportEmptyIconShell,
              child: const Center(
                child: ReportDocumentTextIcon(
                  size: AppSpacing.xl,
                  color: AppColors.errorSoft,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(color: AppColors.errorSoft),
          ),
        ],
      ),
    );
  }
}
