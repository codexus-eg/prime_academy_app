import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/classification_assets.dart';

class ClassificationLottieOverlay extends StatefulWidget {
  const ClassificationLottieOverlay({
    super.key,
    required this.trigger,
    required this.isCorrect,
    this.onAnimationComplete,
  });

  final int trigger;
  final bool isCorrect;
  final VoidCallback? onAnimationComplete;

  @override
  State<ClassificationLottieOverlay> createState() =>
      _ClassificationLottieOverlayState();
}

class _ClassificationLottieOverlayState
    extends State<ClassificationLottieOverlay>
    with SingleTickerProviderStateMixin {
  var _lastTrigger = 0;
  var _correctIndex = 0;
  var _incorrectIndex = 0;
  String? _asset;
  var _visible = false;
  late final AnimationController _enterController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _maybePlay(widget.trigger, widget.isCorrect);
  }

  @override
  void didUpdateWidget(covariant ClassificationLottieOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay(widget.trigger, widget.isCorrect);
  }

  void _maybePlay(int trigger, bool isCorrect) {
    if (trigger <= 0 || trigger == _lastTrigger) return;
    _lastTrigger = trigger;

    final pool = isCorrect
        ? ClassificationAssets.correctLottie
        : ClassificationAssets.incorrectLottie;
    final index = isCorrect
        ? _correctIndex++ % pool.length
        : _incorrectIndex++ % pool.length;

    setState(() {
      _asset = pool[index];
      _visible = true;
    });
    _enterController.forward(from: 0);
  }

  void _finishAnimation() {
    if (!mounted) return;
    setState(() => _visible = false);
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _asset == null) return const SizedBox.shrink();

    final size = math.min(MediaQuery.sizeOf(context).shortestSide * 0.55, 280.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _enterController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Lottie.asset(
              _asset!,
              repeat: false,
              width: size,
              height: size,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                Future.delayed(composition.duration, _finishAnimation);
              },
              errorBuilder: (context, error, stackTrace) {
                Future.delayed(
                  Duration(milliseconds: widget.isCorrect ? 2000 : 1800),
                  _finishAnimation,
                );
                return Icon(
                  widget.isCorrect
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: size * 0.6,
                  color: widget.isCorrect
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFF87171),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
