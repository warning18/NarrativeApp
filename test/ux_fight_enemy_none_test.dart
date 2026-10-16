// An enemy without art keeps its portrait card alone (v1.454): no figure
// stands for the slum thug, and the hero still does.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('an enemy with no art has its card and no figure',
      (tester) async {
    await enterFight(tester, size: const Size(600, 1600));
    final figure = find.byWidgetPredicate((w) =>
        w.key is Key && w.key.toString().contains('fight_enemy_sprite_'));
    expect(figure, findsNothing);
    expect(find.byKey(const Key('fight_hero_sprite')), findsOneWidget);
    expect(find.textContaining('Slum Thug'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
