import 'package:flutter/material.dart';

import '../../../data/quizzes/answered_question_models.dart';
import 'exam_review_question_card.dart';

class ExamReviewQuestionList extends StatelessWidget {
  const ExamReviewQuestionList({
    super.key,
    required this.questions,
    this.shrinkWrap = false,
  });

  final List<AnsweredQuizQuestion> questions;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'لا توجد أسئلة في هذا التقرير',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: questions.length,
      separatorBuilder: (context, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return ExamReviewQuestionCard(
          question: questions[index],
          index: index,
        );
      },
    );
  }
}
