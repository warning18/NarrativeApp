// The fight's sprites are swapped through one resolver (v1.451): every hero
// gets the ronin today, a frame size sizes the figure, and a set whose
// image is missing falls back to the ronin instead of failing.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_figure.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';

void main() {
  test('every hero gets the ronin until later art plugs in', () {
    expect(heroFightSprite(), same(roninSprite));
    expect(heroFightSprite(raceId: 'orc', professionId: 'mage'),
        same(roninSprite));
    expect(roninSprite.facesEast, isTrue);
    expect(roninSprite.frameWidth, 42);
    expect(roninSprite.frameHeight, 47);
  });

  test('the figure is sized from the frame the set gives, not the ronin\'s',
      () {
    const tall = FightSpriteSet(
        id: 'giant',
        idleAsset: 'assets/visuals/walker/missing.png',
        frameWidth: 64,
        frameHeight: 96);
    final ronin = FightFigure.sizeFor(roninSprite, 3);
    final big = FightFigure.sizeFor(tall, 3);
    expect(ronin.width, 42 * 3 + FightFigure.lungeReach);
    expect(ronin.height, 47 * 3 + 6);
    expect(big.width, 64 * 3 + FightFigure.lungeReach);
    expect(big.height, 96 * 3 + 6);
  });

  testWidgets('a set with a missing image falls back to the ronin',
      (tester) async {
    FightSpriteImages.reset();
    const missing = FightSpriteSet(
        id: 'nobody',
        idleAsset: 'assets/visuals/walker/does_not_exist.png',
        frameWidth: 30,
        frameHeight: 30);
    expect(FightSpriteImages.effective(missing).id, 'nobody');
    await tester.runAsync(() => FightSpriteImages.load(missing));
    // The missing set is replaced by the ronin, whose image is in.
    expect(FightSpriteImages.effective(missing), same(roninSprite));
    expect(FightSpriteImages.idleOf(missing), isNotNull);
    expect(FightSpriteImages.idleOf(roninSprite)!.width, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  test('the enemies that have art face west, the others have none', () {
    for (final id in [
      'aurel_vane',
      'inquisition_warden',
      'white_soldier',
      'inquisition_soldier',
      'inquisition_auxiliary',
    ]) {
      final set = enemyFightSprite(id);
      expect(set, isNotNull, reason: id);
      expect(set!.facesEast, isFalse, reason: id);
      expect(set.frameWidth, 48);
      // The file is where the set says (a guard on the data table).
      expect(File(set.idleAsset).existsSync(), isTrue, reason: set.idleAsset);
    }
    expect(enemyFightSprite('slum_thug'), isNull);
    // Two ranks wear the two soldier variants.
    expect(enemyFightSprite('inquisition_soldier')!.id,
        isNot(enemyFightSprite('inquisition_auxiliary')!.id));
  });
}
