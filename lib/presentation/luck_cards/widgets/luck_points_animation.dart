import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_quiz_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'knowledge_quiz_background.dart';

class LuckPointsAnimation extends StatefulWidget {
  const LuckPointsAnimation({
    super.key,
    required this.points,
    required this.onComplete,
  });

  final int points;
  final VoidCallback onComplete;

  @override
  State<LuckPointsAnimation> createState() => _LuckPointsAnimationState();
}

class _LuckPointsAnimationState extends State<LuckPointsAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _textController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
        child: Stack(
          fit: StackFit.expand,
          children: [

            const KnowledgeQuizBackground(),
            AbsorbPointer(
              child: Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1).animate(
                    CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textController,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.borderTailwindXl,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppQuizPalette.pointsOverlayFill,
                                  borderRadius: AppRadius.borderTailwindXl,
                                  border: Border.all(
                                    color: AppQuizPalette.pointsOverlayBorder,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text(
                                        'الإجابة الصحيحة ستمنحك',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyLg.copyWith(
                                          color: AppQuizPalette.pointsLabel,
                                          fontWeight: AppFonts.regular,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.points} نقطة',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppQuizPalette.pointsValue,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _DismissProgressBar(controller: _progressController),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissProgressBar extends StatelessWidget {
  const _DismissProgressBar({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 192,
      height: 4,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value.clamp(0.001, 1.0);
          return Transform.scale(
            scaleX: t,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: AppQuizPalette.pointsProgressTrack),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppQuizPalette.pointsProgressFill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
