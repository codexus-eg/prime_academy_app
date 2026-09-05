import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/core/widgets/lesson_surface_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LessonSurfaceGate.instance.resume();
  });

  test('suppressForNavigation runs releasers then stays suppressed', () async {
    var released = 0;
    Future<void> releaser() async {
      released++;
    }

    LessonSurfaceGate.instance.register(releaser);
    addTearDown(() => LessonSurfaceGate.instance.unregister(releaser));

    expect(LessonSurfaceGate.instance.suppressed, isFalse);
    await LessonSurfaceGate.instance.suppressForNavigation();
    expect(released, 1);
    expect(LessonSurfaceGate.instance.suppressed, isTrue);

    LessonSurfaceGate.instance.resume();
    expect(LessonSurfaceGate.instance.suppressed, isFalse);
  });
}
