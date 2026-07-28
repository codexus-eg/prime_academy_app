import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class LuckCardsStatsBar extends StatelessWidget {
  const LuckCardsStatsBar({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.total,
  });

  final int correctCount;
  final int wrongCount;
  final int total;

  int get _remaining => total - (correctCount + wrongCount);
  double get _progress => total == 0 ? 0 : (correctCount + wrongCount) / total;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProgressBar(progress: _progress),
                const SizedBox(width: AppSpacing.base),
                _StatChip(
                  icon: Icons.check_rounded,
                  iconColor: const Color(0xFF34D399),
                  bgColor: const Color(0x3310B981),
                  count: correctCount,
                ),
                const SizedBox(width: AppSpacing.base),
                _StatChip(
                  icon: Icons.close_rounded,
                  iconColor: const Color(0xFFFB7185),
                  bgColor: const Color(0x33F43F5E),
                  count: wrongCount,
                ),
                if (_remaining > 0) ...[
                  const SizedBox(width: AppSpacing.base),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0x1AFFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_remaining',
                          style: AppTypography.bodySm.copyWith(
                            color: const Color(0x99FFFFFF),
                            fontWeight: AppFonts.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'متبقي',
                        style: AppTypography.bodySm.copyWith(
                          color: const Color(0x66FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animatedProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animatedProgress = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animatedProgress = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: 96,
      height: 6,
      child: AnimatedBuilder(
        animation: _animatedProgress,
        builder: (context, _) {
          final factor = _animatedProgress.value.clamp(0.0, 1.0);
          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x1AFFFFFF)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: factor,
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF3B82F6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.count,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: AppTypography.bodySm.copyWith(
            color: Colors.white,
            fontWeight: AppFonts.bold,
          ),
        ),
      ],
    );
  }
}
