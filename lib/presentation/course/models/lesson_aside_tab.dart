enum LessonAsideTab {
  videos('videos'),
  chat('chat');

  const LessonAsideTab(this.queryValue);

  final String queryValue;

  static LessonAsideTab? fromQuery(String? value) {
    return switch (value) {
      'chat' => LessonAsideTab.chat,
      'videos' => LessonAsideTab.videos,
      // Legacy deep-link; materials moved to course page.
      'files' => LessonAsideTab.videos,
      _ => null,
    };
  }
}
