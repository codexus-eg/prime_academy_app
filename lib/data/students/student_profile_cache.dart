import 'student_profile.dart';

/// In-memory profile filled during splash so Home can paint without a second fetch.
abstract final class StudentProfileCache {
  static StudentProfile? _profile;
  static var visualsReady = false;

  static StudentProfile? get profile => _profile;

  static void store(StudentProfile profile, {required bool visualsReady}) {
    _profile = profile;
    StudentProfileCache.visualsReady = visualsReady;
  }

  static void clear() {
    _profile = null;
    visualsReady = false;
  }
}
