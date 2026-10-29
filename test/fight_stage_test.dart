// The fixed boxes of the fight's stage (v1.612, docs/proposals/
// fight-fixed-sizes.md): one size for the hero, an ally and a foe, a bigger
// one for a boss, a smaller set under 360 px, the art scaled to its box in
// quarter steps and a stage whose height does not depend on the fight.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_sprites.dart';

void main() {
  test('a phone of 360 px or more has the wide boxes, a narrower one the small',
      () {
    expect(FightBoxes.forWidth(412), same(FightBoxes.wide));
    expect(FightBoxes.forWidth(360), same(FightBoxes.wide));
    expect(FightBoxes.forWidth(320), same(FightBoxes.narrow));
    expect([
      FightBoxes.wide.hero,
      FightBoxes.wide.ally,
      FightBoxes.wide.foe,
      FightBoxes.wide.boss
    ], [
      96,
      64,
      96,
      144
    ]);
    expect([
      FightBoxes.narrow.hero,
      FightBoxes.narrow.ally,
      FightBoxes.narrow.foe,
      FightBoxes.narrow.boss
    ], [
      72,
      48,
      72,
      108
    ]);
    // A boss is a box and a half of a foe, in both sets.
    expect(FightBoxes.wide.boss, FightBoxes.wide.foe * 1.5);
    expect(FightBoxes.narrow.boss, FightBoxes.narrow.foe * 1.5);
  });

  test('the art is scaled to its box in quarter steps', () {
    final soldier = enemyFightSprite('inquisition_soldier')!;
    expect(FightBoxes.pixelFor(roninSprite, 96), 2.0, reason: '47 px tall');
    expect(FightBoxes.pixelFor(soldier, 96), 2.0);
    expect(FightBoxes.pixelFor(soldier, 144), 3.0);
    expect(FightBoxes.pixelFor(soldier, 72), 1.5);
    expect(FightBoxes.pixelFor(soldier, 108), 2.25);
    // Whatever the art, it never overflows its box.
    for (final box in [72.0, 96.0, 108.0, 144.0]) {
      for (final set in [roninSprite, soldier]) {
        expect(set.frameHeight * FightBoxes.pixelFor(set, box),
            lessThanOrEqualTo(box));
      }
    }
  });

  test('the stage is as tall as its tallest box, a boss fight\'s a boss\'s',
      () {
    for (final boxes in [FightBoxes.wide, FightBoxes.narrow]) {
      final plain = boxes.stageHeight(boss: false);
      final boss = boxes.stageHeight(boss: true);
      expect(boss - plain, boxes.boss - boxes.hero);
      expect(plain, greaterThan(boxes.hero + FightBoxes.barRoom));
    }
  });
}
