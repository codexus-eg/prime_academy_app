import '../../core/network/api_client.dart';
import 'quiz_models.dart';

abstract final class ClassificationQuizApi {

  static Future<ClassificationQuizAttempt> startOrContinue(int quizId) async {
    final json =
        await ApiClient.getJson('/classification-quizzes/attempt/$quizId');
    return ClassificationQuizAttempt.fromJson(json);
  }

  static Future<ClassificationAnswerResult> submitAnswer({
    required int quizId,
    required String attemptId,
    required String questionId,
    required String type,
    required Object answers,
  }) async {
    final json = await ApiClient.postJson(
      '/classification-quizzes/quiz-answer/$quizId',
      {
        'attemptId': attemptId,
        'questionId': questionId,
        'type': type,
        'answers': answers,
      },
    );
    return ClassificationAnswerResult.fromJson(json);
  }
}
