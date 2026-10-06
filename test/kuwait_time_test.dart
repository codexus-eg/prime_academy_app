import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/core/time/kuwait_time.dart';

void main() {
  group('KuwaitTime', () {
    test('formats UTC instant as Kuwait wall clock (UTC+3)', () {
      // 17:12 UTC → 20:12 Kuwait
      expect(
        KuwaitTime.formatTime12h('2026-09-15T17:12:00.000Z'),
        '08:12 PM',
      );
    });

    test('includes Kuwait label', () {
      expect(
        KuwaitTime.formatTimeWithLabel('2026-09-15T17:12:00.000Z'),
        contains('بتوقيت الكويت'),
      );
    });

    test('empty input returns empty string', () {
      expect(KuwaitTime.formatTime12h(null), isEmpty);
      expect(KuwaitTime.formatTime12h(''), isEmpty);
    });
  });
}
