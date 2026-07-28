enum HomeTab {
  courses('المواد', 'courses'),
  reports('التقارير', 'reports'),
  ranking('تصنيفي', 'ranking'),
  awards('الجوائز', 'awards'),
  incompleteTasks('مهمات غير مكتملة', 'incomplete-tasks');

  const HomeTab(this.label, this.segment);

  final String label;
  final String segment;

  static const HomeTab defaultTab = HomeTab.courses;

  String get routePath => '/home/$segment';

  static HomeTab? fromLocation(String location) {
    for (final tab in HomeTab.values) {
      if (location.startsWith(tab.routePath)) return tab;
    }
    return null;
  }
}
