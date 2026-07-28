import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/quiz_models.dart';
import '../../../data/quizzes/unit_quiz_question.dart';
import '../../classification_quiz/widgets/classification_matching_palette.dart';

class ExamReOrderView extends StatefulWidget {
  const ExamReOrderView({
    super.key,
    required this.question,
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onSubmit,
    this.onDragActiveChanged,
  });

  final UnitReOrderQuestion question;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<List<int>> onSubmit;
  final ValueChanged<bool>? onDragActiveChanged;

  @override
  State<ExamReOrderView> createState() => _ExamReOrderViewState();
}

class _ExamReOrderViewState extends State<ExamReOrderView> {
  late List<QuizMcqAnswer> _shuffledAnswers;
  final Map<int, int> _matches = {};
  var _submitted = false;
  int? _draggingAnswerId;
  var _dragAccepted = false;

  bool get _anyImage => widget.question.answers.any(_answerHasImage);

  double _slotHeightFor(double width) {
    final md = width >= 768;
    if (md) return 220;
    return _anyImage ? 160.0 : 100.0;
  }

  static bool _answerHasImage(QuizMcqAnswer answer) {
    if (answer.imageUrl != null && answer.imageUrl!.isNotEmpty) return true;
    return RegExp(r'<img\b', caseSensitive: false).hasMatch(answer.title);
  }

  bool get _canSubmit =>
      !_submitted && _matches.length == widget.question.answers.length;

