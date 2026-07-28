import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

abstract final class ClassificationMcqCardStyle {
  static const shellSurface = AppColors.mainBg2;

  static Color blend(Color foreground, Color background, double opacity) {
    final t = opacity.clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (foreground.r * 255.0 * t + background.r * 255.0 * (1 - t)).round().clamp(0, 255),
      (foreground.g * 255.0 * t + background.g * 255.0 * (1 - t)).round().clamp(0, 255),
      (foreground.b * 255.0 * t + background.b * 255.0 * (1 - t)).round().clamp(0, 255),
    );
  }

  static const idleBorder = Color(0x1AFFFFFF);
  static const cardShadow = AppShadows.tailwindLgBlack;
  static const badgeShadow = AppShadows.tabActive;
}

class ClassificationMcqOptionTheme {
  const ClassificationMcqOptionTheme({
    required this.gradientStart,
    required this.gradientEnd,
    required this.text,
    required this.badgeFill,
    required this.badgeSolid,
    required this.selectedStart,
    required this.selectedEnd,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color text;
  final Color badgeFill;
  final Color badgeSolid;
  final Color selectedStart;
  final Color selectedEnd;

  static const blue = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF1A2C4A),
    gradientEnd: Color(0xFF162848),
    text: Color(0xFF93C5FD),
    badgeFill: Color(0xFF234072),
    badgeSolid: Color(0xFF3B82F6),
    selectedStart: Color(0xFF244066),
    selectedEnd: Color(0xFF20355C),
  );

  static const purple = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF301E4A),
    gradientEnd: Color(0xFF2C1C48),
    text: Color(0xFFD8B4FE),
    badgeFill: Color(0xFF4A3268),
    badgeSolid: Color(0xFFA855F7),
    selectedStart: Color(0xFF4E3268),
    selectedEnd: Color(0xFF462C60),
  );

  static const emerald = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF123733),
    gradientEnd: Color(0xFF0F2C28),
    text: Color(0xFF6EE7B7),
    badgeFill: Color(0xFF1E4A42),
    badgeSolid: Color(0xFF10B981),
    selectedStart: Color(0xFF1E4E44),
    selectedEnd: Color(0xFF1A4238),
  );

  static const amber = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF3A3018),
    gradientEnd: Color(0xFF362C16),
    text: Color(0xFFFCD34D),
    badgeFill: Color(0xFF5A4820),
    badgeSolid: Color(0xFFF59E0B),
    selectedStart: Color(0xFF5E4A22),
    selectedEnd: Color(0xFF543E1E),
  );

  static const rose = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF3A1E28),
    gradientEnd: Color(0xFF361C26),
    text: Color(0xFFFDA4AF),
    badgeFill: Color(0xFF5A3240),
    badgeSolid: Color(0xFFF43F5E),
    selectedStart: Color(0xFF5E3442),
    selectedEnd: Color(0xFF542E3C),
  );

  static const cyan = ClassificationMcqOptionTheme(
    gradientStart: Color(0xFF163038),
    gradientEnd: Color(0xFF142C34),
    text: Color(0xFF67E8F9),
    badgeFill: Color(0xFF244850),
    badgeSolid: Color(0xFF06B6D4),
    selectedStart: Color(0xFF244E56),
    selectedEnd: Color(0xFF20464E),
  );

  static const options = [blue, purple, emerald, amber, rose, cyan];

  static ClassificationMcqOptionTheme forIndex(int index) =>
      options[index % options.length];
}

enum ClassificationMcqCardState { idle, selected, correct, wrong }

class ClassificationMcqCardColors {
  const ClassificationMcqCardColors({
    required this.gradientStart,
    required this.gradientEnd,
    required this.border,
    required this.badgeFill,
    required this.text,
    required this.statusBadge,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color border;
  final Color badgeFill;
  final Color text;
  final Color statusBadge;

  factory ClassificationMcqCardColors.resolve(
    ClassificationMcqCardState state,
    ClassificationMcqOptionTheme theme,
  ) {
    return switch (state) {
      ClassificationMcqCardState.correct => const ClassificationMcqCardColors(
          gradientStart: Color(0xFF123733),
          gradientEnd: Color(0xFF123733),
          border: Color(0xFF10B981),
          badgeFill: Color(0xFF1E4A42),
          text: Color(0xFF6EE7B7),
          statusBadge: Color(0xFF10B981),
        ),
      ClassificationMcqCardState.wrong => const ClassificationMcqCardColors(
          gradientStart: Color(0xFF3A1E28),
          gradientEnd: Color(0xFF3A1E28),
          border: Color(0xFFF43F5E),
          badgeFill: Color(0xFF5A3240),
          text: Color(0xFFFDA4AF),
          statusBadge: Color(0xFFF43F5E),
        ),
      ClassificationMcqCardState.selected => ClassificationMcqCardColors(
          gradientStart: theme.selectedStart,
          gradientEnd: theme.selectedEnd,
          border: const Color(0xFFF59E0B),
          badgeFill: ClassificationMcqCardStyle.blend(
            const Color(0xFFF59E0B),
            theme.selectedStart,
            0.3,
          ),
          text: const Color(0xFFFCD34D),
          statusBadge: const Color(0xFFF59E0B),
        ),
      ClassificationMcqCardState.idle => ClassificationMcqCardColors(
          gradientStart: theme.gradientStart,
          gradientEnd: theme.gradientEnd,
          border: ClassificationMcqCardStyle.idleBorder,
          badgeFill: theme.badgeFill,
          text: theme.text,
          statusBadge: theme.badgeSolid,
        ),
    };
  }
}
