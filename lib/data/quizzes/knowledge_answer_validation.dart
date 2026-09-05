import 'essay_answer_validation.dart';
import 'knowledge_quiz_question.dart';

abstract final class KnowledgeAnswerValidation {
  static bool isCorrect(
    KnowledgeQuizQuestion question,
    Object answers,
  ) {
    return switch (question) {
      KnowledgeMcqQuestion mcq => _mcqCorrect(
          mcq,
          answers is List<int> ? answers : const [],
        ),
      KnowledgeEssayQuestion essay => _essayCorrect(
          essay,
          answers is List<String> ? answers : const [],
        ),
      KnowledgeFillBlankQuestion fill => _fillCorrect(
          fill,
          answers is List<String> ? answers : const [],
        ),
    };
  }

  static bool _mcqCorrect(KnowledgeMcqQuestion question, List<int> answerIds) {
    if (question.correctAnswerIds.length != answerIds.length) return false;
    return question.correctAnswerIds.every(answerIds.contains);
  }

  static bool _essayCorrect(
    KnowledgeEssayQuestion question,
    List<String> answers,
  ) {
    if (answers.isEmpty) return false;
    return EssayAnswerValidation.isCorrect(
      markAllAnswersCorrect: question.markAllAnswersCorrect,
      correctTitles: question.correctAnswers.map((a) => a.title),
      studentAnswer: answers.first,
    );
  }

  static bool _fillCorrect(
    KnowledgeFillBlankQuestion question,
    List<String> answers,
  ) {
    final correct = question.correctAnswers
        .map((a) => a.title.trim().toLowerCase())
        .toList();
    final student = answers.map((a) => a.trim().toLowerCase()).toList();
    if (correct.length != student.length) return false;
    for (var i = 0; i < correct.length; i++) {
      if (correct[i] != student[i]) return false;
    }
    return true;
  }
}
