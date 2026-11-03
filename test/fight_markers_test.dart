// The fight screen's marks for the fight-length rules and the warrior's core
// (v1.368): Fury as five notches on the hero, the execute line on a foe's
// health bar, the Tide's mark; and the pieces on their own.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_markers_harness.dart';
import 'skill_fight_harness.dart' show settle, tapWhenEnabled, pumpUntil, shows;

void main() {
  testWidgets('a warrior sees its Fury, and a foe its execute line',
      (tester) async {
    await enterFight(tester, 'warrior');
    // Its Fury is an icon on the hero's card (the redesigned slots), at 0;
    // the foe's health bar carries the execute line.
    expect(
        find.byWidgetPredicate(
            (w) => '${w.key}'.startsWith("[<'fight_effect_fury_")),
        findsOneWidget);
    expect(find.byKey(const Key('execute_tick')), findsOneWidget);
    // Round 1: no Tide mark yet, nor its warning.
    expect(find.byKey(const Key('fight_tide_mark')), findsNothing);
    // A round goes by without a break in the marks.
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tapWhenEnabled(tester, 'Confirm');
    await pumpUntil(tester, () => shows('Round 2'));
    await settle(tester);
    expect(
        find.byWidgetPredicate(
            (w) => '${w.key}'.startsWith("[<'fight_effect_fury_")),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
