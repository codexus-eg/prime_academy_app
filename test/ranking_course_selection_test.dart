import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/presentation/home/ranking/ranking_course_selection.dart';

void main() {
  group('resolveRankingCourseId', () {
    test('prefers route course id before profile is available', () {
      expect(
        resolveRankingCourseId(
          routeCourseId: 17,
          selectedCourseId: null,
          enrolledCourseIds: null,
        ),
        17,
      );
    });

    test('uses route course id even when profile courses omit it', () {
      expect(
        resolveRankingCourseId(
          routeCourseId: 17,
          selectedCourseId: 3,
          enrolledCourseIds: [3, 4],
        ),
        17,
      );
    });

    test('falls back to selected enrolled course when route is absent', () {
      expect(
        resolveRankingCourseId(
          routeCourseId: null,
          selectedCourseId: 4,
          enrolledCourseIds: [3, 4],
        ),
        4,
      );
    });

    test('uses first enrolled course when route and selection are absent', () {
      expect(
        resolveRankingCourseId(
          routeCourseId: null,
          selectedCourseId: null,
          enrolledCourseIds: [3, 4],
        ),
        3,
      );
    });

    test('returns null while waiting for profile courses', () {
      expect(
        resolveRankingCourseId(
          routeCourseId: null,
          selectedCourseId: null,
          enrolledCourseIds: null,
        ),
        isNull,
      );
    });
  });
}
