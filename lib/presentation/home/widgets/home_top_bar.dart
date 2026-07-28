import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/custom_button.dart';
import 'notification_dropdown.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    this.onMenuTap,
    this.onCountryTap,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.smPlus,
        AppSpacing.pageContentHorizontal,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_prime.webp',
            width: 120,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          const Spacer(),
          _CountryChip(onTap: onCountryTap),
          const Spacer(),
          const NotificationDropdown(),
          const SizedBox(width: AppSpacing.sm),
          CustomButton.icon(
            onPressed: onMenuTap,
            icon: Icons.menu_rounded,
            height: AppSpacing.iconButtonSize,
            width: AppSpacing.iconButtonSize,
            borderRadius: AppRadius.borderTabBar,
            foregroundColor: AppColors.primary.withValues(alpha: 0.92),
            variant: CustomButtonVariant.text,
          ),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderSm,
        child: Ink(
          decoration: ShapeDecoration(
            color: AppColors.fieldFill,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: AppSpacing.loginCountryBorder,
                color: AppColors.countryBorder,
              ),
              borderRadius: AppRadius.borderSm,
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/flag_kuwait.webp',
                  width: AppSpacing.base,
                  height: AppSpacing.base,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'الكويت',
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: AppFonts.semibold,
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
