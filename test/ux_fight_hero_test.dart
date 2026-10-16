// The hero in the fight (v1.451): the ronin of the side view stands on the
// ground under the party's cards, facing east toward the enemies, and takes
// no room from the dice and the controls.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('the hero stands under the party, facing east, on a tall phone',
      (tester) async {
    await enterFight(tester, size: const Size(600, 1600));
    final sprite = find.byKey(const Key('fight_hero_sprite'));
    expect(sprite, findsOneWidget);
    final rect = tester.getRect(sprite);
    final party = tester.getRect(find.text('You').first);
    expect(rect.center.dx, lessThan(300),
        reason: 'on the left, with the party');
    expect(rect.top, greaterThan(party.bottom - 1),
        reason: 'on the ground below the cards, not over them');
    // The dice and the controls are where they were.
    expect(find.text('Roll Dice'), findsOneWidget);
    await saveFightShot(tester, 'fight-hero-tall');
    expect(tester.takeException(), isNull);
  });
}
