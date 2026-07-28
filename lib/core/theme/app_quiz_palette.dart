import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AnswerPaletteSlot {
  purple,
  blue,
  orange,
  teal,
}

enum LuckAnswerPaletteSlot {
  pink,
  blue,
  violet,
  orange,
}

class ExamCardStyle {
  const ExamCardStyle({
    required this.background,
    required this.border,
    required this.glowOuter,
    required this.glowInner,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color glowOuter;
  final Color glowInner;
  final Color icon;
}

abstract final class AppQuizPalette {
  static const Color purpleStart = AppColors.splashBlobViolet;
  static const Color purpleEnd = AppColors.purple;
  static const Color blueStart = AppColors.blue;
  static const Color blueEnd = AppColors.courseBlueEnd;
  static const Color orangeStart = AppColors.splashBlobOrange;
  static const Color orangeEnd = AppColors.reportWeakStudentText;
  static const Color tealStart = AppColors.memoryCardTeal;
  static const Color tealEnd = AppColors.luckCorrectTrack;

  static const Color luckPink = AppColors.memoryCardPink;
  static const Color luckBlue = AppColors.memoryCardBlue;
  static const Color luckViolet = AppColors.memoryCardViolet;
  static const Color luckOrange = AppColors.splashBlobOrange;

  static const Color answerCorrectStart = AppColors.success;
  static const Color answerCorrectEnd = AppColors.green;
  static const Color answerCorrectBorder = AppColors.luckCorrectBright;
  static const Color answerWrongStart = AppColors.notificationDot;
  static const Color answerWrongEnd = AppColors.error;
  static const Color answerWrongBorder = AppColors.luckWrongBright;

  static const Color luckCorrectBright = AppColors.luckCorrectBright;
  static const Color luckWrongBright = AppColors.luckWrongBright;

  static (Color start, Color end) examGradient(AnswerPaletteSlot slot) {
    return switch (slot) {
      AnswerPaletteSlot.purple => (purpleStart, purpleEnd),
      AnswerPaletteSlot.blue => (blueStart, blueEnd),
      AnswerPaletteSlot.orange => (orangeStart, orangeEnd),
      AnswerPaletteSlot.teal => (tealStart, tealEnd),
    };
  }

  static Color luckColor(LuckAnswerPaletteSlot slot) {
    return switch (slot) {
      LuckAnswerPaletteSlot.pink => luckPink,
      LuckAnswerPaletteSlot.blue => luckBlue,
      LuckAnswerPaletteSlot.violet => luckViolet,
      LuckAnswerPaletteSlot.orange => luckOrange,
    };
  }

  static LinearGradient examOptionGradient(AnswerPaletteSlot slot) {
    final (start, end) = examGradient(slot);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [start, end],
    );
  }

  static const LinearGradient answerCorrectGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [answerCorrectStart, answerCorrectEnd],
  );

