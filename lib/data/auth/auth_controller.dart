import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'auth_session.dart';
import 'auth_state_notifier.dart';

/// App-wide authentication state for navigation and other auth-gated UI.
class AuthController extends ChangeNotifier {
  AuthController._() {
    AuthStateNotifier.onChanged = (user) {
      if (user != null) {
        adopt(user);
      } else {
        release();
      }
    };
  }

  static final AuthController instance = AuthController._();

  AuthUser? _user;
  var _resolved = false;

  AuthUser? get user => _user;

  /// Session check finished (success or failure).
  bool get isResolved => _resolved;

  bool get isAuthenticated => _user != null;

  Future<void> hydrate() async {
    final restored = await AuthService.restoreSession();
    _user = restored ? await AuthSession.load() : null;
    _resolved = true;
    notifyListeners();
  }

  void adopt(AuthUser user) {
    _user = user;
    _resolved = true;
    notifyListeners();
  }

  void release() {
    _user = null;
    _resolved = true;
    notifyListeners();
  }
}
