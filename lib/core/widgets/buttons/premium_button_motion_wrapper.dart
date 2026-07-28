import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/premium_button_animation_theme.dart';
import 'button_palette.dart';

class PremiumButtonMotionWrapper extends StatefulWidget {
  const PremiumButtonMotionWrapper({
    super.key,
    required this.child,
    required this.accentColor,
    this.enabled = true,
    this.showGlow = false,
    this.semanticLabel,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Widget child;
  final Color accentColor;
  final bool enabled;
  final bool showGlow;
  final String? semanticLabel;
  final BorderRadius borderRadius;

  @override
  State<PremiumButtonMotionWrapper> createState() =>
      _PremiumButtonMotionWrapperState();
}

class _PremiumButtonMotionWrapperState extends State<PremiumButtonMotionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _hovering = false;

  PremiumButtonAnimationTheme get _anim =>
      Theme.of(context).extension<PremiumButtonAnimationTheme>() ??
      PremiumButtonAnimationTheme.standard;

  bool get _supportsHover {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    const defaults = PremiumButtonAnimationTheme.standard;
    _scaleController = AnimationController(
      vsync: this,
      duration: defaults.pressDuration,
      reverseDuration: defaults.releaseDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: defaults.pressedScale).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: defaults.pressCurve,
        reverseCurve: defaults.releaseCurve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaleController
      ..duration = _anim.pressDuration
      ..reverseDuration = _anim.releaseDuration;
    _scaleAnimation = Tween<double>(begin: 1, end: _anim.pressedScale).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: _anim.pressCurve,
        reverseCurve: _anim.releaseCurve,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!widget.enabled || !_anim.enablePressScale) return;
    if (value) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowOpacity = _hovering && widget.showGlow
        ? _anim.hoverGlowOpacity
        : widget.showGlow
            ? _anim.restGlowOpacity
            : 0.0;

    Widget content = AnimatedContainer(
      duration: _anim.containerDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.enabled
            ? AppShadows.motionWrapperSurface(
                hovering: _hovering,
                glowOpacity: glowOpacity,
                accentGlow: ButtonPalette.glowColor(widget.accentColor),
                restShadowBlur: _anim.restShadowBlur,
                hoverShadowBlur: _anim.hoverShadowBlur,
              )
            : null,
      ),
      child: Listener(
        onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
        onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
        onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
        child: widget.child,
      ),
    );

    if (_anim.enablePressScale) {
      content = ScaleTransition(scale: _scaleAnimation, child: content);
    }

    if (_supportsHover && _anim.enableHoverEffects) {
      content = MouseRegion(
        onEnter: widget.enabled ? (_) => setState(() => _hovering = true) : null,
        onExit: widget.enabled ? (_) => setState(() => _hovering = false) : null,
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: content,
      );
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: content,
    );
  }
}
