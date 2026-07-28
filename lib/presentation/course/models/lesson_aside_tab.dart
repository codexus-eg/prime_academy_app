enum LessonAsideTab {
  videos('videos'),
  chat('chat'),
  files('files');

  const LessonAsideTab(this.queryValue);

  final String queryValue;

  static LessonAsideTab? fromQuery(String? value) {
    return switch (value) {
      'chat' => LessonAsideTab.chat,
      'files' => LessonAsideTab.files,
      'videos' => LessonAsideTab.videos,
      _ => null,
    };
  }
}
