// Each class starts with one die of its own and only its own skills; dice
// made for a class are sold to that class; Wisdom adds mana; every face
// wears the colour of what it does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/skill_access.dart';
import 'package:narrative_data_app/utils/face_style.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final skills = _data('skills');
  final dice = _data('dice');
  final professions = _data('professions');
  final races = _data('races');
  final merges = _data('skill_merges');

  group('starting kit', () {
    test('only Heavy Blow is everyone\'s skill from the start', () {
      final shared = [
        for (final e in skills.entries)
          if ((e.value as Map<String, dynamic>)['isUnlocked'] == true) e.key,
      ];
      expect(shared, ['heavy_attack']);
      expect(skills['fireball']['restrictedProfessionID'], 'mage');
    });

    test('casters have a mana skill of their own on the apprentice die', () {
      for (final id in ['mage', 'cleric']) {
        final profession = professions[id] as Map<String, dynamic>;
        final manaSkill = profession['manaSkillID'] as String;
        final skill = skills[manaSkill] as Map<String, dynamic>;
        expect(skill['restrictedProfessionID'], id);
        expect(skill['manaGain'], greaterThan(0));
        expect(profession['startingDiceId'], 'apprentice_die');
      }
      final channeling =
          (dice['apprentice_die']['faces'] as List)[1] as Map<String, dynamic>;
      expect(channeling['type'], 'Skill');
      expect(isAssignableFace(channeling), isTrue);
    });

    for (final professionId in [
      'warrior',
      'mage',
      'rogue',
      'cleric',
      'ranger'
    ]) {
      test('a new $professionId owns one die, theirs, and only their skills',
          () async {
        final notifier = await notifierWith(baseSession());
        const raceId = 'human';
        await notifier.startNewGame(
          raceId: raceId,
          race: races[raceId] as Map<String, dynamic>,
          professionId: professionId,
          profession: professions[professionId] as Map<String, dynamic>,
        );
        final s = notifier.state;
        expect(s.ownedDiceIds, hasLength(1));
        final die = dice[s.equippedDiceId] as Map<String, dynamic>;
        expect(dieUsableBy(die, professionId: professionId, raceId: raceId),
            isTrue);
        for (final id in s.unlockedSkillIds) {
          expect(
              skillFitsCharacter(skills[id] as Map<String, dynamic>,
                  raceId: raceId, professionId: professionId),
              isTrue,
              reason: '$professionId starts with $id');
        }
        expect(s.unlockedSkillIds, isNot(contains('fireball')));
        // Every skill set on the die is one the character knows.
        final assigned = s.diceSkillAssignments[s.equippedDiceId]!.values;
        expect(s.unlockedSkillIds, containsAll(assigned));
        if (professionId == 'mage') {
          expect(s.unlockedSkillIds, contains('mage_channel'));
        }
      });
    }
  });

  group('skill lists', () {
    test('a warrior never sees a mage\'s skills, and the other way round', () {
      final warrior = skillIdsForCharacter(skills, merges,
          raceId: 'human', professionId: 'warrior');
      final mage = skillIdsForCharacter(skills, merges,
          raceId: 'human', professionId: 'mage');
      expect(warrior, isNot(contains('fireball')));
      expect(warrior.where((id) => id.startsWith('mage_')), isEmpty);
      expect(warrior, contains('warrior_whirlwind'));
      expect(warrior, contains('second_wind'));
      expect(mage, containsAll(['fireball', 'mage_channel', 'human_resolve']));
      expect(mage.where((id) => id.startsWith('warrior_')), isEmpty);
      expect(mage.where((id) => id.startsWith('elf_')), isEmpty);
      for (final list in [warrior, mage]) {
        for (final id in list) {
          expect(
              (skills[id] as Map<String, dynamic>)['enemyOnly'], isNot(true));
        }
      }
    });

    test('a merge skill is listed only when its recipe fits', () {
      bool listed(String result, String race, String profession) =>
          skillIdsForCharacter(skills, merges,
                  raceId: race, professionId: profession)
              .contains(result);
      // Fireball (mage) + Shadow Step (anyone).
      expect(listed('blazing_shadow', 'human', 'mage'), isTrue);
      expect(listed('blazing_shadow', 'human', 'warrior'), isFalse);
      // Arcane Focus (elf) + Arcane Missile (mage).
      expect(listed('arcane_convergence', 'elf', 'mage'), isTrue);
      expect(listed('arcane_convergence', 'human', 'mage'), isFalse);
    });
  });

  group('dice made for a class', () {
    test('restrictions name real professions and races', () {
      for (final entry in dice.entries) {
        final die = entry.value as Map<String, dynamic>;
        for (final id in dieProfessionIds(die)) {
          expect(professions.containsKey(id), isTrue, reason: entry.key);
        }
        for (final id in dieRaceIds(die)) {
          expect(races.containsKey(id), isTrue, reason: entry.key);
        }
      }
    });

    test('who may roll which die', () {
      bool usable(String die, String profession, [String race = 'human']) =>
          dieUsableBy(dice[die] as Map<String, dynamic>,
              professionId: profession, raceId: race);
      expect(usable('apprentice_die', 'mage'), isTrue);
      expect(usable('apprentice_die', 'cleric'), isTrue);
      expect(usable('apprentice_die', 'warrior'), isFalse);
      expect(usable('flame_die', 'warrior'), isFalse);
      expect(usable('stone_die', 'warrior', 'dwarf'), isTrue);
      expect(usable('stone_die', 'warrior', 'elf'), isFalse);
      expect(usable('gambler_die', 'rogue'), isTrue);
      expect(usable('starter_die', 'mage'), isTrue);
    });

    test('every companion can roll their own signature die', () {
      final companions = _data('companions');
      for (final entry in companions.entries) {
        final c = entry.value as Map<String, dynamic>;
        expect(
            dieUsableBy(dice[c['signatureDiceId']] as Map<String, dynamic>,
                professionId: c['professionId'] as String,
                raceId: c['raceId'] as String),
            isTrue,
            reason: entry.key);
      }
    });
  });

  group('Wisdom and mana', () {
    test('one more mana per 3 Wisdom', () {
      expect(wisdomManaBonusFor(-2), 0);
      expect(wisdomManaBonusFor(1), 0);
      expect(wisdomManaBonusFor(3), 1);
      expect(wisdomManaBonusFor(6), 2);
      expect(wisdomManaBonusFor(10), 3);
    });

    test('a Mana face and a mana skill both add the Wisdom bonus', () {
      const manaFace = DiceFaceResult(
          faceIndex: 0,
          faceName: 'Focus',
          type: 'Mana',
          value: 1,
          linkedSkillID: '',
          element: 'None');
      expect(
          resolvePlayerFace(manaFace, skills, 10, wisdomManaBonus: 2)
              .manaGained,
          3);
      const channel = DiceFaceResult(
          faceIndex: 1,
          faceName: 'Channeling',
          type: 'Skill',
          value: 0,
          linkedSkillID: 'mage_channel',
          element: 'None');
      final result = resolvePlayerFace(channel, skills, 10, wisdomManaBonus: 1);
      expect(result.manaGained, 3);
      expect(result.damageDealt, 0);
      expect(result.healingDone, 0);
    });
  });

  group('face colours', () {
    test('each face reads as what it does', () {
      Map<String, dynamic> skill(String id) =>
          skills[id] as Map<String, dynamic>;
      expect(faceKind('Attack'), FaceKind.attack);
      expect(faceKind('Defend'), FaceKind.defend);
      expect(faceKind('Heal'), FaceKind.heal);
      expect(faceKind('Mana'), FaceKind.mana);
      expect(skillKind(skill('mage_channel')), FaceKind.mana);
      expect(skillKind(skill('rogue_poison_blade')), FaceKind.poison);
      expect(skillKind(skill('second_wind')), FaceKind.heal);
      expect(skillKind(skill('fireball')), FaceKind.attack);
      expect(FaceKind.mana.color, isNot(FaceKind.attack.color));
      expect(FaceKind.poison.color, isNot(FaceKind.heal.color));
    });
  });
}
