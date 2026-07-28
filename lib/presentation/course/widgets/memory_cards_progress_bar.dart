import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class MemoryCardsProgressBar extends StatelessWidget {
  const MemoryCardsProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: progress.clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                if (value <= 0) return const SizedBox.shrink();

                return Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    heightFactor: 1,
                    child: const ColoredBox(
                      color: AppColors.memoryCardProgress,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
