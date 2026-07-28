import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class GradientBorder extends StatelessWidget {
  const GradientBorder({
    super.key,
    required this.child,
    this.borderWidth = AppRadius.borderGradient,
    this.borderRadius = AppRadius.borderMd,
    this.gradient = AppGradients.borderGradientDefault,
    this.backgroundColor = AppColors.mainBg3,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.base,
      vertical: AppSpacing.sm,
    ),
  });

  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final Gradient gradient;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  BorderRadius _innerBorderRadius() {
    final radius = borderRadius.topLeft.x;
    if (radius >= AppRadius.full - 1) {
      return BorderRadius.circular(AppRadius.full);
    }
    return BorderRadius.lerp(
          borderRadius,
          BorderRadius.zero,
          borderWidth / radius,
        ) ??
        borderRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: _innerBorderRadius(),
        ),
        child: child,
      ),
    );
  }
}
