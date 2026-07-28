import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/quizzes/unit_quiz_question.dart';
import '../models/exam_question.dart';
import 'exam_answer_option.dart';

class ExamMcqGridView extends StatelessWidget {
  const ExamMcqGridView({
    super.key,
    required this.question,
    required this.isSubmitted,
    required this.ready,
    required this.onSelect,
    this.selectedId,
    this.selectedIds = const {},
    this.isMulti = false,
  });

  final UnitMcqQuestion question;
  final int? selectedId;
  final Set<int> selectedIds;
  final bool isSubmitted;
  final bool ready;
  final bool isMulti;
  final ValueChanged<int> onSelect;

  int _crossAxisCount(BuildContext context) {
    final count = question.answers.length;
    final lg = MediaQuery.sizeOf(context).width >= 1024;
    if (count <= 2) return 2;
    if (count == 3) return lg ? 3 : 2;
    return lg ? 4 : 2;
  }

  double _cardHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1024 ? 270 : 150;
  }

  ExamAnswerState _stateFor(int answerId) {
    if (!isSubmitted) {
      final selected = isMulti
          ? selectedIds.contains(answerId)
          : selectedId == answerId;
      return selected ? ExamAnswerState.selected : ExamAnswerState.idle;
    }
    if (question.correctAnswerIds.contains(answerId)) {
      return ExamAnswerState.correct;
    }
    final picked = isMulti ? selectedIds.contains(answerId) : selectedId == answerId;
    if (picked) return ExamAnswerState.wrong;
    return ExamAnswerState.idle;
  }

  bool _shouldShow(int answerId) {
    if (!isSubmitted) return true;
    final isCorrect = question.correctAnswerIds.contains(answerId);
    final picked = isMulti ? selectedIds.contains(answerId) : selectedId == answerId;
    return isCorrect || (picked && !isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _crossAxisCount(context);
    final cardHeight = _cardHeight(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.base,
            mainAxisSpacing: AppSpacing.base,
            mainAxisExtent: cardHeight,
          ),
          itemCount: question.answers.length,
          itemBuilder: (context, index) {
            final answer = question.answers[index];
            final state = _stateFor(answer.id);
            final show = _shouldShow(answer.id);
            final disabled = isSubmitted && state == ExamAnswerState.idle;
            final displayTitle = answer.displayTitle;

            return ExamAnswerOptionButton(
              option: ExamAnswerOption(
                text: displayTitle.isNotEmpty ? displayTitle : answer.title,
                id: answer.id,
                imageUrl: answer.imageUrl,
              ),
              index: index,
              state: state,
              shouldShow: show,
              cardHeight: cardHeight,
              onTap: (!ready || disabled)
                  ? null
                  : () => onSelect(answer.id),
            );
          },
        ),
      ),
    );
  }
}
