import 'package:flutter/material.dart';

abstract final class MemoryCardPalette {
  static const colors = [
    Color(0xFF2196C4),
    Color(0xFF7C3AED),
    Color(0xFF0E7490),
    Color(0xFFBE185D),
    Color(0xFFB45309),
    Color(0xFF065F46),
    Color(0xFF1D4ED8),
    Color(0xFF9F1239),
  ];

  static Color colorAt(int index) => colors[index % colors.length];
}
