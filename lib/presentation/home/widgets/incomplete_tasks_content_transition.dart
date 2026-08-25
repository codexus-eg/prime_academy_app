import 'package:flutter/material.dart';

import '../../../core/theme/app_durations.dart';
import '../models/incomplete_task.dart';

/// Matches web IncompleteProgressReport `AnimatePresence mode="wait"`:
/// fade + 10px vertical slide when switching incomplete-task categories.
class IncompleteTasksContentTransition extends StatelessWidget {
  const IncompleteTasksContentTransition({
    super.key,
    required this.category,
    required this.child,
  });

  final IncompleteTaskCategory category;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.incompleteCategorySwitch,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return DualTransitionBuilder(
          animation: animation,
          forwardBuilder: (context, animation, child) {
            return _CategoryEnterTransition(
              animation: animation,
              child: child!,
            );
          },
          reverseBuilder: (context, animation, child) {
            return _CategoryExitTransition(
              animation: animation,
              child: child!,
            );
          },
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(category),
        child: child,
      ),
    );
  }
}

class _CategoryEnterTransition extends StatelessWidget {
  const _CategoryEnterTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              0,
              AppDurations.incompleteCategorySlidePx * (1 - t),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _CategoryExitTransition extends StatelessWidget {
  const _CategoryExitTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(
              0,
              -AppDurations.incompleteCategorySlidePx * t,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Web `itemVariants`: opacity 0 → 1, y 20 → 0, scale 0.95 → 1.
class IncompleteTaskItemEnter extends StatefulWidget {
  const IncompleteTaskItemEnter({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<IncompleteTaskItemEnter> createState() =>
      _IncompleteTaskItemEnterState();
}

class _IncompleteTaskItemEnterState extends State<IncompleteTaskItemEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.incompleteTaskItemEnter,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final scale = AppDurations.incompleteTaskItemStartScale +
            (1 - AppDurations.incompleteTaskItemStartScale) * t;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              0,
              AppDurations.incompleteTaskItemSlidePx * (1 - t),
            ),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
