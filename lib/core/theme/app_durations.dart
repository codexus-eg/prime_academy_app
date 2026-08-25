abstract final class AppDurations {
  static const Duration borderGradient = Duration(milliseconds: 250);
  static const Duration backgroundGradient = Duration(milliseconds: 400);
  static const Duration shadow = Duration(milliseconds: 400);
  static const Duration tab = Duration(milliseconds: 200);
  /// Web StudentProfile tabContentVariants enter (opacity + y).
  static const Duration homeTabContentEnter = Duration(milliseconds: 300);
  /// Web StudentProfile tabContentVariants exit.
  static const Duration homeTabContentExit = Duration(milliseconds: 150);
  static const double homeTabContentSlidePx = 10;
  static const Duration unitExpand = Duration(milliseconds: 250);
  static const Duration onboardingPage = Duration(milliseconds: 320);
  static const Duration onboardingIndicator = Duration(milliseconds: 250);
  static const Duration splashFrame = Duration(milliseconds: 500);
  static const Duration luckFeedback = Duration(milliseconds: 280);
  static const Duration luckAnswerDelay = Duration(milliseconds: 1200);
  static const Duration luckReturnToGrid = Duration(milliseconds: 2000);
  static const Duration luckReveal = Duration(milliseconds: 2000);
  static const Duration luckQuestionTimeout = Duration(seconds: 60);
  static const Duration examReveal = Duration(milliseconds: 1600);
  /// Web MCQ correct advance (confetti path). See [ExamCelebration].
  static const Duration examCorrectAdvance = Duration(milliseconds: 1500);
  /// Web every-4th-correct Lottie advance (`LOTTIE_DELAY`).
  static const Duration examCorrectLottieAdvance = Duration(milliseconds: 2100);
  /// Web MCQ incorrect advance.
  static const Duration examWrongHold = Duration(milliseconds: 2500);
  static const Duration examWrongHide = Duration(milliseconds: 500);
  static const Duration examStartProgress = Duration(milliseconds: 2000);
  static const Duration examQuestionEnter = Duration(milliseconds: 400);
  static const Duration memoryCardFlip = Duration(milliseconds: 500);
  static const Duration memoryCardFly = Duration(milliseconds: 380);
  static const Duration notificationOpacity = Duration(milliseconds: 400);
  static const Duration quizFeedbackHide = Duration(milliseconds: 1500);
  static const Duration hoverScale = Duration(milliseconds: 300);
  /// Web AwardsSwiper autoplay delay.
  static const Duration awardsAutoplayDelay = Duration(seconds: 2);
  /// Embla-like settle / programmatic scroll for awards carousel.
  static const Duration awardsCarouselScroll = Duration(milliseconds: 300);
  /// Web IncompleteProgressReport AnimatePresence tab switch.
  static const Duration incompleteCategorySwitch = Duration(milliseconds: 200);
  static const double incompleteCategorySlidePx = 10;
  /// Web itemVariants enter (opacity + y + scale).
  static const Duration incompleteTaskItemEnter = Duration(milliseconds: 300);
  static const double incompleteTaskItemSlidePx = 20;
  static const double incompleteTaskItemStartScale = 0.95;
}
