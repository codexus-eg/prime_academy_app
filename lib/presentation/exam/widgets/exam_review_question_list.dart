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

    final cards = <Widget>[
      for (var i = 0; i < questions.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        ExamReviewQuestionCard(
          question: questions[i],
          index: i,
        ),
      ],
    ];

    if (shrinkWrap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: cards,
    );
  }
}
