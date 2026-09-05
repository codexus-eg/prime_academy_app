import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/lesson_surface_gate.dart';
import '../../../data/auth/auth_session.dart';
import '../../auth/login_page.dart';
import '../home_tab.dart';
import '../ranking/ranking_open_signal.dart';
import 'notification_link.dart';
import 'notification_pending.dart';

/// Opens a notification destination the same way web `<Link>` does.
///
/// Ranking from an active lesson must **fully leave** the lesson/video route
/// before Ranking mounts. A leftover Android/iOS platform view otherwise sits
/// on top of the Ranking body (tabs visible, table blank).
abstract final class NotificationNavigator {
  static Future<void> open(
    BuildContext context,
    NotificationNavigationTarget target,
  ) async {
    if (target.isExternal) {
      await _openExternal(context, target.externalUrl!);
      return;
    }

    final location = target.location;
    if (location.isEmpty) return;

    final user = await AuthSession.load();
    if (!context.mounted) return;
    if (user == null || user.id <= 0) {
      NotificationPending.store(
        target.opensRanking ? HomeTab.ranking.routePath : location,
      );
      context.go(LoginPage.routePath);
      return;
    }

    final router = GoRouter.of(context);

    if (target.opensRanking || _isRankingPath(Uri.parse(location).path)) {
      await openRankingTabDirectly(router);
      return;
    }

    final current = router.routerDelegate.currentConfiguration.uri;
    final dest = Uri.parse(location);

    if (isSameDestination(current, dest)) {
      return;
    }

    await _leaveLessonIfNeeded(router, current.path);

    if (dest.path.startsWith('/home')) {
      router.go(location);
      _resumeLessonSurfaceAfterNav();
      return;
    }

    if (current.path == dest.path) {
      router.go(location);
      _resumeLessonSurfaceAfterNav();
      return;
    }

    router.push(location);
    _resumeLessonSurfaceAfterNav();
  }

  static Future<void> openAfterAuth(BuildContext context) async {
    final pending = NotificationPending.take();
    if (pending == null || pending.isEmpty) {
      context.go(HomeTab.defaultTab.routePath);
      return;
    }

    final router = GoRouter.of(context);
    final dest = Uri.parse(pending);
    if (_isRankingPath(dest.path)) {
      await openRankingTabDirectly(router);
      return;
    }

    context.go(pending);
  }

  /// Tear down any lesson video surface, leave the lesson route, then open
  /// Ranking on a clean navigator stack — same destination as the تصنيفي tab.
  static Future<void> openRankingTabDirectly(GoRouter router) async {
    final currentPath =
        router.routerDelegate.currentConfiguration.uri.path;
    final fromLesson = _isLessonOrCoursePath(currentPath);

    if (kDebugMode) {
      debugPrint(
        '[Notification] openRankingTabDirectly from=$currentPath '
        'fromLesson=$fromLesson',
      );
    }

    if (fromLesson) {
      // 1) Detach native surfaces while the lesson is still mounted.
      await LessonSurfaceGate.instance.suppressForNavigation();

      // 2) Replace the lesson route with a Flutter-only home tab so the
      //    platform view is removed from the tree (pause-only is not enough).
      router.go(HomeTab.courses.routePath);
      await _waitUntilPath(router, HomeTab.courses.routePath);

      // 3) Now mount Ranking on a tree that never hosted the video.
      RankingOpenSignal.instance.requestOpen();
      router.go(HomeTab.ranking.routePath);
    } else {
      RankingOpenSignal.instance.requestOpen();
      router.go(HomeTab.ranking.routePath);
    }

    _resumeLessonSurfaceAfterNav();
  }

  static Future<void> _leaveLessonIfNeeded(
    GoRouter router,
    String path,
  ) async {
    if (!_isLessonOrCoursePath(path)) return;
    await LessonSurfaceGate.instance.suppressForNavigation();
    // Caller navigates next; surfaces already detached.
  }

  static bool _isLessonOrCoursePath(String path) =>
      path.contains('/lessons/') || path.contains('/course/');

  static Future<void> _waitUntilPath(GoRouter router, String path) async {
    final binding = WidgetsBinding.instance;
    for (var i = 0; i < 12; i++) {
      final current =
          router.routerDelegate.currentConfiguration.uri.path;
      if (current == path || current.startsWith('$path/')) {
        binding.scheduleFrame();
        try {
          await binding.endOfFrame
              .timeout(const Duration(milliseconds: 100));
        } on TimeoutException {
          // Idle binding.
        }
        // One extra frame so disposed PlatformViews finish detaching.
        binding.scheduleFrame();
        try {
          await binding.endOfFrame
              .timeout(const Duration(milliseconds: 100));
        } on TimeoutException {
          // Idle binding.
        }
        return;
      }
      binding.scheduleFrame();
      try {
        await binding.endOfFrame
            .timeout(const Duration(milliseconds: 100));
      } on TimeoutException {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[Notification] timed out waiting for $path '
        '(at ${router.routerDelegate.currentConfiguration.uri.path})',
      );
    }
  }

  static void _resumeLessonSurfaceAfterNav() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      LessonSurfaceGate.instance.resume();
    });
  }

  static bool _isRankingPath(String path) =>
      path == HomeTab.ranking.routePath ||
      path.startsWith('${HomeTab.ranking.routePath}/');

  static bool isSameDestination(Uri current, Uri dest) {
    if (current.path != dest.path) return false;
    return _queryEquals(current.queryParameters, dest.queryParameters);
  }

  static bool _queryEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(context, 'تعذّر فتح الرابط');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showMessage(context, 'تعذّر فتح الرابط');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'تعذّر فتح الرابط');
      }
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
