/// Mirrors web `utils/quiz/quizStreak.ts` + MCQ advance delays in `McqQuestion.tsx`.
abstract final class ExamCelebration {
  /// Web `LOTTIE_DELAY` — every 4th correct answer shows Lottie instead of confetti.
  static const Duration lottieAdvance = Duration(milliseconds: 2100);

  /// Web MCQ correct fallback when streak does not request Lottie.
  static const Duration confettiAdvance = Duration(milliseconds: 1500);

  /// Web MCQ incorrect advance (`setTimeout(..., 2500)`).
  static const Duration incorrectAdvance = Duration(milliseconds: 2500);

  /// Web `useCelebration` Lottie auto-stop.
  static const Duration lottieAutoStop = Duration(milliseconds: 2000);

  /// Align Flutter confetti lifetime with the confetti advance delay so particles
  /// finish before the next question (web canvas may linger; Flutter must not).
  static const Duration confettiLifetime = Duration(milliseconds: 1500);

  /// Safety cap while waiting for overlay `onComplete` before advancing.
  static const Duration effectWaitTimeout = Duration(seconds: 6);

  /// Pause after the overlay hides so the last frame is not cut by the swap.
  static const Duration afterEffectPause = Duration(milliseconds: 300);

  /// Web essay/fill-blank: 3000ms when the correct-answer card is shown.
  static const Duration revealAdvance = Duration(milliseconds: 3000);

  static Duration holdFor({
    required bool isCorrect,
    required bool usedLottie,
    bool revealAnswer = false,
  }) {
    if (usedLottie) return lottieAdvance;
    if (revealAnswer) return revealAdvance;
    if (!isCorrect) return incorrectAdvance;
    return confettiAdvance;
  }
}
