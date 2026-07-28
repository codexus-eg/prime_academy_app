import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/incomplete_task.dart';

class IncompleteCategoryStyle {
  const IncompleteCategoryStyle({
    required this.chipActiveGradient,
    required this.accentText,
    required this.iconBackground,
    required this.cardHoverTint,
    required this.iconAsset,
  });

  final LinearGradient chipActiveGradient;

  final Color accentText;

  final Color iconBackground;

  final Color cardHoverTint;

  final String iconAsset;

  static const Color chipActiveBorder = AppColors.accentBg40;
  static const Color chipInactiveBackground = AppColors.mainBg3;
  static const Color chipInactiveText = AppColors.tabInactive;
  static const Color chipInactiveIcon = AppColors.gray500;
  static const Color chipInactiveHoverBorder = Color(0x1AFFFFFF);
  static const Color chipActiveText = AppColors.primary;
  static const Color countBadgeActiveBackground = AppColors.overlayWhite10;
  static const Color countBadgeInactiveBackground = AppColors.overlayWhite5;
  static const Color countBadgeInactiveText = AppColors.gray500;
  static const Color countBadgeActiveText = AppColors.primary;
  static const Color cardBorder = AppColors.overlayWhite3;
  static const Color cardBorderHover = Color(0x14FFFFFF);
  static const Color cardBackground = AppColors.mainBg3;

  static IncompleteCategoryStyle forCategory(IncompleteTaskCategory category) {
    return switch (category) {
      IncompleteTaskCategory.exams => const IncompleteCategoryStyle(
          chipActiveGradient: LinearGradient(
            colors: [AppColors.accentGradientFrom10, Color(0x0D2563EB)],
          ),
          accentText: AppColors.accentIconMuted400,
          iconBackground: AppColors.accentBg15,
          cardHoverTint: AppColors.accentBg20,
          iconAsset: 'assets/icons/incomplete/exam_fill.svg',
        ),
      IncompleteTaskCategory.lessons => const IncompleteCategoryStyle(
          chipActiveGradient: LinearGradient(
            colors: [Color(0x1AEF4444), Color(0x0DDC2626)],
          ),
          accentText: Color(0xFFF87171),
          iconBackground: Color(0x26EF4444),
          cardHoverTint: Color(0x33EF4444),
          iconAsset: 'assets/icons/incomplete/youtube.svg',
        ),
      IncompleteTaskCategory.categories => const IncompleteCategoryStyle(
          chipActiveGradient: LinearGradient(
            colors: [Color(0x1AEAB308), Color(0x0DCA8A04)],
          ),
          accentText: AppColors.rankGold,
          iconBackground: Color(0x26EAB308),
          cardHoverTint: Color(0x33EAB308),
          iconAsset: 'assets/icons/lesson/ranking_star.svg',
        ),
      IncompleteTaskCategory.luckCards => const IncompleteCategoryStyle(
          chipActiveGradient: LinearGradient(
            colors: [Color(0x1AA855F7), Color(0x0D9333EA)],
          ),
          accentText: AppColors.reportPurple400,
          iconBackground: Color(0x26A855F7),
          cardHoverTint: Color(0x33A855F7),
          iconAsset: 'assets/icons/incomplete/mystery_card.svg',
        ),
      IncompleteTaskCategory.memoryCards => const IncompleteCategoryStyle(
          chipActiveGradient: LinearGradient(
            colors: [Color(0x1A22C55E), Color(0x0D16A34A)],
          ),
          accentText: AppColors.reportGreen400,
          iconBackground: Color(0x2622C55E),
          cardHoverTint: Color(0x3322C55E),
          iconAsset: 'assets/icons/lesson/cards.svg',
        ),
    };
  }
}
