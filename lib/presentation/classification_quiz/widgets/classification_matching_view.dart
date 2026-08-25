import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_answer_image.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../models/classification_question.dart';
import 'classification_matching_palette.dart';

class ClassificationMatchingView extends StatefulWidget {
  const ClassificationMatchingView({
    super.key,
    required this.question,
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onCorrectChange,
    required this.onAnswered,
    this.hideTitle = false,
    this.examStyle = false,
    this.onDragActiveChanged,
  });

  final ClassificationMatchingQuestion question;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<bool> onCorrectChange;
  final ValueChanged<Map<int, int>> onAnswered;
  final bool hideTitle;
  final bool examStyle;
  final ValueChanged<bool>? onDragActiveChanged;

  @override
  State<ClassificationMatchingView> createState() =>
      _ClassificationMatchingViewState();
}

class _ClassificationMatchingViewState extends State<ClassificationMatchingView> {
  late List<_MatchingPair> _pairs;
  final Map<int, int> _matches = {};
  var _submitted = false;
  var _checked = false;
  int? _draggingPromptId;
  var _dragOriginWasMatched = false;

  @override
  void initState() {
    super.initState();
    _initPairs();
    widget.onSubmitReady(_submit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAnswerChange(_canSubmit);
    });
  }

  @override
  void didUpdateWidget(covariant ClassificationMatchingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _matches.clear();
      _submitted = false;
      _checked = false;
      _draggingPromptId = null;
      _dragOriginWasMatched = false;
      _initPairs();
      widget.onSubmitReady(_submit);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onAnswerChange(_canSubmit);
      });
    }
  }

  void _initPairs() {
    final prompts = widget.question.prompts;
    final order = _shuffledResponseOrder(prompts.length);
    _pairs = [
      for (var i = 0; i < prompts.length; i++)
        _MatchingPair(
          prompt: prompts[i],
          response: prompts[order[i]].response,
        ),
    ];
  }

  int _promptIndex(int promptId) =>
      widget.question.prompts.indexWhere((prompt) => prompt.id == promptId);

  bool get _canSubmit =>
      !_submitted && _matches.length == widget.question.prompts.length;

  bool get _isCorrect => widget.question.prompts.every(
        (prompt) => _matches[prompt.response.id] == prompt.id,
      );

  void _submit() {
    if (_submitted || !_canSubmit) return;
    setState(() {
      _submitted = true;
      if (!widget.examStyle) _checked = true;
    });
    widget.onAnswerChange(false);
    widget.onCorrectChange(_isCorrect);

    final answers = Map<int, int>.from(_matches);

    if (widget.examStyle) {
      widget.onAnswered(answers);
      return;
    }

    if (_isCorrect) {
      Future<void>.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        widget.onAnswered(answers);
      });
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _matches
          ..clear()
          ..addEntries(
            widget.question.prompts.map(
              (prompt) => MapEntry(prompt.response.id, prompt.id),
            ),
          );
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      widget.onAnswered(Map<int, int>.from(_matches));
    });
  }

  void _assignMatch(int responseId, int promptId) {
    if (_submitted) return;
    setState(() {
      final existingResponse = _matches.entries
          .where((entry) => entry.value == promptId)
          .map((entry) => entry.key)
          .toList();
      for (final id in existingResponse) {
        _matches.remove(id);
      }

      final replacedPrompt = _matches[responseId];
      _matches[responseId] = promptId;

      if (replacedPrompt != null && replacedPrompt != promptId) {
        final vacantResponse = existingResponse
            .where((id) => id != responseId)
            .toList();
        if (vacantResponse.isNotEmpty) {
          _matches[vacantResponse.first] = replacedPrompt;
        }
      }

      _draggingPromptId = null;
      _dragOriginWasMatched = false;
    });
    HapticFeedback.lightImpact();
    widget.onDragActiveChanged?.call(false);
    widget.onAnswerChange(_canSubmit);
  }

  void _startDrag(int promptId) {
    if (_submitted) return;
    setState(() {
      _draggingPromptId = promptId;
      _dragOriginWasMatched = _matches.containsValue(promptId);
    });
    widget.onDragActiveChanged?.call(true);
  }

  void _finishDrag(int promptId, {required bool accepted}) {
    if (!mounted) return;
    setState(() {
      _draggingPromptId = null;

      if (!accepted && _dragOriginWasMatched && !_submitted) {
        _matches.removeWhere((_, value) => value == promptId);
      }
      _dragOriginWasMatched = false;
    });
    widget.onDragActiveChanged?.call(false);
    widget.onAnswerChange(_canSubmit);
  }

  void _cancelDrag(int promptId) {
    _finishDrag(promptId, accepted: false);
  }

  bool? _matchStatus(int responseId) {
    if (!_checked) return null;
    final matchedPromptId = _matches[responseId];
    final correctPrompt = widget.question.prompts
        .where((prompt) => prompt.response.id == responseId)
        .firstOrNull;
    return matchedPromptId == correctPrompt?.id;
  }

  Widget _buildPairRow(
    int index, {
    required bool stackPairVertically,
    required double slotWidth,
    required double slotHeight,
    required bool anyImage,
  }) {
    final pair = _pairs[index];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: stackPairVertically ? 400 : double.infinity,
      ),
      child: _MatchingPairRow(
        pair: pair,
        stackPairVertically: stackPairVertically,
        slotWidth: slotWidth,
        slotHeight: slotHeight,
        anyImage: anyImage,
        promptIndex: _promptIndex(pair.prompt.id),
        isPromptMatched: _matches.values.contains(pair.prompt.id),
        matchedPromptId: _matches[pair.response.id],
        matchStatus: _matchStatus(pair.response.id),
        submitted: _submitted,
        draggingPromptId: _draggingPromptId,
        promptFor: (promptId) => widget.question.prompts
            .where((prompt) => prompt.id == promptId)
            .firstOrNull,
        promptIndexFor: (promptId) {
          final idx = widget.question.prompts
              .indexWhere((prompt) => prompt.id == promptId);
          return idx < 0 ? 0 : idx;
        },
        onAssign: (promptId) => _assignMatch(pair.response.id, promptId),
        onDragStarted: _startDrag,
        onDragFinished: _finishDrag,
        onDragCanceled: _cancelDrag,
      ),
    );
  }

  Widget _buildPairsLayout(
    bool isWide,
    double slotWidth,
    double slotHeight,
    bool anyImage,
  ) {
    if (_pairs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'لا توجد عناصر للمطابقة في هذا السؤال',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
        ),
      );
    }

    if (widget.examStyle || !isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _pairs.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            _buildPairRow(
              index,
              stackPairVertically: false,
              slotWidth: slotWidth,
              slotHeight: slotHeight,
              anyImage: anyImage,
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _pairs.length; index++) ...[
          if (index > 0) const SizedBox(width: 32),
          Expanded(
            child: _buildPairRow(
              index,
              stackPairVertically: true,
              slotWidth: slotWidth,
              slotHeight: slotHeight,
              anyImage: anyImage,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final anyImage = widget.question.hasAnyImage;

    final slotHeight = anyImage
        ? (isWide ? 180.0 : 120.0)
        : (isWide ? 180.0 : 90.0);

    final pairsContent = Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        widget.examStyle ? 0 : 8,
        32,
        widget.examStyle ? 16 : 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = widget.examStyle || !isWide ? 12.0 : 0.0;
          final slotWidth = widget.examStyle || !isWide
              ? (constraints.maxWidth - gap) / 2
              : 400.0;
          return _buildPairsLayout(isWide, slotWidth, slotHeight, anyImage);
        },
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.hideTitle) _buildTitleCard(),
        pairsContent,
      ],
    );
  }

  Widget _buildTitleCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: QuizHtmlText(
          html: widget.question.title,
          baseStyle: AppTypography.bodyLg.copyWith(
            color: AppColors.onDark,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MatchingPair {
  const _MatchingPair({required this.prompt, required this.response});

  final ClassificationMatchingPrompt prompt;
  final ClassificationMatchingResponse response;
}

class _MatchingPairRow extends StatelessWidget {
  const _MatchingPairRow({
    required this.pair,
    required this.stackPairVertically,
    required this.slotWidth,
    required this.slotHeight,
    required this.anyImage,
    required this.promptIndex,
    required this.isPromptMatched,
    required this.matchedPromptId,
    required this.matchStatus,
    required this.submitted,
    required this.draggingPromptId,
    required this.promptFor,
    required this.promptIndexFor,
    required this.onAssign,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.onDragCanceled,
  });

  final _MatchingPair pair;
  final bool stackPairVertically;
  final double slotWidth;
  final double slotHeight;
  final bool anyImage;
  final int promptIndex;
  final bool isPromptMatched;
  final int? matchedPromptId;
  final bool? matchStatus;
  final bool submitted;
  final int? draggingPromptId;
  final ClassificationMatchingPrompt? Function(int promptId) promptFor;
  final int Function(int promptId) promptIndexFor;
  final ValueChanged<int> onAssign;
  final ValueChanged<int> onDragStarted;
  final void Function(int promptId, {required bool accepted}) onDragFinished;
  final ValueChanged<int> onDragCanceled;

  @override
  Widget build(BuildContext context) {
    final palette = ClassificationMatchingPalette.forIndex(
      promptIndex < 0 ? 0 : promptIndex,
    );
    final matchedPrompt =
        matchedPromptId == null ? null : promptFor(matchedPromptId!);
    final matchedPaletteIndex = matchedPromptId == null
        ? promptIndex
        : promptIndexFor(matchedPromptId!);

    final promptSlot = SizedBox(
      height: slotHeight,
      child: isPromptMatched
          ? const _EmptyPromptSlot()
          : _DraggablePromptBox(
              promptId: pair.prompt.id,
              title: pair.prompt.title,
              imageUrl: pair.prompt.imageUrl,
              anyImage: anyImage,
              palette: palette,
              matchStatus: null,
              disabled: submitted,
              slotWidth: slotWidth,
              slotHeight: slotHeight,
              onDragStarted: onDragStarted,
              onDragFinished: onDragFinished,
              onDragCanceled: onDragCanceled,
            ),
    );

    final responseSlot = SizedBox(
      height: slotHeight,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => !submitted,
        onAcceptWithDetails: (details) => onAssign(details.data),
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          final hasMatch = matchedPrompt != null && matchedPromptId != null;
          final draggingThis =
              hasMatch && draggingPromptId == matchedPromptId;

          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(

                ignoring: hasMatch && !draggingThis,
                child: _DropSlot(
                  text: pair.response.title,
                  imageUrl: pair.response.imageUrl,
                  anyImage: anyImage,
                  isOver: isOver && (!hasMatch || draggingThis),
                ),
              ),
              if (hasMatch)
                Opacity(
                  opacity: draggingThis ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: draggingThis,
                    child: _DraggablePromptBox(
                      promptId: matchedPromptId!,
                      title: matchedPrompt.title,
                      imageUrl: matchedPrompt.imageUrl,
                      anyImage: anyImage,
                      palette: ClassificationMatchingPalette.forIndex(
                        matchedPaletteIndex,
                      ),
                      matchStatus: matchStatus,
                      disabled: submitted,
                      slotWidth: slotWidth,
                      slotHeight: slotHeight,
                      highlighted: isOver,
                      onDragStarted: onDragStarted,
                      onDragFinished: onDragFinished,
                      onDragCanceled: onDragCanceled,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (stackPairVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          promptSlot,
          responseSlot,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Expanded(child: promptSlot),
        Expanded(child: responseSlot),
      ],
    );
  }
}

class _DraggablePromptBox extends StatelessWidget {
  const _DraggablePromptBox({
    required this.promptId,
    required this.title,
    required this.imageUrl,
    required this.anyImage,
    required this.palette,
    required this.matchStatus,
    required this.disabled,
    required this.slotWidth,
    required this.slotHeight,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.onDragCanceled,
    this.highlighted = false,
  });

  final int promptId;
  final String title;
  final String? imageUrl;
  final bool anyImage;
  final ClassificationMatchingPalette palette;
  final bool? matchStatus;
  final bool disabled;
  final double slotWidth;
  final double slotHeight;
  final ValueChanged<int> onDragStarted;
  final void Function(int promptId, {required bool accepted}) onDragFinished;
  final ValueChanged<int> onDragCanceled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final box = _OptionBox(
      title: title,
      imageUrl: imageUrl,
      anyImage: anyImage,
      palette: palette,
      matchStatus: matchStatus,
      disabled: disabled,
      highlighted: highlighted,
    );

    if (disabled) return box;

    return Draggable<int>(
      data: promptId,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      rootOverlay: true,
      feedback: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Transform.scale(
          scale: 1.05,
          child: SizedBox(
            width: slotWidth.clamp(72, 400),
            height: slotHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: palette.border.withValues(alpha: 0.55),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _OptionBox(
                title: title,
                imageUrl: imageUrl,
                anyImage: anyImage,
                palette: palette,
                matchStatus: matchStatus,
                disabled: false,
                highlighted: true,
                isDragging: true,
              ),
            ),
          ),
        ),
      ),

      childWhenDragging: const _EmptyPromptSlot(),
      onDragStarted: () {
        HapticFeedback.selectionClick();
        onDragStarted(promptId);
      },
      onDragEnd: (details) =>
          onDragFinished(promptId, accepted: details.wasAccepted),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: box,
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  const _OptionBox({
    required this.title,
    required this.imageUrl,
    required this.anyImage,
    required this.palette,
    required this.matchStatus,
    required this.disabled,
    this.highlighted = false,
    this.isDragging = false,
  });

  final String title;
  final String? imageUrl;
  final bool anyImage;
  final ClassificationMatchingPalette palette;
  final bool? matchStatus;
  final bool disabled;
  final bool highlighted;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final background = switch (matchStatus) {
      true => const Color(0x8C14532D),
      false => const Color(0x8C7F1D1D),
      null => palette.background,
    };
    final border = switch (matchStatus) {
      true => const Color(0xFF4ADE80),
      false => const Color(0xFFF87171),
      null => palette.border,
    };
    final textColor = switch (matchStatus) {
      true => const Color(0xFF4ADE80),
      false => const Color(0xFFF87171),
      null => palette.text,
    };
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasTitle = title.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: hasImage ? null : background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlighted ? const Color(0xFF60A5FA) : border,
          width: highlighted || isDragging ? 2.5 : 2,
        ),
        boxShadow: [
          if (highlighted || isDragging)
            BoxShadow(
              color: border.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: border.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Positioned.fill(
              child: QuizAnswerImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (hasImage && hasTitle)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xB3000000),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    title.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLg.copyWith(
                      color: textColor,
                      fontWeight: AppFonts.semibold,
                      height: 1.3,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          else if (!hasImage && hasTitle)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: QuizHtmlText(
                  html: title,
                  textAlign: TextAlign.center,
                  baseStyle: AppTypography.bodyLg.copyWith(
                    color: textColor,
                    fontWeight: AppFonts.semibold,
                    height: 1.3,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (matchStatus == true)
            const Positioned(
              top: 8,
              right: 8,
              child: _StatusBadge(
                icon: Icons.check_rounded,
                color: Color(0xFF22C55E),
              ),
            ),
          if (matchStatus == false)
            const Positioned(
              top: 8,
              right: 8,
              child: _StatusBadge(
                icon: Icons.close_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
          if (disabled)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }
}

class _DropSlot extends StatelessWidget {
  const _DropSlot({
    required this.text,
    required this.isOver,
    this.imageUrl,
    this.anyImage = false,
  });

  final String text;
  final String? imageUrl;
  final bool anyImage;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isOver
            ? const Color(0x243B82F6)
            : const Color(0x800F1217),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isOver
              ? const Color(0xFF60A5FA)
              : const Color(0xCC2A3350),
          width: isOver ? 2.5 : 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: isOver
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isOver
              ? const Color(0xB360A5FA)
              : const Color(0xCC2A3350),
          radius: AppRadius.lg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Opacity(
                  opacity: 0.35,
                  child: QuizAnswerImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasText)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLg.copyWith(
                        color: isOver
                            ? const Color(0xE660A5FA)
                            : Colors.white.withValues(alpha: 0.25),
                        fontWeight: AppFonts.semibold,
                        height: 1.3,
                        fontSize: anyImage && hasImage ? 14 : 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPromptSlot extends StatelessWidget {
  const _EmptyPromptSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x4D0A0D14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0x992A3350),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0x992A3350),
          radius: AppRadius.lg,
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

List<int> _shuffledResponseOrder(int length) {
  final original = List<int>.generate(length, (i) => i);
  final shuffled = List<int>.from(original)..shuffle(math.Random());
  var attempt = 0;
  while (_isSameOrder(original, shuffled) && attempt < 5) {
    shuffled.shuffle(math.Random());
    attempt++;
  }
  return shuffled;
}

bool _isSameOrder(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
