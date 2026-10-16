// An enemy with art stands in the fight (v1.454): the Inquisition soldier's
// sprite faces west, toward the hero, on the ground below its card; the card
// stays, and an enemy without art (the slum thug) shows the card alone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('an Inquisition soldier stands facing the hero, its card stays',
      (tester) async {
    await enterFight(tester,
        size: const Size(600, 1600), enemyId: 'inquisition_soldier');
    final figure = find.byWidgetPredicate((w) =>
        w.key is Key && w.key.toString().contains('fight_enemy_sprite_'));
    expect(figure, findsOneWidget);
    final rect = tester.getRect(figure);
    final hero = tester.getRect(find.byKey(const Key('fight_hero_sprite')));
    expect(rect.center.dx, greaterThan(hero.center.dx),
        reason: 'on the right, across from the hero');
    expect(find.textContaining('Inquisition Soldier'), findsWidgets);
    expect(find.text('Roll Dice'), findsOneWidget);
    await saveFightShot(tester, 'fight-enemy-tall');
    expect(tester.takeException(), isNull);
  });
}
