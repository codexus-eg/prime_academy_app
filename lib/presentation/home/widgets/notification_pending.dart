abstract final class NotificationPending {
  static String? _location;

  static void store(String location) {
    if (location.isEmpty) return;
    _location = location;
  }

  static String? take() {
    final value = _location;
    _location = null;
    return value;
  }
}