  @override
  void initState() {
    super.initState();
    _shuffledAnswers = _shuffleAnswers(widget.question.answers);
    widget.onSubmitReady(_submit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAnswerChange(_canSubmit);
    });
  }

  @override
  void didUpdateWidget(covariant ExamReOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _matches.clear();
      _submitted = false;
      _draggingAnswerId = null;
      _dragAccepted = false;
      _shuffledAnswers = _shuffleAnswers(widget.question.answers);
      widget.onSubmitReady(_submit);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onAnswerChange(_canSubmit);
      });
    }
  }

  List<QuizMcqAnswer> _shuffleAnswers(List<QuizMcqAnswer> original) {
    if (original.length <= 1) return List<QuizMcqAnswer>.from(original);
    final shuffled = List<QuizMcqAnswer>.from(original)..shuffle(math.Random());
    var attempt = 0;
    while (_isSameOrder(original, shuffled) && attempt < 5) {
      shuffled.shuffle(math.Random());
      attempt++;
    }
    return shuffled;
  }

  bool _isSameOrder(List<QuizMcqAnswer> a, List<QuizMcqAnswer> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  int _visualIndex(int rowIndex) {
    final ascending = widget.question.sortDirection != 'desc';
    return ascending
        ? rowIndex
        : _shuffledAnswers.length - 1 - rowIndex;
  }

  List<int> _orderedAnswerIds() {
    final positions = _matches.keys.toList()..sort();
    return [for (final position in positions) _matches[position]!];
  }

  void _submit() {
    if (_submitted || !_canSubmit) return;
    setState(() => _submitted = true);
    widget.onAnswerChange(false);
    widget.onSubmit(_orderedAnswerIds());
  }

  void _assignMatch(int position, int answerId) {
    if (_submitted) return;
    _dragAccepted = true;
    setState(() {
      final fromPosition = _matches.entries
          .where((entry) => entry.value == answerId)
          .map((entry) => entry.key)
          .firstOrNull;
      if (fromPosition != null) {
        _matches.remove(fromPosition);
      }
      _matches[position] = answerId;
    });
    HapticFeedback.lightImpact();
    widget.onAnswerChange(_canSubmit);
  }

  void _startDrag(int answerId) {
    setState(() => _draggingAnswerId = answerId);
    widget.onDragActiveChanged?.call(true);
  }

  void _finishDrag(int answerId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _draggingAnswerId = null);
      widget.onDragActiveChanged?.call(false);
      widget.onAnswerChange(_canSubmit);
      _dragAccepted = false;
    });
  }

  void _cancelDrag(int answerId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_dragAccepted && !_submitted && _matches.containsValue(answerId)) {
        setState(() {
          _matches.removeWhere((_, value) => value == answerId);
          _draggingAnswerId = null;
        });
      } else {
        setState(() => _draggingAnswerId = null);
      }
      widget.onDragActiveChanged?.call(false);
      widget.onAnswerChange(_canSubmit);
      _dragAccepted = false;
    });
  }

  QuizMcqAnswer? _answerById(int id) {
    for (final answer in widget.question.answers) {
      if (answer.id == id) return answer;
    }
    return null;
  }

  int _shuffledIndexFor(int answerId) {
    return _shuffledAnswers.indexWhere((answer) => answer.id == answerId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = (constraints.maxWidth - 16) / 2;
          final slotHeight = _slotHeightFor(MediaQuery.sizeOf(context).width);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var rowIndex = 0; rowIndex < _shuffledAnswers.length; rowIndex++) ...[
                if (rowIndex > 0) const SizedBox(height: 16),
                _ReOrderPairRow(
                  answer: _shuffledAnswers[rowIndex],
                  position: _visualIndex(rowIndex),
                  slotWidth: slotWidth,
                  slotHeight: slotHeight,
                  isMatched: _matches.containsValue(_shuffledAnswers[rowIndex].id),
                  matchedAnswerId: _matches[_visualIndex(rowIndex)],
                  matchedAnswer: _matches[_visualIndex(rowIndex)] == null
                      ? null
                      : _answerById(_matches[_visualIndex(rowIndex)]!),
                  matchedAnswerIndex: _matches[_visualIndex(rowIndex)] == null
                      ? -1
                      : _shuffledIndexFor(_matches[_visualIndex(rowIndex)]!),
                  submitted: _submitted,
                  draggingAnswerId: _draggingAnswerId,
                  onAssign: _assignMatch,
                  onDragStarted: _startDrag,
                  onDragFinished: _finishDrag,
                  onDragCanceled: _cancelDrag,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReOrderPairRow extends StatelessWidget {
  const _ReOrderPairRow({
    required this.answer,
    required this.position,
    required this.slotWidth,
    required this.slotHeight,
    required this.isMatched,
    required this.matchedAnswerId,
    required this.matchedAnswer,
    required this.matchedAnswerIndex,
    required this.submitted,
    required this.draggingAnswerId,
    required this.onAssign,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.onDragCanceled,
  });

  final QuizMcqAnswer answer;
  final int position;
  final double slotWidth;
  final double slotHeight;
  final bool isMatched;
  final int? matchedAnswerId;
  final QuizMcqAnswer? matchedAnswer;
  final int matchedAnswerIndex;
  final bool submitted;
  final int? draggingAnswerId;
  final void Function(int position, int answerId) onAssign;
  final ValueChanged<int> onDragStarted;
  final ValueChanged<int> onDragFinished;
  final ValueChanged<int> onDragCanceled;

  @override
  Widget build(BuildContext context) {
    final promptSlot = SizedBox(
      height: slotHeight,
      child: isMatched && draggingAnswerId != answer.id
          ? const _EmptySourceSlot()
          : _DraggableReOrderBox(
              answer: answer,
              paletteIndex: position,
              slotWidth: slotWidth,
              slotHeight: slotHeight,
              disabled: submitted || isMatched,
              onDragStarted: onDragStarted,
              onDragFinished: onDragFinished,
              onDragCanceled: onDragCanceled,
            ),
    );

    final responseSlot = SizedBox(
      height: slotHeight,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => !submitted,
        onAcceptWithDetails: (details) => onAssign(position, details.data),
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          final hasMatch = matchedAnswer != null && matchedAnswerId != null;
          final isDraggingMatched =
              hasMatch && draggingAnswerId == matchedAnswerId;
          final shouldShowMatched =
              hasMatch && (!isDraggingMatched || isOver);

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: shouldShowMatched,
                  child: _PositionDropSlot(
                    label: '${position + 1}',
                    isOver: isOver && !shouldShowMatched,
                  ),
                ),
              ),
              if (hasMatch)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !shouldShowMatched,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: shouldShowMatched ? 1 : 0,
                      child: _DraggableReOrderBox(
                        answer: matchedAnswer!,
                        paletteIndex: matchedAnswerIndex >= 0
                            ? matchedAnswerIndex
                            : position,
                        slotWidth: slotWidth,
                        slotHeight: slotHeight,
                        disabled: submitted,
                        highlighted: isOver,
                        onDragStarted: onDragStarted,
                        onDragFinished: onDragFinished,
                        onDragCanceled: onDragCanceled,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Expanded(child: promptSlot),
        Expanded(child: responseSlot),
      ],
    );
  }
}

class _DraggableReOrderBox extends StatelessWidget {
  const _DraggableReOrderBox({
    required this.answer,
    required this.paletteIndex,
    required this.slotWidth,
    required this.slotHeight,
    required this.disabled,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.onDragCanceled,
    this.highlighted = false,
  });

  final QuizMcqAnswer answer;
  final int paletteIndex;
  final double slotWidth;
  final double slotHeight;
  final bool disabled;
  final ValueChanged<int> onDragStarted;
  final ValueChanged<int> onDragFinished;
  final ValueChanged<int> onDragCanceled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final box = _ReOrderOptionBox(
      answer: answer,
      paletteIndex: paletteIndex,
      slotHeight: slotHeight,
      highlighted: highlighted,
      disabled: disabled,
    );

    if (disabled) return box;

    return Draggable<int>(
      data: answer.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.04,
          child: SizedBox(
            width: slotWidth,
            height: slotHeight,
            child: Opacity(opacity: 0.97, child: box),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0,
        child: SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: box,
        ),
      ),
      onDragStarted: () => onDragStarted(answer.id),
      onDragEnd: (_) => onDragFinished(answer.id),
      onDraggableCanceled: (_, _) => onDragCanceled(answer.id),
      child: box,
    );
  }
}

