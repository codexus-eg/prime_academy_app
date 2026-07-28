import 'package:flutter/material.dart';

class ClassificationMatchingPalette {
  const ClassificationMatchingPalette({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;

  static const schemes = [
    ClassificationMatchingPalette(
      background: Color(0x40FF006E),
      border: Color(0xFFFF006E),
      text: Color(0xFFFFD6E7),
    ),
    ClassificationMatchingPalette(
      background: Color(0x40FFBE0B),
      border: Color(0xFFFFBE0B),
      text: Color(0xFFFFF3C4),
    ),
    ClassificationMatchingPalette(
      background: Color(0x403A86FF),
      border: Color(0xFF3A86FF),
      text: Color(0xFFDBEAFE),
    ),
    ClassificationMatchingPalette(
      background: Color(0x408338EC),
      border: Color(0xFF8338EC),
      text: Color(0xFFEDE9FE),
    ),
  ];

  static ClassificationMatchingPalette forIndex(int index) =>
      schemes[index % schemes.length];
}
