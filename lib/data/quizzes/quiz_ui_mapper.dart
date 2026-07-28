import '../../presentation/exam/models/exam_question.dart';
import '../../core/theme/app_quiz_palette.dart';
import '../../data/quizzes/quiz_models.dart';
import '../../presentation/classification_quiz/models/classification_level.dart'
    as ui;
import '../../presentation/classification_quiz/models/classification_question.dart';
import '../../presentation/luck_cards/models/luck_card_question.dart';

abstract final class QuizUiMapper {
  static ui.ClassificationLevel toUiLevel(ClassificationLevel level) {
    return ui.ClassificationLevel(
      title: level.title,
      questionsRequired: level.questionsRequired,
      imageIndex: level.imageIndex,
    );
  }

  static ClassificationQuestion toClassificationQuestion(
    QuizClassificationQuestion q,
  ) {
    return switch (q) {
      QuizMcqQuestion mcq => ClassificationMcqQuestion(
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
      QuizFillBlankQuestion fill => ClassificationFillBlankQuestion(
          id: fill.id,
          title: fill.title,
          correctAnswer: fill.correctAnswers.isEmpty
              ? ''
              : fill.correctAnswers.first.title,
        ),
      QuizMatchingQuestion match => ClassificationMatchingQuestion(
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
    };
  }

  static ExamQuestion toExamQuestion(QuizMcqQuestion q) {
    final correctIndex = q.correctAnswerIds.isEmpty
        ? 0
        : q.answers.indexWhere((a) => a.id == q.correctAnswerIds.first);
    final safeCorrect = correctIndex < 0 ? 0 : correctIndex;

    return ExamQuestion(
      id: q.id,
      prompt: q.title,
      options: [
        for (final a in q.answers)
          ExamAnswerOption(text: a.title, id: a.id),
      ],
      correctIndex: safeCorrect,
    );
  }

  static LuckCardQuestion toLuckQuestion(QuizMcqQuestion q, int index) {
    const palettes = [
      LuckAnswerPaletteSlot.pink,
      LuckAnswerPaletteSlot.blue,
      LuckAnswerPaletteSlot.violet,
      LuckAnswerPaletteSlot.orange,
    ];

    final correctIndex = q.correctAnswerIds.isEmpty
        ? 0
        : q.answers.indexWhere((a) => a.id == q.correctAnswerIds.first);

    return LuckCardQuestion(
      prompt: q.title,
      options: [
        for (var i = 0; i < q.answers.length; i++)
          LuckAnswerOption(
            text: q.answers[i].title,
            palette: palettes[i % palettes.length],
          ),
      ],
      correctIndex: correctIndex < 0 ? 0 : correctIndex,
      points: q.points > 0 ? q.points : 10,
    );
  }
}
