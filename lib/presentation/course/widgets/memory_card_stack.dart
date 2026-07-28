import 'package:flutter/material.dart';

import '../models/memory_card.dart';
import 'memory_flip_card.dart';

enum MemoryFlyDirection { none, left, right }

class MemoryCardStack extends StatelessWidget {
  const MemoryCardStack({
    super.key,
    required this.cards,
    required this.activeIndex,
    required this.flipped,
    required this.dragX,
    required this.isDragging,
    required this.flyDirection,
    required this.flyT,
    required this.behindHidden,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onCardTap,
  });

  static const dragThreshold = 80.0;

  final List<MemoryCard> cards;
  final int activeIndex;
  final bool flipped;
  final double dragX;
  final bool isDragging;
  final MemoryFlyDirection flyDirection;
  final double flyT;
  final bool behindHidden;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth.clamp(0, 700).toDouble();
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.55)
        .clamp(280.0, 500.0)
        .toDouble();

    final behindIndex = dragX > 0 ? activeIndex - 1 : activeIndex + 1;
    final hasBehindSlot =
        behindIndex >= 0 && behindIndex < cards.length;
    final showBehind = hasBehindSlot && !behindHidden;

    final dragProgress = (dragX.abs() / dragThreshold).clamp(0.0, 1.0);
    final showNextHint =
        isDragging && dragX < -20 && activeIndex < cards.length - 1;
    final showPrevHint = isDragging && dragX > 20 && activeIndex > 0;

    double behindScale = 0.92;
    if (flyDirection == MemoryFlyDirection.none && isDragging) {
      behindScale = 0.92 + dragProgress * 0.08;
    } else if (flyDirection != MemoryFlyDirection.none && flyT > 0) {
      behindScale = 0.92 + flyT * 0.08;
    }

    Offset cardOffset;
    double cardRotation;

    if (flyDirection == MemoryFlyDirection.left) {
      final startX = dragX;
      final endX = -screenWidth * 2;
      cardOffset = Offset(startX + (endX - startX) * flyT, 0);
      cardRotation = dragX * 0.03 + (-25 - dragX * 0.03) * flyT;
    } else if (flyDirection == MemoryFlyDirection.right) {
      final startX = dragX;
      final endX = screenWidth * 2;
      cardOffset = Offset(startX + (endX - startX) * flyT, 0);
      cardRotation = dragX * 0.03 + (25 - dragX * 0.03) * flyT;
    } else {
      cardOffset = Offset(dragX, 0);
      cardRotation = dragX * 0.03;
    }

    Widget buildCard(int index, {required bool cardFlipped, VoidCallback? onTap}) {
      return MemoryFlipCard(
        key: ValueKey('memory-card-$index'),
        card: cards[index],
        cardIndex: index,
        flipped: cardFlipped,
        onTap: onTap,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isDragging) ...[
                PositionedDirectional(
                  start: 40,
                  child: _DragHint(
                    label: 'التالي',
                    symbol: '‹',
                    opacity: showNextHint ? dragProgress : 0,
                  ),
                ),
                PositionedDirectional(
                  end: 40,
                  child: _DragHint(
                    label: 'السابق',
                    symbol: '›',
                    opacity: showPrevHint ? dragProgress : 0,
                  ),
                ),
              ],
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (hasBehindSlot)
                      Positioned.fill(
                        key: const ValueKey('memory-card-behind-slot'),
                        child: IgnorePointer(
                          ignoring: !showBehind,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: showBehind ? 1 : 0,
                            child: Transform.scale(
                              scale: behindScale,
                              child: buildCard(behindIndex, cardFlipped: false),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      key: const ValueKey('memory-card-active-slot'),
                      child: AnimatedContainer(
                        duration: isDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: Transform.translate(
                          offset: cardOffset,
                          child: Transform.rotate(
                            angle: cardRotation * 3.141592653589793 / 180,
                            child: buildCard(
                              activeIndex,
                              cardFlipped: flipped,
                              onTap: onCardTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint({
    required this.label,
    required this.symbol,
    required this.opacity,
  });

  final String label;
  final String symbol;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
