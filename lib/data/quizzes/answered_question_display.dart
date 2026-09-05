import '../../core/widgets/quiz_html_text.dart';
import 'answered_question_models.dart';
import 'quiz_models.dart';

extension AnsweredQuizQuestionDisplay on AnsweredQuizQuestion {
  List<String> get studentAnswerLines => switch (type) {
        'mcq' => _mcqStudentLines(),
        'fill-blank' => studentAnswerTexts,
        'essay' => studentAnswerTexts,
        'match' => _matchStudentLines(),
        're-order' => _reorderStudentLines(),
        _ => const [],
      };

  List<String> get correctAnswerLines => switch (type) {
        'mcq' => _mcqCorrectLines(),
        'fill-blank' => correctAnswerTexts,
        'essay' => correctAnswerTexts,
        'match' => _matchCorrectLines(),
        're-order' => _reorderCorrectLines(),
        _ => const [],
      };

  List<String> _mcqStudentLines() {
    if (studentAnswerIds.isEmpty) return const [];
    return answers
        .where((a) => studentAnswerIds.contains(a.id))
        .map((a) => a.title)
        .toList();
  }

  List<String> _mcqCorrectLines() {
    return answers
        .where((a) => correctAnswerIds.contains(a.id))
        .map((a) => a.title)
        .toList();
  }

  List<String> _matchStudentLines() {
    if (studentAnswerPairs.isEmpty || prompts.isEmpty) return const [];

    final lines = <String>[];
    for (final prompt in prompts) {
      final responseId = studentResponseIdFor(prompt);
      if (responseId == null) continue;
      final response = _responseById(responseId);
      lines.add(
        pairLine(prompt.title, response?.title ?? '$responseId'),
      );
    }
    return lines;
  }

  List<String> _matchCorrectLines() {
    return prompts
        .map((p) => pairLine(p.title, p.response.title))
        .toList();
  }

  /// Web review looks up `{promptId: responseId}`.
  /// Submit/API stores `{responseId: promptId}`. Accept both.
  int? studentResponseIdFor(QuizMatchingPrompt prompt) {
    if (studentAnswerPairs.isEmpty) return null;

    final knownResponseIds = {
      for (final p in prompts) p.response.id,
    };

    final byPrompt = studentAnswerPairs[prompt.id];
    if (byPrompt != null &&
        byPrompt > 0 &&
        knownResponseIds.contains(byPrompt)) {
      return byPrompt;
    }

    for (final entry in studentAnswerPairs.entries) {
      if (entry.value == prompt.id && knownResponseIds.contains(entry.key)) {
        return entry.key;
      }
    }

    if (byPrompt != null && byPrompt > 0) return byPrompt;
    return null;
  }

  QuizMatchingResponse? _responseById(int id) {
    for (final prompt in prompts) {
      if (prompt.response.id == id) return prompt.response;
    }
    return null;
  }

  List<String> _reorderStudentLines() {
    if (studentAnswerPairs.isNotEmpty) {
      final entries = studentAnswerPairs.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return entries.map((entry) {
        final answer = answers.where((a) => a.id == entry.value).firstOrNull;
        return answer?.title ?? '${entry.value}';
      }).toList();
    }

    // Web stores re-order as `number[]`; those IDs land in studentAnswerIds.
    if (studentAnswerIds.isEmpty) return const [];
    return studentAnswerIds.map((id) {
      final answer = answers.where((a) => a.id == id).firstOrNull;
      return answer?.title ?? '$id';
    }).toList();
  }

  List<String> _reorderCorrectLines() {
    if (reorderCorrectAnswers.isEmpty) return const [];
    final sorted = [...reorderCorrectAnswers]
      ..sort((a, b) => a.order.compareTo(b.order));
    return sorted.map((item) {
      final answer = answers.where((a) => a.id == item.answerId).firstOrNull;
      return answer?.title ?? '${item.answerId}';
    }).toList();
  }

}

String pairLine(String left, String right) {
  final leftText = QuizHtmlText.plainText(left);
  final rightText = QuizHtmlText.plainText(right);
  return '${QuizHtmlText.bidiIsolate(leftText)} → ${QuizHtmlText.bidiIsolate(rightText)}';
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
