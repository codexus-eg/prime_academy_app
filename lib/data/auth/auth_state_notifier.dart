import 'auth_session.dart';

typedef AuthStateChanged = void Function(AuthUser? user);

/// Lightweight bridge so [AuthSession] can notify without importing Flutter.
abstract final class AuthStateNotifier {
  static AuthStateChanged? onChanged;
}
