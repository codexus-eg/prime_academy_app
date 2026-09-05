import 'package:flutter/foundation.dart';

/// Notifies home tabs to refetch data after classification quiz completion
/// or other events that change ranking, profile, or incomplete-task state.
class HomeRefreshSignal extends ChangeNotifier {
  HomeRefreshSignal._();

  static final HomeRefreshSignal instance = HomeRefreshSignal._();

  int _generation = 0;

  int get generation => _generation;

  void requestRefresh() {
    _generation++;
    if (kDebugMode) {
      debugPrint('[HomeRefresh] requestRefresh → generation=$_generation');
    }
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _generation = 0;
  }
}
