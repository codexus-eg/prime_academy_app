import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/quizzes/answered_question_models.dart';
import '../../data/quizzes/unit_quiz_question.dart';
import '../../data/quizzes/unit_quiz_api.dart';
import 'data/exam_sounds.dart';
import 'widgets/exam_animated_progress.dart';
import 'data/exam_celebration.dart';
import 'widgets/exam_confetti_overlay.dart';
import 'widgets/exam_feedback_banner.dart';
import 'widgets/exam_finished_state.dart';
import 'widgets/exam_lottie_overlay.dart';
import 'widgets/exam_ready_state.dart';
import 'widgets/exam_review_dialog.dart';
import 'widgets/exam_starry_background.dart';
import 'widgets/unit_exam_question_panel.dart';

enum _ExamPhase {
  loading,
  ready,
  launchProgress,
  inProgress,
  midProgress,
  finished,
  empty,
  error,
}

class ExamPage extends StatefulWidget {
  const ExamPage({
    super.key,
    this.quizId = 0,
    this.courseId,
    this.unitId,
  });

  final int quizId;
  final String? courseId;
  final String? unitId;

  static const String routePath = '/exam';
  static const String routeName = 'exam';
  static const String nestedRoutePath = 'quiz/:quizId';

  static String pathFor({
    required String courseId,
    required String unitId,
    required int quizId,
  }) =>
      '/course/$courseId/units/$unitId/quiz/$quizId';

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  _ExamPhase _phase = _ExamPhase.loading;
  String? _errorMessage;

  String _attemptId = '';
  String _reviewAttemptId = '';
  var _isFirstAttempt = true;
  List<UnitQuizQuestion> _questions = const [];
  int _questionsCount = 0;
  int _initialAnswered = 0;
  int _sessionAnswered = 0;
  int _correctCount = 0;

  bool _isContinue = false;
  bool _isLastChance = false;
  String? _startDateLabel;

  int _index = 0;
  int _passageChildIndex = -1;
  int? _selectedMcqId;
  bool _submitted = false;
  bool? _lastAnswerCorrect;
  int _confettiTrigger = 0;
  int _lottieTrigger = 0;
  int _celebrationClearToken = 0;
  Completer<void>? _celebrationCompleter;
  bool _lottieIsCorrect = true;
  bool _lastCelebrationUsedLottie = false;
  int _feedbackKey = 0;
  int _correctStreak = 0;
  bool _questionReady = false;
  var _submitting = false;

  int _earnedPoints = 0;
  int _totalPoints = 0;
  int _finishedCorrect = 0;
  int _finishedIncorrect = 0;
  bool _hasLastChance = false;
  bool _activatingLastChance = false;
  String? _lastChanceError;

  List<AnsweredQuizQuestion> _answeredQuestions = const [];

  double _progressStart = 0;
  double _progressEnd = 0;
  int? _pendingNextIndex;

  UnitQuizQuestion get _question => _questions[_index];

  UnitQuizQuestion get _activeQuestion {
    final q = _question;
    if (q is UnitPassageQuestion &&
        _passageChildIndex >= 0 &&
        _passageChildIndex < q.childQuestions.length) {
      return q.childQuestions[_passageChildIndex];
    }
    return q;
  }

  bool get _isPassageChild =>
      _question is UnitPassageQuestion && _activeQuestion.id != _question.id;

  int get _totalAnswered => _initialAnswered + _sessionAnswered;

  int get _answeredProgressPercent {
    if (_questionsCount == 0) return 0;
    return ((_totalAnswered / _questionsCount) * 100).round();
  }

  int get _readyProgressPercent {
    if (_questionsCount == 0) return 0;
    return ((_initialAnswered / _questionsCount) * 100).round();
  }

  static var _arDatesReady = false;

  static Future<void> _ensureArDates() async {
    if (_arDatesReady) return;
    await initializeDateFormatting('ar');
    _arDatesReady = true;
  }

