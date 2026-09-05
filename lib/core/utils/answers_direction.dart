import 'package:flutter/material.dart';

/// Admin-configured answer writing direction (`answers_direction` in API).
enum AnswersDirection {
  ltr,
  rtl,
}

AnswersDirection parseAnswersDirection(dynamic value) {
  final raw = value?.toString().trim().toLowerCase();
  if (raw == 'ltr') return AnswersDirection.ltr;
  return AnswersDirection.rtl;
}

extension AnswersDirectionLayout on AnswersDirection {
  TextDirection get textDirection =>
      this == AnswersDirection.ltr ? TextDirection.ltr : TextDirection.rtl;

  TextAlign get textAlign =>
      this == AnswersDirection.ltr ? TextAlign.left : TextAlign.right;
}
