import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/quizzes/classification_quiz_api.dart';
import '../../data/quizzes/quiz_models.dart' hide ClassificationLevel;
import '../../data/quizzes/quiz_ui_mapper.dart';
import 'data/classification_sounds.dart';
import 'models/classification_level.dart';
import 'models/classification_question.dart';
import 'widgets/classification_confirm_button.dart';
import 'widgets/classification_empty_state.dart';
import 'widgets/classification_fill_blank_view.dart';
import 'widgets/classification_finished_state.dart';
import 'widgets/classification_lottie_overlay.dart';
import 'widgets/classification_matching_view.dart';
import 'widgets/classification_mcq_view.dart';
import 'widgets/classification_progress_bar.dart';
import 'widgets/classification_ready_state.dart';
import 'widgets/classification_submit_container.dart';

enum _ClassificationPhase { loading, ready, inProgress, finished, empty, error }

class ClassificationQuizPage extends StatefulWidget {
  const ClassificationQuizPage({
    super.key,
    required this.quizId,
  });

  final int quizId;

  static const String routePath = 'classification-quiz/:quizId';
  static const String routeName = 'classification-quiz';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
    required int quizId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId/classification-quiz/$quizId';

  @override
  State<ClassificationQuizPage> createState() =>
      _ClassificationQuizPageState();
}

class _ClassificationQuizPageState extends State<ClassificationQuizPage> {
  _ClassificationPhase _phase = _ClassificationPhase.loading;
  ClassificationQuizAttempt? _attempt;
  String? _errorMessage;

  var _index = 0;
  var _answeredCount = 0;
  int? _selectedId;
  var _submitted = false;
  bool? _lastCorrect;
  var _feedbackKey = 0;
  var _lottieTrigger = 0;
  Completer<void>? _feedbackEffectCompleter;
  var _canSubmit = false;
  VoidCallback? _submitHandler;
  var _matchingDragActive = false;

