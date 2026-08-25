import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/onboarding/onboarding_page.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/course/course_detail_page.dart';
import '../presentation/course/ask_teacher_page.dart';
import '../presentation/course/electronic_handouts_page.dart';
import '../presentation/course/lesson_detail_page.dart';
import '../presentation/course/memory_cards_page.dart';
import '../presentation/course/models/memory_card.dart';
import '../presentation/exam/exam_page.dart';
import '../presentation/classification_quiz/classification_quiz_page.dart';
import '../presentation/luck_cards/luck_cards_page.dart';
import '../presentation/about/about_page.dart';
import '../presentation/contact/contact_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/home/tabs/home_awards_tab.dart';
import '../presentation/home/tabs/home_courses_tab.dart';
import '../presentation/home/tabs/home_ranking_tab.dart';
import '../presentation/home/tabs/home_reports_tab.dart';
import '../presentation/home/tabs/home_incomplete_tasks_tab.dart';
import '../presentation/reports/student_quiz_review_page.dart';
import '../presentation/session/session_blocked_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: SplashPage.routePath,
  routes: [
    GoRoute(
      path: SplashPage.routePath,
      name: SplashPage.routeName,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: OnboardingPage.routePath,
      name: OnboardingPage.routeName,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: LoginPage.routePath,
      name: LoginPage.routeName,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: SessionBlockedPage.routePath,
      name: SessionBlockedPage.routeName,
      builder: (context, state) => const SessionBlockedPage(),
    ),
    GoRoute(
      path: SessionErrorPage.routePath,
      name: SessionErrorPage.routeName,
      builder: (context, state) => const SessionErrorPage(),
    ),
    GoRoute(
      path: CourseDetailPage.routePath,
      name: CourseDetailPage.routeName,
      builder: (context, state) {
        final courseId = state.pathParameters['courseId']!;
        return CourseDetailPage(courseId: courseId);
      },
      routes: [
        GoRoute(
          path: 'units/:unitId/quiz/:quizId',
          name: 'unit-quiz',
          builder: (context, state) => ExamPage(
            quizId: int.tryParse(state.pathParameters['quizId'] ?? '') ?? 0,
            courseId: state.pathParameters['courseId'],
            unitId: state.pathParameters['unitId'],
          ),
        ),
        GoRoute(
          path: 'units/:unitId/lessons/:lessonId',
          name: LessonDetailPage.routeName,
          pageBuilder: (context, state) {
            final courseId = state.pathParameters['courseId']!;
            final unitId = state.pathParameters['unitId']!;
            final lessonId = state.pathParameters['lessonId']!;
            return NoTransitionPage<void>(
              key: ValueKey('lesson-shell-$courseId-$unitId'),
              child: LessonDetailPage(
                courseId: courseId,
                unitId: unitId,
                lessonId: lessonId,
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'handouts',
              name: ElectronicHandoutsPage.routeName,
              pageBuilder: (context, state) => _lessonOverlayPage(
                ElectronicHandoutsPage(
                  courseId: state.pathParameters['courseId']!,
                  unitId: state.pathParameters['unitId']!,
                  lessonId: state.pathParameters['lessonId']!,
                  isEnrolled: state.extra is bool ? state.extra as bool : false,
                ),
              ),
            ),
            GoRoute(
              path: 'ask-teacher',
              name: AskTeacherPage.routeName,
              pageBuilder: (context, state) => _lessonOverlayPage(
                AskTeacherPage(
                  courseId: state.pathParameters['courseId']!,
                  unitId: state.pathParameters['unitId']!,
                  lessonId: state.pathParameters['lessonId']!,
                  chatId: state.extra is int ? state.extra as int : 0,
                ),
              ),
            ),
            GoRoute(
              path: 'memory-cards',
              name: MemoryCardsPage.routeName,
              builder: (context, state) {
                final extra = state.extra;
                MemoryCardsArgs? args;
                if (extra is MemoryCardsArgs) {
                  args = extra;
                } else if (extra is List<MemoryCard>) {
                  args = MemoryCardsArgs(cards: extra);
                }
                return MemoryCardsPage(
                  courseId: state.pathParameters['courseId'],
                  unitId: state.pathParameters['unitId'],
                  lessonId: state.pathParameters['lessonId'],
                  cards: args?.cards ?? const [],
                  realLessonId: args?.lessonId,
                  cardsCompleted: args?.cardsCompleted ?? false,
                  isEnrolled: args?.isEnrolled ?? false,
                );
              },
            ),
            GoRoute(
              path: ClassificationQuizPage.routePath,
              name: ClassificationQuizPage.routeName,
              builder: (context, state) {
                final quizId =
                    int.tryParse(state.pathParameters['quizId'] ?? '') ?? 0;
                return ClassificationQuizPage(quizId: quizId);
              },
            ),
            GoRoute(
              path: LuckCardsPage.routePath,
              name: LuckCardsPage.routeName,
              builder: (context, state) {
                final quizId =
                    int.tryParse(state.pathParameters['quizId'] ?? '') ?? 0;
                return LuckCardsPage(quizId: quizId);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: StudentQuizReviewPage.routePath,
      name: StudentQuizReviewPage.routeName,
      builder: (context, state) {
        final quizId = int.tryParse(state.pathParameters['quizId'] ?? '') ?? 0;
        final attemptId = state.pathParameters['attemptId'] ?? '';
        return StudentQuizReviewPage(quizId: quizId, attemptId: attemptId);
      },
    ),
    GoRoute(
      path: AboutPage.routePath,
      name: AboutPage.routeName,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: ContactPage.routePath,
      name: ContactPage.routeName,
      builder: (context, state) => const ContactScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: HomePage.routePath,
          redirect: (context, state) {
            final path = state.uri.path;
            if (path == HomePage.routePath || path == '${HomePage.routePath}/') {
              return HomeTab.defaultTab.routePath;
            }
            return null;
          },
          routes: [
            GoRoute(
              path: HomeTab.courses.segment,
              name: 'home-courses',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeCoursesTab(),
              ),
            ),
            GoRoute(
              path: HomeTab.reports.segment,
              name: 'home-reports',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeReportsTab(),
              ),
            ),
            GoRoute(
              path: HomeTab.ranking.segment,
              name: 'home-ranking',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeRankingTab(),
              ),
            ),
            GoRoute(
              path: HomeTab.awards.segment,
              name: 'home-awards',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeAwardsTab(),
              ),
            ),
            GoRoute(
              path: HomeTab.incompleteTasks.segment,
              name: 'home-incomplete-tasks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeIncompleteTasksTab(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _lessonOverlayPage(Widget child) {
  return CustomTransitionPage<void>(
    opaque: false,
    barrierColor: AppColors.scrim80,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
