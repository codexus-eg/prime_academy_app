import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth/auth_session.dart';
import '../../data/courses/courses_api.dart';
import '../../data/courses/user_course.dart';
import '../../core/widgets/celebration_confetti_overlay.dart';
import '../exam/widgets/exam_confetti_overlay.dart';
import 'lesson_detail_page.dart';
import 'models/memory_card.dart';
import 'widgets/memory_card_completion_state.dart';
import 'widgets/memory_card_empty_state.dart';
import 'widgets/memory_card_stack.dart';
import 'widgets/memory_cards_progress_bar.dart';

class MemoryCardsPage extends StatefulWidget {
  const MemoryCardsPage({
    super.key,
    this.courseId,
    this.unitId,
    this.lessonId,
    this.cards = const [],
    this.realLessonId,
    this.cardsCompleted = false,
    this.isEnrolled = false,
  });

  final String? courseId;
  final String? unitId;
  final String? lessonId;
  final List<MemoryCard> cards;
  final int? realLessonId;
  final bool cardsCompleted;
  final bool isEnrolled;

  static const String routePath =
      '/course/:courseId/units/:unitId/lessons/:lessonId/memory-cards';
  static const String routeName = 'memory-cards';
  static const String standalonePath = '/memory-cards';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId/memory-cards';

  @override
  State<MemoryCardsPage> createState() => _MemoryCardsPageState();
}

