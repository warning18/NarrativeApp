// The fight's sprites (v1.451): the ronin is the hero's art today, and a set
// whose image is missing falls back to the ronin instead of failing.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_sprites.dart';

void main() {
  test('the ronin is the hero\'s art until later art plugs in', () {
    expect(roninSprite.facesEast, isTrue);
    expect(roninSprite.frameWidth, 42);
    expect(roninSprite.frameHeight, 47);
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
      'wreck_scavenger',
      'den_bouncer',
      'den_looter',
      'mire_returned_sedge',
      'demon_imp',
      'angel_sentinel',
      'street_bandit',
    ]) {
      final set = enemyFightSprite(id);
      expect(set, isNotNull, reason: id);
      expect(set!.facesEast, isFalse, reason: id);
      expect(set.frameWidth, 48);
      // The file is where the set says (a guard on the data table).
      expect(File(set.idleAsset).existsSync(), isTrue, reason: set.idleAsset);
    }
    // The sewer's vermin are 60 x 60 side views, and the file is that size.
    for (final id in ['harbor_rat', 'rat_matriarch', 'plague_hound']) {
      final set = enemyFightSprite(id)!;
      expect(set.facesEast, isFalse, reason: id);
      expect(set.frameWidth, 60, reason: id);
      expect(set.frameHeight, 60, reason: id);
      final bytes = File(set.idleAsset).readAsBytesSync();
      // PNG header: width and height are the 4-byte words at 16 and 20.
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(16), 60, reason: id);
      expect(data.getUint32(20), 60, reason: id);
    }
    expect(enemyFightSprite('slum_thug'), isNull);
    // Two ranks wear the two soldier variants.
    expect(enemyFightSprite('inquisition_soldier')!.id,
        isNot(enemyFightSprite('inquisition_auxiliary')!.id));
  });
}
