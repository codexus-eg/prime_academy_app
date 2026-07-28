import 'package:flutter/material.dart';

import '../../../core/theme/app_quiz_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/luck_card_question.dart';
import 'knowledge_lightning_icon.dart';

class LuckCardPickTile extends StatefulWidget {
  const LuckCardPickTile({
    super.key,
    required this.deckIndex,
    required this.result,
    required this.onTap,
    this.disabled = false,
    this.heroTag,
  });

  final int deckIndex;
  final LuckCardPickResult result;
  final VoidCallback? onTap;
  final bool disabled;
  final Object? heroTag;

  @override
  State<LuckCardPickTile> createState() => _LuckCardPickTileState();
}

class _LuckCardPickTileState extends State<LuckCardPickTile> {
  var _hovered = false;

  bool get _canInteract =>
      widget.onTap != null &&
      widget.result == LuckCardPickResult.unopened &&
      !widget.disabled;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.disabled && widget.result == LuckCardPickResult.unopened
        ? 0.4
        : 1.0;

    final hoverActive = _hovered && _canInteract;
    final scale = hoverActive ? 1.06 : 1.0;
    final translateY = hoverActive ? -4.0 : 0.0;

    Widget card = AspectRatio(
      aspectRatio: 3 / 4,
      child: Opacity(
        opacity: opacity,
        child: MouseRegion(
          onEnter: (_) {
            if (_canInteract) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (_hovered) setState(() => _hovered = false);
          },
          child: GestureDetector(
            onTapDown: _canInteract ? (_) => setState(() => _hovered = false) : null,
            onTapUp: _canInteract ? (_) => setState(() => _hovered = false) : null,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: scale),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, animatedScale, child) {
                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: animatedScale,
                    child: child,
                  ),
                );
              },

              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _canInteract ? widget.onTap : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppQuizPalette.luckCardGradient,
                    borderRadius:
                        BorderRadius.circular(AppRadius.tailwind2xl),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final iconSize =
                                (width * 0.35).clamp(22.0, 35.0);
                            return KnowledgeLightningIcon(size: iconSize);
                          },
                        ),
                      ),
                      if (widget.result != LuckCardPickResult.unopened)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: _ResultBadge(
                            isCorrect:
                                widget.result == LuckCardPickResult.correct,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      card = Hero(tag: widget.heroTag!, child: card);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, entryScale, child) {
        return Transform.scale(scale: entryScale, child: child);
      },
      child: card,
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isCorrect
            ? AppQuizPalette.knowledgeCorrectBadge
            : AppQuizPalette.knowledgeWrongBadge,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCorrect ? Icons.check_rounded : Icons.close_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
