// A 320 px phone gets the small boxes (v1.612), and the dice and the controls
// stay on screen under the stage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_figure.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('at 320 px the figures stand in the small boxes', (tester) async {
    await enterFight(tester,
        size: const Size(320, 1000), enemyId: 'inquisition_soldier');
    final stage = tester.getSize(find.byKey(const Key('fight_stage')));
    expect(stage.height, FightBoxes.narrow.stageHeight(boss: false));
    final set = enemyFightSprite('inquisition_soldier')!;
    final foe = tester.getSize(find.byWidgetPredicate((w) =>
        w.key is Key && w.key.toString().contains('fight_enemy_sprite_')));
    expect(foe, FightFigure.sizeFor(set, FightBoxes.pixelFor(set, 72)));
    final hero = tester.getSize(find.byKey(const Key('fight_hero_sprite')));
    expect(hero,
        FightFigure.sizeFor(roninSprite, FightBoxes.pixelFor(roninSprite, 72)));
    expect(find.text('Roll Dice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
