import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has finished the first-run onboarding flow.
abstract final class OnboardingStorage {
  static const _completedKey = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
