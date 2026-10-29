// An enemy without art stands as its portrait in its box (v1.612): the slum
// thug has no sprite, and its pixel portrait takes the box a sprite would, so
// no slot on the stage is empty. The hero stands as ever.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/pixel_portrait.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('an enemy with no art stands as its portrait in its box',
      (tester) async {
    await enterFight(tester, size: const Size(600, 1600));
    final figure = find.byWidgetPredicate((w) =>
        w.key is Key && w.key.toString().contains('fight_enemy_sprite_'));
    expect(figure, findsOneWidget);
    expect(tester.widget(figure), isA<PixelEnemyPortrait>(),
        reason: 'the portrait, not a sprite');
    expect(find.byKey(const Key('fight_hero_sprite')), findsOneWidget);
    expect(find.textContaining('Slum Thug'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
