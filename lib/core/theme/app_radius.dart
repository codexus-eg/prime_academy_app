import 'package:flutter/material.dart';

abstract final class AppRadius {

  static const double base = 20;

  static const double xl = 26;

  static const double lg = 20;

  static const double md = 18;

  static const double sm = 16;

  static const double tailwindSm = 6;

  static const double shadcnMd = 6;

  static const double shadcnLg = 8;

  static const double tailwindXl = 12;

  static const double mdPlus = 14;

  static const double smPlus = 10;

  static const double xs = 4;

  static const double tailwind2xl = 16;

  static const double tailwind3xl = 24;

  static const double reportChip = 5;

  static const double answerButton = 16;

  static const double luckButton = 24;

  static const double coursePageTop = 64;

  static const double full = 999;

  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderAuthForm =
      BorderRadius.all(Radius.circular(tailwind2xl));
  static const BorderRadius borderAuthButton =
      BorderRadius.all(Radius.circular(shadcnMd));
  static const BorderRadius borderTabBar =
      BorderRadius.all(Radius.circular(shadcnLg));
  static const BorderRadius borderTabCell =
      BorderRadius.all(Radius.circular(shadcnLg));
  static const BorderRadius borderInput =
      BorderRadius.all(Radius.circular(shadcnMd));
  static const BorderRadius borderShadcnLg =
      BorderRadius.all(Radius.circular(shadcnLg));
  static const BorderRadius borderCard =
      BorderRadius.all(Radius.circular(tailwindXl));
  static const BorderRadius borderTailwindXl =
      BorderRadius.all(Radius.circular(tailwindXl));

  static const BorderRadius borderRankingCard =
      BorderRadius.all(Radius.circular(tailwind2xl));
  static const BorderRadius borderProfileCourse =
      BorderRadius.all(Radius.circular(tailwind3xl));

  static const double courseCtaPill = 40;

  static const BorderRadius borderCourseCta =
      BorderRadius.all(Radius.circular(courseCtaPill));
  static const BorderRadius borderReportChip =
      BorderRadius.all(Radius.circular(reportChip));
  static const BorderRadius borderAnswerButton =
      BorderRadius.all(Radius.circular(answerButton));
  static const BorderRadius borderLuckButton =
      BorderRadius.all(Radius.circular(luckButton));
  static const BorderRadius borderCoursePageTop = BorderRadius.only(
    topLeft: Radius.circular(coursePageTop),
    topRight: Radius.circular(coursePageTop),
  );

  static const double borderGradient = 2;

  static const double borderGradientThick = 1.3;

  static const double borderGradientHoverThick = 2.3;

  static const double borderForm = 2;

  static const double borderActive = 2;
}
