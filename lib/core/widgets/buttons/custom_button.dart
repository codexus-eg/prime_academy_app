import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import 'button_palette.dart';
import 'premium_interactive_surface.dart';

enum CustomButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  tonal,
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.iconTrailing = true,
    this.variant = CustomButtonVariant.primary,
    this.color,
    this.gradient,
    this.borderColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.height,
    this.width,
    this.enabled = true,
    this.semanticLabel,
    this.showGlow,
    this.textStyle,
    this.expand = false,
    this.customBorder,
  }) : assert(
          label != null || icon != null,
          'CustomButton requires a label and/or icon.',
        );

  const CustomButton.primary({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconTrailing = false,
    this.gradient,
    this.color,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.height = 56,
    this.width,
    this.enabled = true,
    this.semanticLabel,
    this.showGlow = true,
    this.textStyle,
    this.expand = true,
    this.customBorder,
    this.borderColor,
  })  : variant = CustomButtonVariant.primary,
        assert(label != null);

  const CustomButton.secondary({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconTrailing = false,
    this.color,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.height = 30,
    this.width,
    this.enabled = true,
    this.semanticLabel,
    this.showGlow = false,
    this.textStyle,
    this.expand = false,
    this.customBorder,
    this.gradient,
    this.borderColor,
  })  : variant = CustomButtonVariant.secondary,
        assert(label != null);

  const CustomButton.outlined({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconTrailing = false,
    this.borderColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.height = 50,
    this.width,
    this.enabled = true,
    this.semanticLabel,
    this.showGlow = false,
    this.textStyle,
    this.expand = false,
    this.customBorder,
    this.color,
    this.gradient,
  })  : variant = CustomButtonVariant.outlined,
        assert(label != null);

  const CustomButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.height = 40,
    this.width,
    this.enabled = true,
    this.semanticLabel,
    this.showGlow = false,
    this.padding,
    this.customBorder,
    this.label,
    this.iconTrailing = false,
    this.textStyle,
    this.expand = false,
    this.gradient,
    this.variant = CustomButtonVariant.outlined,
  }) : assert(icon != null);

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final bool iconTrailing;
  final CustomButtonVariant variant;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final bool enabled;
  final String? semanticLabel;
  final bool? showGlow;
  final TextStyle? textStyle;
  final bool expand;
  final ShapeBorder? customBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedRadius = borderRadius ?? _defaultRadius(variant);
    final resolvedBorder = customBorder ??
        (resolvedRadius == BorderRadius.circular(AppRadius.full)
            ? const StadiumBorder()
            : null);

    final decoration = _resolveDecoration(
      context: context,
      colorScheme: colorScheme,
      isDark: isDark,
    );

    final accent = ButtonPalette.resolveAccent(
      color: decoration.color ?? color,
      gradient: decoration.gradient ?? gradient,
      colorScheme: colorScheme,
    );

    final fg = ButtonPalette.resolveForeground(
      foregroundColor: foregroundColor,
      backgroundColor: decoration.color ?? color,
      gradient: decoration.gradient ?? gradient,
      colorScheme: colorScheme,
    );

    final effectiveGlow = showGlow ?? variant == CustomButtonVariant.primary;

    final content = _ButtonContent(
      label: label,
      icon: icon,
      iconTrailing: iconTrailing,
      foregroundColor: enabled ? fg : fg.withValues(alpha: 0.4),
      textStyle: textStyle ?? _defaultTextStyle(variant),
      padding: padding ?? _resolvePadding(variant),
    );

    final child = Ink(
      decoration: decoration,
      child: SizedBox(
        width: expand ? double.infinity : width,
        height: height,
        child: content,
      ),
    );

    final surface = PremiumInteractiveSurface(
      onTap: enabled ? onPressed : null,
      enabled: enabled && onPressed != null,
      borderRadius: resolvedRadius,
      customBorder: resolvedBorder,
      accentColor: accent,
      showGlow: effectiveGlow,
      semanticLabel: semanticLabel ?? label,
      child: child,
    );

    if (!expand && width == null) {
      return IntrinsicWidth(child: surface);
    }
    return surface;
  }

  BoxDecoration _resolveDecoration({
    required BuildContext context,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    switch (variant) {
      case CustomButtonVariant.primary:
        return BoxDecoration(
          gradient: gradient ??
              (color == null
                  ? AppGradients.primaryButton(
                      primary: colorScheme.primary,
                      end: isDark
                          ? AppTheme.loginGradientEnd
                          : colorScheme.primary.withValues(alpha: 0.85),
                    )
                  : null),
          color: gradient == null ? (color ?? colorScheme.primary) : null,
          borderRadius: borderRadius ?? _defaultRadius(variant),
        );
      case CustomButtonVariant.secondary:
        return BoxDecoration(
          color: color ??
              (isDark ? AppTheme.reportButtonFill : colorScheme.surfaceContainerHigh),
          borderRadius: borderRadius ?? _defaultRadius(variant),
        );
      case CustomButtonVariant.tonal:
        return BoxDecoration(
          color: color ?? colorScheme.secondaryContainer,
          borderRadius: borderRadius ?? _defaultRadius(variant),
        );
      case CustomButtonVariant.outlined:
        return BoxDecoration(
          color: color ?? AppColors.transparent,
          gradient: gradient,
          borderRadius: borderRadius ?? _defaultRadius(variant),
          border: Border.all(
            color: borderColor ?? colorScheme.outline,
            width: 1.1,
          ),
        );
      case CustomButtonVariant.text:
        return BoxDecoration(
          color: AppColors.transparent,
          borderRadius: borderRadius ?? _defaultRadius(variant),
        );
    }
  }

  static BorderRadius _defaultRadius(CustomButtonVariant variant) {
    return switch (variant) {
      CustomButtonVariant.outlined => BorderRadius.circular(AppRadius.full),
      CustomButtonVariant.primary => AppRadius.borderReportChip,
      CustomButtonVariant.secondary => AppRadius.borderReportChip,
      CustomButtonVariant.tonal => AppRadius.borderMd,
      CustomButtonVariant.text => AppRadius.borderMd,
    };
  }

  EdgeInsetsGeometry _resolvePadding(CustomButtonVariant variant) {
    if (icon != null && label == null) {
      return EdgeInsets.zero;
    }
    return _defaultPadding(variant);
  }

  static EdgeInsetsGeometry _defaultPadding(CustomButtonVariant variant) {
    return switch (variant) {
      CustomButtonVariant.primary => const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      CustomButtonVariant.secondary =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      CustomButtonVariant.outlined =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      _ => const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
    };
  }

  static TextStyle _defaultTextStyle(CustomButtonVariant variant) {
    return switch (variant) {
      CustomButtonVariant.primary =>
        AppTypography.size20.copyWith(fontWeight: AppFonts.bold, height: 1.4),
      CustomButtonVariant.secondary => AppTypography.bodyLg.copyWith(
          fontWeight: AppFonts.medium,
          height: 1.5,
        ),
      CustomButtonVariant.outlined => AppTypography.bodyLg.copyWith(
          fontWeight: AppFonts.semibold,
          height: 1.5,
        ),
      _ => AppTypography.bodyLg.copyWith(
          fontWeight: AppFonts.medium,
          height: 1.5,
        ),
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.iconTrailing,
    required this.foregroundColor,
    required this.textStyle,
    required this.padding,
  });

  final String? label;
  final IconData? icon;
  final bool iconTrailing;
  final Color foregroundColor;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon == null
        ? null
        : Icon(icon, color: foregroundColor, size: _iconSize(label));

    final labelWidget = label == null
        ? null
        : Text(
            label!,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(color: foregroundColor),
          );

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconTrailing && iconWidget != null) ...[
            iconWidget,
            if (labelWidget != null) const SizedBox(width: AppSpacing.sm),
          ],
          if (labelWidget != null) labelWidget,
          if (iconTrailing && iconWidget != null) ...[
            if (labelWidget != null) const SizedBox(width: AppSpacing.sm),
            iconWidget,
          ],
        ],
      ),
    );
  }

  double _iconSize(String? label) => label == null ? 22 : 16;
}
