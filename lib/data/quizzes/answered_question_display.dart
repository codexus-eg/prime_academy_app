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
    if (studentAnswerPairs.isEmpty) return const [];
    return studentAnswerPairs.entries.map((entry) {
      final prompt = prompts.where((p) => p.id == entry.key).firstOrNull;
      QuizMatchingResponse? response;
      for (final p in prompts) {
        if (p.response.id == entry.value) {
          response = p.response;
          break;
        }
      }
      final promptTitle = prompt?.title ?? '${entry.key}';
      final responseTitle = response?.title ?? '${entry.value}';
      return '$promptTitle → $responseTitle';
    }).toList();
  }

  List<String> _matchCorrectLines() {
    return prompts.map((p) => '${p.title} → ${p.response.title}').toList();
  }

  List<String> _reorderStudentLines() {
    if (studentAnswerPairs.isEmpty) return const [];
    final entries = studentAnswerPairs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) {
      final answer = answers.where((a) => a.id == entry.value).firstOrNull;
      return answer?.title ?? '${entry.value}';
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
