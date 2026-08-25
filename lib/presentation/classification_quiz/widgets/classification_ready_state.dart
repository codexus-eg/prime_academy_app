import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../models/classification_level.dart';

class ClassificationReadyState extends StatefulWidget {
  const ClassificationReadyState({
    super.key,
    required this.currentLevel,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.onStart,
    this.isContinue = false,
  });

  final ClassificationLevel currentLevel;
  final int totalQuestions;
  final int answeredQuestions;
  final bool isContinue;
  final VoidCallback onStart;

  @override
  State<ClassificationReadyState> createState() =>
      _ClassificationReadyStateState();
}

class _ClassificationReadyStateState extends State<ClassificationReadyState>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFF2072E0);

  late final AnimationController _fadeController;
  late final AnimationController _floatController;
  late final Animation<double> _fade;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (widget.totalQuestions - widget.answeredQuestions).clamp(0, 999999);
    final isContinue =
        widget.isContinue || widget.answeredQuestions > 0;
    final progress = widget.totalQuestions == 0
        ? 0.0
        : widget.answeredQuestions / widget.totalQuestions;
    final imageIndex = widget.currentLevel.imageIndex.clamp(
      0,
      ClassificationAssets.characterImages.length - 1,
    );
    final characterAsset = ClassificationAssets.characterImages[imageIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LevelBadge(title: widget.currentLevel.title),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _floatY,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: child,
                      );
                    },
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 25,
                            offset: Offset(0, 12),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        characterAsset,
                        width: 224,
                        height: 224,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.mainBg3,
                      borderRadius: BorderRadius.circular(AppRadius.tailwind2xl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: SizedBox(
                            height: 8,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    widthFactor: progress.clamp(0.0, 1.0),
                                    heightFactor: 1,
                                    alignment: Alignment.centerRight,
                                    child: const ColoredBox(color: _accent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاوب الأسئلة واثبت نفسك',
                          textAlign: TextAlign.center,
                          style: AppTypography.size20.copyWith(
                            color: AppColors.onDark,
                            fontWeight: AppFonts.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: widget.onStart,
                            borderRadius:
                                BorderRadius.circular(AppRadius.shadcnMd),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.shadcnMd,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isContinue ? 'متابعة' : 'ابدأ',
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.onDark,
                                      fontWeight: AppFonts.semibold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '($remaining) سؤال',
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.onDark,
                                      fontWeight: AppFonts.semibold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Web ready-state pill: `rounded-full px-5 py-2.5` with accent glow + inset.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.title});

  final String title;

  static const _accent = Color(0xFF2072E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E2072E0),
            blurRadius: 24,
          ),
          BoxShadow(
            color: Color(0x142072E0),
            blurRadius: 12,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Text(
        'تصنيفك : $title',
        textAlign: TextAlign.center,
        style: AppTypography.bodySm.copyWith(
          color: Colors.white,
          fontWeight: AppFonts.semibold,
        ),
      ),
    );
  }
}
