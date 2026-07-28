import 'package:flutter/material.dart';

import '../data/memory_card_palette.dart';

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.text,
    required this.answerText,
  });

  final int id;
  final String text;
  final String answerText;

  Color colorAt(int index) => MemoryCardPalette.colorAt(index);
}
