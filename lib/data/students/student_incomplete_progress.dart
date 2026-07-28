class IncompleteQuizItem {
  const IncompleteQuizItem({
    required this.courseId,
    required this.courseName,
    required this.moduleId,
    required this.moduleName,
    required this.itemId,
    required this.quizId,
  });

  final int courseId;
  final String courseName;
  final int moduleId;
  final String moduleName;
  final int itemId;
  final int quizId;

  factory IncompleteQuizItem.fromJson(Map<String, dynamic> json) {
    return IncompleteQuizItem(
      courseId: _asInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      moduleId: _asInt(json['module_id']),
      moduleName: json['module_name'] as String? ?? '',
      itemId: _asInt(json['item_id']),
      quizId: _asInt(json['quiz_id']),
    );
  }
}

class UnwatchedLessonItem {
  const UnwatchedLessonItem({
    required this.courseId,
    required this.courseName,
    required this.moduleId,
    required this.moduleName,
    required this.itemId,
    required this.lessonName,
  });

  final int courseId;
  final String courseName;
  final int moduleId;
  final String moduleName;
  final int itemId;
  final String lessonName;

  factory UnwatchedLessonItem.fromJson(Map<String, dynamic> json) {
    return UnwatchedLessonItem(
      courseId: _asInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      moduleId: _asInt(json['module_id']),
      moduleName: json['module_name'] as String? ?? '',
      itemId: _asInt(json['item_id']),
      lessonName: json['lesson_name'] as String? ?? '',
    );
  }
}

class IncompleteClassificationItem {
  const IncompleteClassificationItem({
    required this.courseId,
    required this.courseName,
    required this.moduleId,
    required this.moduleName,
    required this.itemId,
    required this.lessonName,
    required this.classificationQuizId,
  });

  final int courseId;
  final String courseName;
  final int moduleId;
  final String moduleName;
  final int itemId;
  final String lessonName;
  final int classificationQuizId;

  factory IncompleteClassificationItem.fromJson(Map<String, dynamic> json) {
    return IncompleteClassificationItem(
      courseId: _asInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      moduleId: _asInt(json['module_id']),
      moduleName: json['module_name'] as String? ?? '',
      itemId: _asInt(json['item_id']),
      lessonName: json['lesson_name'] as String? ?? '',
      classificationQuizId: _asInt(json['classification_quiz_id']),
    );
  }
}

class IncompleteKnowledgeItem {
  const IncompleteKnowledgeItem({
    required this.courseId,
    required this.courseName,
    required this.moduleId,
    required this.moduleName,
    required this.itemId,
    required this.lessonName,
    required this.knowledgeQuizId,
  });

  final int courseId;
  final String courseName;
  final int moduleId;
  final String moduleName;
  final int itemId;
  final String lessonName;
  final int knowledgeQuizId;

  factory IncompleteKnowledgeItem.fromJson(Map<String, dynamic> json) {
    return IncompleteKnowledgeItem(
      courseId: _asInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      moduleId: _asInt(json['module_id']),
      moduleName: json['module_name'] as String? ?? '',
      itemId: _asInt(json['item_id']),
      lessonName: json['lesson_name'] as String? ?? '',
      knowledgeQuizId: _asInt(json['knowledge_quiz_id']),
    );
  }
}

class IncompleteLessonCardItem {
  const IncompleteLessonCardItem({
    required this.courseId,
    required this.courseName,
    required this.moduleId,
    required this.moduleName,
    required this.itemId,
    required this.lessonName,
  });

  final int courseId;
  final String courseName;
  final int moduleId;
  final String moduleName;
  final int itemId;
  final String lessonName;

  factory IncompleteLessonCardItem.fromJson(Map<String, dynamic> json) {
    return IncompleteLessonCardItem(
      courseId: _asInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      moduleId: _asInt(json['module_id']),
      moduleName: json['module_name'] as String? ?? '',
      itemId: _asInt(json['item_id']),
      lessonName: json['lesson_name'] as String? ?? '',
    );
  }
}

class StudentIncompleteProgressReport {
  const StudentIncompleteProgressReport({
    this.incompleteQuizzes = const [],
    this.unwatchedLessons = const [],
    this.incompleteClassification = const [],
    this.incompleteKnowledge = const [],
    this.incompleteLessonCards = const [],
  });

  final List<IncompleteQuizItem> incompleteQuizzes;
  final List<UnwatchedLessonItem> unwatchedLessons;
  final List<IncompleteClassificationItem> incompleteClassification;
  final List<IncompleteKnowledgeItem> incompleteKnowledge;
  final List<IncompleteLessonCardItem> incompleteLessonCards;

  bool get isEmpty =>
      incompleteQuizzes.isEmpty &&
      unwatchedLessons.isEmpty &&
      incompleteClassification.isEmpty &&
      incompleteKnowledge.isEmpty &&
      incompleteLessonCards.isEmpty;

  int get totalCount =>
      incompleteQuizzes.length +
      unwatchedLessons.length +
      incompleteClassification.length +
      incompleteKnowledge.length +
      incompleteLessonCards.length;

  factory StudentIncompleteProgressReport.fromJson(Map<String, dynamic> json) {
    return StudentIncompleteProgressReport(
      incompleteQuizzes: _list(json['incompleteQuizzes'], IncompleteQuizItem.fromJson),
      unwatchedLessons: _list(json['unwatchedLessons'], UnwatchedLessonItem.fromJson),
      incompleteClassification:
          _list(json['incompleteClassification'], IncompleteClassificationItem.fromJson),
      incompleteKnowledge:
          _list(json['incompleteKnowledge'], IncompleteKnowledgeItem.fromJson),
      incompleteLessonCards:
          _list(json['incompleteLessonCards'], IncompleteLessonCardItem.fromJson),
    );
  }
}

List<T> _list<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
