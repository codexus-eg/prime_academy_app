abstract final class AuthCookieParser {
  static String? readCookie(Iterable<String> setCookieHeaders, String name) {
    for (final header in setCookieHeaders) {
      final value = _readFromHeader(header, name);
      if (value != null) return value;
    }
    return null;
  }

  static String? readCookieFromCombinedHeader(String? header, String name) {
    if (header == null || header.isEmpty) return null;
    return _readFromHeader(header, name);
  }

  static String? _readFromHeader(String header, String name) {
    final pattern = RegExp('(?:^|,\\s*)$name=([^;,]+)');
    return pattern.firstMatch(header)?.group(1);
  }
}
