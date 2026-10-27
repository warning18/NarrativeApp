// The dice sizes (docs/proposals/dice-sizes.md): the 31 dice on real dice
// sizes, every face a slot with one copy of a skill per four faces, old
// saves moved to the new faces, the tally die (the built d12) from a quest
// and from two d8s, and the one-use fate coin on a crossing check.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/combat/face_keywords.dart';
import 'package:narrative_data_app/combat/face_smithing.dart';
import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/dice_sizes_save.dart';
import 'package:narrative_data_app/data/dice_weave.dart';
import 'package:narrative_data_app/data/fate_coin.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/skill_craft.dart'
    show skillwrightHouseId;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The table of §1: each die's size.
const Map<String, int> _sizes = {
  'starter_die': 6,
  'apprentice_die': 6,
  'iron_die': 6,
  'holy_die': 6,
  'bulwark_die': 6,
  'pilgrim_die': 6,
  'liora_die': 6,
  'grosh_die': 6,
  'tobin_die': 6,
  'malrik_die': 6,
  'void_die': 4,
  'stone_die': 4,
  'berserker_die': 4,
  'shadow_die': 4,
  'twinfang_die': 4,
  'headsman_die': 4,
  'flame_die': 8,
  'tide_die': 8,
  'huntsman_die': 8,
  'vess_die': 8,
  'frost_die': 8,
  'greenwood_die': 8,
  'vigil_die': 8,
  'storm_die': 10,
  'arcane_die': 10,
  'sage_die': 10,
  'ossuary_die': 10,
  'tempest_die': 12,
  'chorus_die': 12,
  'tearglass_die': 12,
  'gambler_die': 20,
  // The built d12.
  'tally_die': 12,
};

typedef _Face = (String type, int value, String skill, double weight);

