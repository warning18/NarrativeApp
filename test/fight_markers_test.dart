// The fight screen's marks for the fight-length rules and the warrior's core
// (v1.361): Fury as five notches on the hero, the execute line on a foe's
// health bar, the Tide's mark; and the pieces on their own.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_markers.dart';

import 'fight_markers_harness.dart';
import 'skill_fight_harness.dart' show settle, tapWhenEnabled, pumpUntil, shows;

void main() {
  testWidgets('Fury is five notches, lit as it builds, glowing when full',
      (tester) async {
    Widget gauge(int v) => MaterialApp(
          home: Scaffold(
            body: FuryGauge(
                value: v,
                max: 5,
                label: 'Fury',
                readyLabel: 'Heavy blow next',
                tooltip: 'tip'),
          ),
        );
    await tester.pumpWidget(gauge(2));
    expect(find.byKey(const Key('fury_notch_4')), findsOneWidget);
    expect(find.text('Heavy blow next'), findsNothing);
    await tester.pumpWidget(gauge(5));
    expect(find.text('Heavy blow next'), findsOneWidget);
  });

  testWidgets('the Watchfire shows its flame, its worth and how much is lit',
      (tester) async {
    Widget mark(int fire) => MaterialApp(
          home: Scaffold(
            body: WatchfireMark(
                fire: fire, cap: 40, label: 'Watchfire', tooltip: 'tip'),
          ),
        );
    await tester.pumpWidget(mark(0));
    expect(find.text('Watchfire'), findsOneWidget);
    await tester.pumpWidget(mark(20));
    expect(find.text('20'), findsOneWidget);
    final fill =
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fill.widthFactor, closeTo(0.5, 1e-9));
    await tester.pumpWidget(mark(400));
    expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        1);
  });

  testWidgets('a warrior sees its Fury, and a foe its execute line',
      (tester) async {
    await enterFight(tester, 'warrior');
    // The five notches, none lit yet; the foe's health bar carries the line.
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('fury_notch_$i')), findsOneWidget);
    }
    expect(find.text('Fury'), findsOneWidget);
    expect(find.byKey(const Key('execute_tick')), findsOneWidget);
    // Round 1: no Tide mark yet, nor its warning.
    expect(find.byKey(const Key('fight_tide_mark')), findsNothing);
    // A round goes by without a break in the marks.
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tapWhenEnabled(tester, 'Confirm');
    await pumpUntil(tester, () => shows('Round 2'));
    await settle(tester);
    expect(find.byKey(const Key('fury_notch_0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
