import 'quiz_models.dart';

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

sealed class KnowledgeQuizQuestion {
  const KnowledgeQuizQuestion({
    required this.id,
    required this.title,
    required this.points,
    this.isAnswered = false,
    this.isCorrect,
    this.answerIndex,
  });

  final String id;
  final String title;
  final int points;
  final bool isAnswered;
  final bool? isCorrect;
  final int? answerIndex;
  String get type;

  factory KnowledgeQuizQuestion.fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String? ?? 'mcq') {
      'essay' => KnowledgeEssayQuestion.fromJson(json),
      'fill-blank' => KnowledgeFillBlankQuestion.fromJson(json),
      _ => KnowledgeMcqQuestion.fromJson(json),
    };
  }
}

class KnowledgeMcqQuestion extends KnowledgeQuizQuestion {
  const KnowledgeMcqQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.answers,
    required this.correctAnswerIds,
    super.isAnswered,
    super.isCorrect,
    super.answerIndex,
  });

  @override
  String get type => 'mcq';

  final List<QuizMcqAnswer> answers;
  final List<int> correctAnswerIds;

  factory KnowledgeMcqQuestion.fromJson(Map<String, dynamic> json) {
    final mcq = QuizMcqQuestion.fromJson(json);
    return KnowledgeMcqQuestion(
      id: mcq.id,
      title: mcq.title,
      points: mcq.points,
      answers: mcq.answers,
      correctAnswerIds: mcq.correctAnswerIds,
      isAnswered: mcq.isAnswered,
      isCorrect: mcq.isCorrect,
      answerIndex: mcq.answerIndex,
    );
  }
}

class KnowledgeEssayQuestion extends KnowledgeQuizQuestion {
  const KnowledgeEssayQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.correctAnswers,
    this.markAllAnswersCorrect = false,
    super.isAnswered,
    super.isCorrect,
    super.answerIndex,
  });

  @override
  String get type => 'essay';

  final List<QuizMcqAnswer> correctAnswers;
  final bool markAllAnswersCorrect;

  factory KnowledgeEssayQuestion.fromJson(Map<String, dynamic> json) {
    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    return KnowledgeEssayQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      correctAnswers: correctAnswers,
      markAllAnswersCorrect: json['mark_all_answers_correct'] == true,
      isAnswered: json['isAnswered'] == true,
      isCorrect: json['isCorrect'] as bool?,
      answerIndex:
          json['answerIndex'] == null ? null : _asInt(json['answerIndex']),
    );
  }
}

class KnowledgeFillBlankQuestion extends KnowledgeQuizQuestion {
  const KnowledgeFillBlankQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.correctAnswers,
    super.isAnswered,
    super.isCorrect,
    super.answerIndex,
  });

  @override
  String get type => 'fill-blank';

  final List<QuizMcqAnswer> correctAnswers;

  String get correctAnswerText =>
      correctAnswers.isEmpty ? '' : correctAnswers.first.title;

  factory KnowledgeFillBlankQuestion.fromJson(Map<String, dynamic> json) {
    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    return KnowledgeFillBlankQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      correctAnswers: correctAnswers,
      isAnswered: json['isAnswered'] == true,
      isCorrect: json['isCorrect'] as bool?,
      answerIndex:
          json['answerIndex'] == null ? null : _asInt(json['answerIndex']),
    );
  }
}
