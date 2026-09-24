// The late-game content pass: boots and greaves for the empty Foot and
// Bottom slots, mid-tier armor, the Hammersmith's iron recipes, spells for
// the warrior, rogue and ranger, dice for the chapter 5-6 shops and
// pack-eligible enemies for chapters 4-6 -- checked against the real game
// data so a later edit can't quietly undo any of it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/sub_node_engine.dart';

Map<String, dynamic> _data(String name) {
  for (final dir in ['assets/gamedata', '../assets/gamedata']) {
    final file = File('$dir/$name.json');
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name.json');
}

const newArmorIds = [
  'boots_worn_leather',
  'boots_tidewalker',
  'boots_iron_shod',
  'boots_bone_laced',
  'boots_tearwalker',
  'greaves_hide',
  'greaves_studded',
  'greaves_iron',
  'greaves_bone_plated',
  'greaves_voidsteel',
  'helm_iron_cap',
  'hood_gravecloth',
  'helm_drowned_sallet',
  'helm_last_watch',
  'coat_brigandine',
  'coat_iron_scale',
  'hauberk_saltcrust',
  'coat_last_watch',
];

const newSpellbookIds = [
  'spellbook_rally_the_line',
  'spellbook_sundering_roar',
  'spellbook_smoke_veil',
  'spellbook_bleeding_cut',
  'spellbook_arrow_volley',
  'spellbook_snare_shot',
];

const newSpellIds = [
  'spell_rally_the_line',
  'spell_sundering_roar',
  'spell_smoke_veil',
  'spell_bleeding_cut',
  'spell_arrow_volley',
  'spell_snare_shot',
];

const newDiceIds = ['ossuary_die', 'vigil_die', 'tearglass_die'];

const newEnemyIds = ['bone_sexton', 'drowned_pilgrim', 'unmade_knight'];

void main() {
  final items = _data('items');
  final shops = _data('shops');
  final spells = _data('spells');
  final dice = _data('dice');
  final enemies = _data('enemies');

  Map<String, dynamic> item(String id) => items[id] as Map<String, dynamic>;

  final stocked = <String>{
    for (final shop in shops.values)
      ...((shop as Map<String, dynamic>)['initialStock'] as List? ?? const [])
          .map((e) => e.toString()),
  };

  group('boots and greaves', () {
    for (final slot in ['Foot', 'Bottom']) {
      test('the $slot slot has a line across the loot chapters', () {
        final pieces = [
          for (final e in items.entries)
            if ((e.value as Map<String, dynamic>)['isEquippable'] == true &&
                (e.value as Map<String, dynamic>)['equipSlot'] == slot)
              e.value as Map<String, dynamic>,
        ];
        expect(pieces.length, greaterThanOrEqualTo(5));
        final chapters = {
          for (final p in pieces) (p['lootChapter'] as num).toInt(),
        }..remove(0);
        expect(chapters.length, greaterThanOrEqualTo(4), reason: '$chapters');
      });
    }

    test('armor rises with the loot chapter along each new line', () {
      for (final prefix in ['boots_', 'greaves_']) {
        final line = [
          for (final id in newArmorIds)
            if (id.startsWith(prefix)) item(id),
        ]..sort((a, b) =>
            (a['lootChapter'] as int).compareTo(b['lootChapter'] as int));
        for (var i = 1; i < line.length; i++) {
          expect(
              line[i]['armor'] as int, greaterThan(line[i - 1]['armor'] as int),
              reason: line[i]['id'].toString());
        }
      }
    });
  });

  group('new armor', () {
    test('every piece is complete, wearable armor', () {
      final template = item('plate_emberproof');
      for (final id in newArmorIds) {
        final piece = item(id);
        for (final key in template.keys) {
          expect(piece.containsKey(key), isTrue, reason: '$id lacks $key');
        }
        expect(piece['itemType'], 'Armor', reason: id);
        expect(piece['isEquippable'], isTrue, reason: id);
        expect(piece['alignment'], '', reason: id);
        expect((piece['armor'] as num).toInt(), greaterThan(0), reason: id);
        expect((piece['cost'] as num).toInt(), greaterThan(0), reason: id);
        expect((piece['lootChapter'] as num).toInt(), inInclusiveRange(1, 6),
            reason: id);
      }
    });

    test('a Common or Uncommon Top stays below the Rare armor of its chapter',
        () {
      for (final id in newArmorIds) {
        final piece = item(id);
        if (piece['equipSlot'] != 'Top' || piece['rarity'] == 'Rare') continue;
        final chapter = piece['lootChapter'] as int;
        for (final other in items.values) {
          final rare = other as Map<String, dynamic>;
          if (rare['itemType'] != 'Armor' ||
              rare['equipSlot'] != 'Top' ||
              rare['rarity'] != 'Rare' ||
              rare['lootChapter'] != chapter) {
            continue;
          }
          expect(piece['armor'] as int, lessThan(rare['armor'] as int),
              reason: '$id vs ${rare['id']}');
        }
      }
    });

    test('everything that is not forged is sold somewhere', () {
      for (final id in newArmorIds) {
        if (item(id).containsKey('craftedAt')) continue;
        expect(stocked, contains(id));
      }
    });
  });

  group('the Hammersmith forges its iron line', () {
    final craftable = [
      for (final e in items.entries)
        if ((e.value as Map<String, dynamic>).containsKey('craftedAt')) e.key,
    ];

    test('four iron pieces are forged', () {
      expect(
          craftable,
          containsAll([
            'boots_iron_shod',
            'greaves_iron',
            'helm_iron_cap',
            'coat_iron_scale',
          ]));
    });

    test('every recipe is gold and iron ore at the Hammersmith, never stock',
        () {
      expect(craftable, isNotEmpty);
      for (final id in craftable) {
        final piece = item(id);
        expect(piece['craftedAt'], 'hammersmith_forge', reason: id);
        expect((piece['craftGold'] as num).toInt(), greaterThan(0), reason: id);
        final materials = piece['craftMaterials'] as Map<String, dynamic>;
        expect(materials.keys.toList(), ['material_iron_ore'], reason: id);
        expect((materials['material_iron_ore'] as num).toInt(),
            inInclusiveRange(1, 5),
            reason: id);
        expect(stocked, isNot(contains(id)), reason: '$id is also sold');
      }
    });
  });

  group('spells for the martial professions', () {
    for (final profession in ['warrior', 'rogue', 'ranger']) {
      test('a $profession has at least two spells, each from a sold book', () {
        final own = [
          for (final e in spells.entries)
            if ((e.value as Map<String, dynamic>)['professionID'] == profession)
              e.key,
        ];
        expect(own.length, greaterThanOrEqualTo(2));
        for (final spellId in own) {
          final books = [
            for (final e in items.entries)
              if ((e.value as Map<String, dynamic>)['itemType'] ==
                      'Spellbook' &&
                  (e.value as Map<String, dynamic>)['teachesSpellId'] ==
                      spellId)
                e.key,
          ];
          expect(books, hasLength(1), reason: spellId);
          expect(stocked, contains(books.single), reason: spellId);
        }
      });
    }

    test('the new spells cost 2-4 mana and play an existing effect', () {
      final vfxInUse = {
        for (final e in spells.entries)
          if (!newSpellIds.contains(e.key))
            (e.value as Map<String, dynamic>)['vfx'],
      };
      for (final id in newSpellIds) {
        final spell = spells[id] as Map<String, dynamic>;
        expect((spell['manaCost'] as num).toInt(), inInclusiveRange(2, 4),
            reason: id);
        expect(vfxInUse, contains(spell['vfx']), reason: id);
      }
    });
  });

  group('late-game dice', () {
    test('each new die costs 200-300 and sells in a chapter 5-6 shop', () {
      final lateShops = ['ossuary_relics', 'last_lantern'];
      for (final id in newDiceIds) {
        final die = dice[id] as Map<String, dynamic>;
        expect(die['diceName'], id);
        expect((die['cost'] as num).toInt(), inInclusiveRange(200, 300),
            reason: id);
        expect((die['faces'] as List).length, die['numberOfFaces']);
        final sellers = [
          for (final shopId in lateShops)
            if (((shops[shopId] as Map<String, dynamic>)['diceStock'] as List)
                .contains(id))
              shopId,
        ];
        expect(sellers, isNotEmpty, reason: id);
      }
    });
  });

  group('chapter 4-6 packs', () {
    for (final chapter in [4, 5, 6]) {
      test('a chapter-$chapter pack can be led by a chapter-$chapter enemy',
          () {
        final pool = SubNodeEngine.filterEnemyPool(
          enemies: enemies,
          unlockedEnemyIds: const [],
          chapter: chapter,
        );
        final packs =
            SubNodeEngine.filterPackPool(enemies: enemies, enemyPool: pool);
        final own = [
          for (final id in packs)
            if ((enemies[id] as Map<String, dynamic>)['minChapter'] == chapter)
              id,
        ];
        expect(own, isNotEmpty);
      });
    }

    test('the new enemies are regular pack enemies with their own lines', () {
      for (final id in newEnemyIds) {
        final e = enemies[id] as Map<String, dynamic>;
        expect(e['packEligible'], isTrue, reason: id);
        expect(e['hunterAlignment'], '', reason: id);
        final lines = e['encounterText'] as List;
        expect(lines.length, greaterThanOrEqualTo(2), reason: id);
        expect((e['encounterText_fr'] as List).length, lines.length,
            reason: id);
        for (final loot in e['lootTable'] as List) {
          expect(items, contains((loot as Map<String, dynamic>)['itemID']),
              reason: id);
        }
      }
    });
  });

  group('French', () {
    test('every new record has its French name and texts', () {
      for (final id in [...newArmorIds, ...newSpellbookIds]) {
        expect((item(id)['itemName_fr'] as String?) ?? '', isNotEmpty,
            reason: id);
      }
      for (final id in newSpellIds) {
        final spell = spells[id] as Map<String, dynamic>;
        for (final key in [
          'spellName_fr',
          'description_fr',
          'battleMessage_fr'
        ]) {
          expect((spell[key] as String?) ?? '', isNotEmpty, reason: '$id $key');
        }
      }
      for (final id in newEnemyIds) {
        final e = enemies[id] as Map<String, dynamic>;
        for (final key in ['enemyName_fr', 'description_fr', 'packText_fr']) {
          expect((e[key] as String?) ?? '', isNotEmpty, reason: '$id $key');
        }
      }
    });
  });
}
