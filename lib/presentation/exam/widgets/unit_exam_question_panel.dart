import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/quizzes/unit_quiz_question.dart';
import '../../classification_quiz/models/classification_question.dart';
import '../../classification_quiz/widgets/classification_fill_blank_view.dart';
import '../../classification_quiz/widgets/classification_matching_view.dart';
import '../models/unit_exam_mapper.dart';
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

  @override
  State<UnitExamQuestionPanel> createState() => _UnitExamQuestionPanelState();
}

class _UnitExamQuestionPanelState extends State<UnitExamQuestionPanel> {
  VoidCallback? _submitHandler;
  var _canSubmit = false;
  var _matchingDragActive = false;

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
      UnitMcqQuestion() => 8,
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
    }
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
                          ExamQuestionCard(
                            prompt: child.title,
                            visible: true,
                            progressPercentage: widget.progressPercent,
                          ),
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
                  ExamQuestionCard(
                    prompt: active.title,
                    visible: true,
                    progressPercentage: widget.progressPercent,
                  ),
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
          onSubmitReady: _registerSubmitHandler,
          onAnswerChange: _updateCanSubmit,
          onSubmit: (text) => submit(
                questionId: essay.id,
                type: 'essay',
                answers: [text],
              ),
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
                answers: {
                  for (var i = 0; i < order.length; i++) '$i': order[i],
                },
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
      onCorrectChange: (_) {},
      onAnswered: (text) => submit(
        questionId: fill.id,
        type: 'fill-blank',
        answers: [text],
      ),
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
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onSubmit,
  });

  final String questionTitle;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<String> onSubmit;

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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return ExamEssayInput(
      questionTitle: widget.questionTitle,
      controller: _controller,
      onAnswerChange: widget.onAnswerChange,
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
