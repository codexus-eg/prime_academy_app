import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/quiz_html_text.dart';
import '../data/memory_card_palette.dart';
import '../models/memory_card.dart';

class MemoryFlipCard extends StatefulWidget {
  const MemoryFlipCard({
    super.key,
    required this.card,
    required this.cardIndex,
    required this.flipped,
    this.onTap,
  });

  final MemoryCard card;
  final int cardIndex;
  final bool flipped;
  final VoidCallback? onTap;

  @override
  State<MemoryFlipCard> createState() => _MemoryFlipCardState();
}

class _MemoryFlipCardState extends State<MemoryFlipCard>
    with SingleTickerProviderStateMixin {
  static const _flipCurve = Cubic(0.4, 0, 0.2, 1);
  static const _flipDuration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _flipDuration,
    );
    _animation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: _flipCurve),
    );
    if (widget.flipped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.flipped) {
          _controller.forward(from: 0);
        }
      });
    }
  }

  void _animateTo(bool flipped) {
    if (flipped) {
      _controller.forward(from: _controller.value);
    } else {
      _controller.reverse(from: _controller.value);
    }
  }

  @override
  void didUpdateWidget(covariant MemoryFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cardIndex != widget.cardIndex) {
      _controller.value = 0;
      if (widget.flipped) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.flipped) {
            _controller.forward(from: 0);
          }
        });
      }
      return;
    }

    if (oldWidget.flipped != widget.flipped) {
      _animateTo(widget.flipped);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color => MemoryCardPalette.colorAt(widget.cardIndex);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final angle = _animation.value;
            final showFront = angle < math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0007)
                ..rotateY(angle),
              child: showFront
                  ? _CardFace(
                      text: widget.card.text,
                      color: _color,
                      onTap: widget.onTap,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _CardFace(
                        text: widget.card.answerText.isEmpty
                            ? 'لا توجد اجابة'
                            : widget.card.answerText,
                        color: _color,
                        dimmed: true,
                        emptyAnswer: widget.card.answerText.isEmpty,
                        onTap: widget.onTap,
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.color,
    this.dimmed = false,
    this.emptyAnswer = false,
    this.onTap,
  });

  final String text;
  final Color color;
  final bool dimmed;
  final bool emptyAnswer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = (MediaQuery.sizeOf(context).width * 0.035)
        .clamp(22.0, 34.0)
        .toDouble();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        decoration: BoxDecoration(
          color: dimmed ? Color.lerp(color, Colors.black, 0.28) : color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _BidiAwareMultilineText(
              text: text,
              style: TextStyle(
                color: emptyAnswer
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white,
                fontSize: emptyAnswer ? 18 : fontSize,
                fontWeight: FontWeight.bold,
                height: 1.45,
                fontStyle: emptyAnswer ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web flashcards use `dir="auto"` + `whitespace-pre-wrap`. Flutter's single
/// Text in an RTL app treats the whole block as RTL, so trailing `?` on an
/// English line jumps to the start. Each line gets its own direction instead.
class _BidiAwareMultilineText extends StatelessWidget {
  const _BidiAwareMultilineText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  static final _breakTag = RegExp(r'<br\s*/?>', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final normalized = text.replaceAll(_breakTag, '\n').replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final lineHeight = (style.fontSize ?? 22) * (style.height ?? 1.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          if (line.trim().isEmpty)
            SizedBox(height: lineHeight / 2)
          else
            Directionality(
              textDirection: QuizHtmlText.detectTextDirection(line),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
      ],
    );
  }
}