class _ReOrderOptionBox extends StatelessWidget {
  const _ReOrderOptionBox({
    required this.answer,
    required this.paletteIndex,
    required this.slotHeight,
    required this.disabled,
    this.highlighted = false,
  });

  final QuizMcqAnswer answer;
  final int paletteIndex;
  final double slotHeight;
  final bool disabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = ClassificationMatchingPalette.forIndex(paletteIndex);
    final letter = String.fromCharCode(65 + (paletteIndex % 26));
    final displayTitle = answer.displayTitle;
    final imageUrl = answer.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasTitle = displayTitle.isNotEmpty;

    final showLetterBadge =
        !hasImage && MediaQuery.sizeOf(context).width >= 640;
    final isMobileLayout = MediaQuery.sizeOf(context).width < 768;
    const radius = AppRadius.tailwindXl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted ? const Color(0xFF60A5FA) : palette.border,
          width: highlighted ? 2.5 : 2,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : isMobileLayout
                ? null
                : [
                    BoxShadow(
                      color: palette.border.withValues(alpha: 0.13),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [

            if (!isMobileLayout) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x0DFFFFFF),
                      Color(0x03FFFFFF),
                      Colors.transparent,
                    ],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.25,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (showLetterBadge)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: palette.border,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.border.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: AppTypography.badge.copyWith(
                      color: AppColors.onDark,
                      fontWeight: AppFonts.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  showLetterBadge ? 34 : 12,
                  12,
                  12,
                ),
                child: _buildContent(
                  imageUrl: imageUrl,
                  hasImage: hasImage,
                  hasTitle: hasTitle,
                  displayTitle: displayTitle,
                  palette: palette,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required String? imageUrl,
    required bool hasImage,
    required bool hasTitle,
    required String displayTitle,
    required ClassificationMatchingPalette palette,
  }) {
    final imageHeight = hasTitle ? slotHeight * 0.55 : slotHeight * 0.65;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasImage)
          SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: QuizAnswerImage(
              imageUrl: imageUrl,
              iconColor: palette.text,
            ),
          ),
        if (hasImage && hasTitle) const SizedBox(height: 6),
        if (hasTitle)
          Expanded(
            child: Center(
              child: QuizHtmlText(
                html: displayTitle,
                textAlign: TextAlign.center,
                baseStyle: AppTypography.bodyLg.copyWith(
                  color: palette.text,
                  fontWeight: AppFonts.semibold,
                  height: 1.3,
                  shadows: const [
                    Shadow(
                      color: Color(0x80000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PositionDropSlot extends StatelessWidget {
  const _PositionDropSlot({
    required this.label,
    required this.isOver,
  });

  final String label;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.tailwindXl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOver
            ? const Color(0x403B82F6)
            : const Color(0x1A1E3A8A),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isOver
              ? const Color(0xFF60A5FA)
              : const Color(0x333B82F6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withValues(alpha: isOver ? 0.35 : 0.18),
            blurRadius: isOver ? 16 : 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(
            color: Colors.white.withValues(alpha: isOver ? 0.9 : 0.25),
            fontWeight: AppFonts.bold,
            fontSize: MediaQuery.sizeOf(context).width >= 640 ? 20 : 18,
            shadows: const [
              Shadow(
                color: Color(0x80000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySourceSlot extends StatelessWidget {
  const _EmptySourceSlot();

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.tailwindXl;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x1A1E3A8A),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0x333B82F6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0x553B82F6),
          radius: radius,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
