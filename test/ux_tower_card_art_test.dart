// v2.3 (UX-2): the lookup behind a Tower card's picture, where Art's vignettes
// plug in: "kind:variant", then "kind", then the kind's stand-in.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/tower_card_art.dart';

void main() {
  test('every key Art draws has its picture, in a declared folder', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- $towerCardsDir/'));
    for (final e in towerCardArt.entries) {
      expect(File(e.value).existsSync(), isTrue,
          reason: '${e.key}: ${e.value}');
    }
    for (final f in [towerCardFrame, towerCardSealBlank, towerCardStamp]) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
    // Art's keys: nine elements, the die, four spell families.
    expect(towerCardArt.keys.where((k) => k.startsWith('skill:')).length, 9);
    expect(towerCardArt.keys.where((k) => k.startsWith('spell:')).length, 4);
    expect(towerCardArt.containsKey('die'), isTrue);
  });

  test('Art\'s picture wins: the variant, then the kind, then the stand-in',
      () {
    const art = {
      'skill:Fire': 'a/fire.png',
      'skill': 'a/skill.png',
    };
    expect(towerCardVignette('skill', variant: 'Fire', art: art), 'a/fire.png');
    expect(towerCardVignette('skill', variant: 'Ice', art: art), 'a/skill.png');
    expect(towerCardVignette('die', art: art), towerCardStandIn['die']);
    expect(towerCardVignette('spell', variant: 'Heal'),
        '$towerCardsDir/spell_heal.png');
    // A kind or a variant Art has not drawn keeps the stand-in.
    expect(towerCardVignette('oath'), towerCardStandIn['oath']);
    expect(
        towerCardVignette('skill', variant: 'Nope'),
        towerCardStandIn['skill'].toString().isEmpty
            ? ''
            : towerCardVignette('skill'));
    expect(towerCardVignette('unknown'), towerCardStandIn['skill']);
  });

  test('a spell\'s effect is one of Art\'s four families', () {
    expect(towerSpellFamily('Damage'), 'Damage');
    expect(towerSpellFamily('Block'), 'Ward');
    expect(towerSpellFamily('Status'), 'Hex');
    expect(towerSpellFamily('Cleanse'), 'Heal');
    expect(towerSpellFamily('Heal'), 'Heal');
    expect(towerSpellFamily(''), 'Damage');
  });

  test('the five rarities are the five seals', () {
    expect([
      for (final r in ['common', 'uncommon', 'rare', 'epic', 'legendary'])
        towerRarityIndex(r)
    ], [
      0,
      1,
      2,
      3,
      4
    ]);
    expect(towerRarityIndex(null), isNull);
    expect(towerRarityIndex('mythic'), isNull);
  });
}