/// The faces of each resized die before the sizes (v1.568's dice.json).
const Map<String, List<_Face>> _before = {
  'flame_die': [
    ('Skill', 0, 'fireball', 0.8),
    ('Attack', 1, '', 1.0),
    ('Defend', 1, '', 1.0),
    ('Skill', 0, 'mage_meteor', 0.3),
    ('Heal', 2, '', 0.6),
    ('Skill', 0, 'heavy_attack', 0.5)
  ],
  'tide_die': [
    ('Heal', 3, '', 0.8),
    ('Attack', 1, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'cleric_holy_light', 0.5),
    ('Skill', 0, 'cleric_purify', 0.4),
    ('Skill', 0, 'heavy_attack', 0.5)
  ],
  'storm_die': [
    ('Attack', 2, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'ranger_aimed_shot', 0.6),
    ('Skill', 0, 'ranger_multi_shot', 0.3),
    ('Heal', 2, '', 0.6),
    ('Skill', 0, 'heavy_attack', 0.5)
  ],
  'stone_die': [
    ('Attack', 2, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'dwarf_hammer_blow', 0.5),
    ('Skill', 0, 'dwarf_forgeheart', 0.4),
    ('Heal', 2, '', 0.6),
    ('Skill', 0, 'heavy_attack', 0.5)
  ],
  'shadow_die': [
    ('Attack', 2, '', 1.0),
    ('Defend', 1, '', 1.0),
    ('Skill', 0, 'rogue_backstab', 0.6),
    ('Skill', 0, 'void_blast', 0.4),
    ('Heal', 2, '', 0.6),
    ('Skill', 0, 'heavy_attack', 0.5)
  ],
  'berserker_die': [
    ('Attack', 2, '', 1.0),
    ('Skill', 0, 'orc_berserk_rage', 0.6),
    ('Skill', 0, 'orc_bloodlust', 0.4),
    ('Attack', 1, '', 1.0),
    ('Defend', 1, '', 0.6),
    ('Defend', 1, '', 0.6)
  ],
  'arcane_die': [
    ('Skill', 0, 'mage_arcane_missile', 0.7),
    ('Skill', 0, 'mage_frost_nova', 0.5),
    ('Skill', 0, 'elf_arcane_focus', 0.4),
    ('Attack', 1, '', 1.0),
    ('Skill', 0, 'mage_mana_shield', 0.5),
    ('Mana', 2, '', 0.8)
  ],
  'huntsman_die': [
    ('Attack', 2, '', 1.0),
    ('Skill', 0, '', 0.5),
    ('Skill', 0, 'ranger_camouflage', 0.4),
    ('Skill', 0, 'ranger_trap_set', 0.3),
    ('Defend', 1, '', 1.0),
    ('Skill', 0, 'ranger_beast_bond', 0.4)
  ],
  'vess_die': [
    ('Attack', 2, '', 1.0),
    ('Defend', 1, '', 1.0),
    ('Skill', 0, 'voidkin_umbral_veil', 0.5),
    ('Skill', 0, 'mage_arcane_missile', 0.5),
    ('Skill', 0, 'voidkin_entropy_touch', 0.3),
    ('Heal', 2, '', 0.5)
  ],
  'sage_die': [
    ('Mana', 2, '', 1.0),
    ('Mana', 2, '', 1.0),
    ('Attack', 2, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'mage_arcane_missile', 0.6),
    ('Heal', 3, '', 0.6)
  ],
  'gambler_die': [
    ('Attack', 3, '', 0.6),
    ('Attack', 1, '', 1.0),
    ('Skill', 0, 'lucky_strike', 0.6),
    ('Skill', 0, '', 0.6),
    ('Heal', 1, '', 0.8),
    ('Mana', 1, '', 0.6)
  ],
  'frost_die': [
    ('Attack', 3, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'frigid_grip', 0.5),
    ('Mana', 1, '', 0.6),
    ('Heal', 3, '', 0.6),
    ('Skill', 0, '', 0.5)
  ],
  'twinfang_die': [
    ('Attack', 1, '', 1.0),
    ('Attack', 1, '', 1.0),
    ('Skill', 0, 'rogue_poison_blade', 0.5),
    ('Skill', 0, '', 0.6),
    ('Defend', 1, '', 0.8),
    ('Skill', 0, 'precision_thrust', 0.4)
  ],
  'tempest_die': [
    ('Attack', 2, '', 1.0),
    ('Skill', 0, 'adrenaline_surge', 0.5),
    ('Skill', 0, '', 0.5),
    ('Mana', 2, '', 0.6),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'steady_aim', 0.4)
  ],
  'ossuary_die': [
    ('Attack', 2, '', 1.1),
    ('Defend', 3, '', 0.9),
    ('Heal', 3, '', 0.7),
    ('Skill', 0, 'final_stand', 0.5),
    ('Skill', 0, 'stone_resolve', 0.5),
    ('Skill', 0, '', 0.7)
  ],
  'vigil_die': [
    ('Attack', 3, '', 1.0),
    ('Defend', 3, '', 0.9),
    ('Heal', 5, '', 0.9),
    ('Skill', 0, 'second_chance', 0.6),
    ('Skill', 0, 'rallying_shout', 0.5),
    ('Mana', 2, '', 0.4),
    ('Skill', 0, '', 0.6)
  ],
  'tearglass_die': [
    ('Attack', 2, '', 1.2),
    ('Defend', 2, '', 0.6),
    ('Skill', 0, 'precision_thrust', 0.7),
    ('Heal', 3, '', 0.5),
    ('Skill', 0, '', 0.6),
    ('Skill', 0, 'final_stand', 0.35)
  ],
  'headsman_die': [
    ('Attack', 2, '', 1.0),
    ('Attack', 2, '', 1.0),
    ('Skill', 0, 'heavy_attack', 0.6),
    ('Defend', 2, '', 1.0),
    ('Attack', 2, '', 1.0),
    ('Heal', 2, '', 1.0)
  ],
  'greenwood_die': [
    ('Attack', 1, '', 1.0),
    ('Defend', 1, '', 1.0),
    ('Heal', 2, '', 1.0),
    ('Attack', 1, '', 1.0),
    ('Skill', 0, 'heavy_attack', 0.6),
    ('Mana', 1, '', 1.0)
  ],
  'chorus_die': [
    ('Attack', 2, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Heal', 2, '', 1.0),
    ('Attack', 2, '', 1.0),
    ('Defend', 2, '', 1.0),
    ('Skill', 0, 'heavy_attack', 0.6)
  ],
};

_Face _face(Map<String, dynamic> f) => (
      f['type'] as String,
      (f['value'] as num).toInt(),
      f['linkedSkillID'] as String,
      (f['weight'] as num).toDouble(),
    );

List<Map<String, dynamic>> _facesOf(Map<String, dynamic> dice, String id) =>
    ((dice[id] as Map<String, dynamic>)['faces'] as List)
        .cast<Map<String, dynamic>>();

