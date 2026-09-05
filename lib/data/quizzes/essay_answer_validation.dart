import '../../core/widgets/quiz_html_text.dart';

/// Essay grading rules (server `getCorrectAnswersForEssay` / product spec):
///
/// For each acceptable title in `correct_answers[]` (OR across titles):
/// - 1 word  → student's full answer must match that word exactly
/// - 2 words → at least 1 word from the title appears in the student's answer
/// - 3+ words → at least 2 words from the title appear in the student's answer
///
/// Also: `mark_all_answers_correct` → always correct.
///
/// Used for local preview only where noted; essay UI grades should prefer the
/// API `correct` field from submit endpoints when available.
abstract final class EssayAnswerValidation {
  static String normalize(String text) {
    return QuizHtmlText.plainText(text).trim().toLowerCase();
  }

  static List<String> words(String text) {
    return normalize(text).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static bool matchesTitle({
    required String correctTitle,
    required String studentAnswer,
  }) {
    final correctWords = words(correctTitle);
    if (correctWords.isEmpty) return false;

    if (correctWords.length == 1) {
      return normalize(studentAnswer) == correctWords.first;
    }

    final requiredMatches = correctWords.length == 2 ? 1 : 2;
    final studentWordSet = words(studentAnswer).toSet();
    var matches = 0;
    for (final word in correctWords) {
      if (studentWordSet.contains(word)) matches++;
    }
    return matches >= requiredMatches;
  }

  static bool isCorrect({
    required bool markAllAnswersCorrect,
    required Iterable<String> correctTitles,
    required String studentAnswer,
  }) {
    if (markAllAnswersCorrect) return true;

    if (normalize(studentAnswer).isEmpty) return false;

    return correctTitles.any(
      (title) => matchesTitle(
        correctTitle: title,
        studentAnswer: studentAnswer,
      ),
    );
  }
}
