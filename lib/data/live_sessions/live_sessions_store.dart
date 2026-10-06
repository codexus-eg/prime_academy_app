import 'package:flutter/foundation.dart';

import 'live_session.dart';

class LiveSessionsStore extends ChangeNotifier {
  LiveSessionsStore._();

  static final LiveSessionsStore instance = LiveSessionsStore._();

  final List<LiveSession> _liveSessions = [];

  List<LiveSession> get liveSessions => List.unmodifiable(_liveSessions);

  bool get hasLiveSessions => _liveSessions.isNotEmpty;

  void addLiveSession(LiveSession session) {
    _liveSessions.removeWhere((existing) => existing.id == session.id);
    _liveSessions.add(session);
    notifyListeners();
  }

  void removeLiveSession(int sessionId) {
    final before = _liveSessions.length;
    _liveSessions.removeWhere((session) => session.id == sessionId);
    if (_liveSessions.length != before) notifyListeners();
  }

  void dismissAll() {
    if (_liveSessions.isEmpty) return;
    _liveSessions.clear();
    notifyListeners();
  }
}
