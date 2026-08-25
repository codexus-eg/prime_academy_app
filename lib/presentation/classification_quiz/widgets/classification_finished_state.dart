import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../models/classification_level.dart';
import 'classification_char_glow.dart';

class ClassificationFinishedState extends StatefulWidget {
  const ClassificationFinishedState({
    super.key,
    required this.currentLevel,
    required this.onExit,
  });

  final ClassificationLevel currentLevel;
  final VoidCallback onExit;

  @override
  State<ClassificationFinishedState> createState() =>
      _ClassificationFinishedStateState();
}

class _ClassificationFinishedStateState
    extends State<ClassificationFinishedState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeFade;
  late final Animation<double> _characterFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _badgeFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeInOut),
    );
    _characterFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.17, 0.67, curve: Curves.easeInOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.83, curve: Curves.easeInOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageIndex = widget.currentLevel.imageIndex.clamp(
      0,
      ClassificationAssets.characterImages.length - 1,
    );
    final characterAsset = ClassificationAssets.characterImages[imageIndex];
    final width = MediaQuery.sizeOf(context).width;
    final maxCharacter = width >= 768 ? 400.0 : 375.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const reserved = 42 + 32 + 32 + 32 + 32 + 48;
              final characterSize = math.min(
                maxCharacter,
                math.min(constraints.maxWidth, constraints.maxHeight - reserved),
              ).clamp(120.0, maxCharacter);

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _badgeFade.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBg10,
                            borderRadius:
                                BorderRadius.circular(AppRadius.shadcnMd),
                            border: Border.all(
                              color: AppColors.accentBg.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Text(
                            'تصنيفك: ${widget.currentLevel.title}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.accentIconMuted,
                              fontWeight: AppFonts.semibold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Opacity(
                        opacity: _characterFade.value,
                        child: ClassificationCharGlow(
                          imageAsset: characterAsset,
                          maxSize: characterSize,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Opacity(
                        opacity: _titleFade.value,
                        child: Text(
                          'اكتملت المهمة',
                          textAlign: TextAlign.center,
                          style: AppTypography.size24.copyWith(
                            color: Colors.white,
                            fontWeight: AppFonts.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Opacity(
                        opacity: _buttonFade.value,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onExit,
                            borderRadius:
                                BorderRadius.circular(AppRadius.shadcnLg),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.shadcnLg,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'العودة للدرس',
                                    style: AppTypography.bodySm.copyWith(
                                      color: Colors.white,
                                      fontWeight: AppFonts.semibold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
