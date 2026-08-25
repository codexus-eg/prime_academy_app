import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/video_progress.dart';
import '../../core/widgets/icons/mystery_card_icon.dart';
import '../../data/auth/auth_session.dart';
import '../../data/courses/courses_api.dart';
import '../../data/courses/module_material.dart';
import '../../data/courses/user_course.dart';
import '../../data/sse/video_session_guard.dart';
import '../home/widgets/app_nav_scaffold.dart';
import '../session/session_blocked_page.dart';
import '../classification_quiz/classification_quiz_page.dart';
import '../luck_cards/luck_cards_page.dart';
import 'memory_cards_page.dart';
import 'models/course_detail_mapper.dart';
import 'models/course_lesson.dart';
import 'models/lesson_aside_tab.dart';
import 'models/memory_card.dart';
import 'widgets/lesson_action_button.dart';
import 'widgets/lesson_action_icons.dart';
import 'widgets/lesson_chat_panel.dart';
import 'widgets/lesson_handouts_panel.dart';
import 'widgets/lesson_video_section.dart';
import 'widgets/lesson_videos_aside.dart';
import 'widgets/testimonial_dialog.dart';

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
  });

  final String courseId;
  final String unitId;
  final String lessonId;

  static const String routePath =
      '/course/:courseId/units/:unitId/lessons/:lessonId';
  static const String routeName = 'lesson-detail';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId';

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late Future<_LessonScreenData> _future;
  _LessonScreenData? _cachedData;
  VideoSessionGuard? _sessionGuard;
  List<CourseLesson> _sidebarLessons = const [];
  int? _liveProgressPercent;
  var _showStudentProgress = false;
  var _hasTestimonial = false;
  LessonAsideTab _asideTab = LessonAsideTab.videos;
  final _mobileScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _load();
    _startSessionGuard();
  }

  Future<void> _startSessionGuard() async {
    final user = await AuthSession.load();
    if (user?.role != 1 || !mounted) return;

    _sessionGuard = VideoSessionGuard(
      onBlocked: () {
        if (!mounted) return;
        context.go(SessionBlockedPage.routePath);
      },
      onNetworkError: () {
        if (!mounted) return;
        context.go(SessionErrorPage.routePath);
      },
    );
    await _sessionGuard!.start();
  }

  @override
  void dispose() {
    _mobileScrollController.dispose();
    _sessionGuard?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = LessonAsideTab.fromQuery(
      GoRouterState.of(context).uri.queryParameters['active_tab'],
    );
    if (tab != null && tab != _asideTab) {
      setState(() => _asideTab = tab);
    }
  }

  @override
  void didUpdateWidget(covariant LessonDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId ||
        oldWidget.unitId != widget.unitId ||
        oldWidget.courseId != widget.courseId) {
      final tab = LessonAsideTab.fromQuery(
        GoRouterState.of(context).uri.queryParameters['active_tab'],
      );
      setState(() {
        _liveProgressPercent = null;
        _asideTab = tab ?? LessonAsideTab.videos;
        _future = _load();
      });
      _scrollToTopOnLessonChange();
    }
  }

  void _scrollToTopOnLessonChange() {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mobileScrollController.hasClients) return;
      _mobileScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<_LessonScreenData> _load() async {
    final courseId = int.tryParse(widget.courseId);
    final moduleId = int.tryParse(widget.unitId);
    final itemId = int.tryParse(widget.lessonId);
    if (courseId == null || moduleId == null || itemId == null) {
      throw ApiException('الحصة غير موجودة');
    }

    final user = await AuthSession.load();
    final showStudentProgress = user?.role == 1;

    final module = await CoursesApi.fetchModuleItems(
      courseId: courseId,
      moduleId: moduleId,
    );

    var lessons =
        CourseDetailMapper.lessonsFromItems(module.isEnrolled, module.items);

    UserModuleItem? activeItem;
    for (final item in module.items) {
      if (item.id == itemId) {
        activeItem = item;
        break;
      }
    }

    String title = activeItem?.lesson?.title ?? '';
    LessonPlayback? playback;
    final realLessonId = activeItem?.lesson?.id;

    var pendingTrophyItemId = '';
    var pendingTrophyLessonId = 0;
    if (realLessonId != null) {
      try {
        playback = await CoursesApi.fetchLesson(realLessonId);
        if (playback.title.isNotEmpty) title = playback.title;

        if (module.isEnrolled &&
            showStudentProgress &&
            activeItem?.lesson?.hasTrophy != true) {
          pendingTrophyItemId = widget.lessonId;
          pendingTrophyLessonId = realLessonId;
        }
      } on ApiException {

      }
    }

    if (mounted) {
      setState(() {
        _sidebarLessons = lessons;
        _showStudentProgress = showStudentProgress;
        _hasTestimonial = playback?.hasTestimonial ?? false;
      });
    }

    final data = _LessonScreenData(
      unitTitle: module.title,
      lessons: lessons,
      materials: module.materials,
      teacher: module.teacher,
      lessonTitle: title,
      videoUrl: playback?.videoUrl,
      videoKind: playback?.kind ?? LessonVideoKind.none,
      thumbnailUrl: playback?.thumbnailUrl,
      hasAccess: playback?.hasAccess ?? module.isEnrolled,
      cards: playback?.cards ?? const [],
      isEnrolled: module.isEnrolled,
      realLessonId: playback?.id ?? realLessonId,
      classificationQuizId: playback?.classificationQuizId,
      knowledgeQuizId: playback?.knowledgeQuizId,
      chatId: playback?.chatId,
      showTeacherChat: user?.role != 0 &&
          module.isEnrolled &&
          (module.teacher?.id ?? 0) > 0,
      classificationQuizCompleted:
          playback?.classificationQuizStatus?.completed ?? false,
      classificationLevelTitle:
          playback?.classificationQuizStatus?.levelTitle,
      knowledgeQuizCompleted:
          playback?.knowledgeQuizStatus?.completed ?? false,
      resumePositionSeconds: VideoProgress.resumePositionSeconds(
        playback?.lastPosition,
      ),
      hasTestimonial: playback?.hasTestimonial ?? false,
      cardsCompleted: playback?.cardsCompleted ?? false,
    );
    _cachedData = data;

    if (pendingTrophyLessonId > 0 && pendingTrophyItemId.isNotEmpty) {

      unawaited(
        _awardTrophyAfterPaint(
          realLessonId: pendingTrophyLessonId,
          itemId: pendingTrophyItemId,
        ),
      );
    }

    return data;
  }

  Future<void> _awardTrophyAfterPaint({
    required int realLessonId,
    required String itemId,
  }) async {

    await Future<void>.delayed(Duration.zero);
    if (!mounted || widget.lessonId != itemId) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || widget.lessonId != itemId) return;

    try {
      await CoursesApi.giveTrophy(realLessonId);
    } catch (_) {
      return;
    }
    if (!mounted || widget.lessonId != itemId) return;

    setState(() {
      _sidebarLessons = _lessonsWithTrophy(
        _sidebarLessons.isNotEmpty
            ? _sidebarLessons
            : (_cachedData?.lessons ?? const []),
        itemId,
      );
      final cached = _cachedData;
      if (cached != null) {
        _cachedData = _LessonScreenData(
          unitTitle: cached.unitTitle,
          lessons: _sidebarLessons,
          materials: cached.materials,
          teacher: cached.teacher,
          lessonTitle: cached.lessonTitle,
          videoUrl: cached.videoUrl,
          videoKind: cached.videoKind,
          thumbnailUrl: cached.thumbnailUrl,
          hasAccess: cached.hasAccess,
          cards: cached.cards,
          isEnrolled: cached.isEnrolled,
          realLessonId: cached.realLessonId,
          classificationQuizId: cached.classificationQuizId,
          knowledgeQuizId: cached.knowledgeQuizId,
          chatId: cached.chatId,
          showTeacherChat: cached.showTeacherChat,
          classificationQuizCompleted: cached.classificationQuizCompleted,
          classificationLevelTitle: cached.classificationLevelTitle,
          knowledgeQuizCompleted: cached.knowledgeQuizCompleted,
          resumePositionSeconds: cached.resumePositionSeconds,
          hasTestimonial: cached.hasTestimonial,
          cardsCompleted: cached.cardsCompleted,
        );
      }
    });
  }

  List<CourseLesson> _lessonsWithTrophy(
    List<CourseLesson> lessons,
    String itemId,
  ) {
    return [
      for (final lesson in lessons)
        lesson.id == itemId ? lesson.copyWith(hasTrophy: true) : lesson,
    ];
  }

  void _onVideoProgress(int percent) {
    setState(() => _liveProgressPercent = percent);
  }

  void _retry() {
    setState(() => _future = _load());
  }

  void _setAsideTab(LessonAsideTab tab) {
    setState(() => _asideTab = tab);
  }

  Future<void> _onPlaybackEnded(_LessonScreenData data) async {
    if (!data.isEnrolled || !_showStudentProgress || _hasTestimonial) return;
    final courseId = int.tryParse(widget.courseId);
    if (courseId == null || !mounted) return;

    await showTestimonialDialog(
      context,
      courseId: courseId,
      onSubmitted: () => setState(() => _hasTestimonial = true),
    );
  }

  Future<void> _openQuiz(String path) async {
    final refreshed = await context.push<bool>(path);
    if (refreshed == true && mounted) _retry();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppTheme.coursePageBackground,
      topBarBackground: AppTheme.coursePageBackground,
      body: FutureBuilder<_LessonScreenData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? _cachedData;
          final waiting = snapshot.connectionState == ConnectionState.waiting;

          if (data != null) {
            return Stack(
              children: [
                _buildContent(context, data),
                if (waiting)
                  const Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          if (waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LessonError(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'تعذّر تحميل الحصة',
              onRetry: _retry,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, _LessonScreenData data) {
    final courseId = widget.courseId;
    final unitId = widget.unitId;
    final lessonId = widget.lessonId;
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop =
              constraints.maxWidth >= AppSpacing.breakpointLessonDesktop;
          final asideHeight = constraints.maxHeight;
          final aside = _buildAside(
            data: data,
            asideHeight: asideHeight,
            courseId: courseId,
            unitId: unitId,
            lessonId: lessonId,
          );
          final mainColumn = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(
                'lesson-main-${data.realLessonId ?? data.lessonTitle}',
              ),
              child: _MainLessonColumn(
                data: data,
                courseId: courseId,
                unitId: unitId,
                lessonId: lessonId,
                asideTab: _asideTab,
                onAsideTabChanged: _setAsideTab,
                onProgressUpdate: _onVideoProgress,
                onPlaybackEnded: () => _onPlaybackEnded(data),
                onOpenQuiz: _openQuiz,
              ),
            ),
          );

          if (isDesktop) {

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageContentHorizontal,
                          AppSpacing.sm,
                          AppSpacing.pageContentHorizontal,
                          AppSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: mainColumn,
                              ),
                            ),
                            const SizedBox(
                              width: AppSpacing.lessonPageSectionGap,
                            ),
                            SizedBox(
                              width: AppSpacing.lessonAsideWidth,
                              height: asideHeight,
                              child: aside,
                            ),
                          ],
                        ),
                      );
                    }

                    if (_asideTab != LessonAsideTab.videos) {
                      return SizedBox(
                        height: asideHeight,
                        child: aside,
                      );
                    }

                    return SingleChildScrollView(
                      controller: _mobileScrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageContentHorizontal,
                        AppSpacing.sm,
                        AppSpacing.pageContentHorizontal,
                        AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          mainColumn,
                          const SizedBox(
                            height: AppSpacing.lessonPageSectionGap,
                          ),
                          SizedBox(
                            height: viewportHeight - AppSpacing.lessonNavHeight,
                            child: aside,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildAside({
    required _LessonScreenData data,
    required double asideHeight,
    required String courseId,
    required String unitId,
    required String lessonId,
  }) {
    switch (_asideTab) {
      case LessonAsideTab.chat:
        if (!data.showTeacherChat) {
          return _buildVideosAside(
            data: data,
            asideHeight: asideHeight,
            courseId: courseId,
            unitId: unitId,
            lessonId: lessonId,
          );
        }
        return SizedBox(
          height: asideHeight,
          child: LessonChatPanel(
            chatId: data.chatId ?? 0,
            courseId: int.parse(courseId),
            teacher: data.teacher,
            onClose: () => _setAsideTab(LessonAsideTab.videos),
          ),
        );
      case LessonAsideTab.files:
        return SizedBox(
          height: asideHeight,
          child: LessonHandoutsPanel(
            materials: data.materials,
            isEnrolled: data.isEnrolled,
            onClose: () => _setAsideTab(LessonAsideTab.videos),
          ),
        );
      case LessonAsideTab.videos:
        return _buildVideosAside(
          data: data,
          asideHeight: asideHeight,
          courseId: courseId,
          unitId: unitId,
          lessonId: lessonId,
        );
    }
  }

  Widget _buildVideosAside({
    required _LessonScreenData data,
    required double asideHeight,
    required String courseId,
    required String unitId,
    required String lessonId,
  }) {
    return SizedBox(
      height: asideHeight,
      child: LessonVideosAside(
        height: asideHeight,
        courseId: courseId,
        unitId: unitId,
        unitTitle: data.unitTitle,
        lessons: _sidebarLessons.isNotEmpty ? _sidebarLessons : data.lessons,
        currentLessonId: lessonId,
        isEnrolled: data.isEnrolled,
        showStudentProgress: _showStudentProgress,
        liveProgressPercent: _liveProgressPercent,
      ),
    );
  }
}

class _LessonScreenData {
  const _LessonScreenData({
    required this.unitTitle,
    required this.lessons,
    required this.materials,
    required this.lessonTitle,
    required this.videoUrl,
    required this.videoKind,
    required this.thumbnailUrl,
    required this.hasAccess,
    required this.cards,
    required this.isEnrolled,
    required this.realLessonId,
    this.teacher,
    this.classificationQuizId,
    this.knowledgeQuizId,
    this.chatId,
    this.showTeacherChat = false,
    this.classificationQuizCompleted = false,
    this.classificationLevelTitle,
    this.knowledgeQuizCompleted = false,
    this.resumePositionSeconds = 0,
    this.hasTestimonial = false,
    this.cardsCompleted = false,
  });

  final String unitTitle;
  final List<CourseLesson> lessons;
  final List<ModuleMaterial> materials;
  final ModuleTeacher? teacher;
  final String lessonTitle;
  final String? videoUrl;
  final LessonVideoKind videoKind;
  final String? thumbnailUrl;
  final bool hasAccess;
  final List<LessonCard> cards;
  final bool isEnrolled;

  final int? realLessonId;
  final int? classificationQuizId;
  final int? knowledgeQuizId;
  final int? chatId;
  final bool showTeacherChat;
  final bool classificationQuizCompleted;
  final String? classificationLevelTitle;
  final bool knowledgeQuizCompleted;
  final int resumePositionSeconds;
  final bool hasTestimonial;
  final bool cardsCompleted;
}

class _LessonError extends StatelessWidget {
  const _LessonError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainLessonColumn extends StatelessWidget {
  const _MainLessonColumn({
    required this.data,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
    required this.asideTab,
    required this.onAsideTabChanged,
    this.onProgressUpdate,
    this.onWatched,
    this.onPlaybackEnded,
    required this.onOpenQuiz,
  });

  final _LessonScreenData data;
  final String courseId;
  final String unitId;
  final String lessonId;
  final LessonAsideTab asideTab;
  final ValueChanged<LessonAsideTab> onAsideTabChanged;
  final ValueChanged<int>? onProgressUpdate;
  final VoidCallback? onWatched;
  final VoidCallback? onPlaybackEnded;
  final Future<void> Function(String path) onOpenQuiz;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonVideoSection(
          key: ValueKey('lesson-video-${data.realLessonId ?? lessonId}'),
          title: data.lessonTitle,
          kind: data.videoKind,
          videoUrl: data.videoUrl,
          thumbnailUrl: data.thumbnailUrl,
          lessonId: data.realLessonId,
          initialPositionSeconds: data.resumePositionSeconds,
          hasAccess: data.hasAccess,
          onProgressUpdate: onProgressUpdate,
          onWatched: onWatched,
          onPlaybackEnded: onPlaybackEnded,
        ),
        const SizedBox(height: AppSpacing.lessonMainColumnGap),
        _ActionGrid(
          data: data,
          courseId: courseId,
          unitId: unitId,
          lessonId: lessonId,
          asideTab: asideTab,
          onAsideTabChanged: onAsideTabChanged,
          onOpenQuiz: onOpenQuiz,
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.data,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
    required this.asideTab,
    required this.onAsideTabChanged,
    required this.onOpenQuiz,
  });

  final _LessonScreenData data;
  final String courseId;
  final String unitId;
  final String lessonId;
  final LessonAsideTab asideTab;
  final ValueChanged<LessonAsideTab> onAsideTabChanged;
  final Future<void> Function(String path) onOpenQuiz;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      LessonActionButton(
        label: asideTab == LessonAsideTab.files ? 'الفيديوهات' : 'الملازم الالكترونية',
        leading: LessonActionIcons.svg(
          asideTab == LessonAsideTab.files
              ? LessonActionIcons.videos
              : LessonActionIcons.bookOpen,
        ),
        onTap: () => onAsideTabChanged(
          asideTab == LessonAsideTab.files
              ? LessonAsideTab.videos
              : LessonAsideTab.files,
        ),
      ),
      if (data.showTeacherChat)
        LessonActionButton(
          label: 'اسأل المعلم',
          leading: LessonActionIcons.svg(LessonActionIcons.comment),
          onTap: () => onAsideTabChanged(LessonAsideTab.chat),
        ),
      if (data.isEnrolled)
        LessonActionButton(
          label: 'كروت الحفظ',
          leading: LessonActionIcons.svg(LessonActionIcons.cards),
          style: LessonActionStyle.purpleRadial,
          onTap: () => context.push(
            MemoryCardsPage.pathFor(
              courseId: courseId,
              unitId: unitId,
              lessonId: lessonId,
            ),
            extra: MemoryCardsArgs(
              cards: [
                for (final card in data.cards)
                  MemoryCard(
                    id: card.id,
                    text: card.text,
                    answerText: card.answerText,
                  ),
              ],
              lessonId: data.realLessonId,
              cardsCompleted: data.cardsCompleted,
              isEnrolled: data.isEnrolled,
            ),
          ),
        ),
      if (data.isEnrolled && data.classificationQuizId != null)
        data.classificationQuizCompleted
            ? LessonActionButton(
                label: (data.classificationLevelTitle?.isNotEmpty ?? false)
                    ? data.classificationLevelTitle!
                    : 'اكتملت المهمة',
                labelAsBadge:
                    data.classificationLevelTitle?.isNotEmpty ?? false,
                leading: LessonActionIcons.svg(
                  LessonActionIcons.rankingStar,
                  color: AppColors.contentQuizIcon,
                ),
                style: LessonActionStyle.blueRadial,
                showCompletionRibbon: true,
                onTap: null,
              )
            : LessonActionButton(
                label: 'تصنيفي',
                leading: LessonActionIcons.svg(
                  LessonActionIcons.rankingStar,
                  color: AppColors.contentQuizIcon,
                ),
                style: LessonActionStyle.blueRadial,
                onTap: () => onOpenQuiz(
                  ClassificationQuizPage.pathFor(
                    courseId: courseId,
                    unitId: unitId,
                    lessonId: lessonId,
                    quizId: data.classificationQuizId!,
                  ),
                ),
              ),
      if (data.isEnrolled && data.knowledgeQuizId != null)
        data.knowledgeQuizCompleted
            ? LessonActionButton(
                label: 'اكتملت المهمة',
                leading: const MysteryCardIcon(
                  size: 24,
                  cardColor: Color.fromRGBO(255, 255, 255, 0.8),
                  symbolColor: Colors.black,
                ),
                style: LessonActionStyle.blueRadial,
                showCompletionRibbon: true,
                onTap: null,
              )
            : LessonActionButton(
                label: 'كروت الحظ',
                leading: const MysteryCardIcon(
                  size: 30,
                  cardColor: Color.fromRGBO(255, 255, 255, 0.8),
                  symbolColor: Color.fromRGBO(0, 0, 0, 0.9),
                ),
                style: LessonActionStyle.blueRadial,
                onTap: () => onOpenQuiz(
                  LuckCardsPage.pathFor(
                    courseId: courseId,
                    unitId: unitId,
                    lessonId: lessonId,
                    quizId: data.knowledgeQuizId!,
                  ),
                ),
              ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final columns = constraints.maxWidth >= 1024 ? 4 : 2;
        final cellWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final button in buttons)
                SizedBox(width: cellWidth, child: button),
            ],
          ),
        );
      },
    );
  }
}

class MemoryCardsArgs {
  const MemoryCardsArgs({
    required this.cards,
    this.lessonId,
    this.cardsCompleted = false,
    this.isEnrolled = false,
  });

  final List<MemoryCard> cards;
  final int? lessonId;
  final bool cardsCompleted;
  final bool isEnrolled;
}
