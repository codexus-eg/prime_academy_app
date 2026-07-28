import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class NotificationStyles {

  static const Color panelBackground = AppColors.surfaceElevated;

  static const Color itemBackground = AppColors.overlayWhite5;

  static const Color itemBackgroundHover = AppColors.overlayWhite10;

  static const Color accentUnread = AppColors.accentSoft;

  static const Color borderRead = AppColors.rankDefaultFill;

  static const Color headerDivider = AppColors.notificationHeaderDivider;

  static const Color textSecondary = AppColors.rankSilverLight;

  static const Color textBody = AppColors.tabInactive;

  static const Color iconRead = AppColors.rankDefaultFill;

  static TextStyle get headerTitle => AppTypography.custom(
        fontSize: 18,
        fontWeight: AppFonts.semibold,
        color: AppColors.primary,
      );

  static TextStyle get markAllRead => AppTypography.custom(
        fontSize: 12,
        fontWeight: AppFonts.regular,
        color: textSecondary,
      );

  static TextStyle get emptyState => AppTypography.custom(
        fontSize: 14,
        fontWeight: AppFonts.regular,
        color: textSecondary,
      );

  static TextStyle get itemTitle => AppTypography.custom(
        fontSize: 14,
        fontWeight: AppFonts.semibold,
        color: AppColors.primary,
        height: 1.375,
      );

  static TextStyle get groupTitle => AppTypography.custom(
        fontSize: 14,
        fontWeight: AppFonts.medium,
        color: AppColors.primary,
        height: 1.6,
      );

  static TextStyle get itemBody => AppTypography.custom(
        fontSize: 12,
        fontWeight: AppFonts.regular,
        color: textBody,
        height: 1.625,
      );

  static TextStyle get groupUnreadCount => AppTypography.custom(
        fontSize: 12,
        fontWeight: AppFonts.regular,
        color: accentUnread,
      );

  static TextStyle get loadingFooter => itemBody.copyWith(
        color: textBody,
      );

  static const BorderRadius itemRadius = AppRadius.borderShadcnLg;
}
