import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/about/about_page.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/contact/contact_page.dart';
import '../../presentation/onboarding/onboarding_page.dart';
import '../../presentation/splash/splash_page.dart';
import 'auth_controller.dart';

/// Redirects unauthenticated users away from protected routes.
String? authRedirect(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;

  if (_isPublicRoute(location)) return null;

  final auth = AuthController.instance;
  if (!auth.isResolved) return null;

  if (!auth.isAuthenticated) {
    return LoginPage.routePath;
  }

  return null;
}

bool _isPublicRoute(String location) {
  const public = {
    LoginPage.routePath,
    SplashPage.routePath,
    OnboardingPage.routePath,
    AboutPage.routePath,
    ContactPage.routePath,
  };
  return public.contains(location);
}
