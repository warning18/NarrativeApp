// A boss stands in the bigger box and its fight reserves the taller stage
// (v1.612): Aurel Vane against the hero at 412 px.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_figure.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';

import 'fight_hero_harness.dart';

void main() {
  testWidgets('a boss stands in the boss box on the taller stage',
      (tester) async {
    await enterFight(tester,
        size: const Size(412, 1000), enemyId: 'aurel_vane');
    final stage = tester.getSize(find.byKey(const Key('fight_stage')));
    expect(stage.height, FightBoxes.wide.stageHeight(boss: true));
    final boss = tester.getSize(find.byWidgetPredicate((w) =>
        w.key is Key && w.key.toString().contains('fight_enemy_sprite_')));
    final set = enemyFightSprite('aurel_vane')!;
    final pixel = FightBoxes.pixelFor(set, FightBoxes.wide.boss);
    expect(boss, FightFigure.sizeFor(set, pixel));
    // The hero keeps its own box.
    final hero = tester.getSize(find.byKey(const Key('fight_hero_sprite')));
    expect(hero.height,
        roninSprite.frameHeight * FightBoxes.pixelFor(roninSprite, 96) + 6);
    expect(tester.takeException(), isNull);
  });
}
