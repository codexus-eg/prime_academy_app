import 'package:flutter/material.dart';

import '../home_tab.dart';

/// Tab body host for [HomeShell].
///
/// No [AnimatedSwitcher] / opacity / slide: those can leave a zero-height or
/// invisible body when HomeShell is created immediately after leaving a lesson
/// (notification → Ranking), which matches the blank area under تصنيفي.
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
    return KeyedSubtree(
      key: ValueKey(tab),
      child: SizedBox(
        width: double.infinity,
        child: child,
      ),
    );
  }
}
