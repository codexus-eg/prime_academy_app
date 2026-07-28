import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/premium_button_animation_theme.dart';
import 'button_palette.dart';

class PremiumInteractiveSurface extends StatefulWidget {
  const PremiumInteractiveSurface({
    super.key,
    required this.onTap,
    required this.borderRadius,
    required this.accentColor,
    required this.child,
    this.enabled = true,
    this.showGlow = false,
    this.semanticLabel,
    this.tooltip,
    this.enablePressScale,
    this.enableHoverEffects,
    this.enablePrimaryGlow,
    this.customBorder,
    this.mouseCursor = SystemMouseCursors.click,
  });

  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final ShapeBorder? customBorder;
  final Color accentColor;
  final Widget child;
  final bool enabled;
  final bool showGlow;
  final String? semanticLabel;
  final String? tooltip;
  final bool? enablePressScale;
  final bool? enableHoverEffects;
  final bool? enablePrimaryGlow;
  final MouseCursor mouseCursor;

  @override
  State<PremiumInteractiveSurface> createState() =>
      _PremiumInteractiveSurfaceState();
}

class _PremiumInteractiveSurfaceState extends State<PremiumInteractiveSurface>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _hovering = false;
  bool _pressed = false;

  PremiumButtonAnimationTheme get _anim =>
      Theme.of(context).extension<PremiumButtonAnimationTheme>() ??
      PremiumButtonAnimationTheme.standard;

  bool get _pressScaleEnabled =>
      widget.enablePressScale ?? _anim.enablePressScale;

  bool get _hoverEnabled => widget.enableHoverEffects ?? _anim.enableHoverEffects;

  bool get _glowEnabled =>
      widget.showGlow && (widget.enablePrimaryGlow ?? _anim.enablePrimaryGlow);

  @override
  void initState() {
    super.initState();
    const defaults = PremiumButtonAnimationTheme.standard;
    _scaleController = AnimationController(
      vsync: this,
      duration: defaults.pressDuration,
      reverseDuration: defaults.releaseDuration,
    );
    _scaleAnimation = _buildScaleAnimation(defaults);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaleController
      ..duration = _anim.pressDuration
      ..reverseDuration = _anim.releaseDuration;
    _scaleAnimation = _buildScaleAnimation(_anim);
  }

  @override
  void didUpdateWidget(covariant PremiumInteractiveSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scaleAnimation = _buildScaleAnimation(_anim);
  }

  Animation<double> _buildScaleAnimation(PremiumButtonAnimationTheme anim) {
    return Tween<double>(begin: 1, end: anim.pressedScale).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: anim.pressCurve,
        reverseCurve: anim.releaseCurve,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!widget.enabled || !_pressScaleEnabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap?.call();
  }

  bool get _supportsHover {
    if (!_hoverEnabled) return false;
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = widget.accentColor;

    final glowOpacity = _hovering && _glowEnabled
        ? _anim.hoverGlowOpacity
        : _glowEnabled
            ? _anim.restGlowOpacity
            : 0.0;

    final elevation = _hovering && _supportsHover
        ? _anim.hoverElevation
        : _anim.restElevation;

    final shadows = AppShadows.interactiveSurface(
      hovering: _hovering && _supportsHover,
      glowOpacity: glowOpacity,
      accentGlow: ButtonPalette.glowColor(accent),
      restShadowBlur: _anim.restShadowBlur,
      hoverShadowBlur: _anim.hoverShadowBlur,
    );

    Widget surface = AnimatedContainer(
      duration: _anim.containerDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: widget.customBorder == null ? widget.borderRadius : null,
        boxShadow: widget.enabled ? shadows : null,
      ),
      child: Material(
        color: AppColors.transparent,
        elevation: widget.enabled ? elevation : 0,
        shadowColor: AppColors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? _handleTap : null,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
          onTapCancel: widget.enabled ? () => _setPressed(false) : null,
          borderRadius:
              widget.customBorder == null ? widget.borderRadius : null,
          customBorder: widget.customBorder,
          splashColor: ButtonPalette.rippleSplash(
            accent,
            brightness: brightness,
          ),
          highlightColor: ButtonPalette.rippleHighlight(
            accent,
            brightness: brightness,
          ),
          hoverColor: _supportsHover
              ? ButtonPalette.rippleHighlight(accent, brightness: brightness)
              : AppColors.transparent,
          mouseCursor: widget.enabled
              ? widget.mouseCursor
              : SystemMouseCursors.basic,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              if (_pressed && widget.enabled)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.customBorder == null
                          ? widget.borderRadius
                          : null,
                      color: ButtonPalette.pressOverlay(
                        accent,
                        brightness: brightness,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (_pressScaleEnabled) {
      surface = ScaleTransition(
        scale: _scaleAnimation,
        child: surface,
      );
    }

    if (_supportsHover) {
      surface = MouseRegion(
        onEnter: widget.enabled ? (_) => setState(() => _hovering = true) : null,
        onExit: widget.enabled ? (_) => setState(() => _hovering = false) : null,
        cursor: widget.enabled
            ? widget.mouseCursor
            : SystemMouseCursors.basic,
        child: surface,
      );
    }

    if (widget.tooltip != null) {
      surface = Tooltip(message: widget.tooltip!, child: surface);
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: surface,
    );
  }
}
