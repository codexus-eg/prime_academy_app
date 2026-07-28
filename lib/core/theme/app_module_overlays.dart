import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppModuleOverlays {
  static const double glowBlurSigma = 63;

  static Color colorFor(CourseModuleOverlay overlay) => switch (overlay) {
        CourseModuleOverlay.none => AppColors.transparent,
        CourseModuleOverlay.blue => AppColors.blue,
        CourseModuleOverlay.purple => AppColors.purple,
        CourseModuleOverlay.cyan => AppColors.cyan,
        CourseModuleOverlay.yellow => AppColors.yellow,
        CourseModuleOverlay.olive => AppColors.olive,
        CourseModuleOverlay.green => AppColors.green,
      };

  static Color timelineDotFor(CourseModuleOverlay overlay) => switch (overlay) {
        CourseModuleOverlay.none => AppColors.blue,
        CourseModuleOverlay.olive => AppColors.olive,
        _ => colorFor(overlay),
      };

  static Widget glow({
    required CourseModuleOverlay overlay,
    required double width,
  }) {
    if (overlay == CourseModuleOverlay.none) {
      return const SizedBox.shrink();
    }

    final glowWidth = width * 0.8;
    return Positioned(
      left: -(width * 0.2),
      top: AppSpacing.courseModuleGlowTop,
      child: RepaintBoundary(
        child: Transform.translate(

          offset: Offset.zero,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: glowBlurSigma,
              sigmaY: glowBlurSigma,
              tileMode: TileMode.decal,
            ),
            child: ColoredBox(
              color: colorFor(overlay),
              child: SizedBox(
                width: glowWidth,
                height: AppSpacing.courseModuleGlowHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum CourseModuleOverlay {
  none,
  blue,
  purple,
  cyan,
  yellow,
  olive,
  green,
}
