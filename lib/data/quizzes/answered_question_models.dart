import 'package:flutter/foundation.dart';

import 'quiz_models.dart' show QuizMatchingPrompt, QuizMcqAnswer;

String stripQuizHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class QuizTeacherReview {
  const QuizTeacherReview({required this.id, this.text});

  final int id;
  final String? text;

  factory QuizTeacherReview.fromJson(Map<String, dynamic> json) {
    return QuizTeacherReview(
      id: _asInt(json['id']),
      text: json['text'] as String?,
    );
  }
}

class QuizReorderCorrectAnswer {
  const QuizReorderCorrectAnswer({
    required this.answerId,
    required this.order,
  });

  final int answerId;
  final int order;
}

class AnsweredQuizQuestion {
  const AnsweredQuizQuestion({
    required this.id,
    required this.type,
    required this.title,
    required this.isCorrect,
    required this.awardedPoints,
    required this.points,
    required this.studentAnswerIds,
    required this.answers,
    required this.correctAnswerIds,
    this.studentAnswerTexts = const [],
    this.studentAnswerPairs = const {},
    this.correctAnswerTexts = const [],
    this.prompts = const [],
    this.reorderCorrectAnswers = const [],
    this.notAnswered = false,
    this.teacherReview,
    this.childQuestions = const [],
  });

  final String id;
  final String type;
  final String title;
  final bool isCorrect;
  final int awardedPoints;
  final int points;
  final List<int> studentAnswerIds;
  final List<QuizMcqAnswer> answers;
  final List<int> correctAnswerIds;
  final List<String> studentAnswerTexts;
  final Map<int, int> studentAnswerPairs;
  final List<String> correctAnswerTexts;
  final List<QuizMatchingPrompt> prompts;
  final List<QuizReorderCorrectAnswer> reorderCorrectAnswers;
  final bool notAnswered;
  final QuizTeacherReview? teacherReview;
  final List<AnsweredQuizQuestion> childQuestions;

  bool get isPassage => type == 'passage';
  bool get isMcq => type == 'mcq';

  String get plainTitle => stripQuizHtml(title);

  factory AnsweredQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawType =
        json['type'] as String? ?? json['question_type'] as String? ?? 'mcq';
    final type = switch (rawType) {
      'matching' => 'match',
      're_order' || 'reorder' => 're-order',
      _ => rawType,
    };

    final answersJson = json['answers'];
    final answers = answersJson is List
        ? answersJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    final correctJson = json['correct_answers'];
    final correctIds = <int>[];
    final correctTexts = <String>[];
    final reorderCorrect = <QuizReorderCorrectAnswer>[];

    if (correctJson is List) {
      for (final entry in correctJson) {
        if (entry is Map<String, dynamic>) {
          if (entry.containsKey('answer_id')) {
            final answerId = _asInt(entry['answer_id']);
            if (answerId > 0) correctIds.add(answerId);
            if (entry.containsKey('order')) {
              reorderCorrect.add(
                QuizReorderCorrectAnswer(
                  answerId: answerId,
                  order: _asInt(entry['order']),
                ),
              );
            }
          }
          final title = entry['title'] as String?;
          if (title != null && title.trim().isNotEmpty) {
            correctTexts.add(title.trim());
          }
        } else {
          final id = _asInt(entry);
          if (id > 0) correctIds.add(id);
        }
      }
    }

    final studentRaw = json['student_answer'];
    final studentIds = _parseStudentAnswerIds(studentRaw);
    final studentTexts = _parseStudentAnswerTexts(studentRaw, type);
    final studentPairs = _parseStudentAnswerPairs(studentRaw);

