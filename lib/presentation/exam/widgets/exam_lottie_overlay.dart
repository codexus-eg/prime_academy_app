import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/exam_assets.dart';
import '../data/exam_celebration.dart';

class ExamLottieOverlay extends StatefulWidget {
  const ExamLottieOverlay({
    super.key,
    required this.trigger,
    required this.isCorrect,
    this.clearToken = 0,
    this.onAnimationComplete,
  });

  final int trigger;
  final bool isCorrect;

  /// When incremented, hide any in-flight Lottie immediately.
  final int clearToken;

  /// Called when the animation finishes or is hard-cleared.
  final VoidCallback? onAnimationComplete;

  @override
  State<ExamLottieOverlay> createState() => _ExamLottieOverlayState();
}

class _ExamLottieOverlayState extends State<ExamLottieOverlay>
    with SingleTickerProviderStateMixin {
  var _lastTrigger = 0;
  var _lastClearToken = 0;
  var _correctIndex = -1;
  var _incorrectIndex = -1;
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
    if (widget.clearToken != _lastClearToken) {
      _lastClearToken = widget.clearToken;
      _hardClear();
    }
    _maybePlay(widget.trigger, widget.isCorrect);
  }

  void _hardClear() {
    _hideTimer?.cancel();
    _hideScheduled = true;
    _enterController.stop();
    if (_visible && mounted) {
      setState(() {
        _visible = false;
        _asset = null;
      });
    } else {
      _visible = false;
      _asset = null;
    }
    widget.onAnimationComplete?.call();
  }

  void _maybePlay(int trigger, bool isCorrect) {
    if (trigger <= 0 || trigger == _lastTrigger) return;
    _lastTrigger = trigger;
    _hideScheduled = false;
    _hideTimer?.cancel();

    final pool =
        isCorrect ? ExamAssets.correctLottie : ExamAssets.incorrectLottie;
    // Avoid repeating the same animation consecutively (web pickRandom).
    if (isCorrect) {
      _correctIndex = _pickNext(pool.length, _correctIndex);
    } else {
      _incorrectIndex = _pickNext(pool.length, _incorrectIndex);
    }
    final index = isCorrect ? _correctIndex : _incorrectIndex;

    setState(() {
      _asset = pool[index];
      _visible = true;
    });
    _enterController.forward(from: 0);

    // Fallback only if the asset never loads. The real hide is scheduled
    // from onLoaded so we do not complete (and allow a question swap)
    // while the animation is still on screen.
    _hideTimer = Timer(
      ExamCelebration.lottieAutoStop + const Duration(seconds: 1),
      _finishAnimation,
    );
  }

  int _pickNext(int length, int lastIndex) {
    if (length <= 1) return 0;
    var next = lastIndex;
    do {
      next = math.Random().nextInt(length);
    } while (next == lastIndex);
    return next;
  }

  void _finishAnimation() {
    if (!mounted || _hideScheduled) return;
    _hideScheduled = true;
    _hideTimer?.cancel();
    setState(() => _visible = false);
    widget.onAnimationComplete?.call();
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
                // Prefer composition length, but never exceed web auto-stop.
                final capped = duration > Duration.zero &&
                        duration < ExamCelebration.lottieAutoStop
                    ? duration
                    : ExamCelebration.lottieAutoStop;
                _scheduleHide(capped);
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scheduleHide(ExamCelebration.lottieAutoStop);
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
