import 'package:flutter/material.dart';

import 'lesson_surface_gate.dart';

/// When true, native platform views (YouTube iframe / WebView) must be
/// unmounted so they do not paint above Flutter overlays like [Drawer].
class PlatformViewOcclusion extends InheritedNotifier<ValueNotifier<bool>> {
  const PlatformViewOcclusion({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Drawer-open flag from [AppNavScaffold]. Prefer [isOccluded] which also
  /// checks [ScaffoldState.isDrawerOpen] so a stale notifier cannot leave
  /// players torn down forever.
  static bool of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlatformViewOcclusion>();
    return scope?.notifier?.value ?? false;
  }

  /// True when the scaffold drawer is open **or** [LessonSurfaceGate] is
  /// suppressing surfaces for navigation away from a lesson.
  static bool isOccluded(BuildContext context) {
    if (LessonSurfaceGate.instance.suppressed) return true;
    final flagged = of(context);
    final drawerOpen = Scaffold.maybeOf(context)?.isDrawerOpen;
    if (drawerOpen != null) return drawerOpen;
    return flagged;
  }
}
