import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/answers_direction.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/quiz_models.dart';
import '../../../data/quizzes/unit_quiz_question.dart';
import '../../classification_quiz/models/classification_question.dart';
import '../../classification_quiz/widgets/classification_fill_blank_view.dart';
import '../../classification_quiz/widgets/classification_matching_view.dart';
import '../models/unit_exam_mapper.dart';
import 'exam_answer_result_card.dart';
import 'exam_essay_input.dart';
import 'exam_mcq_grid_view.dart';
import 'exam_question_card.dart';
import 'exam_passage_view.dart';
import 'exam_reorder_view.dart';
import 'exam_submit_button.dart';

typedef UnitExamSubmitCallback = void Function({
  required String questionId,
  required String type,
  required Object answers,
  bool? localCorrect,
});

class UnitExamQuestionPanel extends StatefulWidget {
  const UnitExamQuestionPanel({
    super.key,
    required this.question,
    required this.progressPercent,
    required this.questionReady,
    required this.onSubmit,
    this.passageChildIndex = -1,
    this.onPassageChildChanged,
    this.selectedMcqId,
    this.mcqSubmitted = false,
    this.onMcqSelect,
    this.onMarkPassageChild,
    this.onPassageComplete,
    /// Server grade for the active answer (`response.result.correct`).
    /// Used as the single source of truth for essay/fill UI + colors.
    this.gradedCorrect,
    /// Bumped when submit fails so the panel can re-enable input.
    this.gradeResetToken = 0,
  });

  final UnitQuizQuestion question;
  final int progressPercent;
  final bool questionReady;
  final UnitExamSubmitCallback onSubmit;
  final int passageChildIndex;
  final ValueChanged<int>? onPassageChildChanged;
  final int? selectedMcqId;
  final bool mcqSubmitted;
  final ValueChanged<int>? onMcqSelect;
  final ExamPassageMarkChild? onMarkPassageChild;
  final Future<void> Function()? onPassageComplete;
  final bool? gradedCorrect;
  final int gradeResetToken;

  @override
  State<UnitExamQuestionPanel> createState() => _UnitExamQuestionPanelState();
}

class _UnitExamQuestionPanelState extends State<UnitExamQuestionPanel> {
  VoidCallback? _submitHandler;
  var _canSubmit = false;
  var _matchingDragActive = false;
  bool? _revealedCorrect;
  List<String> _revealedAnswers = const [];
  var _revealedFillChars = false;
  var _awaitingGrade = false;
  List<String> _pendingRevealAnswers = const [];
  var _pendingRevealFillChars = false;

  UnitQuizQuestion get _activeQuestion {
    final q = widget.question;
    if (q is UnitPassageQuestion &&
        widget.passageChildIndex >= 0 &&
        widget.passageChildIndex < q.childQuestions.length) {
      return q.childQuestions[widget.passageChildIndex];
    }
    return q;
  }

  double _spacingAfterQuestion(UnitQuizQuestion q) {
    return switch (q) {
      UnitEssayQuestion() => 32,
      // Clear gap between question card and answer squares (web visual spacing).
      UnitMcqQuestion() => 24,
      _ => 48,
    };
  }

  bool get _needsSubmitButton {
    final q = _activeQuestion;
    if (q is UnitMcqQuestion) return q.allowMultipleAnswers;
    return q is UnitEssayQuestion ||
        q is UnitFillBlankQuestion ||
        q is UnitMatchingQuestion ||
        q is UnitReOrderQuestion;
  }

