import 'package:flutter/material.dart';

class ExamProgressBar extends StatefulWidget {
  const ExamProgressBar({
    super.key,
    required this.progressPercentage,
    this.compact = true,
  });

  final int progressPercentage;
  final bool compact;

  @override
  State<ExamProgressBar> createState() => _ExamProgressBarState();
}

class _ExamProgressBarState extends State<ExamProgressBar> {
  static const _fillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0050C8),
      Color(0xFF007BFF),
      Color(0xFF40B0FF),
    ],
    stops: [0, 0.6, 1],
  );

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progressPercentage.clamp(0, 100);
    final factor = (clamped / 100).clamp(0.0, 1.0);

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: widget.compact ? 6 : 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: factor),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * value,
                        height: widget.compact ? 6 : 8,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          gradient: _fillGradient,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.compact) return bar;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: bar,
    );
  }
}