  static const LinearGradient answerWrongGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [answerWrongStart, answerWrongEnd],
  );

  static const LinearGradient luckCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1254AF),
      Color(0xFF1A74C8),
      Color(0xFF1565BD),
    ],
    stops: [0, 0.4, 1],
  );

  static const LinearGradient lightningFillGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE566), Color(0xFFF59E0B)],
  );

  static const Color lightningStroke = Color(0x80F59E0B);
  static const Color lightningDimFill = Color(0x14FFFFFF);

  static const List<Color> knowledgeAnswerColors = [
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
  ];

  static Color knowledgeAnswerColor(int index) =>
      knowledgeAnswerColors[index % knowledgeAnswerColors.length];

  static const LinearGradient knowledgeCorrectBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F7B3E), Color(0xFF16A854)],
  );

  static const LinearGradient knowledgeWrongBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAF1212), Color(0xFFC81A1A)],
  );

  static const Color pointsOverlayFill = Color(0x1AFFFFFF);
  static const Color pointsOverlayBorder = Color(0x4DEAB308);
  static const Color pointsLabel = Color(0xFFFACC15);
  static const Color pointsValue = Color(0xFFFDE047);
  static const Color pointsProgressTrack = Color(0x33FFFFFF);

  static const LinearGradient pointsProgressFill = LinearGradient(
    colors: [Color(0xFFEAB308), Color(0xFFF59E0B)],
  );

  static const Color knowledgeScrim = Color(0x80000000);

  static const List<BoxShadow> knowledgeAnswerShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static const Color knowledgeAnswerBadgeFill = Color(0x40FFFFFF);

  static const LinearGradient examProgressGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blue],
  );

  static ExamCardStyle examCardStyle(int index) {
    return switch (index % 4) {
      0 => const ExamCardStyle(
          background: Color(0xFF091C3F),
          border: Color(0xFF0076F5),
          glowOuter: Color(0x66007BFF),
          glowInner: Color(0x1A007BFF),
          icon: Color(0xFF007BFF),
        ),
      1 => const ExamCardStyle(
          background: Color(0xFF250D38),
          border: Color(0xFF7B4CF0),
          glowOuter: Color(0x668B5CF6),
          glowInner: Color(0x1A8B5CF6),
          icon: Color(0xFF8B5CF6),
        ),
      2 => const ExamCardStyle(
          background: Color(0xFF082823),
          border: Color(0xFF12B09E),
          glowOuter: Color(0x6614B8A6),
          glowInner: Color(0x1A14B8A6),
          icon: Color(0xFF14B8A6),
        ),
      _ => const ExamCardStyle(
          background: Color(0xFF2C1D07),
          border: Color(0xFFEDA30A),
          glowOuter: Color(0x66F59E0B),
          glowInner: Color(0x1AF59E0B),
          icon: Color(0xFFF59E0B),
        ),
    };
  }

  static const ExamCardStyle examSelectedStyle = ExamCardStyle(
    background: Color(0x99091C3F),
    border: Color(0xFF0076F5),
    glowOuter: Color(0x66007BFF),
    glowInner: Color(0x26007BFF),
    icon: Color(0xFF007BFF),
  );

  static const ExamCardStyle examCorrectStyle = ExamCardStyle(
    background: Color(0x9914532D),
    border: Color(0xFF4ADE80),
    glowOuter: Color(0x4D4ADE80),
    glowInner: Color(0x1A4ADE80),
    icon: Color(0xFF4ADE80),
  );

  static const ExamCardStyle examWrongStyle = ExamCardStyle(
    background: Color(0x997F1D1D),
    border: Color(0xFFF87171),
    glowOuter: Color(0x4DF87171),
    glowInner: Color(0x1AF87171),
    icon: Color(0xFFF87171),
  );

  static List<BoxShadow> examCardShadows(
    ExamCardStyle style, {
    bool mobile = false,
    bool hovered = false,
  }) {

    if (mobile) {
      return [
        BoxShadow(
          color: style.glowOuter,
          blurRadius: hovered ? 20 : 15,
        ),
      ];
    }
    return [
      BoxShadow(
        color: style.glowOuter,
        blurRadius: hovered ? 40 : 25,
      ),
      BoxShadow(
        color: style.glowInner,
        blurRadius: hovered ? 20 : 10,
        spreadRadius: -2,
      ),
    ];
  }

  static const LinearGradient examButtonGradient = LinearGradient(
    colors: [blueStart, blueEnd],
  );

  static ({Color bg, Color border}) examCardColors(int index) {
    final style = examCardStyle(index);
    return (bg: style.background, border: style.border);
  }

  static const Color examSelectedBg = Color(0x99091C3F);
  static const Color examSelectedBorder = Color(0xFF0076F5);
  static const Color examCorrectBg = Color(0x9914532D);
  static const Color examCorrectBorder = Color(0xFF4ADE80);
  static const Color examWrongBg = Color(0x997F1D1D);
  static const Color examWrongBorder = Color(0xFFF87171);

  static List<BoxShadow> examCardIdleShadow(Color border) => examCardShadows(
        ExamCardStyle(
          background: border,
          border: border,
          glowOuter: border.withValues(alpha: 0.35),
          glowInner: border.withValues(alpha: 0.1),
          icon: border,
        ),
      );

  static List<BoxShadow> examCardGlow(Color color) => [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20),
      ];
}
