class StudentQuizAttempt {
  const StudentQuizAttempt({
    required this.quizId,
    required this.moduleName,
    required this.moduleId,
    required this.attemptId,
    required this.gradePercent,
    required this.firstAttemptScore,
    required this.maxScore,
    this.quizName,
  });

  final int quizId;
  final String moduleName;
  final int moduleId;
  final String attemptId;
  final double gradePercent;
  final int firstAttemptScore;
  final int maxScore;
  final String? quizName;

  String get displayQuizName =>
      (quizName != null && quizName!.trim().isNotEmpty)
          ? quizName!.trim()
          : moduleName;

  factory StudentQuizAttempt.fromJson(Map<String, dynamic> json) {
    final gradeRaw = json['firstAttemptGrade'];
    final grade = switch (gradeRaw) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0.0,
    };

    return StudentQuizAttempt(
      quizId: _asInt(json['id']),
      moduleName: json['moduleName'] as String? ?? '',
      moduleId: _asInt(json['moduleId']),
      attemptId: (json['attemptId'] ?? '').toString(),
      gradePercent: grade,
      firstAttemptScore: _asInt(json['firstAttemptScore']),
      maxScore: _asInt(json['maxScore']),
      quizName: json['quizName'] as String?,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
