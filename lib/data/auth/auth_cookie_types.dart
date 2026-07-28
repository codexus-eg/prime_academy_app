class AuthLoginNetworkResult {
  const AuthLoginNetworkResult({
    required this.statusCode,
    required this.body,
    this.refreshToken,
    this.accessTokenFromCookie,
  });

  final int statusCode;
  final Map<String, dynamic>? body;
  final String? refreshToken;
  final String? accessTokenFromCookie;
}

class AuthCookieRefreshResult {
  const AuthCookieRefreshResult({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
}

class AuthLoginNetworkException implements Exception {
  AuthLoginNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}
