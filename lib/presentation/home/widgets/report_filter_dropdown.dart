import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ReportFilterDropdown extends StatelessWidget {
  const ReportFilterDropdown({
    super.key,
    required this.label,
    this.onTap,
    this.width,
    this.showFilterIcon = false,
  });

  final String label;
  final void Function(BuildContext triggerContext)? onTap;
  final double? width;
  final bool showFilterIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: AppSpacing.profileFilterHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: AppRadius.borderTailwindXl,
          border: Border.all(color: AppColors.overlayWhite6),
          boxShadow: AppShadows.lg,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(context),
            borderRadius: AppRadius.borderTailwindXl,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.base,
              ),
              child: Row(
                children: [
                  if (showFilterIcon) ...[
                    Icon(
                      Icons.filter_list_rounded,
                      size: AppSpacing.base,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.filterLabel.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tabInactive,
                    size: AppSpacing.base,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
