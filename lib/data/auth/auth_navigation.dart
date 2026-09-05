import '../../presentation/auth/login_page.dart';
import '../../router/app_router.dart';
import '../notifications/notification_store.dart';
import '../onboarding/onboarding_storage.dart';
import '../sse/sse_service.dart';
import 'auth_service.dart';

/// Ends the session, clears user caches, and resets navigation to login.
abstract final class AuthNavigation {
  /// Calls the logout API, clears tokens/session, and opens login.
  static Future<void> signOut() async {
    SseService.instance.disconnect();
    NotificationStore.instance.reset();

    await AuthService.logout();
    await OnboardingStorage.markCompleted();

    _goLogin();
  }

  /// Clears local session state and opens login without a remote logout call.
  /// Use after [AuthService.deleteMyAccount] which already cleared the session.
  static Future<void> finishLocalSignOut() async {
    SseService.instance.disconnect();
    NotificationStore.instance.reset();
    await OnboardingStorage.markCompleted();
    _goLogin();
  }

  static void _goLogin() {
    appRouter.go(LoginPage.routePath);
  }
}
