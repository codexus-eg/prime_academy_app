import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

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
      duration: Duration(seconds: widget.totalSeconds),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.stopped) _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant LuckQuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopped && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _gradient {
    if (widget.seconds > 30) {
      return const LinearGradient(
        colors: [AppColors.blue, Color(0xFF3B82F6)],
      );
    }
    if (widget.seconds > 15) {
      return const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFFB7185), Color(0xFFDC2626)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
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
                        widthFactor: 1 - _controller.value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: _gradient),
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
    );
  }
}
