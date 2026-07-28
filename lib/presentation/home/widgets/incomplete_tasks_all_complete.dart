import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'awards_empty_trophy.dart';

class IncompleteTasksAllComplete extends StatefulWidget {
  const IncompleteTasksAllComplete({super.key});

  @override
  State<IncompleteTasksAllComplete> createState() =>
      _IncompleteTasksAllCompleteState();
}

class _IncompleteTasksAllCompleteState extends State<IncompleteTasksAllComplete>
    with TickerProviderStateMixin {
  static const _yKeyframes = [0.0, -15.0, 0.0, -8.0, 0.0];
  static const _rotateKeyframes = [0.0, 8.0, -8.0, 5.0, 0.0];

  late final AnimationController _floatController;
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(_fade);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
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
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final y = _sample(_yKeyframes, _floatController.value);
                  final rotate = _sample(_rotateKeyframes, _floatController.value);
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: Transform.rotate(
                      angle: rotate * math.pi / 180,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageFiltered(

                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x33FACC15),
                              Color(0x1AF59E0B),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Image.asset(
                      AwardsEmptyTrophy.asset,
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration_rounded, color: AppColors.yellow, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'أحسنت!',
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: AppFonts.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Transform.flip(
                    flipX: true,
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: AppColors.yellow,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'لا يوجد مهمات غير مكتملة في هذه المادة',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
