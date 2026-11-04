// QA: the short settle most widget tests use after pumping the app or a
// screen: three rounds of a real 100 ms (the game data loads from the bundle
// in a real future, which `pump` alone never waits for) and a 100 ms frame.
// It was written out in 39 files.
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

Future<void> settleApp(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A phone-sized window at pixel ratio 1 for the test, put back after it
/// (the four lines every layout test began with).
void usePhone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Lets [steps] frames of 100 ms go by, with a short real pause each for the
/// game's async work. For a moment that has no screen sign to wait for (the
/// enemy's turn after a Confirm): it replaces a poll for text that no longer
/// existed, which always ran to its limit at 300 ms of real time a step.
Future<void> pumpFor(WidgetTester tester, int steps) async {
  for (var i = 0; i < steps; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
