import 'auth_cookie_types.dart';

export 'auth_cookie_types.dart';

abstract final class AuthCookieClient {
  static Future<AuthLoginNetworkResult> login({
    required String identifier,
  }) {
    throw UnsupportedError('AuthCookieClient.login is unavailable on this platform');
  }

  static Future<AuthCookieRefreshResult?> refreshSession({
    required String refreshToken,
    String? expiredAccessToken,
  }) {
    throw UnsupportedError(
      'AuthCookieClient.refreshSession is unavailable on this platform',
    );
  }
}
