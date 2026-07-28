sealed class ClassificationQuestion {
  const ClassificationQuestion({required this.id, required this.title});

  final String id;
  final String title;
}

class ClassificationAnswer {
  const ClassificationAnswer({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String? imageUrl;
}

class ClassificationMcqQuestion extends ClassificationQuestion {
  const ClassificationMcqQuestion({
    required super.id,
    required super.title,
    required this.answers,
    required this.correctAnswerIds,
  });

  final List<ClassificationAnswer> answers;
  final List<int> correctAnswerIds;
}

class ClassificationFillBlankQuestion extends ClassificationQuestion {
  const ClassificationFillBlankQuestion({
    required super.id,
    required super.title,
    required this.correctAnswer,
  });

  final String correctAnswer;
}

class ClassificationMatchingResponse {
  const ClassificationMatchingResponse({
    required this.id,
    required this.title,
    required this.promptId,
    this.imageUrl,
  });

  final int id;
  final String title;
  final int promptId;
  final String? imageUrl;
}

class ClassificationMatchingPrompt {
  const ClassificationMatchingPrompt({
    required this.id,
    required this.title,
    required this.response,
    this.imageUrl,
  });

  final int id;
  final String title;
  final ClassificationMatchingResponse response;
  final String? imageUrl;
}

class ClassificationMatchingQuestion extends ClassificationQuestion {
  const ClassificationMatchingQuestion({
    required super.id,
    required super.title,
    required this.prompts,
  });

  final List<ClassificationMatchingPrompt> prompts;

  bool get hasAnyImage => prompts.any(
        (prompt) =>
            (prompt.imageUrl != null && prompt.imageUrl!.isNotEmpty) ||
            (prompt.response.imageUrl != null &&
                prompt.response.imageUrl!.isNotEmpty),
      );
}
