import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/quizzes/knowledge_answer_validation.dart';
import '../../data/quizzes/knowledge_quiz_api.dart';
import '../../data/quizzes/knowledge_quiz_question.dart';
import '../../data/quizzes/quiz_models.dart';
import 'data/luck_sounds.dart';
import 'models/luck_card_question.dart';
import 'widgets/knowledge_quiz_background.dart';
import 'widgets/luck_active_question.dart';
import 'widgets/luck_card_pick_tile.dart';
import 'widgets/luck_cards_stats_bar.dart';
import 'widgets/luck_empty_state.dart';
import 'widgets/luck_finished_state.dart';
import 'widgets/luck_knowledge_lottie_overlay.dart';

class LuckCardsPage extends StatefulWidget {
  const LuckCardsPage({
    super.key,
    required this.quizId,
  });

  final int quizId;

  static const String routePath = 'knowledge-quiz/:quizId';
  static const String routeName = 'knowledge-quiz';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
    required int quizId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId/knowledge-quiz/$quizId';

  @override
  State<LuckCardsPage> createState() => _LuckCardsPageState();
}

class _DeckCard {
  const _DeckCard({
    required this.deckIndex,
    required this.question,
  });

  final int deckIndex;
  final KnowledgeQuizQuestion question;
}

enum _LuckPhase { loading, empty, grid, question, finished, error }

class _LuckCardsPageState extends State<LuckCardsPage> {
  static const _questionTimeoutSeconds = 60;

  _LuckPhase _phase = _LuckPhase.loading;
  KnowledgeQuizAttempt? _attempt;
  String? _errorMessage;

  List<_DeckCard> _deck = const [];
  int _totalPicks = 5;
  int _questionsLeft = 5;

  List<LuckCardPickResult> _results = [];
  int? _activeCardIndex;
  int? _selectedAnswer;
  var _answered = false;
  bool? _answerCorrect;
  var _lottieTrigger = 0;
  var _lottieCorrect = true;
  Completer<void>? _feedbackEffectCompleter;
  var _totalPointsAwarded = 0;
  var _timerSeconds = _questionTimeoutSeconds;
  Timer? _timer;
  Timer? _tickLoop;

  int get _pickedCount =>
      _results.where((r) => r != LuckCardPickResult.unopened).length;

  int get _correctCount =>
      _results.where((r) => r == LuckCardPickResult.correct).length;

  int get _wrongCount =>
      _results.where((r) => r == LuckCardPickResult.wrong).length;

  int get _remaining => _totalPicks - _pickedCount;

  _DeckCard? get _activeCard {
    if (_activeCardIndex == null) return null;
    for (final card in _deck) {
      if (card.deckIndex == _activeCardIndex) return card;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stopTimer();
    LuckSounds.stopTimeTick();
    super.dispose();
  }

  List<_DeckCard> _buildDeck(KnowledgeQuizAttempt attempt) {
    final questions = attempt.questions;
    if (questions.isEmpty) return const [];

    final totalSlots = questions.length;
    final result = List<_DeckCard?>.filled(totalSlots, null);
    final usedSlots = <int>{};

    for (final q in questions.where((q) => q.isAnswered && q.answerIndex != null)) {
      final idx = q.answerIndex!;
      if (idx >= 0 && idx < totalSlots) {
        result[idx] = _DeckCard(
          deckIndex: idx,
          question: q,
        );
        usedSlots.add(idx);
      }
    }

    final unanswered = List<KnowledgeQuizQuestion>.from(
      questions.where((q) => !q.isAnswered),
    )..shuffle(Random());

    final emptySlots = [
      for (var i = 0; i < totalSlots; i++)
        if (!usedSlots.contains(i)) i,
    ];

    for (var i = 0; i < unanswered.length && i < emptySlots.length; i++) {
      final slot = emptySlots[i];
      final q = unanswered[i];
      result[slot] = _DeckCard(
        deckIndex: slot,
        question: q,
      );
    }

    return result.whereType<_DeckCard>().toList();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _LuckPhase.loading;
      _errorMessage = null;
    });

