import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_typography.dart';

abstract final class ProfileCourseStyles {

  static const Color titleColor = Color(0xFFFFFFFF);

  static const double ctaBackgroundAlpha = 0.51;

  static const double ctaBackgroundAlphaHover = 0.41;

  static const Color cardScaffoldUnderlay = AppColors.mainBg;

  static Color ctaFill(double alpha) => Color.fromRGBO(0, 0, 0, alpha);

  static Color get ctaBackground => ctaFill(ctaBackgroundAlpha);

  static Color get ctaBackgroundHover => ctaFill(ctaBackgroundAlphaHover);

  static const Color ctaTextColor = Color(0xFFFFFFFF);

  static const List<BoxShadow> ctaShadow = AppShadows.courseCardCta;

  static TextStyle titleMobile({FontWeight? fontWeight}) {
    return AppTypography.custom(
      fontSize: 14,
      fontWeight: fontWeight ?? AppFonts.semibold,
      color: titleColor,
      height: 1.25,
    );
  }

  static TextStyle titleDesktop({FontWeight? fontWeight}) {
    return AppTypography.custom(
      fontSize: 16,
      fontWeight: fontWeight ?? AppFonts.semibold,
      color: titleColor,
      height: 1.25,
    );
  }

  static TextStyle get ctaLabel {
    return AppTypography.custom(
      fontSize: 20,
      fontWeight: AppFonts.normal,
      color: ctaTextColor,
      height: 1.25,
    );
  }
}
