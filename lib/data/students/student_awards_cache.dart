import 'student_awards.dart';

abstract final class StudentAwardsCache {
  static StudentAwards? _awards;

  static StudentAwards? get awards => _awards;

  static void store(StudentAwards awards) {
    _awards = awards;
  }

  static void clear() {
    _awards = null;
  }
}
