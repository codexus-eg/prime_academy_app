import 'package:flutter/material.dart';

import '../../../core/theme/app_durations.dart';
import '../home_tab.dart';

/// Matches web `tabContentVariants` + `AnimatePresence mode="wait"` on
/// StudentProfile tab switches: fade + 10px vertical slide.
class HomeTabContentTransition extends StatelessWidget {
  const HomeTabContentTransition({
    super.key,
    required this.tab,
    required this.child,
  });

  final HomeTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.homeTabContentEnter,
      reverseDuration: AppDurations.homeTabContentExit,
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
            return _TabEnterTransition(animation: animation, child: child!);
          },
          reverseBuilder: (context, animation, child) {
            return _TabExitTransition(animation: animation, child: child!);
          },
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(tab),
        child: child,
      ),
    );
  }
}

class _TabEnterTransition extends StatelessWidget {
  const _TabEnterTransition({
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
            offset: Offset(0, AppDurations.homeTabContentSlidePx * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _TabExitTransition extends StatelessWidget {
  const _TabExitTransition({
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
            offset: Offset(0, -AppDurations.homeTabContentSlidePx * t),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