  ClassificationLevel? _currentLevel;
  List<ClassificationLevel> _levels = const [];
  List<ClassificationQuestion> _questions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _ClassificationPhase.loading;
      _errorMessage = null;
    });
    try {
      final attempt =
          await ClassificationQuizApi.startOrContinue(widget.quizId);
      if (!mounted) return;

      final questions = attempt.questions
          .map(QuizUiMapper.toClassificationQuestion)
          .toList();
      final levels =
          attempt.levels.map(QuizUiMapper.toUiLevel).toList(growable: false);

      if (attempt.completed) {
        setState(() {
          _attempt = attempt;
          _questions = questions;
          _levels = levels;
          _currentLevel = QuizUiMapper.toUiLevel(attempt.level);
          _answeredCount = attempt.answeredCount;
          _phase = _ClassificationPhase.finished;
        });
        return;
      }

      if (questions.isEmpty) {
        setState(() {
          _attempt = attempt;
          _questions = questions;
          _levels = levels;
          _currentLevel = QuizUiMapper.toUiLevel(attempt.level);
          _answeredCount = attempt.answeredCount;
          _phase = _ClassificationPhase.empty;
        });
        return;
      }

      setState(() {
        _attempt = attempt;
        _questions = questions;
        _levels = levels;
        _currentLevel = QuizUiMapper.toUiLevel(attempt.level);
        _answeredCount = attempt.answeredCount;
        _index = 0;

        _phase = _ClassificationPhase.ready;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _phase = _ClassificationPhase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر تحميل اختبار التصنيف';
        _phase = _ClassificationPhase.error;
      });
    }
  }

  ClassificationLevel get _level =>
      _currentLevel ??
      (_levels.isNotEmpty
          ? _levels.first
          : const ClassificationLevel(
              title: '',
              questionsRequired: 0,
              imageIndex: 0,
            ));

  ClassificationLevel? get _nextLevel {
    final idx = _levels.indexWhere((l) => l.title == _level.title);
    if (idx < 0 || idx >= _levels.length - 1) return null;
    return _levels[idx + 1];
  }

  ClassificationQuestion get _question => _questions[_index];

  bool get _hideSubmitButton => _question is ClassificationMcqQuestion;

  void _start() => setState(() => _phase = _ClassificationPhase.inProgress);

  void _registerSubmitHandler(VoidCallback handler) {
    _submitHandler = handler;
  }

  void _onCanSubmitChanged(bool canSubmit) {
    if (_canSubmit != canSubmit) {
      setState(() => _canSubmit = canSubmit);
    }
  }

  void _onLottieAnimationComplete() {
    final completer = _feedbackEffectCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitForFeedbackEffect() async {
    final completer = _feedbackEffectCompleter;
    if (completer == null) return;
    await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );
    _feedbackEffectCompleter = null;
  }

  void _onCorrectChanged(bool isCorrect) {
    _feedbackEffectCompleter = Completer<void>();
    setState(() {
      _lastCorrect = isCorrect;
      _feedbackKey++;
      _lottieTrigger++;
    });
    if (isCorrect) {
      unawaited(ClassificationSounds.playCorrect());
    } else {
      unawaited(ClassificationSounds.playIncorrect());
    }
  }

  Future<void> _advanceAfterAnswer({
    required String type,
    required Object answers,
  }) async {
    await _waitForFeedbackEffect();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await _submitToApi(type: type, answers: answers);
  }

  Future<void> _onSelectMcq(int answerId) async {
    if (_submitted || _attempt == null) return;
    final question = _question as ClassificationMcqQuestion;
    final isCorrect = question.correctAnswerIds.contains(answerId);
    _feedbackEffectCompleter = Completer<void>();
    setState(() {
      _selectedId = answerId;
      _submitted = true;
      _lastCorrect = isCorrect;
      _feedbackKey++;
      _lottieTrigger++;
    });

    if (isCorrect) {
      unawaited(ClassificationSounds.playCorrect());
    } else {
      unawaited(ClassificationSounds.playIncorrect());
    }

    await _advanceAfterAnswer(
      type: 'mcq',
      answers: [answerId],
    );
  }

  Future<void> _onFillBlankAnswered(String answer) async {
    await _waitForFeedbackEffect();
    if (!mounted) return;
    await _submitToApi(type: 'fill-blank', answers: [answer]);
  }

  Future<void> _onMatchingAnswered(Map<int, int> matches) async {
    await _waitForFeedbackEffect();
    if (!mounted) return;
    final payload = {
      for (final entry in matches.entries) '${entry.key}': entry.value,
    };
    await _submitToApi(type: 'match', answers: payload);
  }

  Future<void> _submitToApi({
    required String type,
    required Object answers,
  }) async {
    if (_attempt == null) return;

    try {
      final result = await ClassificationQuizApi.submitAnswer(
        quizId: widget.quizId,
        attemptId: _attempt!.attemptId,
        questionId: _question.id,
        type: type,
        answers: answers,
      );

      if (!mounted) return;

      if (result.level != null && result.level!.title != _level.title) {
        unawaited(ClassificationSounds.playLevelUp());
        setState(() => _currentLevel = QuizUiMapper.toUiLevel(result.level!));
      }

      setState(() => _answeredCount++);

      if (result.completed || _index >= _questions.length - 1) {
        setState(() => _phase = _ClassificationPhase.finished);
        return;
      }

      setState(() {
        _index++;
        _selectedId = null;
        _submitted = false;
        _lastCorrect = null;
        _canSubmit = false;
        _submitHandler = null;
        _matchingDragActive = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() {
        _selectedId = null;
        _submitted = false;
        _lastCorrect = null;
        _canSubmit = false;
      });
    }
  }

  void _handleConfirmTap() => _submitHandler?.call();

  Widget _buildQuestionView() {
    final question = _question;
    return switch (question) {
      ClassificationMcqQuestion mcq => ClassificationMcqView(
          question: mcq,
          selectedId: _selectedId,
          isSubmitted: _submitted,
          onSelect: _onSelectMcq,
        ),
      ClassificationFillBlankQuestion fill => ClassificationFillBlankView(
          question: fill,
          onSubmitReady: _registerSubmitHandler,
          onAnswerChange: _onCanSubmitChanged,
          onCorrectChange: _onCorrectChanged,
          onAnswered: _onFillBlankAnswered,
        ),
      ClassificationMatchingQuestion match => ClassificationMatchingView(
          question: match,
          onSubmitReady: _registerSubmitHandler,
          onAnswerChange: _onCanSubmitChanged,
          onCorrectChange: _onCorrectChanged,
          onAnswered: _onMatchingAnswered,
          onDragActiveChanged: (active) {
            if (_matchingDragActive == active) return;
            setState(() => _matchingDragActive = active);
          },
        ),
    };
  }

  Widget _buildInProgressBody(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      child: SingleChildScrollView(
        key: ValueKey(_question.id),
        physics: _matchingDragActive
            ? const NeverScrollableScrollPhysics()
            : null,

        padding: const EdgeInsets.only(bottom: 128),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: wide ? 20 : 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.mainBg2, AppColors.mainBg],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    borderRadius: wide
                        ? BorderRadius.circular(16)
                        : BorderRadius.zero,
                    boxShadow: AppShadows.shadow2xl,
                  ),
                  child: _buildQuestionView(),
                ),
                if (!_hideSubmitButton)
                  const SizedBox(height: 24),
                if (!_hideSubmitButton)
                  Center(
                    child: ClassificationConfirmButton(
                      enabled: _canSubmit,
                      onPressed: _handleConfirmTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShellPanel(BuildContext context, Widget child) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: wide ? 20 : 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.mainBg2, AppColors.mainBg],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              borderRadius: wide
                  ? BorderRadius.circular(16)
                  : BorderRadius.zero,
              boxShadow: AppShadows.shadow2xl,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.classificationShellBg,
        body: ColoredBox(
          color: AppColors.classificationShellBg,
          child: switch (_phase) {
            _ClassificationPhase.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            _ClassificationPhase.error => _ErrorState(
                message: _errorMessage ?? 'حدث خطأ',
                onRetry: _load,
                onExit: () => context.pop(),
              ),
            _ => Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      if (_phase == _ClassificationPhase.inProgress)
                        ClassificationProgressBar(
                          current: _index + 1,
                          total: _questions.length,
                        ),
                      Expanded(
                        child: switch (_phase) {
                          _ClassificationPhase.ready => _buildShellPanel(
                            context,
                            ClassificationReadyState(
                              currentLevel: _level,
                              totalQuestions: _attempt?.questionsCount ??
                                  _questions.length,
                              answeredQuestions: _answeredCount,
                              isContinue: _attempt?.status == 'continued',
                              onStart: _start,
                            ),
                          ),
                          _ClassificationPhase.inProgress =>
                            _buildInProgressBody(context),
                          _ClassificationPhase.finished => _buildShellPanel(
                            context,
                            ClassificationFinishedState(
                              currentLevel: _level,
                              onExit: () => context.pop(true),
                            ),
                          ),
                          _ClassificationPhase.empty => _buildShellPanel(
                            context,
                            ClassificationEmptyState(
                              onExit: () => context.pop(),
                            ),
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ),
                  if (_phase == _ClassificationPhase.inProgress) ...[
                    ClassificationLottieOverlay(
                      trigger: _lottieTrigger,
                      isCorrect: _lastCorrect ?? false,
                      onAnimationComplete: _onLottieAnimationComplete,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClassificationSubmitContainer(
                        currentLevel: _level,
                        nextLevel: _nextLevel,
                        isCorrect: _lastCorrect,
                        feedbackKey: _feedbackKey,
                      ),
                    ),
                  ],
                ],
              ),
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onExit,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            TextButton(onPressed: onExit, child: const Text('خروج')),
          ],
        ),
      ),
    );
  }
}
