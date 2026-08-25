import 'package:flutter/material.dart';

import '../../../core/theme/app_quiz_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/knowledge_quiz_question.dart';
import '../models/luck_card_question.dart';
import 'luck_answer_button.dart';
import 'luck_knowledge_essay_view.dart';
import 'luck_knowledge_fill_view.dart';
import 'luck_points_animation.dart';
import 'luck_quiz_timer.dart';

class LuckActiveQuestion extends StatefulWidget {
  const LuckActiveQuestion({
    super.key,
    required this.question,
    required this.deckIndex,
    required this.answered,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.onMcqAnswer,
    required this.onTextSubmit,
    required this.timerSeconds,
    required this.totalTimerSeconds,
    required this.onTimerStart,
    this.showTimer = true,
  });

  final KnowledgeQuizQuestion question;
  final int deckIndex;
  final bool answered;
  final int? selectedAnswer;
  final bool? isCorrect;
  final ValueChanged<int> onMcqAnswer;
  final ValueChanged<String> onTextSubmit;
  final int timerSeconds;
  final int totalTimerSeconds;
  final VoidCallback onTimerStart;
  final bool showTimer;

  @override
  State<LuckActiveQuestion> createState() => _LuckActiveQuestionState();
}

class _LuckActiveQuestionState extends State<LuckActiveQuestion> {
  var _showPoints = false;
  var _showQuestion = false;

  @override
  void initState() {
    super.initState();
    if (widget.question.points > 0) {
      _showPoints = true;
    } else {
      _showQuestion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onTimerStart());
    }
  }

  void _onPointsComplete() {
    setState(() {
      _showPoints = false;
      _showQuestion = true;
    });
    widget.onTimerStart();
  }

  LuckAnswerVisualState _visualState(KnowledgeMcqQuestion mcq, int index) {
    if (!widget.answered) return LuckAnswerVisualState.idle;
    final answerId = mcq.answers[index].id;
    if (mcq.correctAnswerIds.contains(answerId)) {
      return LuckAnswerVisualState.correct;
    }
    if (widget.selectedAnswer == index) return LuckAnswerVisualState.wrong;
    return LuckAnswerVisualState.dimmed;
  }

  Widget _buildQuestionCard(double cardWidth) {
    return Hero(
      tag: 'luck-card-${widget.deckIndex}',
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppQuizPalette.luckCardGradient,
              borderRadius: AppRadius.borderAnswerButton,
              boxShadow: AppShadows.knowledgeCardActive,
            ),
            child: Center(
              child: SingleChildScrollView(
                child: QuizHtmlText(
                  html: widget.question.title,
                  textAlign: TextAlign.center,
                  baseStyle: AppTypography.headingDialog.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                    fontSize: cardWidth < 260 ? 16 : 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerBody(double answersWidth, double answerCellSize) {
    return switch (widget.question) {
      KnowledgeMcqQuestion mcq => SizedBox(
          width: answersWidth,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: answerCellSize,
            ),
            itemCount: mcq.answers.length,
            itemBuilder: (context, index) {
              const palettes = [
                LuckAnswerPaletteSlot.pink,
                LuckAnswerPaletteSlot.blue,
                LuckAnswerPaletteSlot.violet,
                LuckAnswerPaletteSlot.orange,
              ];
              return LuckAnswerButton(
                option: LuckAnswerOption(
                  text: mcq.answers[index].title,
                  palette: palettes[index % palettes.length],
                ),
                index: index,
                state: _visualState(mcq, index),
                compact: answerCellSize < 120,
                onTap: widget.answered
                    ? null
                    : () => widget.onMcqAnswer(index),
              );
            },
          ),
        ),
      KnowledgeEssayQuestion essay => LuckKnowledgeEssayView(
          question: essay,
          answered: widget.answered,
          onSubmit: widget.onTextSubmit,
        ),
      KnowledgeFillBlankQuestion fill => SizedBox(
          width: answersWidth,
          child: LuckKnowledgeFillView(
            question: fill,
            answered: widget.answered,
            isCorrect: widget.isCorrect,
            onSubmit: widget.onTextSubmit,
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showPoints)
          LuckPointsAnimation(
            points: widget.question.points,
            onComplete: _onPointsComplete,
          ),
        if (_showQuestion) ...[
          const Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: AppQuizPalette.knowledgeScrim,
            ),
          ),
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 768;
                  final cardWidth = (constraints.maxWidth * 0.55)
                      .clamp(160.0, 440.0)
                      .toDouble();
                  final answersWidth =
                      (constraints.maxWidth - 32).clamp(0.0, 448.0);
                  final answerCellSize =
                      ((answersWidth - 16) / 2).clamp(72.0, 160.0);

                  final card = _buildQuestionCard(cardWidth);
                  final answers =
                      _buildAnswerBody(answersWidth, answerCellSize);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      AppSpacing.xxs,
                      AppSpacing.base,
                      AppSpacing.base,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LuckQuizTimer(
                            key: ValueKey('luck-timer-${widget.question.id}'),
                            seconds: widget.timerSeconds,
                            totalSeconds: widget.totalTimerSeconds,
                            visible: widget.showTimer && !widget.answered,
                            stopped: widget.answered,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (wide)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                card,
                                const SizedBox(width: AppSpacing.xxl),
                                Flexible(child: answers),
                              ],
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                card,
                                const SizedBox(height: AppSpacing.xxl),
                                SizedBox(
                                  width: double.infinity,
                                  child: answers,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
