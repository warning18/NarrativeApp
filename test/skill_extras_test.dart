// The 20 skills of 1.245 and the rules they add (see skill_extras.dart): the
// records are whole, sit in a skill tree, have an icon and a French text, and
// each rule reads off its record as the skill says.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/status_effect.dart';

Map<String, dynamic> _load(String file) =>
    jsonDecode(File('assets/gamedata/$file').readAsStringSync())
        as Map<String, dynamic>;

const _ids = [
  'mage_rime_lance',
  'mage_glacial_ward',
  'mage_chain_lightning',
  'mage_static_charge',
  'mage_thunderclap',
  'mage_stormcaller',
  'cleric_tidal_wash',
  'cleric_undertow',
  'cleric_dawn_lance',
  'cleric_lantern_ward',
  'cleric_winter_hush',
  'cleric_second_dawn',
  'rogue_gale_cut',
  'rogue_dust_devil',
  'ranger_rain_of_arrows',
  'ranger_hawk_mark',
  'ranger_windwalker',
  'warrior_rockfall',
  'warrior_bastion_slam',
  'warrior_thornwall',
];

DiceFaceResult _face(String skillId, {String channeledFrom = ''}) =>
    DiceFaceResult(
      faceIndex: 0,
      faceName: 'Test',
      type: 'Skill',
      value: 0,
      linkedSkillID: skillId,
      element: 'None',
      channeledFrom: channeledFrom,
    );

PlayerActionResult _cast(String id, {int base = 10, int armor = 0}) {
  final skills = _load('skills.json');
  return resolvePlayerFace(_face(id), skills, base, armor: armor);
}

void main() {
  final skills = _load('skills.json');
  final trees = _load('skill_trees.json');

  test('the 20 skills are whole records', () {
    for (final id in _ids) {
      final skill = skills[id] as Map<String, dynamic>?;
      expect(skill, isNotNull, reason: id);
      expect(skill!['id'], id);
      expect(skill['restrictedProfessionID'], id.split('_').first);
      for (final key in ['name_fr', 'description_fr', 'battleMessage_fr']) {
        expect((skill[key] as String?)?.isNotEmpty, isTrue, reason: '$id $key');
      }
      expect(File('assets/icons/skills/$id.png').existsSync(), isTrue,
          reason: '$id icon');
    }
  });

  test('each of them sits on its own profession\'s tree, once', () {
    for (final id in _ids) {
      final homes = [
        for (final branch in trees.values)
          if ((branch['skillIds'] as List).contains(id)) branch,
      ];
      expect(homes, hasLength(1), reason: id);
      expect(homes.single['professionId'], id.split('_').first, reason: id);
    }
  });

  test('Ice, Electricity and Light now have player skills', () {
    for (final element in ['Ice', 'Electricity', 'Light']) {
      final player = [
        for (final s in skills.values)
          if (s['element'] == element &&
              (s['restrictedProfessionID'] as String).isNotEmpty)
            s,
      ];
      expect(player.length, greaterThanOrEqualTo(3), reason: element);
    }
  });

  group('what a record asks for', () {
    test('a ward raises block and lays a status on whoever strikes it', () {
      final glacial = _cast('mage_glacial_ward');
      expect(glacial.blockAmount, 12);
      expect(glacial.damageDealt, 0);
      expect(glacial.extras.reflect?.type, StatusEffectType.weaken);
      final thorn = _cast('warrior_thornwall');
      expect(thorn.blockAmount, 10);
      expect(thorn.extras.reflect?.type, StatusEffectType.poison);
      expect(thorn.extras.reflect?.magnitude, 3);
    });

    test('Lantern Ward shields and heals a little', () {
      final r = _cast('cleric_lantern_ward');
      expect(r.blockAmount, 8);
      expect(r.healingDone, 6);
    });

    test('a skill of several blows carries their total', () {
      final one = _cast('rogue_dust_devil');
      final gale = _cast('rogue_gale_cut');
      expect(gale.extras.strikes, 2);
      // (10 + 5) x 1.2 a blow, twice.
      expect(gale.damageDealt, ((10 + 5) * 1.2 * 2).round());
      expect(one.extras.strikes, 1);
      final storm = _cast('mage_stormcaller');
      expect(storm.extras.strikes, 3);
      expect(storm.extras.splashShare, 0.3);
    });

    test('Chain Lightning reaches one other enemy; Rain of Arrows all', () {
      final chain = _cast('mage_chain_lightning').extras;
      expect((chain.splashShare, chain.splashTargets), (0.5, 1));
      final rain = _cast('ranger_rain_of_arrows').extras;
      expect((rain.splashShare, rain.splashTargets), (0.8, 0));
    });

    test('Bastion Slam hits harder for more armor', () {
      final bare = _cast('warrior_bastion_slam');
      final plated = _cast('warrior_bastion_slam', armor: 6);
      expect(plated.damageDealt, greaterThan(bare.damageDealt));
      expect(plated.damageDealt - bare.damageDealt, 9);
    });

    test('Winter\'s Hush stuns and weakens every enemy', () {
      final hush = _cast('cleric_winter_hush');
      expect(hush.damageDealt, 0);
      expect(hush.inflictedStatus?.type, StatusEffectType.stun);
      expect(hush.extras.secondStatus?.type, StatusEffectType.weaken);
      expect(hush.extras.statusAll, isTrue);
    });

    test('Second Dawn mends the party and lifts every affliction', () {
      final dawn = _cast('cleric_second_dawn');
      expect(dawn.healingDone, 20);
      expect(dawn.extras.healAll, isTrue);
      final afflicted = [
        const StatusEffect(
            type: StatusEffectType.poison, remainingTurns: 2, magnitude: 3),
        const StatusEffect(type: StatusEffectType.weaken, remainingTurns: 1),
      ];
      expect(dawn.extras.cleansed(afflicted), isEmpty);
    });

    test('Tidal Wash clears poison and nothing else', () {
      final wash = _cast('cleric_tidal_wash');
      final afflicted = [
        const StatusEffect(
            type: StatusEffectType.poison, remainingTurns: 2, magnitude: 3),
        const StatusEffect(type: StatusEffectType.weaken, remainingTurns: 1),
      ];
      final after = wash.extras.cleansed(afflicted);
      expect(after.map((e) => e.type), [StatusEffectType.weaken]);
    });

    test('Dawn Lance pierces, Hawk Mark fills momentum, Windwalker rerolls',
        () {
      expect(_cast('cleric_dawn_lance').extras.pierces, isTrue);
      expect(_cast('ranger_hawk_mark').extras.chargesMomentum, isTrue);
      expect(_cast('ranger_windwalker').extras.bonusRolls, 1);
    });

    test('Static Charge gives mana; Thunderclap and Rockfall stun', () {
      expect(_cast('mage_static_charge').manaGained, greaterThan(0));
      for (final id in ['mage_thunderclap', 'warrior_rockfall']) {
        expect(_cast(id).inflictedStatus?.type, StatusEffectType.stun,
            reason: id);
      }
    });

    test('a ward set on a basic face works at channeled power', () {
      final r = resolvePlayerFace(
          _face('warrior_thornwall', channeledFrom: 'Defend'), skills, 10);
      expect(r.blockAmount, (10 * channeledPower).round());
    });

    test('an old skill reads as having no extras', () {
      expect(_cast('fireball').extras.isNone, isTrue);
      expect(SkillExtras.none.isNone, isTrue);
    });
  });
}
