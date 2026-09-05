import '../../presentation/home/ranking/home_refresh_signal.dart';
import '../../presentation/home/ranking/ranking_open_signal.dart';
import '../auth/auth_session.dart';
import '../students/student_awards_cache.dart';
import '../students/student_profile_cache.dart';
import '../students/students_api.dart';

/// Refetches home data after a classification quiz completes successfully.
///
/// Mirrors web remount/refetch behavior: profile, ranks, awards, and
/// incomplete-progress lists pick up fresh server state on next access;
/// Flutter proactively refreshes caches and notifies mounted home tabs.
abstract final class ClassificationQuizCompletionRefresh {
  static Future<void> run() async {
    final user = await AuthSession.load();
    if (user == null) return;

    await Future.wait([
      _refreshAwards(user.id, user.role),
      _refreshProfile(user.role),
    ]);

    HomeRefreshSignal.instance.requestRefresh();
    RankingOpenSignal.instance.requestOpen();
  }

  static Future<void> _refreshAwards(int userId, int? role) async {
    if (role != 1) return;

    StudentAwardsCache.clear();
    try {
      final awards = await StudentsApi.fetchStudentAwards(userId);
      StudentAwardsCache.store(awards);
    } catch (_) {}
  }

  static Future<void> _refreshProfile(int? role) async {
    if (role != 1) return;

    try {
      final profile = await StudentsApi.fetchMyProfile();
      StudentProfileCache.store(profile, visualsReady: true);
    } catch (_) {}
  }
}
