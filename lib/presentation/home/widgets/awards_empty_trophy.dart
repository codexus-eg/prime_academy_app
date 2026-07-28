import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class AwardsEmptyTrophy extends StatefulWidget {
  const AwardsEmptyTrophy({super.key});

  static const asset = 'assets/web/icons/trophy-2.png';

  @override
  State<AwardsEmptyTrophy> createState() => _AwardsEmptyTrophyState();
}

class _AwardsEmptyTrophyState extends State<AwardsEmptyTrophy>
    with SingleTickerProviderStateMixin {
  static const _yKeyframes = [0.0, -10.0, 0.0, -5.0, 0.0];
  static const _rotateKeyframes = [0.0, 5.0, -5.0, 3.0, 0.0];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _sample(List<double> values, double progress) {
    final scaled = progress * (values.length - 1);
    final index = scaled.floor().clamp(0, values.length - 2);
    final fraction = Curves.easeInOut.transform(scaled - index);
    return values[index] + (values[index + 1] - values[index]) * fraction;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final y = _sample(_yKeyframes, _controller.value);
        final rotate = _sample(_rotateKeyframes, _controller.value);

        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.rotate(
            angle: rotate * math.pi / 180,
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: 0.8,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 25,
                offset: Offset(0, 25),
              ),
            ],
          ),
          child: Image.asset(
            AwardsEmptyTrophy.asset,
            width: AppSpacing.awardsEmptyTrophySize,
            height: AppSpacing.awardsEmptyTrophySize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