class _MemoryCardsPageState extends State<MemoryCardsPage>
    with TickerProviderStateMixin {
  static const _dragThreshold = MemoryCardStack.dragThreshold;

  var _activeIndex = 0;
  var _isFlipped = false;
  var _dragX = 0.0;
  var _isDragging = false;
  var _behindHidden = false;
  var _showCompletion = false;
  var _confettiTrigger = 0;
  var _didDrag = false;
  var _canMark = false;
  var _loading = false;
  String? _loadError;

  late List<MemoryCard> _cards;
  late int? _realLessonId;
  late bool _cardsCompleted;
  late bool _isEnrolled;

  MemoryFlyDirection _flyDirection = MemoryFlyDirection.none;
  var _pendingFlyIndex = 0;
  late AnimationController _flyController;
  Timer? _behindTimer;

  bool get _isEmpty => _cards.isEmpty;
  bool get _isFlying => _flyDirection != MemoryFlyDirection.none;

  double get _progress {
    if (_showCompletion) return 1;
    if (_isEmpty) return 0;
    return _activeIndex / _cards.length;
  }

  @override
  void initState() {
    super.initState();
    _cards = List<MemoryCard>.from(widget.cards);
    _realLessonId = widget.realLessonId;
    _cardsCompleted = widget.cardsCompleted;
    _isEnrolled = widget.isEnrolled;

    if (_cards.isEmpty &&
        widget.courseId != null &&
        widget.unitId != null &&
        widget.lessonId != null) {
      _loadFromRoute();
    } else {
      _resolveCanMark();
    }
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completeFly();
        }
      });
  }

  Future<void> _loadFromRoute() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final courseId = int.tryParse(widget.courseId!);
      final moduleId = int.tryParse(widget.unitId!);
      final itemId = int.tryParse(widget.lessonId!);
      if (courseId == null || moduleId == null || itemId == null) {
        throw ApiException('تعذّر تحميل كروت الحفظ');
      }

      final module = await CoursesApi.fetchModuleItems(
        courseId: courseId,
        moduleId: moduleId,
      );

      UserModuleItem? activeItem;
      for (final item in module.items) {
        if (item.id == itemId) {
          activeItem = item;
          break;
        }
      }

      final realLessonId = activeItem?.lesson?.id;
      if (realLessonId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _cards = const [];
          _isEnrolled = module.isEnrolled;
        });
        return;
      }

      final playback = await CoursesApi.fetchLesson(realLessonId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _realLessonId = playback.id;
        _isEnrolled = module.isEnrolled;
        _cardsCompleted = playback.cardsCompleted;
        _cards = [
          for (final card in playback.cards)
            MemoryCard(
              id: card.id,
              text: card.text,
              answerText: card.answerText,
            ),
        ];
      });
      await _resolveCanMark();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'تعذّر تحميل كروت الحفظ';
      });
    }
  }

  Future<void> _resolveCanMark() async {
    if (_cardsCompleted || _realLessonId == null) return;
    final user = await AuthSession.load();
    if (mounted && _isEnrolled && user?.role == 1) {
      setState(() => _canMark = true);
    }
  }

  Future<void> _markCurrentCardViewed() async {
    if (!_canMark || _realLessonId == null || _isEmpty) return;
    final card = _cards[_activeIndex];
    try {
      await CoursesApi.markLessonCardViewed(
        lessonId: _realLessonId!,
        cardId: card.id,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _behindTimer?.cancel();
    _flyController.dispose();
    super.dispose();
  }

  void _setFlipped(bool value) {
    setState(() => _isFlipped = value);
    _behindTimer?.cancel();
    _behindTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_isFlipped) {
        setState(() => _behindHidden = true);
      } else {
        setState(() => _behindHidden = false);
      }
    });
  }

  void _toggleFlip() {
    if (_isFlying || _showCompletion) return;
    _setFlipped(!_isFlipped);
  }

  void _onCardTap() {
    if (_didDrag || _isFlying || _showCompletion) return;
    _toggleFlip();
  }

  void _completeFly() {
    if (!mounted) return;
    setState(() {
      _activeIndex = _pendingFlyIndex;
      _flyDirection = MemoryFlyDirection.none;
      _dragX = 0;
      _isFlipped = false;
      _behindHidden = false;
    });
    _flyController.reset();
  }

  void _startFly(MemoryFlyDirection direction, int nextIndex) {
    if (_isFlying || _isEmpty) return;
    _pendingFlyIndex = nextIndex;
    setState(() => _flyDirection = direction);
    _flyController.forward(from: 0);
  }

  void _navigate({required bool next}) {
    if (_isFlying || _isEmpty) return;
    if (next && _activeIndex >= _cards.length - 1) return;
    if (!next && _activeIndex <= 0) return;
    _startFly(
      next ? MemoryFlyDirection.left : MemoryFlyDirection.right,
      next ? _activeIndex + 1 : _activeIndex - 1,
    );
  }

  void _resetDeck() {
    if (_isEmpty) return;
    setState(() {
      _activeIndex = 0;
      _flyDirection = MemoryFlyDirection.none;
      _dragX = 0;
      _isDragging = false;
      _showCompletion = false;
      _isFlipped = false;
      _behindHidden = false;
    });
    _flyController.reset();
  }

  void _showCompletionScreen() {
    setState(() => _showCompletion = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _confettiTrigger++);
    });
  }

  void _handleMemorized() {
    if (_isFlying || _showCompletion || _isEmpty) return;
    _markCurrentCardViewed();
    if (_activeIndex >= _cards.length - 1) {
      _showCompletionScreen();
    } else {
      _navigate(next: true);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isFlying || _isEmpty || _showCompletion) return;
    _didDrag = false;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    var delta = _dragX + details.delta.dx;

    if (_activeIndex == 0 && delta > 0) delta = 0;
    if (_activeIndex == _cards.length - 1 &&
        delta < -_dragThreshold * 1.2) {
      delta = -_dragThreshold * 1.2;
    }

    if (delta.abs() > 6) _didDrag = true;
    setState(() => _dragX = delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    Future.delayed(const Duration(milliseconds: 50), () => _didDrag = false);

    if (_dragX < -_dragThreshold) {
      if (_activeIndex < _cards.length - 1) {
        _markCurrentCardViewed();
        _startFly(MemoryFlyDirection.left, _activeIndex + 1);
      } else {
        _markCurrentCardViewed();
        setState(() => _dragX = 0);
        _showCompletionScreen();
      }
    } else if (_dragX > _dragThreshold && _activeIndex > 0) {
      _startFly(MemoryFlyDirection.right, _activeIndex - 1);
    } else {
      setState(() => _dragX = 0);
    }
  }

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (widget.courseId != null &&
        widget.unitId != null &&
        widget.lessonId != null) {
      context.go(
        LessonDetailPage.pathFor(
          courseId: widget.courseId!,
          unitId: widget.unitId!,
          lessonId: widget.lessonId!,
        ),
      );
      return;
    }
    context.go('/home/incomplete-tasks');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.memoryCardsBackground,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.memoryCardsBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  TextButton(
                    onPressed: _loadFromRoute,
                    child: const Text('إعادة المحاولة'),
                  ),
                  TextButton(
                    onPressed: () => _exit(context),
                    child: const Text('رجوع'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.memoryCardsBackground,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                if (!_showCompletion)
                  _MemoryCardsHeader(
                    progress: _progress,
                    canGoPrevious: !_isEmpty && _activeIndex > 0 && !_isFlying,
                    isEmpty: _isEmpty,
                    onPrevious: () => _navigate(next: false),
                    onReset: _resetDeck,
                    onClose: () => _exit(context),
                  ),
                if (_showCompletion)
                  MemoryCardCompletionState(onClose: () => _exit(context))
                else if (_isEmpty)
                  MemoryCardEmptyState(onClose: () => _exit(context))
                else
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _flyController,
                      builder: (context, _) => MemoryCardStack(
                        cards: _cards,
                        activeIndex: _activeIndex,
                        flipped: _isFlipped,
                        dragX: _dragX,
                        isDragging: _isDragging,
                        flyDirection: _flyDirection,
                        flyT: _flyController.value,
                        behindHidden: _behindHidden,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onCardTap: _onCardTap,
                      ),
                    ),
                  ),
                if (!_showCompletion && !_isEmpty)
                  _MemoryCardsActionBar(
                    isFlipped: _isFlipped,
                    onMemorized: _handleMemorized,
                    onToggleFlip: _toggleFlip,
                    onExit: () => _exit(context),
                  ),
              ],
            ),
            if (_showCompletion)
              CelebrationConfettiOverlay(trigger: _confettiTrigger)
            else
              ExamConfettiOverlay(trigger: _confettiTrigger),
          ],
        ),
      ),
    );
  }
}