  static String _formatAttemptStartDate(DateTime date) {
    try {
      return DateFormat('d MMM yyyy، hh:mm a', 'ar').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy, hh:mm a').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    ExamSounds.enable();
    _ensureArDates().then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    await _ensureArDates();
    setState(() {
      _phase = _ExamPhase.loading;
      _errorMessage = null;
      _answeredQuestions = const [];
    });

    if (widget.quizId <= 0) {
      setState(() {
        _errorMessage = 'معرّف الاختبار غير صالح';
        _phase = _ExamPhase.error;
      });
      return;
    }

    try {
      final attempt = await UnitQuizApi.startOrContinue(widget.quizId);
      if (!mounted) return;

      final questions = attempt.questions;

      if (attempt.isCompleted && questions.isEmpty) {
        setState(() {
          _phase = _ExamPhase.finished;
          _questionsCount = attempt.questionsCount;
        });
        return;
      }

      if (questions.isEmpty) {
        setState(() {
          _errorMessage = 'لا توجد أسئلة صالحة في هذا الاختبار';
          _phase = _ExamPhase.error;
        });
        return;
      }

      setState(() {
        _attemptId = attempt.attemptId;
        _reviewAttemptId = attempt.firstAttempt
            ? attempt.attemptId
            : (_reviewAttemptId.isNotEmpty ? _reviewAttemptId : attempt.attemptId);
        _isFirstAttempt = attempt.firstAttempt;
        _questions = questions;
        _questionsCount =
            attempt.questionsCount > 0 ? attempt.questionsCount : questions.length;
        _initialAnswered = attempt.totalAnswered;
        _sessionAnswered = 0;
        _correctCount = 0;
        _isContinue = attempt.isContinue;
        _isLastChance = attempt.isLastChance;

        _startDateLabel = attempt.isContinue && attempt.startedAt != null
            ? _formatAttemptStartDate(attempt.startedAt!)
            : null;
        _index = 0;
        _passageChildIndex = _initialPassageChildIndex(questions.first);
        _phase = _ExamPhase.ready;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        final code = error.statusCode;
        _errorMessage = code == null
            ? error.message
            : '${error.message} ($code)';
        _phase = _ExamPhase.error;
      });
    } catch (error, stackTrace) {
      debugPrint('ExamPage._load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر معالجة بيانات الاختبار';
        _phase = _ExamPhase.error;
      });
    }
  }

  int _initialPassageChildIndex(UnitQuizQuestion question) => -1;

  bool _isPassageChildId(String questionId) {
    final q = _question;
    if (q is! UnitPassageQuestion) return false;
    return q.childQuestions.any((child) => child.id == questionId);
  }

  void _handleReadyStart() {
    ExamSounds.enable();
    setState(() {
      _progressStart = _readyProgressPercent.toDouble();
      _progressEnd = _answeredProgressPercent.toDouble();
      _phase = _ExamPhase.launchProgress;
    });
  }

  Future<void> _openReview() async {
    await _ensureAnsweredQuestions();
    if (!mounted) return;

    await showExamReviewDialog(
      context,
      questions: _answeredQuestions,
      quizId: widget.quizId,
      attemptId: _reviewAttemptId.isNotEmpty ? _reviewAttemptId : _attemptId,
      fetchFromApi: false,
    );
  }

