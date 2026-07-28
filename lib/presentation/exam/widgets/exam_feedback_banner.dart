import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_typography.dart';

class ExamFeedbackBanner extends StatefulWidget {
  const ExamFeedbackBanner({
    super.key,
    required this.isCorrect,
  });

  final bool isCorrect;

  @override
  State<ExamFeedbackBanner> createState() => _ExamFeedbackBannerState();
}

class _ExamFeedbackBannerState extends State<ExamFeedbackBanner>
    with SingleTickerProviderStateMixin {
  static const _correctMessages = [
    ('إجابة صحيحة!', Icons.check_circle_rounded),
    ('ممتاز!', Icons.star_rounded),
    ('أحسنت!', Icons.thumb_up_rounded),
    ('رائع جداً!', Icons.emoji_events_rounded),
    ('إجابة مثالية!', Icons.favorite_rounded),
  ];

  static const _wrongMessages = [
    ('إجابة خاطئة!', Icons.close_rounded),
    ('حاول مرة أخرى!', Icons.sentiment_dissatisfied_rounded),
    ('للأسف خطأ!', Icons.sentiment_very_dissatisfied_rounded),
    ('ليست هذه المرة!', Icons.cancel_rounded),
    ('حظاً أوفر!', Icons.sentiment_dissatisfied_outlined),
  ];

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final (String, IconData) _message;

  @override
  void initState() {
    super.initState();
    final pool = widget.isCorrect ? _correctMessages : _wrongMessages;
    _message = pool[math.Random().nextInt(pool.length)];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
    Future.delayed(AppDurations.quizFeedbackHide, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;
    final accent = isCorrect ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slide,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB30A1128),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    offset: Offset(0, -8),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCorrect
                              ? [
                                  const Color(0x664ADE80),
                                  const Color(0x3316A34A),
                                ]
                              : [
                                  const Color(0x66F87171),
                                  const Color(0x33DC2626),
                                ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _message.$2,
                          color: accent,
                          size: 24,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _message.$1,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onDark,
                            fontWeight: AppFonts.bold,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 4,
                              ),
                            ],
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
