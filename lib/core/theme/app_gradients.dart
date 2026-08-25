import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {

  static const RadialGradient borderGradientDefault = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.secondary, AppColors.accent],
    stops: [0.0, 1.0],
  );

  static const RadialGradient borderGradientHover = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.accent, AppColors.secondary],
    stops: [0.0, 1.0],
  );

  static const RadialGradient backgroundGradientDefault = RadialGradient(
    center: Alignment.topRight,
    focal: Alignment.topRight,
    radius: 1.2,
    colors: [AppColors.accent, AppColors.secondary],
    stops: [0.0, 1.0],
  );

  static RadialGradient bgGradientBefore({
    required double width,
    required double height,
  }) {
    if (width <= 0 || height <= 0) {
      return backgroundGradientDefault;
    }

    final minSide = math.min(width, height);
    final farthestCorner = math.sqrt(width * width + height * height);
    final radius = farthestCorner / (minSide / 2);

    return RadialGradient(
      center: Alignment.topRight,
      focal: Alignment.topRight,
      radius: radius,
      colors: const [AppColors.accent, AppColors.secondary],
      stops: const [0.0, 1.0],
    );
  }

  static const RadialGradient backgroundGradientHover = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.accent, AppColors.secondary],
    stops: [0.0, 1.0],
  );

  static const RadialGradient buttonGradientDefault = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [AppColors.secondary, AppColors.accent],
    stops: [0.0, 0.88],
  );

  static const RadialGradient buttonGradientHover = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.secondary, AppColors.accent],
    stops: [0.0, 1.0],
  );

  static const RadialGradient backgroundGradientDarkDefault = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [AppColors.gradientDarkStart, AppColors.secondary],
    stops: [0.0, 1.0],
  );

  static const RadialGradient backgroundGradientDarkHover = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.secondary, AppColors.gradientDarkStart],
    stops: [0.0, 1.0],
  );

  static const LinearGradient borderBottomGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.secondary, AppColors.accent],
  );

  static const LinearGradient courseTitle = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.courseTitleGradientStart, AppColors.secondaryBg],
    stops: [0.0, 1.0],
  );

  static const LinearGradient courseTitleRtl = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.courseTitleGradientStart, AppColors.accent],
    stops: [0.0, 1.0],
  );

  static const LinearGradient rankingCurrentRow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.rankBlueGlow20,
      AppColors.rankBlueGlow10,
      AppColors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient incompleteTaskCountBadge = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.rankBlueGlow10,
      AppColors.rankBlueLightGlow5,
    ],
  );

  static const LinearGradient rankingPointsCurrent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.blue, AppColors.blueLight],
  );

  static const LinearGradient maintenanceBanner = LinearGradient(
    begin: Alignment(-0.17, -1.0),
    end: Alignment(0.17, 1.0),
    colors: [AppColors.secondary, AppColors.accent],
  );

  static const LinearGradient brandText = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.secondaryOld, AppColors.accentOld],
    stops: [0.0, 1.0],
  );

  static const LinearGradient sessionBlockedCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mainBg3, AppColors.mainBg2],
    stops: [0.0, 1.0],
  );

  static const LinearGradient tournamentCard = LinearGradient(
    begin: Alignment(-0.17, -1.0),
    end: Alignment(0.17, 1.0),
    colors: [AppColors.accentOld, AppColors.secondaryOld],
    stops: [0.0, 1.0],
  );

  static const LinearGradient imageBorderDefault = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.accent, AppColors.secondary],
  );

  static const LinearGradient profileRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.profileRingStart, AppColors.profileRingEnd],
  );

  static const RadialGradient scrollbar = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.2,
    colors: [AppColors.secondary, AppColors.accent],
    stops: [0.0, 1.0],
  );

  static BoxDecoration buttonDecoration({BorderRadius? borderRadius}) {
    return BoxDecoration(
      gradient: buttonGradientDefault,
      borderRadius: borderRadius,
    );
  }

  static BoxDecoration cardBackgroundDecoration({BorderRadius? borderRadius}) {
    return BoxDecoration(
      color: AppColors.mainBg3,
      borderRadius: borderRadius,
    );
  }

  static const LinearGradient courseCardFooterFade = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.mainBg3, AppColors.transparent],
  );

  static const Color courseCardEnglishGlowCore = Color(0xFF333366);

  static const LinearGradient courseCardEnglish = LinearGradient(
    begin: Alignment(0.50, 0.52),
    end: Alignment(0.51, 0.79),
    colors: [
      Color(0x004E23B4),
      AppColors.courseBlueEnd,
    ],
  );

  static const RadialGradient lessonActionRadialBlue = RadialGradient(
    center: Alignment(-1.2214, 1.4174),
    radius: 1.0,
    colors: [AppColors.blue, AppColors.contentBtnBg],
  );

  static const RadialGradient lessonActionRadialPurple = RadialGradient(
    center: Alignment(-1.2214, 1.4174),
    radius: 1.0,
    colors: [AppColors.purple, AppColors.contentBtnBg],
  );

  static const RadialGradient lessonQuizCard = RadialGradient(
    center: Alignment(-0.11, 1.21),
    radius: 1.37,
    colors: [AppColors.secondaryBg, AppColors.secondaryBg],
  );

  static const LinearGradient lessonActionBlue = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional(0.83, -0.57),
    colors: [AppColors.lessonCardBlueStart, AppColors.lessonActionDark],
  );

  static const LinearGradient lessonActionPurple = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [
      AppColors.purple,
      AppColors.charGlowPurple,
      AppColors.lessonActionDark,
    ],
  );

  static const LinearGradient homeTabActive = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.rankBlueGlow20,
      AppColors.blueLightGlow10,
    ],
  );

  static const LinearGradient homeTabActiveDesktop = homeTabActive;

  static const LinearGradient unitLeftAccent = LinearGradient(
    begin: Alignment(-1, -0.15),
    end: Alignment(0.85, 0.55),
    colors: [
      AppColors.unitGradientBlueStart,
      AppColors.unitGradientBlueMid,
      AppColors.unitGradientBlueEnd,
    ],
    stops: [0, 0.14, 0.28],
  );

  static const LinearGradient unitActive = LinearGradient(
    begin: Alignment(0.06, 0.15),
    end: Alignment(1, 0.5),
    colors: [
      AppColors.unitGradientOliveStart,
      AppColors.unitGradientOliveEnd,
      AppColors.unitGradientBlueEnd,
    ],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient lessonAsideHeader = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.primaryBg, Color(0xFF091C40)],
  );

  /// Web chat/files header: `linear-gradient(0deg, aside-header-start, aside-header-end)`.
  static const LinearGradient lessonChatFilesHeader = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.primaryBg, AppColors.asideHeaderEnd],
  );

  /// Web `.button-gradient` default layer: radial at top right.
  static const RadialGradient chatRoleBadge = RadialGradient(
    center: Alignment.topRight,
    radius: 1.35,
    colors: [AppColors.courseTitleGradientStart, AppColors.cssAccent],
    stops: [0, 0.88],
  );

  static const LinearGradient lessonProgressCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.lessonProgressCardTop,
      AppColors.lessonProgressCardMid,
      AppColors.mainBg2,
    ],
  );

  static const LinearGradient loginSubmitRtl = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AppColors.loginGradientStart, AppColors.accent],
  );

  static const LinearGradient selectItemHover = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.rankBlueGlow10, AppColors.rankBlueLightGlow5],
  );

  static const LinearGradient reportIconBox = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.reportBlueSurface, AppColors.rankBlueLightGlow5],
  );

  static const LinearGradient reportEmptyIconShell = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentGradientFrom10, AppColors.reportBlueLight5],
  );

  static const LinearGradient reportHeaderIconBox = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rankBlueGlow20, AppColors.blueLightGlow10],
  );

  static const LinearGradient reportCardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.reportBlueGlow5, AppColors.transparent],
  );

  static const LinearGradient reportCta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.reportBlueSurface,
      Color(0x262072E0),
      AppColors.reportBlueSurface,
    ],
  );

  static const LinearGradient reportCtaHover = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x4D2072E0), Color(0x4D2072E0)],
  );

  static LinearGradient reportAccuracyBar(int grade) {
    if (grade >= 100) {
      return const LinearGradient(
        colors: [AppColors.reportGreen400, AppColors.reportGreen500],
      );
    }
    if (grade >= 80) {
      return const LinearGradient(
        colors: [AppColors.reportYellow400, AppColors.reportYellow500],
      );
    }
    return const LinearGradient(
      colors: [AppColors.reportOrange400, AppColors.reportOrange500],
    );
  }

  static const LinearGradient loginCta = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [AppColors.loginGradientStart, AppColors.accent],
  );

  static const LinearGradient challengeBanner = LinearGradient(
    begin: Alignment(0.33, 1.66),
    end: Alignment(0.54, 0.24),
    colors: [AppColors.lessonCardBlueStart, AppColors.accent],
  );

  static const LinearGradient onboardingAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.loginGradientStart, AppColors.accent],
  );

  static const LinearGradient splashOrange = LinearGradient(
    begin: Alignment(-1, 0),
    end: Alignment(1, 0),
    colors: [AppColors.splashBlobOrange, AppColors.reportWeakStudentText],
  );

  static const LinearGradient splashPurple = LinearGradient(
    begin: Alignment(-1, 0),
    end: Alignment(1, 0),
    colors: [AppColors.splashBlobViolet, AppColors.purple],
  );

  static LinearGradient splashBlobDiagonal({required bool reversed}) {
    return LinearGradient(
      begin: const Alignment(0, 0),
      end: const Alignment(1, 1),
      colors: reversed
          ? const [AppColors.shadowPurple50, AppColors.shadowRed50]
          : const [AppColors.shadowRed50, AppColors.shadowPurple50],
    );
  }

  static const RadialGradient splashBackground = RadialGradient(
    center: Alignment(0, -0.05),
    radius: 0.85,
    colors: [
      AppColors.splashBlobPurple,
      AppColors.mainBg2,
      AppColors.mainBg,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient primaryButton({
    required Color primary,
    required Color end,
  }) {
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [primary, end],
    );
  }

  static RadialGradient splashBlobGlow({required bool reversed}) {
    final diagonal = splashBlobDiagonal(reversed: reversed);
    return RadialGradient(
      center: const Alignment(-0.18, -0.18),
      radius: 0.95,
      colors: [
        diagonal.colors.first.withValues(alpha: 0.55),
        diagonal.colors.last.withValues(alpha: 0.35),
        AppColors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }
}
