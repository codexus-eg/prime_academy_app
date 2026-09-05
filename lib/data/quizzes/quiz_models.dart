import 'package:flutter/foundation.dart';

import '../../core/utils/answers_direction.dart';
import '../../core/utils/json_bool.dart';
import 'knowledge_quiz_question.dart';
import 'unit_quiz_question.dart';

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class QuizMcqAnswer {
  const QuizMcqAnswer({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String? imageUrl;

  factory QuizMcqAnswer.fromJson(Map<String, dynamic> json) {
    final title = _stringify(json['title']);
    final imageUrl = _resolveImageUrl(json) ?? _extractImageFromHtml(title);

    return QuizMcqAnswer(
      id: _asInt(json['id']),
      title: title,
      imageUrl: imageUrl,
    );
  }

  static String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _resolveImageUrl(Map<String, dynamic> json) {
    final direct = json['image_url'];
    if (direct is String && direct.isNotEmpty) return direct;

    final image = json['image'];

    if (image is Map) {
      final map = Map<String, dynamic>.from(image);
      final url = map['url'];
      if (url is String && url.isNotEmpty) return url;
      final path = map['path'];
      if (path is String && path.isNotEmpty) return path;
      final key = map['key'];
      if (key is String && key.isNotEmpty) return key;
      final filename = map['filename'];
      if (filename is String && filename.isNotEmpty) return filename;
    }
    if (image is String && image.isNotEmpty) return image;

    return null;
  }

  static String? _extractImageFromHtml(String html) {
    final patterns = [
      RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''<img[^>]+src=([^\s>]+)''', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      final url = match?.group(1)?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  String get displayTitle =>
      title.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '').trim();
}

class QuizMcqQuestion extends QuizClassificationQuestion {
  const QuizMcqQuestion({
    required super.id,
    required super.title,
    super.answersDirection,
    required this.answers,
    required this.correctAnswerIds,
    this.points = 0,
    this.isAnswered = false,
    this.isCorrect,
    this.answerIndex,
  });

  @override
  String get type => 'mcq';

  final List<QuizMcqAnswer> answers;
  final List<int> correctAnswerIds;
  final int points;
  final bool isAnswered;
  final bool? isCorrect;
  final int? answerIndex;

  factory QuizMcqQuestion.fromJson(Map<String, dynamic> json) {
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

    return QuizMcqQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      answersDirection: parseAnswersDirection(json['answers_direction']),
      answers: answers,
      correctAnswerIds: correctIds,
      points: _asInt(json['points']),
      isAnswered: json['isAnswered'] == true,
      isCorrect: json['isCorrect'] as bool?,
      answerIndex: json['answerIndex'] == null
          ? null
          : _asInt(json['answerIndex']),
    );
  }
}

sealed class QuizClassificationQuestion {
  const QuizClassificationQuestion({
    required this.id,
    required this.title,
    this.answersDirection = AnswersDirection.rtl,
  });

  final String id;
  final String title;
  final AnswersDirection answersDirection;
  String get type;

  factory QuizClassificationQuestion.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'mcq').toLowerCase();
    return switch (type) {
      'fill-blank' => QuizFillBlankQuestion.fromJson(json),
      'match' || 'matching' => QuizMatchingQuestion.fromJson(json),
      _ => QuizMcqQuestion.fromJson(json),
    };
  }
}

class QuizFillBlankQuestion extends QuizClassificationQuestion {
  const QuizFillBlankQuestion({
    required super.id,
    required super.title,
    super.answersDirection,
    required this.correctAnswers,
    this.points = 0,
  });

  @override
  String get type => 'fill-blank';

  final List<QuizMcqAnswer> correctAnswers;
  final int points;

  factory QuizFillBlankQuestion.fromJson(Map<String, dynamic> json) {
    final correctJson = json['correct_answers'];
    final correctAnswers = correctJson is List
        ? correctJson
            .whereType<Map<String, dynamic>>()
            .map(QuizMcqAnswer.fromJson)
            .toList()
        : <QuizMcqAnswer>[];

    return QuizFillBlankQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      answersDirection: parseAnswersDirection(json['answers_direction']),
      correctAnswers: correctAnswers,
      points: _asInt(json['points']),
    );
  }
}

class QuizMatchingResponse {
  const QuizMatchingResponse({
    required this.id,
    required this.title,
    required this.promptId,
    this.imageUrl,
  });

  final int id;
  final String title;
  final int promptId;
  final String? imageUrl;

  factory QuizMatchingResponse.fromJson(Map<String, dynamic> json) {
    final title = QuizMcqAnswer._stringify(json['title']);
    return QuizMatchingResponse(
      id: _asInt(json['id']),
      title: title,
      promptId: _asInt(json['prompt_id']),
      imageUrl:
          QuizMcqAnswer._resolveImageUrl(json) ??
          QuizMcqAnswer._extractImageFromHtml(title),
    );
  }

  String get displayTitle => QuizMcqAnswer(id: id, title: title).displayTitle;
}

class QuizMatchingPrompt {
  const QuizMatchingPrompt({
    required this.id,
    required this.title,
    required this.response,
    this.imageUrl,
  });

  final int id;
  final String title;
  final QuizMatchingResponse response;
  final String? imageUrl;

  factory QuizMatchingPrompt.fromJson(
    Map<String, dynamic> json, {
    Map<int, Map<String, dynamic>>? responsesByPromptId,
  }) {
    final promptId = _asInt(json['id']);
    final title = QuizMcqAnswer._stringify(json['title']);
    final responseJson = json['response'];
    QuizMatchingResponse response;
    if (responseJson is Map<String, dynamic>) {
      response = QuizMatchingResponse.fromJson(responseJson);
    } else {
      final fallback = responsesByPromptId?[promptId];
      response = fallback is Map<String, dynamic>
          ? QuizMatchingResponse.fromJson(fallback)
          : const QuizMatchingResponse(id: 0, title: '', promptId: 0);
    }

    return QuizMatchingPrompt(
      id: promptId,
      title: title,
      imageUrl:
          QuizMcqAnswer._resolveImageUrl(json) ??
          QuizMcqAnswer._extractImageFromHtml(title),
      response: response,
    );
  }

  String get displayTitle => QuizMcqAnswer(id: id, title: title).displayTitle;
}

class QuizMatchingQuestion extends QuizClassificationQuestion {
  const QuizMatchingQuestion({
    required super.id,
    required super.title,
    super.answersDirection,
    required this.prompts,
    this.points = 0,
  });

  @override
  String get type => 'match';

  final List<QuizMatchingPrompt> prompts;
  final int points;

  factory QuizMatchingQuestion.fromJson(Map<String, dynamic> json) {
    final responsesByPromptId = <int, Map<String, dynamic>>{};
    final responsesJson = json['responses'];
    if (responsesJson is List) {
      for (final item in responsesJson.whereType<Map<String, dynamic>>()) {
        final promptId = _asInt(item['prompt_id']);
        if (promptId > 0) {
          responsesByPromptId[promptId] = item;
        }
      }
    }

    final promptsJson = json['prompts'] ?? json['answers'];
    final prompts = promptsJson is List
        ? promptsJson
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => QuizMatchingPrompt.fromJson(
                item,
                responsesByPromptId: responsesByPromptId,
              ),
            )
            .toList()
        : <QuizMatchingPrompt>[];

    return QuizMatchingQuestion(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String? ?? ''),
      answersDirection: parseAnswersDirection(json['answers_direction']),
      prompts: prompts,
      points: _asInt(json['points']),
    );
  }
}

class ClassificationLevel {
  const ClassificationLevel({
    required this.title,
    required this.questionsRequired,
    required this.imageIndex,
  });

  final String title;
  final int questionsRequired;
  final int imageIndex;

  factory ClassificationLevel.fromJson(Map<String, dynamic> json) {
    return ClassificationLevel(
      title: (json['title'] as String? ?? ''),
      questionsRequired: _asInt(json['questionsRequired']),
      imageIndex: _asInt(json['imageIndex']),
    );
  }
}

class ClassificationQuizAttempt {
  const ClassificationQuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.level,
    required this.levels,
    required this.questions,
    required this.questionsCount,
    required this.answeredCount,
    required this.completed,
    required this.status,
  });

  final String attemptId;
  final int quizId;
  final ClassificationLevel level;
  final List<ClassificationLevel> levels;
  final List<QuizClassificationQuestion> questions;
  final int questionsCount;
  final int answeredCount;
  final bool completed;
  final String status;

  int get remainingQuestions =>
      (questionsCount - answeredCount).clamp(0, questionsCount);

  factory ClassificationQuizAttempt.fromJson(Map<String, dynamic> json) {
    final attempt = json['attempt'];
    final attemptMap = attempt is Map<String, dynamic> ? attempt : const {};
    final levelJson = attemptMap['level'];
    final levelsJson = json['levels'];

    final questionsJson = json['questions'];
    final questions = questionsJson is List
        ? questionsJson
            .whereType<Map<String, dynamic>>()
            .where((q) {
              final type = (q['type'] as String? ?? 'mcq').toLowerCase();
              return type == 'mcq' ||
                  type == 'fill-blank' ||
                  type == 'match' ||
                  type == 'matching';
            })
            .map(QuizClassificationQuestion.fromJson)
            .toList()
        : <QuizClassificationQuestion>[];

    return ClassificationQuizAttempt(
      attemptId: (attemptMap['id'] as String? ?? ''),
      quizId: _asInt(attemptMap['classification_quiz_id']),
      level: levelJson is Map<String, dynamic>
          ? ClassificationLevel.fromJson(levelJson)
          : const ClassificationLevel(
              title: '',
              questionsRequired: 0,
              imageIndex: 0,
            ),
      levels: levelsJson is List
          ? levelsJson
              .whereType<Map<String, dynamic>>()
              .map(ClassificationLevel.fromJson)
              .toList()
          : const [],
      questions: questions,
      questionsCount: _asInt(json['questionsCount']),
      answeredCount: _asInt(json['answeredCount']),
      completed: json['completed'] == true,
      status: (json['status'] as String? ?? ''),
    );
  }
}

class ClassificationAnswerResult {
  const ClassificationAnswerResult({
    required this.correct,
    required this.completed,
    this.level,
  });

  final bool correct;
  final bool completed;
  final ClassificationLevel? level;

  factory ClassificationAnswerResult.fromJson(Map<String, dynamic> json) {
    final levelJson = json['level'];
    return ClassificationAnswerResult(
      correct: json['correct'] == true,
      completed: json['completed'] == true,
      level: levelJson is Map<String, dynamic>
          ? ClassificationLevel.fromJson(levelJson)
          : null,
    );
  }
}

class KnowledgeQuizAttempt {
  const KnowledgeQuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.questionsLeft,
    required this.maxQuestionsPerAttempt,
    required this.questions,
    required this.completed,
    required this.status,
    this.score,
  });

  final String attemptId;
  final int quizId;
  final int questionsLeft;
  final int maxQuestionsPerAttempt;
  final List<KnowledgeQuizQuestion> questions;
  final bool completed;
  final String status;
  final int? score;

  factory KnowledgeQuizAttempt.fromJson(Map<String, dynamic> json) {
    final attempt = json['attempt'];
    final attemptMap = attempt is Map<String, dynamic> ? attempt : const {};

    final questionsJson = json['questions'];
    final questions = questionsJson is List
        ? questionsJson
            .whereType<Map<String, dynamic>>()
            .map(KnowledgeQuizQuestion.fromJson)
            .toList()
        : <KnowledgeQuizQuestion>[];

    return KnowledgeQuizAttempt(
      attemptId: (attemptMap['id'] as String? ?? ''),
      quizId: _asInt(attemptMap['knowledge_quiz_id']),
      questionsLeft: _asInt(attemptMap['questionsLeft']),
      maxQuestionsPerAttempt: _asInt(attemptMap['maxQuestionsPerAttempt']),
      questions: questions,
      completed: json['completed'] == true,
      status: (json['status'] as String? ?? ''),
      score: attemptMap['score'] == null ? null : _asInt(attemptMap['score']),
    );
  }
}

class KnowledgeAnswerResult {
  const KnowledgeAnswerResult({
    required this.correct,
    required this.completed,
    required this.awardedPoints,
    this.totalPointsAwarded,
  });

  final bool correct;
  final bool completed;
  final int awardedPoints;
  final int? totalPointsAwarded;

  factory KnowledgeAnswerResult.fromJson(Map<String, dynamic> json) {
    return KnowledgeAnswerResult(
      correct: parseApiBool(json['correct']),
      completed: parseApiBool(json['completed']),
      awardedPoints: _asInt(json['awardedPoints']),
      totalPointsAwarded: json['totalPointsAwarded'] == null
          ? null
          : _asInt(json['totalPointsAwarded']),
    );
  }
}

class UnitQuizAttempt {
  const UnitQuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.questionsCount,
    required this.totalAnswered,
    required this.questions,
    required this.status,
    this.firstAttempt = true,
    this.lastChanceActive = false,
    this.totalIncorrect,
    this.startedAt,
  });

  final String attemptId;
  final int quizId;
  final int questionsCount;
  final int totalAnswered;
  final List<UnitQuizQuestion> questions;
  final String status;
  final bool firstAttempt;
  final bool lastChanceActive;
  final int? totalIncorrect;

  final DateTime? startedAt;

  bool get isContinue => status == 'continued';
  bool get isLastChance => status == 'last_chance';
  bool get isCompleted =>
      status == 'completed' || (questions.isEmpty && questionsCount == 0);

  factory UnitQuizAttempt.fromJson(Map<String, dynamic> json) {
    final attemptMap = json['attempt'];
    final questionsJson = json['questions'];
    final questions = questionsJson is List
        ? questionsJson.whereType<Map<String, dynamic>>().map((item) {
            try {
              return UnitQuizQuestion.fromJson(item);
            } catch (error, stackTrace) {
              debugPrint(
                'UnitQuizAttempt: skipped question ${item['id']} '
                '(${item['type']}): $error\n$stackTrace',
              );
              return null;
            }
          }).whereType<UnitQuizQuestion>().toList()
        : <UnitQuizQuestion>[];

    DateTime? startedAt;
    if (attemptMap is Map<String, dynamic>) {
      final raw = attemptMap['started_at'] ?? attemptMap['startedAt'];
      if (raw is String && raw.isNotEmpty) {
        startedAt = DateTime.tryParse(raw)?.toLocal();
      }
    }

    return UnitQuizAttempt(
      attemptId: attemptMap is Map<String, dynamic>
          ? (attemptMap['id'] as String? ?? '')
          : '',
      quizId: attemptMap is Map<String, dynamic>
          ? _asInt(attemptMap['quiz_id'])
          : 0,
      questionsCount: _asInt(json['questionsCount']),
      totalAnswered: _asInt(json['totalAnswered']),
      questions: questions,
      status: (json['status'] as String? ?? ''),
      firstAttempt: attemptMap is! Map<String, dynamic> ||
          attemptMap['first_attempt'] != false,
      lastChanceActive: attemptMap is Map<String, dynamic> &&
          attemptMap['last_chance_active'] == true,
      totalIncorrect: json['totalIncorrect'] == null
          ? null
          : _asInt(json['totalIncorrect']),
      startedAt: startedAt,
    );
  }
}

class UnitQuizAnswerResult {
  const UnitQuizAnswerResult({
    required this.correct,
    required this.completed,
    this.pointsAwarded,
    this.correctCount,
    this.inCorrectCount,
    this.score,
    this.canStartLastChance = false,
    this.hasLastChance = false,
  });

  final bool correct;
  final bool completed;
  final int? pointsAwarded;
  final int? correctCount;
  final int? inCorrectCount;
  final int? score;
  final bool canStartLastChance;
  final bool hasLastChance;

  factory UnitQuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return UnitQuizAnswerResult(
      correct: parseApiBool(json['correct']),
      completed: parseApiBool(json['completed']),
      pointsAwarded:
          json['pointsAwarded'] == null ? null : _asInt(json['pointsAwarded']),
      correctCount:
          json['correctCount'] == null ? null : _asInt(json['correctCount']),
      inCorrectCount: json['inCorrectCount'] == null
          ? null
          : _asInt(json['inCorrectCount']),
      score: json['score'] == null ? null : _asInt(json['score']),
      canStartLastChance: parseApiBool(json['canStartLastChance']),
      hasLastChance: parseApiBool(json['hasLastChance']),
    );
  }
}

class LessonQuizStatus {
  const LessonQuizStatus({
    required this.id,
    required this.completed,
    this.levelTitle,
  });

  final int id;
  final bool completed;
  final String? levelTitle;

  factory LessonQuizStatus.fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    return LessonQuizStatus(
      id: _asInt(json['id']),
      completed: json['completed'] == true,
      levelTitle: level is Map<String, dynamic>
          ? level['title'] as String?
          : null,
    );
  }
}
