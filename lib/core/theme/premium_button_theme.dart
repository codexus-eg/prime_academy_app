import 'package:flutter/material.dart';

import '../widgets/buttons/button_palette.dart';
import '../widgets/buttons/premium_button_motion_wrapper.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'premium_button_animation_theme.dart';

abstract final class PremiumButtonTheme {
  static ThemeData apply(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final accent = colorScheme.primary;

    final splash = ButtonPalette.rippleSplash(accent, brightness: brightness);
    final highlight =
        ButtonPalette.rippleHighlight(accent, brightness: brightness);

  final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.borderInput,
    );

    ButtonStyle baseStyle({
      Color? background,
      Color? foreground,
      Color? border,
      EdgeInsetsGeometry? padding,
      double? elevation,
    }) {
      return ButtonStyle(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 2;
          return elevation ?? 0;
        }),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.25),
        ),
        animationDuration: PremiumButtonAnimationTheme.standard.containerDuration,
        padding: WidgetStatePropertyAll(
          padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(shape),
        textStyle: WidgetStatePropertyAll(AppTypography.buttonLg),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return (foreground ?? colorScheme.onPrimary)
                .withValues(alpha: 0.38);
          }
          return foreground ?? colorScheme.onPrimary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (background == null) return null;
          if (states.contains(WidgetState.disabled)) {
            return background.withValues(alpha: 0.35);
          }
          if (states.contains(WidgetState.pressed)) {
            return Color.alphaBlend(
              ButtonPalette.pressOverlay(background, brightness: brightness),
              background,
            );
          }
          if (states.contains(WidgetState.hovered)) {
            return Color.alphaBlend(
              highlight,
              background,
            );
          }
          return background;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return splash;
          if (states.contains(WidgetState.hovered)) return highlight;
          return splash.withValues(alpha: splash.a * 0.5);
        }),
        side: border == null
            ? null
            : WidgetStateProperty.resolveWith((states) {
                final base = border;
                if (states.contains(WidgetState.disabled)) {
                  return BorderSide(
                    color: base.withValues(alpha: 0.35),
                    width: 1.1,
                  );
                }
                return BorderSide(color: base, width: 1.1);
              }),
      );
    }

    return theme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseStyle(
          background: colorScheme.primary,
          foreground: colorScheme.onPrimary,
          elevation: 1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: baseStyle(
          background: colorScheme.primary,
          foreground: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseStyle(
          background: Colors.transparent,
          foreground: colorScheme.onSurface,
          border: colorScheme.outline,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseStyle(
          background: Colors.transparent,
          foreground: colorScheme.onSurface.withValues(alpha: 0.85),
          padding: EdgeInsets.zero,
        ).copyWith(
          minimumSize: const WidgetStatePropertyAll(Size.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return splash;
            if (states.contains(WidgetState.hovered)) return highlight;
            return null;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
        ),
      ),
    );
  }
}

class PremiumElevatedButton extends StatelessWidget {
  const PremiumElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.showGlow = true,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showGlow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _PremiumMaterialButtonShell(
      onPressed: onPressed,
      style: style ?? Theme.of(context).elevatedButtonTheme.style,
      showGlow: showGlow,
      semanticLabel: semanticLabel,
      child: child,
      materialBuilder: (child) => ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class PremiumFilledButton extends StatelessWidget {
  const PremiumFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.showGlow = true,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showGlow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _PremiumMaterialButtonShell(
      onPressed: onPressed,
      style: style ?? Theme.of(context).filledButtonTheme.style,
      showGlow: showGlow,
      semanticLabel: semanticLabel,
      child: child,
      materialBuilder: (child) => FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class PremiumOutlinedButton extends StatelessWidget {
  const PremiumOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _PremiumMaterialButtonShell(
      onPressed: onPressed,
      style: style ?? Theme.of(context).outlinedButtonTheme.style,
      showGlow: false,
      semanticLabel: semanticLabel,
      child: child,
      materialBuilder: (child) => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class PremiumTextButton extends StatelessWidget {
  const PremiumTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _PremiumMaterialButtonShell(
      onPressed: onPressed,
      style: style ?? Theme.of(context).textButtonTheme.style,
      showGlow: false,
      semanticLabel: semanticLabel,
      child: child,
      materialBuilder: (child) => TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

class PremiumTextButtonIcon extends StatelessWidget {
  const PremiumTextButtonIcon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.style,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final ButtonStyle? style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PremiumTextButton(
      onPressed: onPressed,
      style: style,
      semanticLabel: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          label,
        ],
      ),
    );
  }
}

typedef _PremiumMaterialBuilder = Widget Function(Widget child);

class _PremiumMaterialButtonShell extends StatelessWidget {
  const _PremiumMaterialButtonShell({
    required this.onPressed,
    required this.child,
    required this.style,
    required this.showGlow,
    required this.materialBuilder,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showGlow;
  final String? semanticLabel;
  final _PremiumMaterialBuilder materialBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = <WidgetState>{
      if (onPressed == null) WidgetState.disabled,
    };

    final background = style?.backgroundColor?.resolve(states) ??
        theme.colorScheme.primary;
    final radius = _resolveRadius(style?.shape?.resolve(states));

    return PremiumButtonMotionWrapper(
      enabled: onPressed != null,
      accentColor: ButtonPalette.resolveAccent(
        color: background,
        colorScheme: theme.colorScheme,
      ),
      showGlow: showGlow,
      semanticLabel: semanticLabel,
      borderRadius: radius,
      child: materialBuilder(child),
    );
  }

  BorderRadius _resolveRadius(OutlinedBorder? shape) {
    if (shape is RoundedRectangleBorder) {
      final radius = shape.borderRadius.resolve(TextDirection.rtl);
      return BorderRadius.all(radius.topLeft);
    }
    return AppRadius.borderInput;
  }
}
