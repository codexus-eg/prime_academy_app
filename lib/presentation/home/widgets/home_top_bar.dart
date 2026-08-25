import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_border.dart';
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
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.breakpointSm;

    // Web MobileNav sits outside <main dir="rtl">, so it lays out LTR:
    // [menu | bell | الكويت] ........ [logo]
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.mobileNavTopPadding,
        AppSpacing.pageContentHorizontal,
        AppSpacing.mobileNavBottomPadding,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuButton(onTap: onMenuTap),
                SizedBox(width: AppSpacing.mobileNavItemGap),
                const NotificationDropdown(),
                SizedBox(width: AppSpacing.mobileNavItemGap),
                _CountryChip(onTap: onCountryTap),
              ],
            ),
            Image.asset(
              'assets/images/logo_prime.webp',
              width: isMobile
                  ? AppSpacing.mobileNavLogoWidth
                  : AppSpacing.mobileNavLogoWidth * 1.25,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderSm,
        child: SizedBox(
          width: AppSpacing.xxxl,
          height: AppSpacing.xxxl,
          child: Center(
            child: Icon(
              Icons.menu_rounded,
              size: AppSpacing.mobileNavMenuIconSize,
              color: AppColors.onDark,
            ),
          ),
        ),
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
        borderRadius: AppRadius.borderTailwindXl,
        child: GradientBorder(
          borderRadius: AppRadius.borderTailwindXl,
          backgroundColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/Flag_of_Kuwait.svg',
                width: AppSpacing.mobileNavFlagSize,
                height: AppSpacing.mobileNavFlagSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الكويت',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onDark,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
