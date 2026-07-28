import '../../core/network/api_client.dart';
import 'answered_question_models.dart';
import 'quiz_models.dart';
import 'student_quiz_attempt_models.dart';

abstract final class UnitQuizApi {

  static Future<List<StudentQuizAttempt>> fetchStudentAttempts(
    int courseId,
  ) async {
    final json = await ApiClient.getJsonList('/quizzes/attempts/$courseId/student');
    return json
        .whereType<Map<String, dynamic>>()
        .map(StudentQuizAttempt.fromJson)
        .toList();
  }

  static Future<UnitQuizAttempt> startOrContinue(int quizId) async {
    final json = await ApiClient.getJson('/quizzes/attempt/$quizId');
    return UnitQuizAttempt.fromJson(json);
  }

  static Future<UnitQuizSubmitResponse> submitAnswer({
    required int quizId,
    required String attemptId,
    required String questionId,
    required String type,
    required Object answers,
  }) async {
    final json = await ApiClient.postJson('/quizzes/quiz-answer/$quizId', {
      'attemptId': attemptId,
      'questionId': questionId,
      'type': type,
      'answers': answers,
    });
    return UnitQuizSubmitResponse.fromJson(json);
  }

  static Future<UnitQuizSubmitResponse> submitMcqAnswer({
    required int quizId,
    required String attemptId,
    required String questionId,
    required List<int> answerIds,
  }) =>
      submitAnswer(
        quizId: quizId,
        attemptId: attemptId,
        questionId: questionId,
        type: 'mcq',
        answers: answerIds,
      );

  static Future<UnitQuizAttempt> startLastChance(int quizId) async {
    final json =
        await ApiClient.patchJsonMap('/quizzes/attempts/$quizId/last-chance');
    return UnitQuizAttempt.fromJson(json);
  }

  static Future<QuizAttemptReview> getFirstAttemptReview({
    required int quizId,
    required String attemptId,
  }) async {
    final json = await ApiClient.getJson(
      '/quizzes/first-attempt/$quizId/$attemptId/print',
    );
    return QuizAttemptReview.fromJson(json);
  }

  static Future<List<int>> downloadReportPdf({
    required int quizId,
    required String attemptId,
    required String html,
    required String styles,
  }) {
    return ApiClient.postBytes(
      '/quizzes/$quizId/attempts/$attemptId/report',
      {'html': html, 'styles': styles},
    );
  }
}

class UnitQuizSubmitResponse {
  const UnitQuizSubmitResponse({
    required this.result,
    this.answeredQuestions = const [],
  });

  final UnitQuizAnswerResult result;
  final List<AnsweredQuizQuestion> answeredQuestions;

  factory UnitQuizSubmitResponse.fromJson(Map<String, dynamic> json) {
    return UnitQuizSubmitResponse(
      result: UnitQuizAnswerResult.fromJson(json),
      answeredQuestions: parseAnsweredQuestionsList(json['answeredQuestions']),
    );
  }
}
