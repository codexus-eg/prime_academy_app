import '../../core/network/api_client.dart';
import 'quiz_models.dart';

abstract final class KnowledgeQuizApi {

  static Future<KnowledgeQuizAttempt> startOrContinue(int quizId) async {
    final json = await ApiClient.getJson('/knowledge-quizzes/attempt/$quizId');
    return KnowledgeQuizAttempt.fromJson(json);
  }

  static Future<KnowledgeAnswerResult> submitAnswer({
    required int quizId,
    required String attemptId,
    required String questionId,
    required String type,
    required Object answers,
    required int index,
  }) async {
    final json = await ApiClient.postJson(
      '/knowledge-quizzes/quiz-answer/$quizId',
      {
        'attemptId': attemptId,
        'questionId': questionId,
        'type': type,
        'answers': answers,
        'index': index,
      },
    );
    return KnowledgeAnswerResult.fromJson(json);
  }
}
