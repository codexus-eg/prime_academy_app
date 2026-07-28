import 'quiz_models.dart';

sealed class UnitQuizQuestion {
  const UnitQuizQuestion({
    required this.id,
    required this.title,
    required this.points,
  });

  final String id;
  final String title;
  final int points;
  String get type;

  factory UnitQuizQuestion.fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String? ?? 'mcq') {
      'essay' => UnitEssayQuestion.fromJson(json),
      'fill-blank' => UnitFillBlankQuestion.fromJson(json),
      'match' || 'matching' => UnitMatchingQuestion.fromJson(json),
      're-order' || 're_order' || 'reorder' => UnitReOrderQuestion.fromJson(json),
      'passage' => UnitPassageQuestion.fromJson(json),
      _ => UnitMcqQuestion.fromJson(json),
    };
  }
}

class UnitMcqQuestion extends UnitQuizQuestion {
  const UnitMcqQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.answers,
    required this.correctAnswerIds,
    this.allowMultipleAnswers = false,
  });

  @override
  String get type => 'mcq';

  final List<QuizMcqAnswer> answers;
  final List<int> correctAnswerIds;
  final bool allowMultipleAnswers;

  factory UnitMcqQuestion.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'];
    final answers = answersJson is List
        ? answersJson
            .whereType<Map>()
            .map((e) => QuizMcqAnswer.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <QuizMcqAnswer>[];

    final correctJson = json['correct_answers'];
    final correctIds = correctJson is List
        ? correctJson
            .map((e) {
              if (e is Map) {
                return _asInt(Map<String, dynamic>.from(e)['answer_id']);
              }
              return _asInt(e);
            })
            .where((id) => id > 0)
            .toList()
        : <int>[];

    return UnitMcqQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      answers: answers,
      correctAnswerIds: correctIds,
      allowMultipleAnswers: json['allow_multiple_answers'] == true,
    );
  }
}

class UnitEssayQuestion extends UnitQuizQuestion {
  const UnitEssayQuestion({
    required super.id,
    required super.title,
    required super.points,
    this.markAllAnswersCorrect = false,
    this.correctAnswers = const [],
  });

  @override
  String get type => 'essay';

  final bool markAllAnswersCorrect;
  final List<QuizMcqAnswer> correctAnswers;

  factory UnitEssayQuestion.fromJson(Map<String, dynamic> json) {
    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    return UnitEssayQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      markAllAnswersCorrect: json['mark_all_answers_correct'] == true,
      correctAnswers: correctAnswers,
    );
  }
}

class UnitFillBlankQuestion extends UnitQuizQuestion {
  const UnitFillBlankQuestion({
    required super.id,
    required super.title,
    required super.points,
    this.correctAnswers = const [],
  });

  @override
  String get type => 'fill-blank';

  final List<QuizMcqAnswer> correctAnswers;

  factory UnitFillBlankQuestion.fromJson(Map<String, dynamic> json) {
    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    return UnitFillBlankQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      correctAnswers: correctAnswers,
    );
  }
}

class UnitMatchingQuestion extends UnitQuizQuestion {
  const UnitMatchingQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.prompts,
  });

  @override
  String get type => 'match';

  final List<QuizMatchingPrompt> prompts;

  factory UnitMatchingQuestion.fromJson(Map<String, dynamic> json) {
    final promptsJson = json['prompts'];
    final prompts = promptsJson is List
        ? promptsJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMatchingPrompt.fromJson)
            .toList()
        : <QuizMatchingPrompt>[];

    return UnitMatchingQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      prompts: prompts,
    );
  }
}

class UnitReOrderCorrectAnswer {
  const UnitReOrderCorrectAnswer({
    required this.answerId,
    required this.order,
  });

  final int answerId;
  final int order;

  factory UnitReOrderCorrectAnswer.fromJson(Map<String, dynamic> json) {
    return UnitReOrderCorrectAnswer(
      answerId: _asInt(json['answer_id']),
      order: _asInt(json['order']),
    );
  }
}

class UnitReOrderQuestion extends UnitQuizQuestion {
  const UnitReOrderQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.answers,
    required this.correctAnswers,
    this.sortDirection = 'asc',
  });

  @override
  String get type => 're-order';

  final List<QuizMcqAnswer> answers;
  final List<UnitReOrderCorrectAnswer> correctAnswers;
  final String sortDirection;

  factory UnitReOrderQuestion.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'];
    final answers = answersJson is List
        ? answersJson
            .whereType<Map>()
            .map((e) => QuizMcqAnswer.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <QuizMcqAnswer>[];

    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map>()
            .map(
              (e) => UnitReOrderCorrectAnswer.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <UnitReOrderCorrectAnswer>[];

    return UnitReOrderQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      answers: answers,
      correctAnswers: correctAnswers,
      sortDirection: (json['sortDirection'] as String? ??
          json['sort_direction'] as String? ??
          'asc'),
    );
  }
}

class UnitPassageQuestion extends UnitQuizQuestion {
  const UnitPassageQuestion({
    required super.id,
    required super.title,
    required super.points,
    required this.passages,
    required this.childQuestions,
  });

  @override
  String get type => 'passage';

  final List<String> passages;
  final List<UnitQuizQuestion> childQuestions;

  factory UnitPassageQuestion.fromJson(Map<String, dynamic> json) {
    final passagesJson = json['passages'];
    final passages = passagesJson is List
        ? passagesJson.map((e) => '$e').toList()
        : <String>[];

    final childJson = json['childQuestions'] ?? json['child_questions'];
    final children = childJson is List
        ? childJson
            .whereType<Map<String, dynamic>>()
            .map(UnitQuizQuestion.fromJson)
            .toList()
        : <UnitQuizQuestion>[];

    return UnitPassageQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      points: _asInt(json['points']),
      passages: passages,
      childQuestions: children,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
