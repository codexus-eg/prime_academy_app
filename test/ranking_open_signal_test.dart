import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/presentation/home/ranking/ranking_open_signal.dart';

void main() {
  tearDown(() {
    RankingOpenSignal.instance.reset();
  });

  test('requestOpen bumps generation and notifies listeners', () {
    final signal = RankingOpenSignal.instance;
    expect(signal.generation, 0);

    var notified = 0;
    void listener() => notified++;
    signal.addListener(listener);
    addTearDown(() => signal.removeListener(listener));

    signal.requestOpen();
    expect(signal.generation, 1);
    expect(notified, 1);

    signal.requestOpen();
    expect(signal.generation, 2);
    expect(notified, 2);
  });
}
