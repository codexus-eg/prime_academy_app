import 'package:flutter/foundation.dart';

/// Signals that Ranking must initialize like a fresh Web `RankTable` mount.
///
/// Point-notification taps call [requestOpen] before `go(/home/ranking)`.
/// [HomeRankingTab] keys off [generation] so an active-session notification
/// remounts the tab even when HomeShell stayed alive under a pushed lesson.
class RankingOpenSignal extends ChangeNotifier {
  RankingOpenSignal._();

  static final RankingOpenSignal instance = RankingOpenSignal._();

  int _generation = 0;

  /// Bumps whenever a ranking-destined notification is opened.
  int get generation => _generation;

  void requestOpen() {
    _generation++;
    if (kDebugMode) {
      debugPrint(
        '[Notification] Destination resolved → Ranking (generation=$_generation)',
      );
      debugPrint('[Notification] course_id ignored');
    }
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _generation = 0;
  }
}
