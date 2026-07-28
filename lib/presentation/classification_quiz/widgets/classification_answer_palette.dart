import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ClassificationAnswerPalette {
  const ClassificationAnswerPalette({
    required this.gradientStart,
    required this.gradientEnd,
    required this.border,
    required this.text,
    required this.badge,
    required this.badgeFill,
    required this.selectedStart,
    required this.selectedEnd,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color border;
  final Color text;

  final Color badge;

  final Color badgeFill;
  final Color selectedStart;
  final Color selectedEnd;

  static const schemes = [

    ClassificationAnswerPalette(
      gradientStart: Color(0x333B82F6),
      gradientEnd: Color(0x332563EB),
      border: Color(0x803B82F6),
      text: AppColors.accentIconMuted300,
      badge: Color(0xFF3B82F6),
      badgeFill: Color(0x4D3B82F6),
      selectedStart: Color(0x4D3B82F6),
      selectedEnd: Color(0x4D2563EB),
    ),

    ClassificationAnswerPalette(
      gradientStart: Color(0x33A855F7),
      gradientEnd: Color(0x339333EA),
      border: Color(0x80A855F7),
      text: Color(0xFFD8B4FE),
      badge: Color(0xFFA855F7),
      badgeFill: Color(0x4DA855F7),
      selectedStart: Color(0x4DA855F7),
      selectedEnd: Color(0x4D9333EA),
    ),

    ClassificationAnswerPalette(
      gradientStart: Color(0x3310B981),
      gradientEnd: Color(0x33059669),
      border: Color(0x8010B981),
      text: Color(0xFF6EE7B7),
      badge: Color(0xFF10B981),
      badgeFill: Color(0x4D10B981),
      selectedStart: Color(0x4D10B981),
      selectedEnd: Color(0x4D059669),
    ),

    ClassificationAnswerPalette(
      gradientStart: Color(0x33F59E0B),
      gradientEnd: Color(0x33D97706),
      border: Color(0x80F59E0B),
      text: Color(0xFFFCD34D),
      badge: Color(0xFFF59E0B),
      badgeFill: Color(0x4DF59E0B),
      selectedStart: Color(0x4DF59E0B),
      selectedEnd: Color(0x4DD97706),
    ),

    ClassificationAnswerPalette(
      gradientStart: Color(0x33F43F5E),
      gradientEnd: Color(0x33E11D48),
      border: Color(0x80F43F5E),
      text: Color(0xFFFDA4AF),
      badge: Color(0xFFF43F5E),
      badgeFill: Color(0x4DF43F5E),
      selectedStart: Color(0x4DF43F5E),
      selectedEnd: Color(0x4DE11D48),
    ),

    ClassificationAnswerPalette(
      gradientStart: Color(0x3306B6D4),
      gradientEnd: Color(0x330891B2),
      border: Color(0x8006B6D4),
      text: Color(0xFF67E8F9),
      badge: Color(0xFF06B6D4),
      badgeFill: Color(0x4D06B6D4),
      selectedStart: Color(0x4D06B6D4),
      selectedEnd: Color(0x4D0891B2),
    ),
  ];

  static ClassificationAnswerPalette forIndex(int index) =>
      schemes[index % schemes.length];
}

enum ClassificationAnswerVisualState { idle, selected, correct, wrong }
