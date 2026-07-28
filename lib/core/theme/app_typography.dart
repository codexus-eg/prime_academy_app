import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

abstract final class AppTypography {
  static TextStyle _bahij({
    required double fontSize,
    FontWeight fontWeight = AppFonts.regular,
    Color color = AppColors.primary,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AppFonts.bahij,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = AppFonts.regular,
    Color color = AppColors.primary,
    double? height,
    double? letterSpacing,
  }) =>
      _bahij(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get displayHero =>
      _bahij(fontSize: 48, fontWeight: AppFonts.bold);

  static TextStyle get displayLg =>
      _bahij(fontSize: 36, fontWeight: AppFonts.bold, height: 1.2);

  static TextStyle get displayMd =>
      _bahij(fontSize: 30, fontWeight: AppFonts.bold, height: 1.2);

  static TextStyle get headingCourse =>
      _bahij(fontSize: 16, fontWeight: AppFonts.semibold);

  static TextStyle get headingCourseLg =>
      _bahij(fontSize: 30, fontWeight: AppFonts.bold, height: 1.2);

  static TextStyle get headingDialog =>
      _bahij(fontSize: 18, fontWeight: AppFonts.semibold);

  static TextStyle get headingModuleTitle =>
      _bahij(
        fontSize: 18,
        fontWeight: AppFonts.semibold,
        color: AppColors.onDark,
      );

  static TextStyle get headingModuleDescription =>
      _bahij(
        fontSize: 14,
        fontWeight: AppFonts.regular,
        color: AppColors.onDark,
        height: 1.5,
      );

  static TextStyle get headingProfileName =>
      _bahij(fontSize: 18, fontWeight: AppFonts.semibold);

  static TextStyle get headingProfileNameLg =>
      _bahij(fontSize: 20, fontWeight: AppFonts.semibold);

  static TextStyle get bodyLg =>
      _bahij(fontSize: 16, fontWeight: AppFonts.regular, height: 1.5);

  static TextStyle get bodyMd =>
      _bahij(fontSize: 14, fontWeight: AppFonts.regular, height: 1.5);

  static TextStyle get bodySm =>
      _bahij(fontSize: 12, fontWeight: AppFonts.regular, height: 1.5);

  static TextStyle get filterLabel =>
      _bahij(fontSize: 17.6, fontWeight: AppFonts.regular, height: 1.2);

  static TextStyle get labelAuth =>
      _bahij(fontSize: 18, fontWeight: AppFonts.regular);

  static TextStyle get loginWelcome =>
      _bahij(fontSize: 30, fontWeight: AppFonts.bold, height: 1.2);

  static TextStyle get loginSubtitle => _bahij(
        fontSize: 16,
        fontWeight: AppFonts.regular,
        color: AppColors.loginPlaceholder,
        height: 1.5,
      );

  static TextStyle get loginFieldLabel =>
      _bahij(fontSize: 16, fontWeight: AppFonts.medium, height: 1.5);

  static TextStyle get loginInputHint => _bahij(
        fontSize: 16,
        fontWeight: AppFonts.regular,
        color: AppColors.loginPlaceholder,
      );

  static TextStyle get loginButtonText =>
      _bahij(fontSize: 20, fontWeight: AppFonts.bold, height: 1.4);

  static TextStyle get navLink =>
      _bahij(fontSize: 15, fontWeight: AppFonts.medium);

  static TextStyle get navLinkLg =>
      _bahij(fontSize: 16, fontWeight: AppFonts.medium);

  static TextStyle get button =>
      _bahij(fontSize: 14, fontWeight: AppFonts.medium);

  static TextStyle get buttonLg =>
      _bahij(fontSize: 18, fontWeight: AppFonts.semibold);

  static TextStyle get buttonXl =>
      _bahij(fontSize: 20, fontWeight: AppFonts.semibold);

  static TextStyle get badge =>
      _bahij(fontSize: 12, fontWeight: AppFonts.semibold);

  static TextStyle get reportStatusBadge =>
      badge.copyWith(height: 16 / 12);

  static TextStyle get tab =>
      _bahij(fontSize: 14, fontWeight: AppFonts.medium);

  static TextStyle get tabSm =>
      _bahij(fontSize: 10, fontWeight: AppFonts.regular, height: 2.4);

  static TextStyle get tabSmActive =>
      _bahij(fontSize: 11, fontWeight: AppFonts.medium, height: 2.18);

  static TextStyle get muted => _bahij(
        fontSize: 16,
        fontWeight: AppFonts.regular,
        color: AppColors.textMuted,
        height: 1.5,
      );

  static TextStyle get mutedSm => _bahij(
        fontSize: 14,
        fontWeight: AppFonts.regular,
        color: AppColors.tabInactive,
      );

  static TextStyle get greeting => _bahij(
        fontSize: 14,
        fontWeight: AppFonts.medium,
        color: AppColors.primary.withValues(alpha: 0.8),
      );

  static TextStyle get error => _bahij(
        fontSize: 14,
        fontWeight: AppFonts.regular,
        color: AppColors.error,
      );

  static TextStyle get errorLg => _bahij(
        fontSize: 20,
        fontWeight: AppFonts.regular,
        color: AppColors.error,
      );

  static TextStyle get input =>
      _bahij(fontSize: 16, fontWeight: AppFonts.regular);

  static TextStyle get inputHint => _bahij(
        fontSize: 16,
        fontWeight: AppFonts.regular,
        color: AppColors.textMuted,
        height: 1.5,
      );

  static TextStyle get size10 => custom(fontSize: 10);
  static TextStyle get size11 => custom(fontSize: 11);
  static TextStyle get size15 => custom(fontSize: 15);
  static TextStyle get size20 => custom(fontSize: 20);
  static TextStyle get size22 => custom(fontSize: 22);
  static TextStyle get size24 => custom(fontSize: 24);
  static TextStyle get size28 => custom(fontSize: 28);
  static TextStyle get size30 => custom(fontSize: 30);
  static TextStyle get size32 => custom(fontSize: 32);
  static TextStyle get size36 => custom(fontSize: 36);

  static TextTheme textTheme({Brightness brightness = Brightness.dark}) {
    final onSurface =
        brightness == Brightness.dark ? AppColors.primary : AppColors.lightMuted;

    return TextTheme(
      displayLarge: displayLg.copyWith(color: onSurface),
      displayMedium: displayMd.copyWith(color: onSurface),
      displaySmall: headingCourseLg.copyWith(color: onSurface),
      headlineLarge: headingCourseLg.copyWith(color: onSurface),
      headlineMedium: headingDialog.copyWith(color: onSurface),
      headlineSmall: headingProfileName.copyWith(color: onSurface),
      titleLarge: buttonXl.copyWith(color: onSurface),
      titleMedium: bodyLg.copyWith(
        fontWeight: AppFonts.semibold,
        color: onSurface,
      ),
      titleSmall: button.copyWith(color: onSurface),
      bodyLarge: bodyLg.copyWith(color: onSurface),
      bodyMedium: bodyMd.copyWith(color: onSurface),
      bodySmall: bodySm.copyWith(color: onSurface),
      labelLarge: buttonLg.copyWith(color: onSurface),
      labelMedium: button.copyWith(color: onSurface),
      labelSmall: badge.copyWith(color: onSurface),
    );
  }

  static TextStyle of(BuildContext context, TextStyle base) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return base.copyWith(color: onSurface);
  }
}