  Future<void> _ensureAnsweredQuestions() async {
    if (_answeredQuestions.isNotEmpty) return;

    final reviewAttemptId =
        _reviewAttemptId.isNotEmpty ? _reviewAttemptId : _attemptId;
    if (!_isFirstAttempt ||
        widget.quizId <= 0 ||
        reviewAttemptId.isEmpty) {
      return;
    }

    try {
      final review = await UnitQuizApi.getFirstAttemptReview(
        quizId: widget.quizId,
        attemptId: reviewAttemptId,
      );
      if (!mounted || review.answeredQuestions.isEmpty) return;
      setState(() => _answeredQuestions = review.answeredQuestions);
    } on ApiException catch (error) {
      debugPrint('ExamPage._ensureAnsweredQuestions: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('ExamPage._ensureAnsweredQuestions failed: $error\n$stackTrace');
    }
  }

  void _beginSession() {
    setState(() {
      _phase = _ExamPhase.inProgress;
      _index = 0;
      _passageChildIndex = _initialPassageChildIndex(_questions.first);
      _selectedMcqId = null;
      _submitted = false;
      _lastAnswerCorrect = null;
      _questionReady = false;
      _correctStreak = 0;
    });
    _armQuestionEntrance();
  }

  void _armQuestionEntrance() {
    Future.delayed(AppDurations.examQuestionEnter, () {
      if (mounted && _phase == _ExamPhase.inProgress) {
        setState(() => _questionReady = true);
      }
    });
  }

  Future<void> _onMcqSelect(int answerId) async {
    if (_submitted || !_questionReady || _submitting) return;
    final q = _activeQuestion;
    if (q is! UnitMcqQuestion || q.allowMultipleAnswers) return;

    setState(() {
      _selectedMcqId = answerId;
      _submitted = true;
    });

    await _handleSubmitAnswer(
      questionId: q.id,
      type: 'mcq',
      answers: [answerId],
    );
  }

  Future<void> _handleSubmitAnswer({
    required String questionId,
    required String type,
    required Object answers,
  }) async {
    if (_submitting) return;
    _submitting = true;

    final isPassageChild = _isPassageChildId(questionId);

    if (type == 'mcq') {
      final ids = answers is List ? answers : const [];
      if (ids.isNotEmpty) {
        setState(() {
          _selectedMcqId = ids.first is int ? ids.first as int : int.tryParse('${ids.first}');
          _submitted = true;
        });
      }
    } else {
      setState(() => _submitted = true);
    }

    try {
      final response = await UnitQuizApi.submitAnswer(
        quizId: widget.quizId,
        attemptId: _attemptId,
        questionId: questionId,
        type: type,
        answers: answers,
      );
      if (!mounted) return;

      final isCorrect = response.result.correct;
      setState(() {
        _lastAnswerCorrect = isCorrect;
        _feedbackKey++;
        if (_isPassageChild || _question.type != 'passage') {
          _sessionAnswered++;
          if (isCorrect) _correctCount++;
        }
      });
      _triggerCelebration(isCorrect);

      if (response.result.completed) {
        setState(() {
          _finishedCorrect = response.result.correctCount ?? _correctCount;
          _finishedIncorrect = response.result.inCorrectCount ??
              (_questionsCount - (response.result.correctCount ?? _correctCount));
          _earnedPoints = response.result.pointsAwarded ?? 0;
          _totalPoints = response.result.score ?? _questionsCount;
          _hasLastChance = response.result.hasLastChance;
          _answeredQuestions = response.answeredQuestions;
        });
        if (response.answeredQuestions.isEmpty) {
          await _ensureAnsweredQuestions();
        }
        await _holdFeedback(isCorrect);
        if (!mounted) return;
        setState(() => _phase = _ExamPhase.finished);
        return;
      }

      await _holdFeedback(isCorrect);
      if (!mounted) return;

      if (isPassageChild) {
        setState(() {
          _selectedMcqId = null;
          _submitted = false;
          _lastAnswerCorrect = null;
        });
        return;
      }

      await _goToNextQuestion();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _submitted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      _submitting = false;
    }
  }

  Future<void> _skipPassageQuestion() async {
    await _goToNextQuestion();
  }

  Future<void> _goToNextQuestion() async {
    final nextIndex = _index + 1;
    if (nextIndex >= _questions.length) {
      await _ensureAnsweredQuestions();
      if (!mounted) return;
      setState(() {
        _finishedCorrect = _correctCount;
        _finishedIncorrect = _questionsCount - _correctCount;
        _earnedPoints = _correctCount;
        _totalPoints = _questionsCount;
        _phase = _ExamPhase.finished;
      });
      return;
    }

    if (nextIndex % 3 == 0) {
      setState(() {
        _progressStart = _questionsCount == 0
            ? 0
            : ((_totalAnswered - 1) / _questionsCount) * 100;
        _progressEnd = _answeredProgressPercent.toDouble();
        _pendingNextIndex = nextIndex;
        _phase = _ExamPhase.midProgress;
      });
      return;
    }

    await _advanceQuestion();
  }

  void _onCelebrationComplete() {
    final completer = _celebrationCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitForCelebrationEffect() async {
    final completer = _celebrationCompleter;
    if (completer == null) return;
    await completer.future.timeout(
      ExamCelebration.effectWaitTimeout,
      onTimeout: () {},
    );
    _celebrationCompleter = null;
  }

  Future<void> _holdFeedback(bool isCorrect) async {
    final revealing = _activeQuestion is UnitEssayQuestion ||
        _activeQuestion is UnitFillBlankQuestion;
    final delay = ExamCelebration.holdFor(
      isCorrect: isCorrect,
      usedLottie: isCorrect && _lastCelebrationUsedLottie,
      revealAnswer: revealing,
    );
    // Keep the answer colors on screen for the web delay, and do not swap
    // questions until confetti / Lottie has actually finished playing.
    await Future.wait<void>([
      Future<void>.delayed(delay),
      _waitForCelebrationEffect(),
    ]);
    if (!mounted) return;
    await Future<void>.delayed(ExamCelebration.afterEffectPause);
    if (!mounted) return;
    await _clearCelebrations();
  }

  Future<void> _clearCelebrations() async {
    await ExamSounds.stop();
    if (!mounted) return;
    setState(() => _celebrationClearToken++);
  }

  void _completeMidProgress() {
    final next = _pendingNextIndex;
    if (next == null) {
      setState(() => _phase = _ExamPhase.inProgress);
      return;
    }
    setState(() {
      _index = next;
      _passageChildIndex = _initialPassageChildIndex(_questions[next]);
      _selectedMcqId = null;
      _submitted = false;
      _lastAnswerCorrect = null;
      _questionReady = false;
      _pendingNextIndex = null;
      _phase = _ExamPhase.inProgress;
    });
    _armQuestionEntrance();
  }

  Future<void> _advanceQuestion() async {
    if (_index >= _questions.length - 1) {
      await _ensureAnsweredQuestions();
      if (!mounted) return;
      setState(() {
        _finishedCorrect = _correctCount;
        _finishedIncorrect = _questionsCount - _correctCount;
        _earnedPoints = _correctCount;
        _totalPoints = _questionsCount;
        _phase = _ExamPhase.finished;
      });
      return;
    }

    setState(() {
      _index++;
      _passageChildIndex = _initialPassageChildIndex(_questions[_index]);
      _selectedMcqId = null;
      _submitted = false;
      _lastAnswerCorrect = null;
      _questionReady = false;
    });
    _armQuestionEntrance();
  }

  void _triggerCelebration(bool isCorrect) {
    _celebrationCompleter = Completer<void>();
    if (isCorrect) {
      ExamSounds.playCorrect();
      _correctStreak++;
      if (_correctStreak >= 4) {
        // Web: every 4th correct → Lottie + LOTTIE_DELAY (2100ms).
        _correctStreak = 0;
        _lastCelebrationUsedLottie = true;
        setState(() {
          _lottieIsCorrect = true;
          _lottieTrigger++;
        });
      } else {
        // Web: confetti + 1500ms MCQ advance.
        _lastCelebrationUsedLottie = false;
        setState(() => _confettiTrigger++);
      }
    } else {
      ExamSounds.playIncorrect();
      _correctStreak = 0;
      _lastCelebrationUsedLottie = true;
      setState(() {
        _lottieIsCorrect = false;
        _lottieTrigger++;
      });
    }
  }

  Future<void> _handleLastChance() async {
    setState(() {
      _activatingLastChance = true;
      _lastChanceError = null;
    });
    try {
      final attempt = await UnitQuizApi.startLastChance(widget.quizId);
      if (!mounted) return;
      setState(() {
        _questions = attempt.questions;
        _questionsCount = attempt.questionsCount;
        _initialAnswered = attempt.totalAnswered;
        _sessionAnswered = 0;
        _correctCount = 0;
        _attemptId = attempt.attemptId;
        _reviewAttemptId = attempt.attemptId;
        _isFirstAttempt = attempt.firstAttempt;
        _isLastChance = true;
        _isContinue = false;
        _startDateLabel = null;
        _hasLastChance = false;
        _activatingLastChance = false;
        _phase = _ExamPhase.ready;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _activatingLastChance = false;
        _lastChanceError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activatingLastChance = false;
        _lastChanceError = 'فشل تفعيل الفرصة الأخيرة، حاول مرة أخرى';
      });
    }
  }

  Widget _buildQuizBody() {
    final q = _question;

    final isPassageShell =
        q is UnitPassageQuestion && q.childQuestions.isNotEmpty;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal:
            isPassageShell ? 0 : AppSpacing.pageContentHorizontal,
      ),
      child: Column(
        children: [
          Expanded(
            child: UnitExamQuestionPanel(
              question: q,
              progressPercent: _answeredProgressPercent,
              questionReady: _questionReady,
              passageChildIndex: _passageChildIndex,
              onPassageChildChanged: (i) => setState(() {
                _passageChildIndex = i;
                _selectedMcqId = null;
                _submitted = false;
              }),
              selectedMcqId: _selectedMcqId,
              mcqSubmitted: _submitted,
              onMcqSelect: _onMcqSelect,
              onSubmit: ({
                required questionId,
                required type,
                required answers,
                localCorrect,
              }) =>
                  _handleSubmitAnswer(
                questionId: questionId,
                type: type,
                answers: answers,
              ),
              onMarkPassageChild: ({
                required questionId,
                required type,
                required answers,
              }) =>
                  _handleSubmitAnswer(
                questionId: questionId,
                type: type,
                answers: answers,
              ),
              onPassageComplete: _goToNextQuestion,
            ),
          ),
          if (q is UnitPassageQuestion && q.childQuestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _skipPassageQuestion,
                  child: const Text('التالي'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExamBackdropHost(
      child: Scaffold(
        backgroundColor: AppColors.examBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: ExamStarryBackground()),
          SafeArea(
            child: Center(
              child: switch (_phase) {
                _ExamPhase.loading => const CircularProgressIndicator(
                    color: AppColors.examAccentBlue,
                  ),
                _ExamPhase.ready => ExamReadyState(
                    progressPercent: _readyProgressPercent,
                    isContinue: _isContinue,
                    isLastChance: _isLastChance,
                    startDateLabel: _startDateLabel,
                    onStart: _handleReadyStart,
                    onExit: () => context.pop(),
                  ),
                _ExamPhase.launchProgress => SizedBox(
                    width: double.infinity,
                    child: ExamAnimatedProgress(
                      startPercent: _progressStart,
                      endPercent: _progressEnd,
                      showLaunchLabels: true,
                      onComplete: _beginSession,
                    ),
                  ),
                _ExamPhase.midProgress => SizedBox(
                    width: double.infinity,
                    child: ExamAnimatedProgress(
                      startPercent: _progressStart,
                      endPercent: _progressEnd,
                      duration: const Duration(milliseconds: 3000),
                      onComplete: _completeMidProgress,
                    ),
                  ),
                _ExamPhase.inProgress => _buildQuizBody(),
                _ExamPhase.finished => ExamFinishedState(
                    correctCount: _finishedCorrect > 0
                        ? _finishedCorrect
                        : _correctCount,
                    inCorrectCount: _finishedIncorrect > 0
                        ? _finishedIncorrect
                        : (_questionsCount - _correctCount),
                    earnedPoints: _earnedPoints > 0
                        ? _earnedPoints
                        : _correctCount,
                    totalPoints:
                        _totalPoints > 0 ? _totalPoints : _questionsCount,
                    hasLastChance: _hasLastChance,
                    onExit: () => context.pop(true),
                    onRestart: _load,
                    onLastChance: _handleLastChance,
                    isActivatingLastChance: _activatingLastChance,
                    errorMessage: _lastChanceError,
                    onReview: _openReview,
                  ),
                _ExamPhase.empty => _MessageState(
                    title: 'لا توجد أسئلة بعد',
                    subtitle: 'هذا الاختبار لا يحتوي على أسئلة في الوقت الحالي.',
                    onExit: () => context.pop(),
                  ),
                _ExamPhase.error => _MessageState(
                    title: 'حدث خطأ',
                    subtitle: _errorMessage ?? 'تعذّر تحميل الاختبار',
                    onExit: () => context.pop(),
                    onRetry: _load,
                  ),
              },
            ),
          ),
          if (_phase == _ExamPhase.inProgress ||
              _phase == _ExamPhase.midProgress) ...[
            ExamConfettiOverlay(
              trigger: _confettiTrigger,
              clearToken: _celebrationClearToken,
              onComplete: _onCelebrationComplete,
            ),
            ExamLottieOverlay(
              trigger: _lottieTrigger,
              isCorrect: _lottieIsCorrect,
              clearToken: _celebrationClearToken,
              onAnimationComplete: _onCelebrationComplete,
            ),
          ],
          if (_lastAnswerCorrect != null &&
              (_phase == _ExamPhase.inProgress ||
                  _phase == _ExamPhase.midProgress))
            ExamFeedbackBanner(
              key: ValueKey(_feedbackKey),
              isCorrect: _lastAnswerCorrect!,
            ),
        ],
      ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.subtitle,
    required this.onExit,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onExit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageContentHorizontal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.size28.copyWith(
              color: AppColors.onDark,
              fontWeight: AppFonts.extrabold,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (onRetry != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onExit,
              child: const Text('خروج'),
            ),
          ),
        ],
      ),
    );
  }
}
