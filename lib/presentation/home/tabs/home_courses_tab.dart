import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/course_assets.dart';
import '../../../core/theme/app_spacing.dart';
import '../../course/course_detail_page.dart';
import '../home_page_scroll.dart';
import '../student_profile_scope.dart';
import '../widgets/course_card.dart';

class HomeCoursesTab extends StatelessWidget {
  const HomeCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);

    if (scope == null || scope.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scope.errorMessage != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.profileTabContentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                scope.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (scope.onRetry != null) ...[
                const SizedBox(height: AppSpacing.base),
                TextButton(
                  onPressed: scope.onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final courses = scope.profile?.courses ?? const [];

    if (courses.isEmpty) {
      return Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Text(
          'لا يوجد دورات',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: HomePageScroll.scrollPhysics,
      padding: AppSpacing.profileTabContentPadding,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.courseListGap,
          runSpacing: AppSpacing.courseListGap,
          children: [
            for (final course in courses)
              Builder(
                builder: (context) {
                  final visuals = CourseAssets.resolve(course.type);
                  return CourseCard(
                    title: course.title,
                    logoUrl: visuals.iconUrl,
                    backgroundUrl: visuals.backgroundUrl,
                    onGoToCourse: () =>
                        context.push(CourseDetailPage.pathFor('${course.id}')),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