  @override
  void didUpdateWidget(covariant UnitExamQuestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.passageChildIndex != widget.passageChildIndex) {
      _submitHandler = null;
      _canSubmit = false;
      _matchingDragActive = false;
      _clearReveal();
      return;
    }
    if (oldWidget.gradeResetToken != widget.gradeResetToken) {
      _cancelAwaitingGrade();
    }
    if (oldWidget.gradedCorrect != widget.gradedCorrect) {
      _applyGradedCorrect(widget.gradedCorrect);
    }
  }

  void _clearReveal() {
    _revealedCorrect = null;
    _revealedAnswers = const [];
    _revealedFillChars = false;
    _awaitingGrade = false;
    _pendingRevealAnswers = const [];
    _pendingRevealFillChars = false;
  }

  void _applyGradedCorrect(bool? graded) {
    if (graded == null) {
      // Do not clear `_awaitingGrade` here — a null grade while awaiting means
      // the API has not returned yet (or a previous grade was reset).
      return;
    }
    if (!mounted) return;
    setState(() {
      _revealedCorrect = graded;
      _revealedAnswers = _pendingRevealAnswers;
      _revealedFillChars = _pendingRevealFillChars;
      _awaitingGrade = false;
    });
  }

  void _cancelAwaitingGrade() {
    if (!_awaitingGrade && _revealedCorrect == null) return;
    setState(_clearReveal);
  }

  List<String> _plainAnswers(Iterable<dynamic> answers) {
    return answers
        .map((a) => QuizHtmlText.plainText((a as QuizMcqAnswer).title).trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _beginAwaitingGrade({
    required List<String> answers,
    required bool fillChars,
  }) {
    setState(() {
      _awaitingGrade = true;
      _pendingRevealAnswers = answers;
      _pendingRevealFillChars = fillChars;
      _revealedCorrect = null;
      _revealedAnswers = const [];
      _revealedFillChars = false;
    });
  }

  Widget _headerFor(UnitQuizQuestion question) {
    final revealed = _revealedCorrect;
    if (revealed != null && question is UnitEssayQuestion) {
      return ExamAnswerResultCard(
        key: ValueKey('result-${question.id}-$revealed'),
        isCorrect: revealed,
        answers: _revealedAnswers,
        answersDirection: question.answersDirection,
        showAsFillChars: false,
      );
    }
    // Web FillBlankQuestion: AnswerResultCard only when wrong.
    final showFillResult =
        revealed == false && question is UnitFillBlankQuestion;
    if (showFillResult) {
      return ExamAnswerResultCard(
        key: ValueKey('result-${question.id}-$revealed'),
        isCorrect: false,
        answers: _revealedAnswers,
        answersDirection: question.answersDirection,
        showAsFillChars: _revealedFillChars,
      );
    }
    return ExamQuestionCard(
      key: ValueKey('prompt-${question.id}'),
      prompt: question.title,
      visible: true,
      progressPercentage: widget.progressPercent,
    );
  }

  void _registerSubmitHandler(VoidCallback handler) {
    if (identical(_submitHandler, handler)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || identical(_submitHandler, handler)) return;
      setState(() => _submitHandler = handler);
    });
  }

  void _updateCanSubmit(bool value) {
    if (_canSubmit == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _canSubmit == value) return;
      setState(() => _canSubmit = value);
    });
  }

  void _setMatchingDragActive(bool active) {
    if (_matchingDragActive == active) return;
    setState(() => _matchingDragActive = active);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    if (q is UnitPassageQuestion &&
        q.childQuestions.isNotEmpty &&
        widget.onMarkPassageChild != null &&
        widget.onPassageComplete != null) {

      return LayoutBuilder(
        builder: (context, constraints) {
          final sm = MediaQuery.sizeOf(context).width >= 640;
          final shellHeight = constraints.maxHeight * (sm ? 0.85 : 0.81);
          return Column(
            children: [
              SizedBox(
                height: shellHeight,
                width: double.infinity,
                child: ExamPassageView(
                  question: q,
                  onChildIndexChange: widget.onPassageChildChanged ?? (_) {},
                  onMarkChild: widget.onMarkPassageChild!,
                  onPassageComplete: widget.onPassageComplete!,
                  questionBuilder: (child, markChild) {
                    return SingleChildScrollView(
                      physics: _matchingDragActive
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          _headerFor(child),
                          SizedBox(height: _spacingAfterQuestion(child)),
                          _buildQuestionBody(
                            child,
                            passageMarkChild: markChild,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_needsSubmitButton) ...[
                const SizedBox(height: AppSpacing.sm),
                ExamSubmitButton(
                  active: _canSubmit,
                  onPressed: _submitHandler,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      );
    }

    final active = _activeQuestion;

    return Column(
      children: [
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              physics: _matchingDragActive
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _headerFor(active),
                  SizedBox(height: _spacingAfterQuestion(active)),
                  _buildQuestionBody(active),
                ],
              ),
            ),
          ),
        ),
        if (_needsSubmitButton) ...[
          const SizedBox(height: AppSpacing.sm),
          ExamSubmitButton(
            active: _canSubmit,
            onPressed: _submitHandler,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildQuestionBody(
    UnitQuizQuestion active, {
    ExamPassageMarkChild? passageMarkChild,
  }) {
    void submit({
      required String questionId,
      required String type,
      required Object answers,
      bool? localCorrect,
    }) {
      if (passageMarkChild != null) {
        passageMarkChild(
          questionId: questionId,
          type: type,
          answers: answers,
        );
        return;
      }
      widget.onSubmit(
        questionId: questionId,
        type: type,
        answers: answers,
        localCorrect: localCorrect,
      );
    }

    return switch (active) {
      UnitMcqQuestion mcq => _buildMcq(mcq, passageMarkChild: passageMarkChild),
      UnitEssayQuestion essay => _EssayView(
          key: ValueKey(essay.id),
          questionTitle: essay.title,
          answersDirection: essay.answersDirection,
          isSubmitted: _awaitingGrade || _revealedCorrect != null,
          isCorrect: _revealedCorrect,
          onSubmitReady: _registerSubmitHandler,
          onAnswerChange: _updateCanSubmit,
          onSubmit: (text) {
            _beginAwaitingGrade(
              answers: _plainAnswers(essay.correctAnswers),
              fillChars: false,
            );
            submit(
              questionId: essay.id,
              type: 'essay',
              answers: [text],
            );
          },
        ),
      UnitFillBlankQuestion fill => _buildFillBlank(fill, submit: submit),
      UnitMatchingQuestion match => _buildMatching(match, submit: submit),
      UnitReOrderQuestion reorder => ExamReOrderView(
          key: ValueKey(reorder.id),
          question: reorder,
          onDragActiveChanged: _setMatchingDragActive,
          onSubmitReady: _registerSubmitHandler,
          onAnswerChange: _updateCanSubmit,
          onSubmit: (order) => submit(
                questionId: reorder.id,
                type: 're-order',
                answers: order,
              ),
        ),
      UnitPassageQuestion passage => Center(
          child: Text(
            passage.childQuestions.isEmpty
                ? 'اضغط «التالي» للمتابعة'
                : 'اختر سؤالاً من القائمة',
            style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
          ),
        ),
    };
  }

  Widget _buildMcq(
    UnitMcqQuestion mcq, {
    ExamPassageMarkChild? passageMarkChild,
  }) {
    if (mcq.allowMultipleAnswers) {
      return _MultiMcqView(
        key: ValueKey(mcq.id),
        question: mcq,
        ready: widget.questionReady,
        onSubmitReady: _registerSubmitHandler,
        onAnswerChange: _updateCanSubmit,
        onSubmit: (ids) {
          if (passageMarkChild != null) {
            passageMarkChild(
              questionId: mcq.id,
              type: 'mcq',
              answers: ids,
            );
            return;
          }
          widget.onSubmit(
            questionId: mcq.id,
            type: 'mcq',
            answers: ids,
          );
        },
      );
    }

    void onSelect(int id) {
      if (passageMarkChild != null) {
        passageMarkChild(
          questionId: mcq.id,
          type: 'mcq',
          answers: [id],
        );
        return;
      }
      widget.onMcqSelect?.call(id);
    }

    return ExamMcqGridView(
      question: mcq,
      selectedId: widget.selectedMcqId,
      isSubmitted: widget.mcqSubmitted,
      ready: widget.questionReady,
      onSelect: onSelect,
      expandSquares: passageMarkChild != null,
    );
  }

  Widget _buildFillBlank(
    UnitFillBlankQuestion fill, {
    required void Function({
      required String questionId,
      required String type,
      required Object answers,
      bool? localCorrect,
    }) submit,
  }) {
    final mapped = UnitExamMapper.toClassificationQuestion(fill);
    if (mapped is! ClassificationFillBlankQuestion) {
      return const SizedBox.shrink();
    }
    return ClassificationFillBlankView(
      key: ValueKey(fill.id),
      question: mapped,
      hideTitle: true,
      examStyle: true,
      onSubmitReady: _registerSubmitHandler,
      onAnswerChange: _updateCanSubmit,
      onCorrectChange: (_) {
        // Result-card / unified grade comes from API `gradedCorrect`.
      },
      onAnswered: (text) {
        _beginAwaitingGrade(
          answers: _plainAnswers(fill.correctAnswers),
          fillChars: true,
        );
        submit(
          questionId: fill.id,
          type: 'fill-blank',
          answers: [text],
        );
      },
    );
  }

  Widget _buildMatching(
    UnitMatchingQuestion match, {
    required void Function({
      required String questionId,
      required String type,
      required Object answers,
      bool? localCorrect,
    }) submit,
  }) {
    final mapped = UnitExamMapper.toClassificationQuestion(match);
    if (mapped is! ClassificationMatchingQuestion) {
      return const SizedBox.shrink();
    }
    return ClassificationMatchingView(
      key: ValueKey(match.id),
      question: mapped,
      hideTitle: true,
      examStyle: true,
      onDragActiveChanged: _setMatchingDragActive,
      onSubmitReady: _registerSubmitHandler,
      onAnswerChange: _updateCanSubmit,
      onCorrectChange: (_) {},
      onAnswered: (map) => submit(
        questionId: match.id,
        type: 'match',
        answers: {
          for (final entry in map.entries) '${entry.key}': entry.value,
        },
      ),
    );
  }
}

class _EssayView extends StatefulWidget {
  const _EssayView({
    super.key,
    required this.questionTitle,
    required this.answersDirection,
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onSubmit,
    this.isSubmitted = false,
    this.isCorrect,
  });

  final String questionTitle;
  final AnswersDirection answersDirection;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<String> onSubmit;
  final bool isSubmitted;
  final bool? isCorrect;

  @override
  State<_EssayView> createState() => _EssayViewState();
}

class _EssayViewState extends State<_EssayView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.onSubmitReady(_submit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitted) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  void didUpdateWidget(covariant _EssayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSubmitted && !oldWidget.isSubmitted) {
      widget.onAnswerChange(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExamEssayInput(
      questionTitle: widget.questionTitle,
      answersDirection: widget.answersDirection,
      controller: _controller,
      onAnswerChange: widget.onAnswerChange,
      isSubmitted: widget.isSubmitted,
      isCorrect: widget.isCorrect,
    );
  }
}

class _MultiMcqView extends StatefulWidget {
  const _MultiMcqView({
    super.key,
    required this.question,
    required this.ready,
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onSubmit,
  });

  final UnitMcqQuestion question;
  final bool ready;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<List<int>> onSubmit;

  @override
  State<_MultiMcqView> createState() => _MultiMcqViewState();
}

class _MultiMcqViewState extends State<_MultiMcqView> {
  final _selected = <int>{};

  @override
  void initState() {
    super.initState();
    widget.onSubmitReady(_submit);
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onAnswerChange(_selected.isNotEmpty);
  }

  void _submit() {
    if (_selected.isEmpty) return;
    widget.onSubmit(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'اختر كل الاجابات الصحيحة',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.tabInactive,
              fontWeight: AppFonts.semibold,
            ),
          ),
        ),
        ExamMcqGridView(
          question: widget.question,
          selectedIds: _selected,
          isMulti: true,
          isSubmitted: false,
          ready: widget.ready,
          onSelect: _toggle,
        ),
      ],
    );
  }
}
