import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_quiz_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../models/exam_question.dart';

enum ExamAnswerState { idle, selected, correct, wrong }

class ExamAnswerOptionButton extends StatefulWidget {
  const ExamAnswerOptionButton({
    super.key,
    required this.option,
    required this.index,
    required this.state,
    required this.shouldShow,
    required this.onTap,
    this.animateEntrance = true,
    this.cardHeight = 150,
  });

  final ExamAnswerOption option;
  final int index;
  final ExamAnswerState state;
  final bool shouldShow;
  final VoidCallback? onTap;
  final bool animateEntrance;
  final double cardHeight;

  @override
  State<ExamAnswerOptionButton> createState() => _ExamAnswerOptionButtonState();
}

class _ExamAnswerOptionButtonState extends State<ExamAnswerOptionButton>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _shakeController;
  late final Animation<double> _enterOpacity;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterY;
  late final Animation<double> _shakeX;
  var _hovered = false;

  static const _cardRadius = AppRadius.tailwindXl;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final curve = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _enterOpacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _enterScale = Tween<double>(begin: 0.8, end: 1).animate(curve);
    _enterY = Tween<double>(begin: 20, end: 0).animate(curve);
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: -1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    if (widget.animateEntrance) {
      Future.delayed(Duration(milliseconds: widget.index * 80), () {
        if (mounted) _enterController.forward();
      });
    } else {
      _enterController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ExamAnswerOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ExamAnswerState.wrong &&
        oldWidget.state != ExamAnswerState.wrong) {
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0);
    }
    if (widget.state == ExamAnswerState.correct &&
        oldWidget.state != ExamAnswerState.correct) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  ExamCardStyle _styleForState() {
    return switch (widget.state) {
      ExamAnswerState.correct => AppQuizPalette.examCorrectStyle,
      ExamAnswerState.wrong => AppQuizPalette.examWrongStyle,
      ExamAnswerState.selected => AppQuizPalette.examSelectedStyle,
      ExamAnswerState.idle => AppQuizPalette.examCardStyle(widget.index),
    };
  }

  Widget _buildTitle(String displayTitle) {
    return QuizHtmlText(
      html: displayTitle,
      textAlign: TextAlign.center,
      baseStyle: AppTypography.bodyLg.copyWith(
        color: AppColors.onDark,
        fontWeight: AppFonts.bold,
        height: 1.35,
        shadows: const [
          Shadow(
            color: Color(0x80000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForState();
    final width = MediaQuery.sizeOf(context).width;

    final isMobileLayout = width < 768;
    final rawTitle = widget.option.text.trim();
    final displayTitle = rawTitle
        .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
        .trim();
    final imageUrl = widget.option.imageUrl;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final showLetterBadge = width >= 640 && !hasImage;
    final letter = String.fromCharCode(65 + widget.index);
    final hoverScale =
        !isMobileLayout && _hovered && widget.onTap != null ? 1.03 : 1.0;
    final hoverLift =
        !isMobileLayout && _hovered && widget.onTap != null ? -4.0 : 0.0;
    final radius = BorderRadius.circular(_cardRadius);

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _shakeController]),
      builder: (context, child) {
        final visible = widget.shouldShow;
        return Opacity(
          opacity: visible ? _enterOpacity.value : 0,
          child: Transform.translate(
            offset: Offset(
              _shakeX.value,
              (isMobileLayout ? 0 : _enterY.value) * (visible ? 1 : 0) +
                  hoverLift,
            ),
            child: Transform.scale(
              scale: visible
                  ? (isMobileLayout ? 1.0 : _enterScale.value) * hoverScale
                  : (isMobileLayout ? 1.0 : 0.8),
              child: child,
            ),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          if (!isMobileLayout) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (!isMobileLayout) setState(() => _hovered = false);
        },
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: Ink(
              height: widget.cardHeight,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: radius,
                border: Border.all(color: style.border, width: 2),

                boxShadow: AppQuizPalette.examCardShadows(
                  style,
                  mobile: isMobileLayout,
                  hovered: _hovered && !isMobileLayout,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    if (hasImage)
                      Positioned.fill(
                        child: QuizAnswerImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),

                    if (!isMobileLayout) ...[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x0DFFFFFF),
                              Color(0x03FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: 0.25,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (showLetterBadge)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: style.icon,
                            shape: BoxShape.circle,
                            boxShadow: isMobileLayout
                                ? null
                                : [
                                    BoxShadow(
                                      color: style.icon.withValues(alpha: 0.9),
                                      blurRadius: 10,
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: AppTypography.badge.copyWith(
                              color: AppColors.onDark,
                              fontWeight: AppFonts.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    if (displayTitle.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.base,
                          showLetterBadge ? AppSpacing.xxl : AppSpacing.base,
                          AppSpacing.base,
                          AppSpacing.base,
                        ),
                        child: Center(child: _buildTitle(displayTitle)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
