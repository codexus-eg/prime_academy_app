import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/exam_assets.dart';

class ExamLottieOverlay extends StatefulWidget {
  const ExamLottieOverlay({
    super.key,
    required this.trigger,
    required this.isCorrect,
  });

  final int trigger;
  final bool isCorrect;

  @override
  State<ExamLottieOverlay> createState() => _ExamLottieOverlayState();
}

class _ExamLottieOverlayState extends State<ExamLottieOverlay>
    with SingleTickerProviderStateMixin {
  var _lastTrigger = 0;
  var _correctIndex = 0;
  var _incorrectIndex = 0;
  String? _asset;
  var _visible = false;
  var _hideScheduled = false;
  Timer? _hideTimer;
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
  void didUpdateWidget(covariant ExamLottieOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay(widget.trigger, widget.isCorrect);
  }

  void _maybePlay(int trigger, bool isCorrect) {
    if (trigger <= 0 || trigger == _lastTrigger) return;
    _lastTrigger = trigger;
    _hideScheduled = false;
    _hideTimer?.cancel();

    final pool =
        isCorrect ? ExamAssets.correctLottie : ExamAssets.incorrectLottie;
    final index = isCorrect
        ? _correctIndex++ % pool.length
        : _incorrectIndex++ % pool.length;

    setState(() {
      _asset = pool[index];
      _visible = true;
    });
    _enterController.forward(from: 0);

    _hideTimer = Timer(const Duration(milliseconds: 3500), _finishAnimation);
  }

  void _finishAnimation() {
    if (!mounted || _hideScheduled) return;
    _hideScheduled = true;
    _hideTimer?.cancel();
    setState(() => _visible = false);
  }

  void _scheduleHide(Duration delay) {
    if (_hideScheduled) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(delay, _finishAnimation);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _asset == null) return const SizedBox.shrink();

    final screen = MediaQuery.sizeOf(context);
    final size = math.min(
      math.min(screen.width * 0.8, 400.0),
      screen.height * 0.8,
    );

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
              key: ValueKey('${_asset}_$_lastTrigger'),
              repeat: false,
              width: size,
              height: size,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                final duration = composition.duration;
                _scheduleHide(
                  duration > Duration.zero
                      ? duration
                      : const Duration(milliseconds: 1800),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scheduleHide(
                    Duration(milliseconds: widget.isCorrect ? 2000 : 1800),
                  );
                });
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
