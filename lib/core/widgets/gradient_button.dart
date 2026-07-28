import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = AppSpacing.buttonHeightLg,
    this.horizontalPadding = AppSpacing.buttonHorizontalLg,
    this.borderRadius = AppRadius.borderAuthButton,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double horizontalPadding;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final shadows =
        _pressed || _hovered ? AppShadows.buttonHover : AppShadows.buttonRest;
    final gradient = _hovered
        ? AppGradients.buttonGradientHover
        : AppGradients.buttonGradientDefault;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: AppShadows.backgroundGradientTransition,
          curve: Curves.easeInOut,
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppColors.accent.withValues(alpha: 0.5),
            borderRadius: widget.borderRadius,
            boxShadow: enabled ? shadows : null,
          ),
          transform: _pressed
              ? (Matrix4.identity()..scaleByDouble(0.95, 0.95, 1, 1))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onDark,
                  ),
                )
              : Text(
                  widget.label,
                  style: (widget.textStyle ?? AppTypography.buttonLg)
                      .copyWith(color: AppColors.onDark),
                ),
        ),
      ),
    );
  }
}
