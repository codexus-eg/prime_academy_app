import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {

  static const List<BoxShadow> buttonRest = [
    BoxShadow(
      color: AppColors.shadowButton,
      offset: Offset(7, 7),
      blurRadius: 15,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonHover = [
    BoxShadow(
      color: AppColors.shadowButton,
      offset: Offset(2, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> containerRest = [
    BoxShadow(
      color: AppColors.shadowContainer,
      offset: Offset(2, 7),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> containerHover = [
    BoxShadow(
      color: AppColors.shadowContainer,
      offset: Offset(2, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> tabActive = [
    BoxShadow(
      color: AppColors.overlayBlack10,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: AppColors.shadowBlack19,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.overlayWhite5,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: AppColors.overlayBlack10,
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.overlayWhite5,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> shadow2xl = [
    BoxShadow(
      color: AppColors.overlayBlack10,
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: AppColors.overlayWhite5,
      offset: Offset(0, 10),
      blurRadius: 20,
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> reportHeaderIcon = [
    BoxShadow(
      color: AppColors.rankBlueGlow10,
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.rankBlueGlow10,
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> tailwindLgBlack = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> reportLatestBadge = [
    BoxShadow(
      color: AppColors.accentBg20,
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.accentBg20,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: AppColors.overlayBlack10,
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: AppColors.overlayWhite5,
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> sessionBlocked = [
    BoxShadow(
      color: AppColors.secondary,
      offset: Offset.zero,
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> sessionBlockedCta = [
    BoxShadow(
      color: AppColors.shadowPurple40,
      offset: Offset(0, 4),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> maintenanceBanner = [
    BoxShadow(
      color: AppColors.scrim80,
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> profileRing = [
    BoxShadow(
      color: AppColors.shadowPurple50,
      offset: Offset(0, 3),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> courseCard = [
    BoxShadow(
      color: AppColors.shadowCourseCard,
      offset: Offset(2, 2),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> courseCardCta = [
    BoxShadow(
      color: AppColors.shadowCourseCta,
      offset: Offset(2, 4),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const double courseIconDropShadowPrimaryBlur = 12.5;
  static const Offset courseIconDropShadowPrimaryOffset = Offset(0, 20);
  static const double courseIconDropShadowPrimaryOpacity = 0.1;

  static const double courseIconDropShadowSecondaryBlur = 5;
  static const Offset courseIconDropShadowSecondaryOffset = Offset(0, 8);
  static const double courseIconDropShadowSecondaryOpacity = 0.1;

  static const List<BoxShadow> examAnswerCorrect = [
    BoxShadow(
      color: AppColors.shadowGreen50,
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];

  static const List<BoxShadow> examAnswerWrong = [
    BoxShadow(
      color: AppColors.shadowRed50,
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];

  static const List<BoxShadow> examAnswerIdle = [
    BoxShadow(
      color: AppColors.shadowBlack19,
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: AppColors.shadowBlack19,
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];

  static const List<BoxShadow> luckAnswerCorrect = [
    BoxShadow(
      color: AppColors.shadowGreen60,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> luckAnswerWrong = [
    BoxShadow(
      color: AppColors.shadowRed60,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> luckAnswerIdle = [
    BoxShadow(
      color: AppColors.shadowPurple40,
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> luckCardPick = [
    BoxShadow(
      color: AppColors.shadowPurple50,
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> knowledgeCardActive = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 20),
      blurRadius: 40,
    ),
  ];

  static const List<BoxShadow> luckCardReveal = [
    BoxShadow(
      color: AppColors.shadowPurple50,
      blurRadius: 40,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> lessonProgressRing(Color glowColor) => [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.3),
          blurRadius: 24,
        ),
      ];

  static List<BoxShadow> lessonPlayCircle(Color glowColor) => [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.4),
          blurRadius: 15,
        ),
      ];

  static List<BoxShadow> interactiveSurface({
    required bool hovering,
    required double glowOpacity,
    required Color accentGlow,
    required double restShadowBlur,
    required double hoverShadowBlur,
    bool includeSpread = true,
  }) {
    final shadowBlur = hovering ? hoverShadowBlur : restShadowBlur;
    return [
      BoxShadow(
        color: AppColors.scrim80.withValues(alpha: hovering ? 0.28 : 0.18),
        blurRadius: shadowBlur,
        offset: Offset(0, hovering ? 6 : 3),
        spreadRadius: includeSpread && hovering ? 1 : 0,
      ),
      if (glowOpacity > 0)
        BoxShadow(
          color: accentGlow.withValues(alpha: glowOpacity),
          blurRadius: hovering ? 22 : 14,
          spreadRadius: hovering ? 1.5 : 0.5,
        ),
    ];
  }

  static List<BoxShadow> motionWrapperSurface({
    required bool hovering,
    required double glowOpacity,
    required Color accentGlow,
    required double restShadowBlur,
    required double hoverShadowBlur,
  }) {
    final shadowBlur = hovering ? hoverShadowBlur : restShadowBlur;
    return [
      BoxShadow(
        color: AppColors.scrim80.withValues(alpha: hovering ? 0.28 : 0.16),
        blurRadius: shadowBlur,
        offset: Offset(0, hovering ? 6 : 3),
      ),
      if (glowOpacity > 0)
        BoxShadow(
          color: accentGlow.withValues(alpha: glowOpacity),
          blurRadius: hovering ? 22 : 14,
          spreadRadius: hovering ? 1.5 : 0.5,
        ),
    ];
  }

  static const Duration shadowTransition = Duration(milliseconds: 400);
  static const Duration borderGradientTransition = Duration(milliseconds: 250);
  static const Duration backgroundGradientTransition = Duration(milliseconds: 400);
  static const Duration tabTransition = Duration(milliseconds: 200);
}
