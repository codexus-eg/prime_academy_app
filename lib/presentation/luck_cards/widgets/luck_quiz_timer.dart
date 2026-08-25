import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Knowledge quiz countdown bar. Matches web `KnowledgeQuizTimer`:
/// linear shrink over [totalSeconds], gradient stages at 30s / 15s, freeze on stop.
class LuckQuizTimer extends StatefulWidget {
  const LuckQuizTimer({
    super.key,
    required this.seconds,
    required this.totalSeconds,
    required this.visible,
    this.stopped = false,
  });

  final int seconds;
  final int totalSeconds;
  final bool visible;
  final bool stopped;

  @override
  State<LuckQuizTimer> createState() => _LuckQuizTimerState();
}

class _LuckQuizTimerState extends State<LuckQuizTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds.clamp(1, 3600)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.stopped) return;
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant LuckQuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopped && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.stopped &&
        oldWidget.stopped &&
        !_controller.isAnimating &&
        _controller.value < 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Web: >30 `from-accent-gradient-from to-blue-500`,
  /// >15 `from-amber-400 to-orange-500`, else `from-rose-400 to-red-600`.
  (Color from, Color to) get _barColors {
    if (widget.seconds > 30) {
      return (AppColors.blue, const Color(0xFF3B82F6));
    }
    if (widget.seconds > 15) {
      return (const Color(0xFFFBBF24), const Color(0xFFF97316));
    }
    return (const Color(0xFFFB7185), const Color(0xFFDC2626));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _barColors;
    final urgent = widget.seconds <= 15;

    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colors.$1.withValues(alpha: urgent ? 0.7 : 0.45),
                blurRadius: urgent ? 14 : 10,
                spreadRadius: urgent ? 1 : 0.4,
              ),
              BoxShadow(
                color: colors.$2.withValues(alpha: urgent ? 0.4 : 0.22),
                blurRadius: urgent ? 18 : 12,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: double.infinity,
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0x1AFFFFFF)),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: (1 - _controller.value).clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [colors.$1, colors.$2],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
