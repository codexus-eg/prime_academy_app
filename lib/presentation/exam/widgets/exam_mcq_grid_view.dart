import 'dart:math' as math;

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
    this.expandSquares = false,
  });

  final UnitMcqQuestion question;
  final int? selectedId;
  final Set<int> selectedIds;
  final bool isSubmitted;
  final bool ready;
  final bool isMulti;
  final ValueChanged<int> onSelect;

  /// Passage child questions: fill more of the width (still square).
  final bool expandSquares;

  /// Web `max-h-37.5` / `lg:max-h-67.5` (rem×16).
  static const _squareSm = 150.0;
  static const _squareLg = 270.0;
  static const _squarePassageMax = 240.0;

  int _crossAxisCount(double width) {
    final count = question.answers.length;
    final lg = width >= 1024;
    if (count <= 2) return 2;
    if (count == 3) return lg ? 3 : 2;
    return lg ? 4 : 2;
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
    final picked =
        isMulti ? selectedIds.contains(answerId) : selectedId == answerId;
    if (picked) return ExamAnswerState.wrong;
    return ExamAnswerState.idle;
  }

  bool _shouldShow(int answerId) {
    if (!isSubmitted) return true;
    final isCorrect = question.correctAnswerIds.contains(answerId);
    final picked =
        isMulti ? selectedIds.contains(answerId) : selectedId == answerId;
    return isCorrect || (picked && !isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: expandSquares ? AppSpacing.sm : AppSpacing.xxxl,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = MediaQuery.sizeOf(context).width;
            final cols = _crossAxisCount(width);
            final gap = AppSpacing.base;
            final maxSquare = expandSquares
                ? (width >= 1024 ? _squareLg : _squarePassageMax)
                : (width >= 1024 ? _squareLg : _squareSm);
            final fromWidth =
                (constraints.maxWidth - gap * (cols - 1)) / cols;
            final cellSize = math.min(fromWidth, maxSquare);
            final gridWidth = cellSize * cols + gap * (cols - 1);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: gridWidth,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    // Force square cells (width == height).
                    childAspectRatio: 1,
                  ),
                  itemCount: question.answers.length,
                  itemBuilder: (context, index) {
                    final answer = question.answers[index];
                    final state = _stateFor(answer.id);
                    final show = _shouldShow(answer.id);
                    final disabled =
                        isSubmitted && state == ExamAnswerState.idle;
                    final displayTitle = answer.displayTitle;

                    return AspectRatio(
                      aspectRatio: 1,
                      child: ExamAnswerOptionButton(
                        option: ExamAnswerOption(
                          text: displayTitle.isNotEmpty
                              ? displayTitle
                              : answer.title,
                          id: answer.id,
                          imageUrl: answer.imageUrl,
                        ),
                        index: index,
                        state: state,
                        shouldShow: show,
                        onTap: (!ready || disabled)
                            ? null
                            : () => onSelect(answer.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
