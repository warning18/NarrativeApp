// The data review's balance fixes: the bosses' own moves stay theirs, a
// zone's boss is met only at its zone, detours open only shops their
// chapter allows, the Void Banner is one reward among others, loot tables
// hold what their enemy's fight can use, and every zone says when it is
// cleared.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _data(String name) {
  for (final dir in ['assets/gamedata', '../assets/gamedata']) {
    final file = File('$dir/$name.json');
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name.json');
}

void main() {
  final enemies = _data('enemies');
  final skills = _data('skills');
  final items = _data('items');
  final shops = _data('shops');
  final zones = _data('zones');
  final quests = _data('quests');
  final dice = _data('dice');

  group('enemy-only skills', () {
    test('every skill only enemies use is flagged, and nothing else', () {
      final usedByParty = <String>{
        for (final die in dice.values)
          for (final face in (die as Map<String, dynamic>)['faces'] as List)
            (face as Map<String, dynamic>)['linkedSkillID']?.toString() ?? '',
        for (final merge in _data('skill_merges').values)
          (merge as Map<String, dynamic>)['resultSkillID'].toString(),
        for (final p in _data('professions').values)
          (p as Map<String, dynamic>)['standardSkillID'].toString(),
        for (final r in _data('races').values)
          (r as Map<String, dynamic>)['standardSkillID'].toString(),
      };
      final flagged = {
        for (final e in skills.entries)
          if (isEnemyOnlySkill(e.value as Map<String, dynamic>)) e.key,
      };
      expect(flagged, hasLength(12));
      expect(flagged, contains('sovereign_unmaking'));
      expect(flagged.intersection(usedByParty), isEmpty);
      for (final id in flagged) {
        expect((skills[id] as Map<String, dynamic>)['isUnlocked'], isFalse,
            reason: id);
      }
    });
  });

  group('zone bosses', () {
    final bosses = {
      for (final z in zones.values)
        (z as Map<String, dynamic>)['bossEnemyId'].toString(),
    };

    test('every zone boss is kept out of random draws', () {
      for (final id in bosses) {
        expect(isRandomDrawEnemy(id), isFalse, reason: id);
      }
    });

    test('no chapter pool or pack pool ever holds one', () {
      for (var chapter = 1; chapter <= 7; chapter++) {
        final pool = SubNodeEngine.filterEnemyPool(
          enemies: enemies,
          unlockedEnemyIds: const [],
          chapter: chapter,
        );
        expect(pool.toSet().intersection(bosses), isEmpty,
            reason: 'chapter $chapter');
        final packs =
            SubNodeEngine.filterPackPool(enemies: enemies, enemyPool: pool);
        expect(packs.toSet().intersection(bosses), isEmpty);
      }
    });
  });

  group('detour shops', () {
    test('a chapter-1 detour never opens a later or a house shop', () {
      final pool = SubNodeEngine.filterShopPool(
        shops: shops,
        unlockedShopIds: const [],
        chapter: 1,
      );
      expect(pool, isNot(contains('hammersmith_forge')));
      expect(pool, isNot(contains('arcane_academy')));
      expect(pool, isNot(contains('sharpweave_den')));
      expect(pool, isNot(contains('ossuary_relics')));
      expect(pool, contains('weaponsmith_forge'));
    });

    test('house shops never turn up on a detour, whatever the chapter', () {
      final pool = SubNodeEngine.filterShopPool(
        shops: shops,
        unlockedShopIds: const [],
        chapter: 9,
      );
      expect(pool, isNot(contains('hammersmith_forge')));
      expect(pool, contains('last_lantern'));
    });
  });

  group('items and rewards', () {
    test('the Void Banner is rewarded once and sold nowhere', () {
      final rewards = [
        for (final q in quests.values)
          if ((q as Map<String, dynamic>)['rewardItemID'] == 'void_banner') q,
      ];
      expect(rewards, hasLength(1));
      for (final shop in shops.values) {
        expect(
            ((shop as Map<String, dynamic>)['initialStock'] as List? ??
                const []),
            isNot(contains('void_banner')));
      }
      final banner = items['void_banner'] as Map<String, dynamic>;
      expect(banner['attackDamage'], lessThan(12));
    });

    test('a starting Top piece is not as tough as a chapter-4 one', () {
      expect(
          (items['armor_leather'] as Map<String, dynamic>)['armor'],
          lessThan(
              (items['hollow_court_mantle'] as Map<String, dynamic>)['armor']));
    });

    test('the chapter-6 Tear-Glass Blade outclasses chapter-4 steel', () {
      expect(
          (items['tear_glass_blade'] as Map<String, dynamic>)['attackDamage'],
          greaterThan((items['sword_t7']
              as Map<String, dynamic>)['attackDamage'] as int));
    });
  });

  group('loot tables', () {
    test('every loot entry is a real item', () {
      for (final e in enemies.entries) {
        for (final entry
            in ((e.value as Map<String, dynamic>)['lootTable'] as List? ??
                const [])) {
          final id = (entry as Map<String, dynamic>)['itemID'].toString();
          expect(items.containsKey(id), isTrue, reason: '${e.key} → $id');
        }
      }
    });

    test('a hunter drops gear the character it hunts can wear', () {
      for (final e in enemies.entries) {
        final enemy = e.value as Map<String, dynamic>;
        final hunts = enemy['hunterAlignment']?.toString() ?? '';
        if (hunts.isEmpty) continue;
        for (final entry in enemy['lootTable'] as List) {
          final item = items[(entry as Map<String, dynamic>)['itemID']]
              as Map<String, dynamic>;
          final alignment = item['alignment']?.toString() ?? '';
          expect(alignment.isEmpty || alignment == hunts, isTrue,
              reason: '${e.key} hunts $hunts but drops $alignment gear');
        }
      }
    });

    test('iron ore drops somewhere in every chapter from 2 to 4', () {
      final chapters = <int>{
        for (final e in enemies.values)
          if (((e as Map<String, dynamic>)['lootTable'] as List? ?? const [])
              .any((l) => (l as Map)['itemID'] == 'material_iron_ore'))
            (e['minChapter'] as num).toInt(),
      };
      expect(chapters, containsAll([2, 3, 4]));
    });
  });

  test('every zone says when it is cleared', () {
    for (final z in zones.values) {
      final flag = (z as Map<String, dynamic>)['rewardFlag'].toString();
      final key = 'zone_flag_$flag';
      expect(trFor(AppLanguage.en, key), isNot(key), reason: key);
      expect(trFor(AppLanguage.fr, key), isNot(key), reason: key);
    }
  });

  test('Full House asks for six companions, not all eight', () {
    expect(fullRosterCompanionCount, 6);
    expect(_data('companions').length, greaterThan(fullRosterCompanionCount));
  });
}
