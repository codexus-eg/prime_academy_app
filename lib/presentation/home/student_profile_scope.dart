import 'package:flutter/material.dart';

import '../../data/students/student_profile.dart';

class StudentProfileScope extends InheritedWidget {
  const StudentProfileScope({
    super.key,
    required this.profile,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    required super.child,
  });

  final StudentProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  static StudentProfileScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StudentProfileScope>();
  }

  @override
  bool updateShouldNotify(StudentProfileScope oldWidget) {
    return profile != oldWidget.profile ||
        isLoading != oldWidget.isLoading ||
        errorMessage != oldWidget.errorMessage;
  }
}
