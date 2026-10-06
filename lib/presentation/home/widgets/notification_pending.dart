import 'notification_link.dart';

/// Holds a destination until auth / first frame can navigate.
abstract final class NotificationPending {
  static String? _location;
  static String? _externalUrl;
  static var _opensRanking = false;

  static void store(String location) {
    if (location.isEmpty) return;
    _location = location;
    _externalUrl = null;
    _opensRanking = false;
  }

  static void storeTarget(NotificationNavigationTarget target) {
    if (target.opensRanking) {
      _location = '/home/ranking';
      _externalUrl = null;
      _opensRanking = true;
      return;
    }

    if (target.isExternal) {
      _externalUrl = target.externalUrl;
      _location = target.location.isEmpty ? '/home/courses' : target.location;
      _opensRanking = false;
      return;
    }

    store(target.location);
  }

  static String? take() {
    final value = _location;
    _location = null;
    _externalUrl = null;
    _opensRanking = false;
    return value;
  }

  static NotificationNavigationTarget? takeTarget() {
    final external = _externalUrl;
    final location = _location;
    final ranking = _opensRanking;
    _location = null;
    _externalUrl = null;
    _opensRanking = false;

    if (external != null && external.isNotEmpty) {
      return NotificationNavigationTarget(
        location: location ?? '/home/courses',
        externalUrl: external,
      );
    }
    if (ranking) {
      return const NotificationNavigationTarget(
        location: '/home/ranking',
        opensRanking: true,
      );
    }
    if (location == null || location.isEmpty) return null;
    return NotificationNavigationTarget(location: location);
  }
}