    final promptsJson = json['prompts'];
    final prompts = promptsJson is List
        ? promptsJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMatchingPrompt.fromJson)
            .toList()
        : const <QuizMatchingPrompt>[];

    final childJson = json['childQuestions'] ?? json['child_questions'];
    final children = childJson is List
        ? childJson
            .whereType<Map<String, dynamic>>()
            .map(AnsweredQuizQuestion.fromJson)
            .toList()
        : const <AnsweredQuizQuestion>[];

    final reviewJson = json['teacher_review'];
    final teacherReview = reviewJson is Map<String, dynamic>
        ? QuizTeacherReview.fromJson(reviewJson)
        : null;

    final unanswered = json['not_answered'] == true ||
        (studentIds.isEmpty &&
            studentTexts.isEmpty &&
            studentPairs.isEmpty &&
            type != 'passage');

    return AnsweredQuizQuestion(
      id: (json['id'] ?? json['question_id'])?.toString() ?? '',
      type: type,
      title: (json['title'] as String? ?? ''),
      isCorrect: json['is_correct'] == true,
      awardedPoints: _asInt(json['awarded_points']),
      points: _asInt(json['points']),
      studentAnswerIds: studentIds,
      answers: answers,
      correctAnswerIds: correctIds,
      studentAnswerTexts: studentTexts,
      studentAnswerPairs: studentPairs,
      correctAnswerTexts: correctTexts,
      prompts: prompts,
      reorderCorrectAnswers: reorderCorrect,
      notAnswered: unanswered,
      teacherReview: teacherReview,
      childQuestions: children,
    );
  }

  factory AnsweredQuizQuestion.fromExamSession({
    required String id,
    required String title,
    required List<QuizMcqAnswer> answers,
    required List<int> correctAnswerIds,
    required List<int> studentAnswerIds,
    required bool isCorrect,
    int points = 1,
  }) {
    return AnsweredQuizQuestion(
      id: id,
      type: 'mcq',
      title: title,
      isCorrect: isCorrect,
      awardedPoints: isCorrect ? points : 0,
      points: points,
      studentAnswerIds: studentAnswerIds,
      answers: answers,
      correctAnswerIds: correctAnswerIds,
      notAnswered: studentAnswerIds.isEmpty,
    );
  }
}

class QuizAttemptReview {
  const QuizAttemptReview({
    required this.answeredQuestions,
    this.studentName,
    this.correctCount,
    this.inCorrectCount,
    this.pointsAwarded,
    this.score,
  });

  final List<AnsweredQuizQuestion> answeredQuestions;
  final String? studentName;
  final int? correctCount;
  final int? inCorrectCount;
  final int? pointsAwarded;
  final int? score;

  factory QuizAttemptReview.fromJson(Map<String, dynamic> json) {
    final questions = parseAnsweredQuestionsList(json['answeredQuestions']);

    return QuizAttemptReview(
      answeredQuestions: questions,
      studentName: json['studentName'] as String?,
      correctCount:
          json['correctCount'] == null ? null : _asInt(json['correctCount']),
      inCorrectCount: json['inCorrectCount'] == null
          ? null
          : _asInt(json['inCorrectCount']),
      pointsAwarded: json['pointsAwarded'] == null
          ? null
          : _asInt(json['pointsAwarded']),
      score: json['score'] == null ? null : _asInt(json['score']),
    );
  }
}

List<AnsweredQuizQuestion> parseAnsweredQuestionsList(dynamic raw) {
  if (raw is! List) return const [];

  final questions = <AnsweredQuizQuestion>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    try {
      questions.add(AnsweredQuizQuestion.fromJson(item));
    } catch (error, stackTrace) {
      debugPrint(
        'parseAnsweredQuestionsList: skipped ${item['id']} '
        '(${item['type']}): $error\n$stackTrace',
      );
    }
  }
  return questions;
}

List<int> _parseStudentAnswerIds(dynamic raw) {
  if (raw is List) {
    return raw.map(_asInt).where((id) => id > 0).toList();
  }
  return const [];
}

List<String> _parseStudentAnswerTexts(dynamic raw, String type) {
  if (type == 'mcq' || type == 'match' || type == 're-order') {
    return const [];
  }
  if (raw is List) {
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return [raw.trim()];
  }
  return const [];
}

Map<int, int> _parseStudentAnswerPairs(dynamic raw) {
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(_asInt(key), _asInt(value)),
    );
  }
  return const {};
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
