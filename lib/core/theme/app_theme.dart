import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'premium_button_animation_theme.dart';
import 'premium_button_theme.dart';

export 'app_colors.dart';
export 'app_durations.dart';
export 'app_fonts.dart';
export 'app_gradients.dart';
export 'app_quiz_palette.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

abstract final class AppTheme {

  static const Color background = AppColors.mainBg2;
  static const Color fieldFill = AppColors.fieldFill;
  static const Color fieldBorderEmail = Color(0xFF0F3589);
  static const Color fieldBorderPassword = Color(0xFF0E368D);
  static const Color countryBorder = Color(0xFF193574);
  static const Color muted = AppColors.textMuted;
  static const Color loginGradientStart = AppColors.loginGradientStart;
  static const Color loginGradientEnd = AppColors.accent;
  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightFieldFill = AppColors.lightFieldFill;
  static const Color lightMuted = AppColors.lightMuted;
  static const Color homeTabBarFill = AppColors.mainBg3;
  static const Color homeTabInactive = AppColors.tabInactive;
  static const Color homeHeaderBorder = AppColors.headerBorder;
  static const Color mobileNavBorder = AppColors.mobileNavBorder;
  static const Color profileRingStart = AppColors.profileRingStart;
  static const Color profileRingEnd = AppColors.profileRingEnd;
  static const Color profileInner = AppColors.profileInner;
  static const Color notificationDot = AppColors.notificationDot;
  static const Color courseBlueEnd = AppColors.courseBlueEnd;
  static const Color coursePurpleEnd = AppColors.coursePurpleEnd;
  static const Color coursePageBackground = AppColors.mainBg;

  static const Color courseModulesSheet = AppColors.primaryBg;

  static const Color courseModuleSurface = AppColors.secondaryBg;
  static const Color unitAccentStart = AppColors.unitAccentStart;
  static const Color unitAccentMid = AppColors.unitAccentMid;
  static const Color unitActiveStart = AppColors.unitActiveStart;
  static const Color unitActiveMid = AppColors.unitActiveMid;
  static const Color lessonTimelineLine = AppColors.lessonTimelineLine;
  static const Color lessonCompleted = AppColors.lessonCompleted;
  static const Color lessonProgressOuter = AppColors.lessonProgressOuter;
  static const Color lessonProgressInner = AppColors.lessonProgressInner;
  static const Color lessonProgressCardTop = AppColors.lessonProgressCardTop;
  static const Color lessonProgressCardMid = AppColors.lessonProgressCardMid;
  static const Color lessonActionDark = AppColors.lessonActionDark;
  static const Color chatInputBorder = AppColors.chatInputBorder;
  static const Color reportBadgeFill = AppColors.reportBadgeFill;
  static const Color reportWeakStudentFill = AppColors.reportWeakStudentFill;
  static const Color reportAccuracyFill = AppColors.reportAccuracyFill;
  static const Color reportWeakStudentText = AppColors.reportWeakStudentText;
  static const Color reportButtonFill = AppColors.reportButtonFill;
  static const Color rankingDivider = AppColors.rankingDivider;
  static const Color rankingRankFill = AppColors.rankingRankFill;
  static const Color awardTitleGold = AppColors.awardTitleGold;
  static const Color incompleteTaskTabBorder = AppColors.incompleteTaskTabBorder;
  static const Color categoryIconFill = AppColors.categoryIconFill;
  static const Color flashcardIconFill = AppColors.flashcardIconFill;
  static const Color flashcardSubtitle = AppColors.flashcardSubtitle;
  static const Color memoryCardsBackground = AppColors.memoryCardsBackground;
  static const Color memoryCardsBorder = AppColors.memoryCardsBorder;
  static const Color memoryCardProgress = AppColors.memoryCardProgress;
  static const Color memoryCardAnswerLabel = AppColors.memoryCardAnswerLabel;
  static const Color memoryCardExitBorder = AppColors.memoryCardExitBorder;
  static const Color memoryCardExitText = AppColors.memoryCardExitText;
  static const Color examBackground = AppColors.examBackground;
  static const Color examDialogFill = AppColors.examDialogFill;
  static const Color examDialogBorder = AppColors.examDialogBorder;
  static const Color examLabelBlue = AppColors.examLabelBlue;
  static const Color examProgressTrack = AppColors.examProgressTrack;
  static const Color luckCardsBackground = AppColors.luckCardsBackground;

  static ThemeData get primeDark => _buildTheme(
        brightness: Brightness.dark,
        backgroundColor: AppColors.mainBg,
        surfaceColor: AppColors.mainBg2,
        onSurface: AppColors.primary,
        primary: AppColors.blue,
        onPrimary: AppColors.primary,
        outline: AppColors.borderMuted,
        mutedColor: AppColors.textMuted,
        fieldFillColor: AppColors.fieldFill,
      );

  static ThemeData get primeLight => _buildTheme(
        brightness: Brightness.light,
        backgroundColor: AppColors.lightBackground,
        surfaceColor: AppColors.lightSurface,
        onSurface: const Color(0xFF0F1728),
        primary: AppColors.loginGradientStart,
        onPrimary: AppColors.primary,
        outline: AppColors.lightBorder,
        mutedColor: AppColors.lightMuted,
        fieldFillColor: AppColors.lightFieldFill,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color onSurface,
    required Color primary,
    required Color onPrimary,
    required Color outline,
    required Color mutedColor,
    required Color fieldFillColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              surface: surfaceColor,
              onSurface: onSurface,
              primary: primary,
              onPrimary: onPrimary,
              outline: outline,
              secondary: AppColors.secondary,
              secondaryContainer: AppColors.profileInner,
              onSecondaryContainer: onSurface,
              surfaceContainerHigh: fieldFillColor,
              error: AppColors.error,
            )
          : ColorScheme.light(
              surface: surfaceColor,
              onSurface: onSurface,
              primary: primary,
              onPrimary: onPrimary,
              outline: outline,
              secondaryContainer: AppColors.lightFieldFill,
              onSecondaryContainer: onSurface,
              surfaceContainerHigh: AppColors.lightFieldFill,
              error: AppColors.error,
            ),
      textTheme: AppTypography.textTheme(brightness: brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        titleTextStyle: AppTypography.headingDialog.copyWith(color: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: AppTypography.inputHint.copyWith(color: mutedColor),
        labelStyle: AppTypography.labelAuth.copyWith(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.mainBg3,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.3),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.mainBg3,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.mainBg3,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      extensions: const [PremiumButtonAnimationTheme.standard],
    );

    return PremiumButtonTheme.apply(base);
  }
}
