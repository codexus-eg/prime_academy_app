import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../models/classification_level.dart';
import 'classification_char_glow.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(_fade);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: FadeTransition(
          opacity: _fade,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg10,
                      borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
                      border: Border.all(
                        color: AppColors.accentBg.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Text(
                      'تصنيفك : ${widget.currentLevel.title}',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.accentIconMuted400,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ScaleTransition(
                    scale: _scale,
                    child: ClassificationCharGlow(
                      imageAsset: characterAsset,
                      maxSize: 224,
                      imageOffsetX: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
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
                                    child: const ColoredBox(
                                      color: AppColors.accentBg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          'جاوب الأسئلة واثبت نفسك',
                          textAlign: TextAlign.center,
                          style: AppTypography.size20.copyWith(
                            color: AppColors.onDark,
                            fontWeight: AppFonts.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                                color: AppColors.accentBg,
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
