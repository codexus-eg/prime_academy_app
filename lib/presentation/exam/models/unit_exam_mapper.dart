import '../../../data/quizzes/unit_quiz_question.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../classification_quiz/models/classification_question.dart';

abstract final class UnitExamMapper {
  static ClassificationQuestion? toClassificationQuestion(
    UnitQuizQuestion question,
  ) {
    return switch (question) {
      UnitMcqQuestion mcq => ClassificationMcqQuestion(
          id: mcq.id,
          title: mcq.title,
          answers: [
            for (final a in mcq.answers)
              ClassificationAnswer(
                id: a.id,
                title: a.displayTitle,
                imageUrl: a.imageUrl,
              ),
          ],
          correctAnswerIds: mcq.correctAnswerIds,
        ),
      UnitFillBlankQuestion fill => ClassificationFillBlankQuestion(
          id: fill.id,
          title: fill.title,
          correctAnswer: fill.correctAnswers.isEmpty
              ? ''
              : QuizHtmlText.plainText(fill.correctAnswers.first.title),
        ),
      UnitMatchingQuestion match => ClassificationMatchingQuestion(
          id: match.id,
          title: match.title,
          prompts: [
            for (final prompt in match.prompts)
              ClassificationMatchingPrompt(
                id: prompt.id,
                title: prompt.displayTitle,
                imageUrl: prompt.imageUrl,
                response: ClassificationMatchingResponse(
                  id: prompt.response.id,
                  title: prompt.response.displayTitle,
                  promptId: prompt.response.promptId,
                  imageUrl: prompt.response.imageUrl,
                ),
              ),
          ],
        ),
      _ => null,
    };
  }
}
