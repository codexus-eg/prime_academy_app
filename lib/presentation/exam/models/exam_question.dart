class ExamAnswerOption {
  const ExamAnswerOption({
    required this.text,
    this.id,
    this.imageUrl,
  });

  final String text;
  final int? id;
  final String? imageUrl;
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String prompt;
  final List<ExamAnswerOption> options;
  final int correctIndex;
}
