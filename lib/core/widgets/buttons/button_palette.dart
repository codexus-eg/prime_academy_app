import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

abstract final class ButtonPalette {

  static Color resolveAccent({
    Color? color,
    Gradient? gradient,
    required ColorScheme colorScheme,
  }) {
    if (gradient != null) {
      return _dominantGradientColor(gradient);
    }
    return color ?? colorScheme.primary;
  }

  static Color rippleSplash(Color accent, {required Brightness brightness}) {
    final alpha = brightness == Brightness.dark ? 0.22 : 0.16;
    return accent.withValues(alpha: alpha);
  }

  static Color rippleHighlight(Color accent, {required Brightness brightness}) {
    final alpha = brightness == Brightness.dark ? 0.10 : 0.08;
    return accent.withValues(alpha: alpha);
  }

  static Color pressOverlay(Color accent, {required Brightness brightness}) {
    if (brightness == Brightness.dark) {
      return AppColors.scrim80.withValues(alpha: 0.14);
    }
    return accent.withValues(alpha: 0.12);
  }

  static Color glowColor(Color accent) => accent.withValues(alpha: 0.45);

  static Color resolveForeground({
    Color? foregroundColor,
    Color? backgroundColor,
    Gradient? gradient,
    required ColorScheme colorScheme,
  }) {
    if (foregroundColor != null) return foregroundColor;

    final bg = backgroundColor ??
        (gradient != null ? _dominantGradientColor(gradient) : null);
    if (bg != null) {
      return bg.computeLuminance() > 0.55
          ? AppColors.scrim80.withValues(alpha: 0.87)
          : AppColors.onDark;
    }
    return colorScheme.onPrimary;
  }

  static Color _dominantGradientColor(Gradient gradient) {
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      if (gradient.colors.length == 1) return gradient.colors.first;
      return Color.lerp(gradient.colors.first, gradient.colors.last, 0.35)!;
    }
    if (gradient is RadialGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }
    if (gradient is SweepGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }
    return AppColors.loginGradientStart;
  }
}
