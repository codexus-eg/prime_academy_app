class ReportAttempt {
  const ReportAttempt({
    required this.quizId,
    required this.moduleName,
    required this.quizName,
    required this.grade,
    required this.attemptId,
  });

  final int quizId;
  final String moduleName;
  final String quizName;
  final double grade;
  final String attemptId;
}
