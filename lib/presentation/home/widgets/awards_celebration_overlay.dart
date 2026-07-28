import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AwardsCelebrationOverlay extends StatefulWidget {
  const AwardsCelebrationOverlay({
    super.key,
    required this.visible,
  });

  final bool visible;

  static const asset = 'assets/animations/celebration-2.json';

  @override
  State<AwardsCelebrationOverlay> createState() =>
      _AwardsCelebrationOverlayState();
}

class _AwardsCelebrationOverlayState extends State<AwardsCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(_opacity);
    _slide = Tween<Offset>(
      begin: const Offset(0, 50),
      end: Offset.zero,
    ).animate(_opacity);

    if (widget.visible) {
      _show();
    }
  }

  @override
  void didUpdateWidget(covariant AwardsCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _show();
    } else if (!widget.visible && oldWidget.visible) {
      _hide();
    }
  }

  void _show() {
    _hideTimer?.cancel();
    _controller.forward(from: 0);
    _hideTimer = Timer(const Duration(seconds: 3), _hide);
  }

  void _hide() {
    if (!mounted) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context).shortestSide * 0.75;

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: Lottie.asset(
                AwardsCelebrationOverlay.asset,
                repeat: false,
                width: size,
                height: size,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
