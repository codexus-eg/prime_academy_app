import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/luck_assets.dart';

class LuckKnowledgeLottieOverlay extends StatefulWidget {
  const LuckKnowledgeLottieOverlay({
    super.key,
    required this.trigger,
    required this.isCorrect,
    this.onAnimationComplete,
  });

  final int trigger;
  final bool isCorrect;
  final VoidCallback? onAnimationComplete;

  @override
  State<LuckKnowledgeLottieOverlay> createState() =>
      _LuckKnowledgeLottieOverlayState();
}

class _LuckKnowledgeLottieOverlayState extends State<LuckKnowledgeLottieOverlay>
    with SingleTickerProviderStateMixin {
  var _lastTrigger = 0;
  var _visible = false;
  late final AnimationController _enterController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _maybePlay(widget.trigger);
  }

  @override
  void didUpdateWidget(covariant LuckKnowledgeLottieOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay(widget.trigger);
  }

  void _finishAnimation() {
    if (!mounted) return;
    setState(() => _visible = false);
    widget.onAnimationComplete?.call();
  }

  void _maybePlay(int trigger) {
    if (trigger <= 0 || trigger == _lastTrigger) return;
    _lastTrigger = trigger;
    setState(() => _visible = true);
    _enterController.forward(from: 0);
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final width = math.min(MediaQuery.sizeOf(context).width * 0.6, 250.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height * 0.1),
            child: AnimatedBuilder(
              animation: _enterController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: SlideTransition(position: _slide, child: child),
                  ),
                );
              },
              child: Lottie.asset(
                widget.isCorrect
                    ? LuckAssets.correctLottie
                    : LuckAssets.incorrectLottie,
                repeat: false,
                width: width,
                height: width,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, _finishAnimation);
                },
                errorBuilder: (context, error, stackTrace) {
                  Future.delayed(const Duration(milliseconds: 1800), _finishAnimation);
                  return Icon(
                    widget.isCorrect
                        ? Icons.emoji_events_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    size: width * 0.6,
                    color: widget.isCorrect
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF87171),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