class _MemoryCardsHeader extends StatelessWidget {
  const _MemoryCardsHeader({
    required this.progress,
    required this.canGoPrevious,
    required this.isEmpty,
    required this.onPrevious,
    required this.onReset,
    required this.onClose,
  });

  final double progress;
  final bool canGoPrevious;
  final bool isEmpty;
  final VoidCallback onPrevious;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 18, 28, 18),
      child: Row(
        children: [
          TextButton(
            onPressed: canGoPrevious ? onPrevious : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.55),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.2),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'السابق',
              style: AppTypography.bodyMd.copyWith(fontWeight: AppFonts.semibold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            onPressed: isEmpty ? null : onReset,
            icon: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: isEmpty ? 0.15 : 0.3),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MemoryCardsProgressBar(progress: progress),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton.icon(
            onPressed: onClose,
            icon: Transform.rotate(
              angle: 3.141592653589793,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            label: Text(
              'العودة إلى الدرس',
              style: AppTypography.bodyMd.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: AppFonts.semibold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCardsActionBar extends StatelessWidget {
  const _MemoryCardsActionBar({
    required this.isFlipped,
    required this.onMemorized,
    required this.onToggleFlip,
    required this.onExit,
  });

  final bool isFlipped;
  final VoidCallback onMemorized;
  final VoidCallback onToggleFlip;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 20, 28, 36),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'حفظت',
              onPressed: onMemorized,
              isExit: false,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: _ActionButton(
              label: isFlipped ? 'إخفاء الإجابة' : 'عرض الإجابة',
              onPressed: onToggleFlip,
              isExit: false,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: _ActionButton(
              label: 'خروج',
              onPressed: onExit,
              isExit: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isExit,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isExit;

  @override
  Widget build(BuildContext context) {
    final borderColor = isExit
        ? const Color(0x66EF4444)
        : AppColors.blue;
    final textColor = isExit
        ? const Color(0xB3F87171)
        : Colors.white.withValues(alpha: 0.7);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: AppTypography.bodyLg
              .copyWith(fontSize: 18, fontWeight: AppFonts.bold),
        ),
      ),
    );
  }
}
