import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../models/classification_question.dart';
import 'classification_mcq_card_style.dart';

class ClassificationMcqView extends StatefulWidget {
  const ClassificationMcqView({
    super.key,
    required this.question,
    required this.selectedId,
    required this.isSubmitted,
    required this.onSelect,
    this.hideTitle = false,
  });

  final ClassificationMcqQuestion question;
  final int? selectedId;
  final bool isSubmitted;
  final ValueChanged<int> onSelect;
  final bool hideTitle;

  @override
  State<ClassificationMcqView> createState() => _ClassificationMcqViewState();
}

class _ClassificationMcqViewState extends State<ClassificationMcqView> {
  var _ready = false;

  bool get _anyImage => widget.question.answers.any(
        (a) => a.imageUrl != null && a.imageUrl!.trim().isNotEmpty,
      );

  @override
  void initState() {
    super.initState();
    _armReady();
  }

  @override
  void didUpdateWidget(covariant ClassificationMcqView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _ready = false;
      _armReady();
    }
  }

  void _armReady() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.hideTitle)
            Padding(

              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.mainBg3,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: AppShadows.xl,
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: QuizHtmlText(
                  html: widget.question.title,
                  textAlign: TextAlign.center,
                  baseStyle: AppTypography.bodyLg.copyWith(
                    color: AppColors.onDark,
                    height: 1.625,
                  ),
                ),
              ),
            ),
          Padding(

            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _anyImage ? _buildImageGrid() : _buildTextList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextList() {
    return Padding(

      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < widget.question.answers.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            _buildTextAnswer(index),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.question.answers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => _buildImageAnswer(index),
      ),
    );
  }

  Widget _buildTextAnswer(int index) {
    final answer = widget.question.answers[index];
    final state = _stateFor(answer.id);
    final theme = ClassificationMcqOptionTheme.forIndex(index);
    final disabled =
        widget.isSubmitted && state == ClassificationMcqCardState.idle;
    final colors = ClassificationMcqCardColors.resolve(state, theme);

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: (!_ready || disabled) ? null : () => widget.onSelect(answer.id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [colors.gradientStart, colors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
            border: Border.all(color: colors.border, width: 2),
            boxShadow: ClassificationMcqCardStyle.cardShadow,
          ),

          child: Row(
            children: [
              _LetterBadge(
                label: String.fromCharCode(65 + index),
                fill: colors.badgeFill,
                textColor: colors.text,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuizHtmlText(
                  html: answer.title,
                  textAlign: TextAlign.right,
                  baseStyle: AppTypography.bodyLg.copyWith(
                    color: colors.text,
                    fontWeight: AppFonts.semibold,
                    height: 1.35,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusIcon(state: state, badgeColor: colors.statusBadge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageAnswer(int index) {
    final answer = widget.question.answers[index];
    final state = _stateFor(answer.id);
    final theme = ClassificationMcqOptionTheme.forIndex(index);
    final disabled =
        widget.isSubmitted && state == ClassificationMcqCardState.idle;
    final colors = ClassificationMcqCardColors.resolve(state, theme);
    final hasTitle = answer.title.trim().isNotEmpty;
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    final cardHeight = isWide ? 240.0 : 100.0;

    final overlay = switch (state) {
      ClassificationMcqCardState.correct => const Color(0x2610B981),
      ClassificationMcqCardState.wrong => const Color(0x26F43F5E),
      ClassificationMcqCardState.selected => const Color(0x26F59E0B),
      ClassificationMcqCardState.idle => Colors.transparent,
    };

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: (!_ready || disabled) ? null : () => widget.onSelect(answer.id),
        child: SizedBox(
          height: cardHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border, width: 2),
              boxShadow: ClassificationMcqCardStyle.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [

                  Positioned.fill(
                    child: QuizAnswerImage(
                      imageUrl: answer.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(child: ColoredBox(color: overlay)),
                  if (state == ClassificationMcqCardState.idle &&
                      !widget.isSubmitted)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _LetterBadge(
                        label: String.fromCharCode(65 + index),
                        fill: colors.badgeFill,
                        textColor: colors.text,
                        size: 24,
                      ),
                    ),
                  if (hasTitle)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xB3000000),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            answer.title.trim(),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: Colors.white,
                              fontWeight: AppFonts.semibold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state == ClassificationMcqCardState.correct ||
                      state == ClassificationMcqCardState.wrong ||
                      (state == ClassificationMcqCardState.selected &&
                          !widget.isSubmitted))
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _StatusIcon(
                        state: state,
                        badgeColor: colors.statusBadge,
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

  ClassificationMcqCardState _stateFor(int answerId) {
    if (!widget.isSubmitted) {
      return widget.selectedId == answerId
          ? ClassificationMcqCardState.selected
          : ClassificationMcqCardState.idle;
    }
    if (widget.question.correctAnswerIds.contains(answerId)) {
      return ClassificationMcqCardState.correct;
    }
    if (widget.selectedId == answerId) {
      return ClassificationMcqCardState.wrong;
    }
    return ClassificationMcqCardState.idle;
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({
    required this.label,
    required this.fill,
    required this.textColor,
    this.size = 40,
  });

  final String label;
  final Color fill;
  final Color textColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,

        borderRadius: BorderRadius.circular(AppRadius.tailwindSm),

        boxShadow: ClassificationMcqCardStyle.badgeShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.bodyLg.copyWith(
          color: textColor,
          fontWeight: AppFonts.bold,
          fontSize: size < 30 ? 12 : 18,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.state, required this.badgeColor});

  final ClassificationMcqCardState state;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: switch (state) {
        ClassificationMcqCardState.correct => _badge(
            const Color(0xFF10B981),
            Icons.check_rounded,
          ),
        ClassificationMcqCardState.wrong => _badge(
            const Color(0xFFF43F5E),
            Icons.close_rounded,
          ),
        ClassificationMcqCardState.selected => _badge(
            badgeColor,
            Icons.check_rounded,
          ),
        ClassificationMcqCardState.idle => Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      },
    );
  }

  Widget _badge(Color color, IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: ClassificationMcqCardStyle.cardShadow,
      ),
      child: Icon(icon, color: AppColors.onDark, size: 14),
    );
  }
}