    try {
      final attempt = await KnowledgeQuizApi.startOrContinue(widget.quizId);
      if (!mounted) return;

      if (attempt.questions.isEmpty && !attempt.completed) {
        setState(() {
          _attempt = attempt;
          _phase = _LuckPhase.empty;
        });
        return;
      }

      final deck = _buildDeck(attempt);
      final slotCount = attempt.questions.length;
      final totalPicks = attempt.maxQuestionsPerAttempt > 0
          ? attempt.maxQuestionsPerAttempt
          : slotCount;

      final results = List<LuckCardPickResult>.filled(
        slotCount,
        LuckCardPickResult.unopened,
      );

      for (final card in deck) {
        final q = card.question;
        if (q.isAnswered && q.isCorrect != null) {
          results[card.deckIndex] =
              q.isCorrect! ? LuckCardPickResult.correct : LuckCardPickResult.wrong;
        }
      }

      if (attempt.completed) {
        setState(() {
          _attempt = attempt;
          _deck = deck;
          _totalPicks = totalPicks;
          _questionsLeft = attempt.questionsLeft;
          _results
            ..clear()
            ..addAll(results);
          _totalPointsAwarded = attempt.score ?? 0;
          _phase = _LuckPhase.finished;
        });
        return;
      }

      setState(() {
        _attempt = attempt;
        _deck = deck;
        _totalPicks = totalPicks;
        _questionsLeft = attempt.questionsLeft;
        _results
          ..clear()
          ..addAll(results);
        _phase = _LuckPhase.grid;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _phase = _LuckPhase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر تحميل كروت الحظ';
        _phase = _LuckPhase.error;
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _tickLoop?.cancel();
    _tickLoop = null;
    LuckSounds.stopTimeTick();
  }

  void _startTimer() {
    _stopTimer();
    setState(() => _timerSeconds = _questionTimeoutSeconds);
    LuckSounds.startTimeTick();
    _tickLoop = Timer.periodic(const Duration(seconds: 29), (_) {
      if (!_answered) LuckSounds.startTimeTick();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_answered) {
        _stopTimer();
        return;
      }
      if (_timerSeconds <= 1) {
        _stopTimer();
        _onTimeout();
        return;
      }
      setState(() => _timerSeconds--);
    });
  }

  void _openCard(int index) {
    if (_results[index] != LuckCardPickResult.unopened) return;
    if (_remaining <= 0 || _questionsLeft <= 0) return;
    LuckSounds.playFlipCard();
    setState(() {
      _activeCardIndex = index;
      _selectedAnswer = null;
      _answered = false;
      _answerCorrect = null;
      _phase = _LuckPhase.question;
    });
  }

  void _onTimeout() {
    if (_answered || _activeCardIndex == null) return;
    _finalizeAnswer(correct: false, selectedIndex: null, answers: const []);
  }

  void _onMcqAnswer(int optionIndex) {
    if (_answered || _activeCardIndex == null) return;
    final card = _activeCard;
    if (card == null || card.question is! KnowledgeMcqQuestion) return;
    final mcq = card.question as KnowledgeMcqQuestion;
    final answerIds = [mcq.answers[optionIndex].id];
    final correct =
        KnowledgeAnswerValidation.isCorrect(mcq, answerIds);
    _finalizeAnswer(
      correct: correct,
      selectedIndex: optionIndex,
      answers: answerIds,
    );
  }

  void _onTextSubmit(String text) {
    if (_answered || _activeCardIndex == null) return;
    final card = _activeCard;
    if (card == null) return;
    final answers = [text];
    final correct =
        KnowledgeAnswerValidation.isCorrect(card.question, answers);
    _finalizeAnswer(
      correct: correct,
      selectedIndex: null,
      answers: answers,
    );
  }

  void _onLottieAnimationComplete() {
    final completer = _feedbackEffectCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _startFeedbackEffect(bool correct) {
    _feedbackEffectCompleter = Completer<void>();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _lottieCorrect = correct;
        _lottieTrigger++;
      });
    });
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

  Future<void> _finalizeAnswer({
    required bool correct,
    required int? selectedIndex,
    required Object answers,
  }) async {
    final card = _activeCard;
    if (card == null || _attempt == null) return;

    _stopTimer();
    setState(() {
      _answered = true;
      _selectedAnswer = selectedIndex;
      _answerCorrect = correct;
      if (_activeCardIndex! < _results.length) {
        _results[_activeCardIndex!] =
            correct ? LuckCardPickResult.correct : LuckCardPickResult.wrong;
      }
      if (correct) _totalPointsAwarded += card.question.points;
    });

    if (correct) {
      LuckSounds.playCorrect();
      HapticFeedback.lightImpact();
    } else {
      LuckSounds.playIncorrect();
      HapticFeedback.mediumImpact();
    }

    _startFeedbackEffect(correct);

    await Future.delayed(AppDurations.luckAnswerDelay);
    if (!mounted) return;

    try {
      final result = await KnowledgeQuizApi.submitAnswer(
        quizId: widget.quizId,
        attemptId: _attempt!.attemptId,
        questionId: card.question.id,
        type: card.question.type,
        answers: answers,
        index: card.deckIndex,
      );

      if (!mounted) return;

      if (result.totalPointsAwarded != null) {
        _totalPointsAwarded = result.totalPointsAwarded!;
      } else if (result.awardedPoints > 0) {

      }

      setState(() => _questionsLeft = max(0, _questionsLeft - 1));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }

    await _waitForFeedbackEffect();
    if (!mounted) return;

    await Future.delayed(AppDurations.luckReturnToGrid);
    if (!mounted) return;

    if (_pickedCount >= _totalPicks || _questionsLeft <= 0) {
      setState(() => _phase = _LuckPhase.finished);
      return;
    }
    setState(() {
      _phase = _LuckPhase.grid;
      _activeCardIndex = null;
      _selectedAnswer = null;
      _answered = false;
      _answerCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showGrid =
        _phase == _LuckPhase.grid || _phase == _LuckPhase.question;

    return Scaffold(
      backgroundColor: AppColors.mainBg3,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const KnowledgeQuizBackground(),
          SafeArea(
            child: switch (_phase) {
              _LuckPhase.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                ),
              _LuckPhase.error => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage ?? 'حدث خطأ',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                        TextButton(onPressed: () => context.pop(), child: const Text('خروج')),
                      ],
                    ),
                  ),
                ),
              _LuckPhase.empty => LuckEmptyState(onExit: () => context.pop()),
              _LuckPhase.grid || _LuckPhase.question when showGrid => Offstage(
                  offstage: _phase == _LuckPhase.question,
                  child: _buildGridPhase(),
                ),
              _LuckPhase.finished => LuckFinishedState(
                  totalPointsAwarded: _totalPointsAwarded,
                  onExit: () => context.pop(true),
                ),
              _ => const SizedBox.shrink(),
            },
          ),
          if (_phase == _LuckPhase.question)
            Positioned.fill(child: _buildQuestionPhase()),
          if (_phase != _LuckPhase.finished &&
              _phase != _LuckPhase.loading &&
              _phase != _LuckPhase.error)
            LuckKnowledgeLottieOverlay(
              trigger: _lottieTrigger,
              isCorrect: _lottieCorrect,
              onAnimationComplete: _onLottieAnimationComplete,
            ),
        ],
      ),
    );
  }

  Widget _buildGridPhase() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Center(child: _buildPickHint()),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final align = constraints.maxWidth >= 1024
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.center;
                      return Align(
                        alignment: align,
                        child: LuckCardsStatsBar(
                          correctCount: _correctCount,
                          wrongCount: _wrongCount,
                          total: _totalPicks,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 16.0;
                        const minTileWidth = 130.0;
                        final columns = ((constraints.maxWidth + gap) /
                                (minTileWidth + gap))
                            .floor()
                            .clamp(1, 12);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: gap,
                            crossAxisSpacing: gap,
                            childAspectRatio: 3 / 4,
                          ),
                          itemCount: _deck.length,
                          itemBuilder: (context, index) {
                            final card = _deck[index];
                            final result = card.deckIndex < _results.length
                                ? _results[card.deckIndex]
                                : LuckCardPickResult.unopened;
                            final disabled = (_remaining <= 0 ||
                                    _questionsLeft <= 0) &&
                                result == LuckCardPickResult.unopened;
                            return LuckCardPickTile(
                              deckIndex: card.deckIndex,
                              result: result,
                              disabled: disabled,
                              heroTag: 'luck-card-${card.deckIndex}',
                              onTap: result == LuckCardPickResult.unopened &&
                                      _remaining > 0 &&
                                      _questionsLeft > 0
                                  ? () => _openCard(card.deckIndex)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        PositionedDirectional(
          top: AppSpacing.sm,
          start: AppSpacing.base,
          child: _buildCloseButton(),
        ),
      ],
      ),
    );
  }

  Widget _buildQuestionPhase() {
    final card = _activeCard;
    if (card == null) return const SizedBox.shrink();

    return LuckActiveQuestion(
      question: card.question,
      deckIndex: card.deckIndex,
      answered: _answered,
      selectedAnswer: _selectedAnswer,
      isCorrect: _answerCorrect,
      onMcqAnswer: _onMcqAnswer,
      onTextSubmit: _onTextSubmit,
      timerSeconds: _timerSeconds,
      totalTimerSeconds: _questionTimeoutSeconds,
      onTimerStart: _startTimer,
    );
  }

  Widget _buildPickHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentBg10,
        borderRadius: BorderRadius.circular(AppRadius.tailwindSm),
        border: Border.all(color: AppColors.accentBg, width: 2),
        boxShadow: AppShadows.lg,
      ),
      child: Text(
        'اختر $_totalPicks كروت وانت وحظك',
        textAlign: TextAlign.center,
        style: AppTypography.size24.copyWith(

          color: AppColors.accentIconMuted400,
          fontWeight: AppFonts.semibold,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}
