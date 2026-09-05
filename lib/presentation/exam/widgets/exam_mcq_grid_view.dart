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

  /// Passage child questions: fill more of the width (still square for images).
  final bool expandSquares;

  /// Web `max-h-37.5` / `lg:max-h-67.5` (rem×16) — used as **minimum** for
  /// text answers; cells grow taller when the option text needs more lines.
  static const _squareSm = 150.0;
  static const _squareLg = 270.0;
  static const _squarePassageMax = 240.0;

  bool get _anyImage => question.answers.any(
        (a) => a.imageUrl != null && a.imageUrl!.trim().isNotEmpty,
      );

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
      child: LayoutBuilder(
        builder: (context, _) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          // Wide side gutters shrink cells on phones and force mid-word wraps.
          final horizontalPad = expandSquares
              ? AppSpacing.sm
              : screenWidth < 400
                  ? AppSpacing.base
                  : screenWidth < 768
                      ? AppSpacing.xl
                      : AppSpacing.xxxl;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = screenWidth;
                final cols = _crossAxisCount(width);
                final gap = AppSpacing.base;
                final maxSquare = expandSquares
                    ? (width >= 1024 ? _squareLg : _squarePassageMax)
                    : (width >= 1024 ? _squareLg : _squareSm);
                final fromWidth =
                    (constraints.maxWidth - gap * (cols - 1)) / cols;
                final cellWidth = math.min(fromWidth, maxSquare);
                final gridWidth = cellWidth * cols + gap * (cols - 1);

                if (_anyImage) {
                  return _squareGrid(
                    gridWidth: gridWidth,
                    cols: cols,
                    gap: gap,
                    cellWidth: cellWidth,
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: gridWidth,
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var index = 0;
                            index < question.answers.length;
                            index++)
                          SizedBox(
                            width: cellWidth,
                            height: cellWidth,
                            child: _optionAt(
                              index,
                              minHeight: cellWidth,
                              fillParent: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _squareGrid({
    required double gridWidth,
    required int cols,
    required double gap,
    required double cellWidth,
  }) {
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
            childAspectRatio: 1,
          ),
          itemCount: question.answers.length,
          itemBuilder: (context, index) => AspectRatio(
            aspectRatio: 1,
            child: _optionAt(index, minHeight: cellWidth, fillParent: true),
          ),
        ),
      ),
    );
  }

  Widget _optionAt(
    int index, {
    required double minHeight,
    required bool fillParent,
  }) {
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
      minHeight: minHeight,
      fillParent: fillParent,
      onTap: (!ready || disabled) ? null : () => onSelect(answer.id),
    );
  }
}
