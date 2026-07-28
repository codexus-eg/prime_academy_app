import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';

class ClassificationEmptyState extends StatefulWidget {
  const ClassificationEmptyState({super.key, required this.onExit});

  final VoidCallback onExit;

  @override
  State<ClassificationEmptyState> createState() =>
      _ClassificationEmptyStateState();
}

class _ClassificationEmptyStateState extends State<ClassificationEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceRotate;
  late final Animation<double> _entranceOpacity;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final curve = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _entranceRotate = Tween<double>(begin: -math.pi, end: 0.0).animate(curve);
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mainBg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrophy(),
                  const SizedBox(height: 48),
                  Text(
                    'لا توجد أسئلة بعد',
                    textAlign: TextAlign.center,
                    style: AppTypography.custom(
                      fontSize: 34,
                      fontWeight: AppFonts.extrabold,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildExitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrophy() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ..._buildParticles(),
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _entranceController]),
            builder: (context, child) {

              final t = _floatController.value;
              final floatY = _floatKeyframe(t);
              return Opacity(
                opacity: _entranceOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.rotate(
                    angle: _entranceRotate.value,
                    child: Transform.scale(
                      scale: _entranceScale.value.clamp(0.0, 1.2),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Image.asset(
              ClassificationAssets.trophyEmptyImage,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  double _floatKeyframe(double t) {

    const points = [0.0, -15.0, 0.0, -8.0, 0.0];
    final scaled = t * (points.length - 1);
    final i = scaled.floor().clamp(0, points.length - 2);
    final localT = scaled - i;
    return points[i] + (points[i + 1] - points[i]) * localT;
  }

  List<Widget> _buildParticles() {
    return List.generate(8, (i) {
      return _FloatingParticle(
        controller: _floatController,
        index: i,
      );
    });
  }

  Widget _buildExitButton() {
    return SizedBox(
      width: 260,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: widget.onExit,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'خروج',
                style: AppTypography.custom(
                  fontSize: 18,
                  fontWeight: AppFonts.semibold,
                  color: AppColors.onDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatelessWidget {
  const _FloatingParticle({required this.controller, required this.index});

  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {

        final phase = (controller.value + index * 0.125) % 1.0;
        final dx = math.sin(index.toDouble()) * 60 +
            (index.isEven ? 40 : -40);
        final dy = math.cos(index.toDouble()) * 60 +
            (index.isEven ? -30 : 30);

        final fade = math.sin(phase * math.pi);

        return Transform.translate(
          offset: Offset(dx * phase, dy * phase),
          child: Opacity(
            opacity: (fade * 0.6).clamp(0.0, 0.6),
            child: Transform.scale(
              scale: fade,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
