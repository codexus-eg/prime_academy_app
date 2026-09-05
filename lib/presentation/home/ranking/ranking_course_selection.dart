/// Pure ranking course resolution used by [HomeRankingTab].
///
/// Web `RankTable` initializes as `course_id || courses[0]?.id`.
/// Point notifications open bare `/home/ranking` (no `course_id`) — matching
/// web `buildNotificationLink` which returns `?tab=2` only — so resolution
/// falls through to the first enrolled course.
int? resolveRankingCourseId({
  required int? routeCourseId,
  required int? selectedCourseId,
  required List<int>? enrolledCourseIds,
}) {
  if (routeCourseId != null && routeCourseId > 0) {
    return routeCourseId;
  }

  if (enrolledCourseIds == null || enrolledCourseIds.isEmpty) {
    return null;
  }

  if (selectedCourseId != null &&
      enrolledCourseIds.contains(selectedCourseId)) {
    return selectedCourseId;
  }

  return enrolledCourseIds.first;
}
