// Unit coverage for lib/utils/spell_preview.dart -- the numbers the
// character and skills screens show for a spell outside a fight, and the
// "where is this spellbook sold" lookup behind the unlearned-spell cards.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/utils/spell_preview.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

PlayerSession _session({
  int baseDamage = 10,
  int level = 1,
  int intelligence = 4,
  int wisdom = 0,
  List<String> equippedItemIds = const [],
  List<String> knownSpellIds = const [],
  String professionId = 'mage',
}) {
  return PlayerSession(
    level: level,
    currentXP: 0,
    gold: 0,
    alignmentScore: 0,
    maxHealth: 100,
    currentHealth: 100,
    baseDamage: baseDamage,
    baseArmor: 0,
    luck: 0,
    charisma: 0,
    strength: 0,
    dexterity: 0,
    constitution: 0,
    intelligence: intelligence,
    wisdom: wisdom,
    perception: 0,
    potionCount: 0,
    statPoints: 0,
    skillPoints: 0,
    maxSkillSlots: 3,
    flags: const [],
    activeQuestIds: const [],
    completedQuestIds: const [],
    inventoryItemIds: const [],
    equippedItemIds: equippedItemIds,
    unlockedSkillIds: const [],
    unlockedShopIds: const [],
    unlockedQuestIds: const [],
    unlockedEnemyIds: const [],
    diceSkillAssignments: const {},
    raceId: 'human',
    professionId: professionId,
    ownedDiceIds: const [],
    equippedDiceId: null,
    knownSpellIds: knownSpellIds,
  );
}

void main() {
  final spells = parseSpells(_loadGamedata('spells.json'));
  final items = _loadGamedata('items.json');
  final shops = _loadGamedata('shops.json');

  group('sessionCasterDamage', () {
    test('base damage plus a weapon, its stat scaling and element bonus', () {
      const staff = {
        'staff': {
          'itemType': 'Weapon',
          'attackDamage': 6,
          'scalingStat': 'intelligence',
          'elecDmgBonus': 3,
        },
      };
      final session =
          _session(baseDamage: 16, intelligence: 4, equippedItemIds: ['staff']);
      // 16 base + 6 flat + 4 ~/ 2 scaling = 24 with no element...
      expect(sessionCasterDamage(session, staff, 'None'), 24);
      // ...and 27 for an Electricity spell, thanks to the elecDmgBonus.
      expect(sessionCasterDamage(session, staff, 'Electricity'), 27);
      expect(sessionCasterDamage(session, staff, 'Fire'), 24);
    });
  });

  group('previewSpellFor', () {
    test('matches spellAmountFor on the session\'s own caster damage', () {
      final bolt = spells['spell_arcane_bolt']!;
      final session = _session(baseDamage: 16, intelligence: 4);
      final preview = previewSpellFor(bolt, session, const {});
      expect(
        preview.amount,
        spellAmountFor(bolt,
            intelligence: 4, wisdom: 0, level: 1, casterDamage: 16),
      );
      expect(preview.amount, greaterThan(16));
      expect(preview.status, isNull);
    });

    test('a hex previews its level-scaled poison', () {
      final hex = spells['spell_venom_hex']!;
      final preview = previewSpellFor(
          hex, _session(level: 11, professionId: 'rogue'), const {});
      expect(preview.amount, 0);
      expect(preview.status!.type, StatusEffectType.poison);
      expect(
          preview.status!.magnitude, spellStatusFor(hex, level: 11)!.magnitude);
    });
  });

  group('spellbookShopsFor', () {
    test('finds the shops stocking a spell\'s book, none for a starting spell',
        () {
      expect(spellbookShopsFor('spell_frost_bind', items, shops),
          contains('arcane_bazaar'));
      expect(spellbookShopsFor('spell_arcane_bolt', items, shops), isEmpty);
      expect(spellbookShopsFor('no_such_spell', items, shops), isEmpty);
    });

    test('every non-starting spell in the data is sold somewhere', () {
      final professions = _loadGamedata('professions.json');
      final starting = <String>{
        for (final p in professions.values)
          ...((p as Map<String, dynamic>)['startingSpellIds'] as List? ??
                  const [])
              .map((e) => e.toString()),
      };
      for (final id in spells.keys) {
        if (starting.contains(id)) continue;
        expect(spellbookShopsFor(id, items, shops), isNotEmpty,
            reason: '$id has no shop');
      }
    });
  });

  group('spellsForProfession', () {
    test('known spells first in learned order, then the profession\'s rest',
        () {
      final list = spellsForProfession(
          spells, 'mage', const ['spell_mana_ward', 'spell_arcane_bolt']);
      expect(list.map((s) => s.id).take(2),
          ['spell_mana_ward', 'spell_arcane_bolt']);
      final rest = list.skip(2).map((s) => s.id).toList();
      expect(rest, containsAll(['spell_ember_wave', 'spell_frost_bind']));
      expect(rest, isNot(contains('spell_purge')),
          reason: 'a Cleric spell never shows for a Mage');
      expect(rest, isNot(contains('spell_arcane_bolt')));
    });

    test('an unknown profession sees only unrestricted spells', () {
      expect(spellsForProfession(spells, 'bard', const []), isEmpty);
    });
  });
}
