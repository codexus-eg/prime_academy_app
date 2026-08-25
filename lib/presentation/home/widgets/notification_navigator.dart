import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/auth/auth_session.dart';
import '../../auth/login_page.dart';
import '../home_tab.dart';
import 'notification_link.dart';
import 'notification_pending.dart';

/// Opens a notification destination the same way web `<Link>` does:
/// push a history entry, skip duplicates, and restore after login.
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
      NotificationPending.store(location);
      context.go(LoginPage.routePath);
      return;
    }

    final router = GoRouter.of(context);
    final current = router.routerDelegate.currentConfiguration.uri;
    final dest = Uri.parse(location);

    if (isSameDestination(current, dest)) return;

    if (current.path == dest.path) {
      router.go(location);
      return;
    }

    final currentIsHome = current.path.startsWith('/home');
    final destIsHome = dest.path.startsWith('/home');
    if (currentIsHome && destIsHome) {
      router.go(location);
      return;
    }

    router.push(location);
  }

  static Future<void> openAfterAuth(BuildContext context) async {
    final pending = NotificationPending.take();
    if (pending == null || pending.isEmpty) {
      context.go(HomeTab.defaultTab.routePath);
      return;
    }
    context.go(pending);
  }

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
