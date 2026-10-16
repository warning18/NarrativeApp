// A small phone's fight keeps its dice and controls on screen with the hero
// in it (v1.451): the sprite takes no room, and gives way to the cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('a small phone keeps its dice and controls on screen',
      (tester) async {
    // The setup page needs room to be entered with the test font; the
    // battle is then looked at on the small phone.
    await enterFight(tester, size: const Size(360, 1000));
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump(const Duration(milliseconds: 300));
    final roll = tester.getRect(find.text('Roll Dice'));
    expect(roll.bottom, lessThanOrEqualTo(640));
    expect(roll.top, greaterThan(0));
    await saveFightShot(tester, 'fight-hero-small');
    expect(tester.takeException(), isNull);
  });
}
