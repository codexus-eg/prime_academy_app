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
    this.showLogo = true,
    this.showNotifications = false,
    this.onMenuTap,
    this.onLogoTap,
    this.onCountryTap,
  });

  /// Shows the brand logo on the far right (matches web `MobileNav`).
  final bool showLogo;

  /// Shows the notification bell between menu and country chip (authenticated users).
  final bool showNotifications;

  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoTap;
  final VoidCallback? onCountryTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.breakpointSm;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageContentHorizontal,
        AppSpacing.mobileNavTopPadding,
        AppSpacing.pageContentHorizontal,
        AppSpacing.mobileNavBottomPadding,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: _NavRow(
          isMobile: isMobile,
          showLogo: showLogo,
          showNotifications: showNotifications,
          onMenuTap: onMenuTap,
          onLogoTap: onLogoTap,
          onCountryTap: onCountryTap,
        ),
      ),
    );
  }
}

/// Web `MobileNav` (dir=ltr): [menu] · [bell?] · [الكويت] … [logo — far right]
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.isMobile,
    required this.showLogo,
    required this.showNotifications,
    this.onMenuTap,
    this.onLogoTap,
    this.onCountryTap,
  });

  final bool isMobile;
  final bool showLogo;
  final bool showNotifications;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoTap;
  final VoidCallback? onCountryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(onTap: onMenuTap),
              SizedBox(width: AppSpacing.mobileNavItemGap),
              if (showNotifications) ...[
                const NotificationDropdown(),
                SizedBox(width: AppSpacing.mobileNavItemGap),
              ],
              IgnorePointer(
                ignoring: onCountryTap == null,
                child: _CountryChip(onTap: onCountryTap),
              ),
            ],
          ),
          if (showLogo)
            _NavLogo(isMobile: isMobile, onTap: onLogoTap),
        ],
      ),
    );
  }
}

/// Web `MobileNav` → `footer-logo.webp` (`w-30 sm:w-50 h-auto shrink-0`).
class _NavLogo extends StatelessWidget {
  const _NavLogo({required this.isMobile, this.onTap});

  final bool isMobile;
  final VoidCallback? onTap;

  static const String _webp = 'assets/images/logo_prime.webp';
  static const String _png = 'assets/images/logo_prime.png';

  static Size logoSize({required bool isMobile}) {
    final width = isMobile
        ? AppSpacing.mobileNavLogoWidth
        : AppSpacing.mobileNavLogoWidth * 1.25;
    // footer-logo.webp is 752×250.
    return Size(width, width * (250 / 752));
  }

  @override
  Widget build(BuildContext context) {
    final size = logoSize(isMobile: isMobile);

    final logo = Image.asset(
      _webp,
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        _png,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: onTap == null
          ? logo
          : Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.borderSm,
                child: logo,
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