Future<ProviderContainer> _session(Map<String, dynamic> save) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  container.read(playerSessionProvider.notifier);
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(save));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dice = _table('dice');
  final skills = _table('skills');

  group('the sizes', () {
    test('every die has its size from the table, a real die\'s', () {
      expect(dice.keys.toSet(), _sizes.keys.toSet());
      for (final MapEntry(:key, :value) in _sizes.entries) {
        final faces = _facesOf(dice, key);
        expect(faces, hasLength(value), reason: key);
        expect((dice[key] as Map)['numberOfFaces'], value, reason: key);
        expect(const {2, 4, 6, 8, 10, 12, 20}, contains(faces.length),
            reason: key);
      }
      // The proposal's spread: 10 d6, 6 d4, 7 d8, 4 d10, 3 d12 (and the
      // built one), 1 d20.
      final bySize = <int, int>{};
      for (final size in _sizes.values) {
        bySize[size] = (bySize[size] ?? 0) + 1;
      }
      expect(bySize, {6: 10, 4: 6, 8: 7, 10: 4, 12: 4, 20: 1});
    });

    test('a grown die keeps its faces where they were, and adds plain ones',
        () {
      for (final MapEntry(:key, value: old) in _before.entries) {
        final faces = _facesOf(dice, key);
        if (faces.length < old.length) continue;
        for (var i = 0; i < old.length; i++) {
          expect(_face(faces[i]), old[i], reason: '$key face $i');
        }
        // The new faces: plain, weight 1, the die's average plain number.
        final plain = [
          for (final f in old)
            if (f.$1 != 'Skill') f.$2,
        ];
        final average = (plain.reduce((a, b) => a + b) / plain.length).round();
        for (final f in faces.skip(old.length)) {
          expect(const ['Attack', 'Defend', 'Heal'], contains(f['type']),
              reason: key);
          expect(f['weight'], 1.0, reason: key);
          expect(f['linkedSkillID'], '', reason: key);
          if (key != 'gambler_die') expect(f['value'], average, reason: key);
        }
      }
      // The d20 spreads its numbers around its average (2).
      final gambler = _facesOf(dice, 'gambler_die').skip(6).toList();
      expect(gambler.map((f) => f['value']).toSet(), {1, 2, 3});
      expect(
          gambler.fold<int>(0, (n, f) => n + (f['value'] as int)) /
              gambler.length,
          closeTo(2, 0.1));
    });

    test('a shrunk die keeps its Skill faces and its strongest plain ones', () {
      expect(shrunkDiceFaces.keys.toSet(), {
        for (final MapEntry(:key, :value) in _sizes.entries)
          if (value < (_before[key]?.length ?? value)) key,
      });
      for (final MapEntry(key: id, value: remap) in shrunkDiceFaces.entries) {
        final old = _before[id]!;
        final faces = _facesOf(dice, id);
        // Every face kept is the old face, at its new index.
        for (final MapEntry(key: from, value: to) in remap.entries) {
          expect(_face(faces[to]), old[from], reason: '$id $from -> $to');
        }
        // A face below the new size that stayed keeps its index.
        for (final MapEntry(key: from, value: to) in remap.entries) {
          if (from < faces.length) expect(to, from, reason: id);
        }
        // Every Skill face stayed; two plain faces went, none stronger
        // than a plain face kept.
        final dropped = [
          for (var i = 0; i < old.length; i++)
            if (!remap.containsKey(i)) old[i],
        ];
        expect(dropped, hasLength(2), reason: id);
        expect(dropped.every((f) => f.$1 != 'Skill'), isTrue, reason: id);
        final keptPlain = [
          for (final i in remap.keys)
            if (old[i].$1 != 'Skill') old[i].$2,
        ];
        for (final f in dropped) {
          for (final kept in keptPlain) {
            expect(f.$2, lessThanOrEqualTo(kept), reason: id);
          }
        }
      }
    });

    test('the gambler\'s d20 is rare: 200 gold, in the late shop', () {
      expect((dice['gambler_die'] as Map)['cost'], 200);
      final shops = _table('shops');
      final selling = [
        for (final MapEntry(:key, :value) in shops.entries)
          if (((value as Map)['diceStock'] as List? ?? const [])
              .contains('gambler_die'))
            key,
      ];
      expect(selling, ['last_lantern']);
      expect((shops['last_lantern'] as Map)['diceStock'],
          containsAll(['vigil_die', 'chorus_die', 'tearglass_die']));
    });
  });

  group('every face is a slot', () {
    test('a skill can be placed on any face of every die', () {
      for (final id in dice.keys) {
        final faces = _facesOf(dice, id);
        for (var i = 0; i < faces.length; i++) {
          expect(isAssignableFace(faces[i]), isTrue, reason: '$id $i');
          expect(canSetSkillOnFace('wrath_of_dawn', i, faces, const {}, skills),
              isTrue,
              reason: '$id $i');
        }
      }
      // A Mana face and a signature face too: the pick casts.
      final holy = _facesOf(dice, 'holy_die');
      expect(holy[5]['type'], 'Mana');
      expect(faceSkillId(holy[5], 'fireball'), 'fireball');
      expect(isSignatureFace(holy[3]), isTrue);
      expect(faceSkillId(holy[3], 'fireball'), 'fireball');
      expect(faceSkillId(holy[3], null), 'cleric_smite');
    });

    test('one copy of a skill per four faces', () {
      for (final MapEntry(:key, :value)
          in {4: 1, 6: 1, 8: 2, 10: 2, 12: 3, 20: 5}.entries) {
        expect(maxCopiesOnDie(key), value, reason: 'd$key');
      }
      // A common skill (three faces by rarity) on dice of each size.
      int placed(String dieId) {
        final faces = _facesOf(dice, dieId);
        final picks = <String, String>{};
        for (var i = 0; i < faces.length; i++) {
          if (canSetSkillOnFace('heavy_attack', i, faces, picks, skills)) {
            picks['$i'] = 'heavy_attack';
          }
        }
        return limitedFaceAssignments(faces, picks, skills).length;
      }

      expect(placed('void_die'), 1);
      expect(placed('iron_die'), 1);
      expect(placed('flame_die'), 2);
      expect(placed('tally_die'), 3);
      // The d20's five are held to the common skill's three.
      expect(placed('gambler_die'), 3);
      // A signature skill counts: the iron die's Shield Bash leaves no room
      // for a second one on a d6.
      final iron = _facesOf(dice, 'iron_die');
      expect(
          canSetSkillOnFace('warrior_shield_bash', 0, iron, const {}, skills),
          isFalse);
      // Placed over the signature face itself, it is the one copy.
      expect(
          canSetSkillOnFace('warrior_shield_bash', 5, iron, const {}, skills),
          isTrue);
    });
  });

  group('old saves', () {
    Map<String, dynamic> oldSave() => {
          'saveVersion': 6,
          'raceId': 'human',
          'professionId': 'mage',
          'gold': 100,
          'ownedDiceIds': ['starter_die', 'flame_die', 'stone_die'],
          'equippedDiceId': 'flame_die',
          'unlockedSkillIds': ['fireball', 'heavy_attack', 'wrath_of_dawn'],
          'inventoryItemIds': <String>[],
          'diceSkillAssignments': {
            'flame_die': {'1': 'wrath_of_dawn', '5': 'heavy_attack'},
            'stone_die': {
              '1': 'fireball',
              '4': 'heavy_attack',
              '5': 'wrath_of_dawn'
            },
          },
          'diceUpgrades': {
            'flame_die': {
              '1': {'hones': 1},
            },
            'stone_die': {
              '0': {'hones': 1},
              '1': {'hones': 2, 'keyword': 'steady'},
              '4': {'recastType': 'Attack'},
              '5': {'keyword': 'cleave'},
            },
            'sable:shadow_die': {
              '4': {'hones': 1},
            },
          },
          'recruitedAllies': [
            {
              'companionId': 'sable',
              'currentHealth': 10,
              'diceSkillAssignments': {'1': 'rogue_backstab', '5': 'fireball'},
            },
          ],
        };

    test('a d6 that grew keeps its picks and work on the same faces', () {
      final session = PlayerSession.fromJson(oldSave());
      expect(session.equippedDiceId, 'flame_die');
      expect(session.diceSkillAssignments['flame_die'],
          {'1': 'wrath_of_dawn', '5': 'heavy_attack'});
      expect(session.upgradesOfDie('flame_die')!['1']!.hones, 1);
      // Now a d8: two more faces, free.
      final faces = _facesOf(dice, 'flame_die');
      expect(faces, hasLength(8));
      expect(
          limitedFaceAssignments(
              faces, session.diceSkillAssignments['flame_die']!, skills),
          {'1': 'wrath_of_dawn', '5': 'heavy_attack'});
    });

    test('a shrunk die moves its picks, and gives back the rest', () {
      final session = PlayerSession.fromJson(oldSave());
      // stone_die: face 5 moved to 1; faces 1 and 4 were dropped.
      expect(session.diceSkillAssignments['stone_die'], {'1': 'wrath_of_dawn'});
      // The skills off the die are still known, to be placed again.
      expect(session.unlockedSkillIds,
          containsAll(['fireball', 'heavy_attack', 'wrath_of_dawn']));
      final stone = session.upgradesOfDie('stone_die')!;
      expect(stone.keys.toSet(), {'0', '1'});
      expect(stone['0']!.hones, 1);
      expect(stone['1']!.keyword, FaceKeyword.cleave);
      // Paid back: two Hones (80 + 160 gold, 1 + 2 iron) and an inscription
      // (250 gold, a trophy) on face 1; a Recast (120) on face 4; and
      // Sable's Hone on her die's dropped face 4 (80, 1 iron).
      expect(session.gold, 100 + 80 + 160 + 250 + 120 + 80);
      expect(session.inventoryItemIds.where((id) => id == ironOreId),
          hasLength(4));
      expect(session.inventoryItemIds.where((id) => id == eliteTrophyId),
          hasLength(1));
      expect(session.upgradesOfDie('shadow_die', companionId: 'sable'), isNull);
      // Sable's picks on her shadow die: face 5 moved to 1, the old 1
      // (dropped) gone.
      expect(session.recruitedAllies.single.diceSkillAssignments,
          {'1': 'fireball'});
    });

    test('the move runs once: a migrated save loads as it was saved', () {
      final once = PlayerSession.fromJson(oldSave());
      final saved = once.toJson();
      expect(saved[diceDataVersionKey], diceDataVersion);
      final twice = PlayerSession.fromJson(
          jsonDecode(jsonEncode(saved)) as Map<String, dynamic>);
      expect(twice.gold, once.gold);
      expect(twice.diceSkillAssignments, once.diceSkillAssignments);
      expect(twice.inventoryItemIds, once.inventoryItemIds);
    });

    test('every companion whose die shrank is moved with it', () {
      final companions = _table('companions');
      expect(shrunkCompanionDice, {
        for (final MapEntry(:key, :value) in companions.entries)
          if (shrunkDiceFaces.containsKey((value as Map)['signatureDiceId']))
            key: value['signatureDiceId'],
      });
    });

    test('a refund is what the work cost', () {
      final refund = smithingRefundFor(const FaceUpgrade(
          hones: 3,
          element: 'Fire',
          keyword: FaceKeyword.pierce,
          recastType: 'Defend'));
      expect(refund.gold, 80 + 160 + 240 + 150 + 250 + 120);
      expect(refund.iron, 1 + 2 + 3 + 2);
      expect(refund.trophies, 1);
    });
  });

  group('the tally die', () {
    test('a d12 of plain faces, the Candle Count\'s reward', () {
      final faces = _facesOf(dice, tallyDieId);
      expect(faces, hasLength(12));
      expect(faces.every((f) => f['type'] != 'Skill'), isTrue);
      final quest = _table('quests')['q_ch5_candle_count'] as Map;
      expect(quest['chapter'], 5);
      expect(quest['rewardDiceID'], tallyDieId);
    });

    test('handing in the Candle Count gives it', () async {
      final container = await _session({'raceId': 'human'});
      addTearDown(container.dispose);
      await container.read(playerSessionProvider.notifier).completeQuest(
          'q_ch5_candle_count',
          rewardDiceId:
              (_table('quests')['q_ch5_candle_count'] as Map)['rewardDiceID']
                  .toString());
      expect(container.read(playerSessionProvider).ownedDiceIds,
          contains(tallyDieId));
    });

    test('two d8s recut at the Skillwright', () async {
      final container = await _session({
        'raceId': 'human',
        'gold': 0,
        'ownedDiceIds': ['starter_die', 'flame_die', 'tide_die', 'frost_die'],
        'equippedDiceId': 'flame_die',
        'builtHouseIds': [skillwrightHouseId],
        'diceSkillAssignments': {
          'flame_die': {'6': 'fireball'},
        },
        'diceUpgrades': {
          'flame_die': {
            '1': {'hones': 1},
          },
        },
      });
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      expect(weavableDice(['starter_die', 'flame_die', 'tide_die'], dice),
          ['flame_die', 'tide_die']);
      // A d6 isn't recut, nor the same die twice.
      expect(await notifier.weaveDice('flame_die', 'starter_die', dice: dice),
          isFalse);
      expect(await notifier.weaveDice('flame_die', 'flame_die', dice: dice),
          isFalse);
      expect(await notifier.weaveDice('flame_die', 'tide_die', dice: dice),
          isTrue);
      final s = container.read(playerSessionProvider);
      expect(s.ownedDiceIds, ['starter_die', 'frost_die', tallyDieId]);
      expect(s.equippedDiceId, tallyDieId);
      expect(s.diceSkillAssignments.containsKey('flame_die'), isFalse);
      expect(s.upgradesOfDie('flame_die'), isNull);
      // The Hone on the flame die is paid back.
      expect(s.gold, 80);
      expect(s.inventoryItemIds, [ironOreId]);
      // One tally die: the next pair is refused.
      expect(await notifier.weaveDice('frost_die', 'frost_die', dice: dice),
          isFalse);
    });

    test('no Skillwright, no recut', () {
      expect(
          canWeaveDice('flame_die', 'tide_die',
              owned: ['flame_die', 'tide_die'],
              builtHouseIds: const [],
              dice: dice),
          isFalse);
    });
  });

  group('the fate coin', () {
    test('a Common one-use coin, 30 gold in two town shops', () {
      final coin = _table('items')[fateCoinId] as Map;
      expect(coin['cost'], 30);
      expect(coin['itemType'], 'Scroll');
      expect(coin['rarity'], 'Common');
      final shops = _table('shops');
      expect([
        for (final MapEntry(:key, :value) in shops.entries)
          if (((value as Map)['initialStock'] as List).contains(fateCoinId))
            key,
      ], [
        'blind_beggar_stall',
        'apothecary_row'
      ]);
    });

    test('it rolls the check once more and is spent', () async {
      const failed = AbilityCheckResult(
          ability: 'dexterity', roll: 1, modifier: 3, dc: 12);
      expect(fateCoinWorthFlipping(failed), isTrue);
      final again = rerolledCheck(failed, Random(5));
      expect(again.ability, 'dexterity');
      expect(again.modifier, 3);
      expect(again.dc, 12);
      expect(again.roll, inInclusiveRange(1, 20));
      expect(
          withFateCoinSpent(['a', fateCoinId, fateCoinId]), ['a', fateCoinId]);
      expect(withFateCoinSpent(['a']), isNull);

      final container = await _session({
        'raceId': 'human',
        'inventoryItemIds': [fateCoinId],
      });
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      expect(await notifier.spendFateCoin(), isTrue);
      expect(container.read(playerSessionProvider).inventoryItemIds, isEmpty);
      expect(await notifier.spendFateCoin(), isFalse);
    });

    testWidgets('a failed crossing check offers the coin, which rolls again',
        (tester) async {
      final events = landEventsFrom(_table('land_events'));
      final ambush = LandRoute.fromJson('ambush', {
        'name': 'Ambush',
        'from': 'crash',
        'to': 'sleeper',
        'days': 1,
        'terrain': 'desert',
        'events': {'scavengers': 1},
      });
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'player_session': jsonEncode({
          'raceId': 'human',
          'currentHealth': 20,
          'maxHealth': 20,
          'dexterity': -10,
          'inventoryItemIds': [fateCoinId],
        }),
      });
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: LandCrossingScreen(
              route: ambush, events: events, random: Random(1)),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 150));
      Future<void> land() async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 1000));
        }
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('crossing_choice_slip')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await land();
      // The check failed (a hero with no Dexterity to speak of): the coin
      // is offered before the outcome.
      expect(find.byKey(const Key('crossing_fate_coin')), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('crossing_fate_coin')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await land();
      await land();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 150));
      // Rolled again, the coin spent, and the outcome follows.
      final element = tester.element(find.byType(LandCrossingScreen));
      final session =
          ProviderScope.containerOf(element).read(playerSessionProvider);
      expect(session.inventoryItemIds, isNot(contains(fateCoinId)));
      expect(find.byKey(const Key('crossing_fate_coin')), findsNothing);
      expect(find.textContaining('The coin lands'), findsOneWidget);
      expect(
          find.byKey(const Key('crossing_next')).evaluate().length +
              find.byKey(const Key('crossing_done')).evaluate().length,
          1);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
    });
  });
}
