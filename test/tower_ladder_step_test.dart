// The hero's head on the Tower's rail steps to its new notch over about a
// second after a won fight; a tap or reduced motion puts it there at once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/tower_ladder.dart';

void main() {
  Widget app(int floor, {bool reduce = false, Key? key}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(
            body: SizedBox(
                height: 600, child: TowerLadder(key: key, floor: floor)),
          ),
        ),
      );

  double headY(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const Key('tower_ladder_head'))).dy;

  testWidgets('the head walks up one notch in about a second', (tester) async {
    await tester.pumpWidget(app(11));
    final start = headY(tester);
    await tester.pumpWidget(app(12));
    await tester.pump(const Duration(milliseconds: 500));
    final mid = headY(tester);
    expect(mid, lessThan(start));
    await tester.pump(const Duration(milliseconds: 600));
    final end = headY(tester);
    expect(end, lessThan(mid));
    // One notch (a thirtieth of the rail) above where it began.
    expect(start - end, closeTo(600 / 30, 0.5));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a tap puts it on its notch at once', (tester) async {
    final key = GlobalKey<TowerLadderState>();
    await tester.pumpWidget(app(11, key: key));
    final start = headY(tester);
    await tester.pumpWidget(app(12, key: key));
    await tester.pump(const Duration(milliseconds: 100));
    key.currentState!.skip();
    await tester.pump();
    expect(start - headY(tester), closeTo(600 / 30, 0.5));
  });

  testWidgets('with reduced motion it does not walk', (tester) async {
    await tester.pumpWidget(app(11, reduce: true));
    final start = headY(tester);
    await tester.pumpWidget(app(12, reduce: true));
    await tester.pump();
    expect(start - headY(tester), closeTo(600 / 30, 0.5));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('it walks down too (a fall) and the first build stays put',
      (tester) async {
    await tester.pumpWidget(app(14));
    final start = headY(tester);
    await tester.pumpWidget(app(12));
    await tester.pumpAndSettle();
    expect(headY(tester) - start, closeTo(2 * 600 / 30, 0.5));
  });
}
