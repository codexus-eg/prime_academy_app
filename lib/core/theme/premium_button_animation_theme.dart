import 'package:flutter/material.dart';

@immutable
class PremiumButtonAnimationTheme extends ThemeExtension<PremiumButtonAnimationTheme> {
  const PremiumButtonAnimationTheme({
    this.pressDuration = const Duration(milliseconds: 120),
    this.releaseDuration = const Duration(milliseconds: 220),
    this.containerDuration = const Duration(milliseconds: 200),
    this.pressCurve = Curves.easeOutCubic,
    this.releaseCurve = Curves.easeOutBack,
    this.pressedScale = 0.97,
    this.hoverElevation = 3,
    this.restElevation = 0,
    this.hoverShadowBlur = 18,
    this.restShadowBlur = 8,
    this.hoverGlowOpacity = 0.35,
    this.restGlowOpacity = 0.18,
    this.enableHoverEffects = true,
    this.enablePressScale = true,
    this.enablePrimaryGlow = true,
  });

  final Duration pressDuration;
  final Duration releaseDuration;
  final Duration containerDuration;
  final Curve pressCurve;
  final Curve releaseCurve;
  final double pressedScale;
  final double hoverElevation;
  final double restElevation;
  final double hoverShadowBlur;
  final double restShadowBlur;
  final double hoverGlowOpacity;
  final double restGlowOpacity;
  final bool enableHoverEffects;
  final bool enablePressScale;
  final bool enablePrimaryGlow;

  static const PremiumButtonAnimationTheme standard =
      PremiumButtonAnimationTheme();

  @override
  PremiumButtonAnimationTheme copyWith({
    Duration? pressDuration,
    Duration? releaseDuration,
    Duration? containerDuration,
    Curve? pressCurve,
    Curve? releaseCurve,
    double? pressedScale,
    double? hoverElevation,
    double? restElevation,
    double? hoverShadowBlur,
    double? restShadowBlur,
    double? hoverGlowOpacity,
    double? restGlowOpacity,
    bool? enableHoverEffects,
    bool? enablePressScale,
    bool? enablePrimaryGlow,
  }) {
    return PremiumButtonAnimationTheme(
      pressDuration: pressDuration ?? this.pressDuration,
      releaseDuration: releaseDuration ?? this.releaseDuration,
      containerDuration: containerDuration ?? this.containerDuration,
      pressCurve: pressCurve ?? this.pressCurve,
      releaseCurve: releaseCurve ?? this.releaseCurve,
      pressedScale: pressedScale ?? this.pressedScale,
      hoverElevation: hoverElevation ?? this.hoverElevation,
      restElevation: restElevation ?? this.restElevation,
      hoverShadowBlur: hoverShadowBlur ?? this.hoverShadowBlur,
      restShadowBlur: restShadowBlur ?? this.restShadowBlur,
      hoverGlowOpacity: hoverGlowOpacity ?? this.hoverGlowOpacity,
      restGlowOpacity: restGlowOpacity ?? this.restGlowOpacity,
      enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
      enablePressScale: enablePressScale ?? this.enablePressScale,
      enablePrimaryGlow: enablePrimaryGlow ?? this.enablePrimaryGlow,
    );
  }

  @override
  PremiumButtonAnimationTheme lerp(
    covariant ThemeExtension<PremiumButtonAnimationTheme>? other,
    double t,
  ) {
    if (other is! PremiumButtonAnimationTheme) return this;
    return PremiumButtonAnimationTheme(
      pressedScale:
          lerpDouble(pressedScale, other.pressedScale, t) ?? pressedScale,
      hoverElevation:
          lerpDouble(hoverElevation, other.hoverElevation, t) ?? hoverElevation,
      restElevation:
          lerpDouble(restElevation, other.restElevation, t) ?? restElevation,
      hoverShadowBlur: lerpDouble(hoverShadowBlur, other.hoverShadowBlur, t) ??
          hoverShadowBlur,
      restShadowBlur:
          lerpDouble(restShadowBlur, other.restShadowBlur, t) ?? restShadowBlur,
      hoverGlowOpacity: lerpDouble(
            hoverGlowOpacity,
            other.hoverGlowOpacity,
            t,
          ) ??
          hoverGlowOpacity,
      restGlowOpacity:
          lerpDouble(restGlowOpacity, other.restGlowOpacity, t) ??
              restGlowOpacity,
    );
  }

  static double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
