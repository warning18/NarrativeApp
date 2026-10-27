// The build "Play to chapter" hands back (autoplay_build.dart): stat points
// to the profession's stat, the best carried gear the player may wear, the
// best skills on the die within the rarity limits, and the same build for
// the same session every time.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/autoplay_build.dart';
import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

const _items = <String, dynamic>{
  'rusty_sword': {
    'isEquippable': true,
    'equipSlot': 'weapon',
    'attackDamage': 2,
  },
  'fine_sword': {
    'isEquippable': true,
    'equipSlot': 'weapon',
    'attackDamage': 5,
  },
  'giant_maul': {
    'isEquippable': true,
    'equipSlot': 'weapon',
    'attackDamage': 9,
    'reqStrength': 12,
  },
  'leather': {'isEquippable': true, 'equipSlot': 'armor', 'armor': 3},
  'chain': {'isEquippable': true, 'equipSlot': 'armor', 'armor': 3},
  'potion': {'itemType': 'Potion'},
};

const _skills = <String, dynamic>{
  'jab': {'rarity': 'common', 'damageMod': 2},
  'cleave': {'rarity': 'rare', 'damageMod': 10},
  'doom': {'rarity': 'legendary', 'damageMod': 30},
  'channel': {'rarity': 'common', 'damageMultiplier': 0},
};

const _dice = <String, dynamic>{
  'test_die': {
    'faces': [
      {'type': 'Attack'},
      {'type': 'Skill', 'linkedSkillID': ''},
      {'type': 'Skill', 'linkedSkillID': ''},
      {'type': 'Skill', 'linkedSkillID': ''},
      {'type': 'Skill', 'linkedSkillID': ''},
      {'type': 'Skill', 'linkedSkillID': 'heavy_attack', 'fixed': true},
    ],
  },
};

const _professions = <String, dynamic>{
  'warrior': {'preferredScalingStat': 'strength'},
  'cleric': {'preferredScalingStat': ''},
};

PlayerSession _session({
  String profession = 'warrior',
  int strength = 10,
  int statPoints = 2,
}) =>
    PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': profession,
      'strength': strength,
      'statPoints': statPoints,
      'inventoryItemIds': [
        'rusty_sword',
        'fine_sword',
        'giant_maul',
        'chain',
        'leather',
        'potion',
      ],
      'equippedItemIds': ['rusty_sword'],
      'equippedDiceId': 'test_die',
      'unlockedSkillIds': ['jab', 'cleave', 'doom', 'channel'],
      'diceSkillAssignments': {
        'test_die': {'1': 'channel', '2': 'jab'},
      },
    });

AutoplayBuild _plan(PlayerSession session) => planAutoplayBuild(session,
    items: _items, skills: _skills, dice: _dice, professions: _professions);

void main() {
  test(
      'stat points go to the profession\'s damage stat, Wisdom when it has '
      'none', () {
    final build = _plan(_session());
    expect(build.statToRaise, 'strength');
    expect(build.statPoints, 2);
    // A cleric's damage stat is Intelligence (stat_rules.dart).
    expect(_plan(_session(profession: 'cleric')).statToRaise, 'intelligence');
    expect(_plan(_session(profession: '')).statToRaise, 'wisdom');
  });

  test('the best gear per slot, counting the points spent first', () {
    // Strength 10 + 2 points meets the maul's 12.
    expect(_plan(_session()).equip, {'weapon': 'giant_maul', 'armor': 'chain'});
    // Without the points the maul stays out of reach.
    expect(_plan(_session(statPoints: 0)).equip,
        {'weapon': 'fine_sword', 'armor': 'chain'});
  });

  test('the best skills on the open faces, within the rarity limits', () {
    final faces = _plan(_session()).faceAssignments!;
    // The mana skill keeps face 1; the legendary goes on one face only,
    // the rare on two, the common fills what is left.
    expect(faces, {'1': 'channel', '2': 'doom', '3': 'cleave', '4': 'cleave'});
  });

  test('the same session always gets the same build', () {
    final a = _plan(_session());
    final b = _plan(_session());
    expect(a.equip, b.equip);
    expect(a.faceAssignments, b.faceAssignments);
  });

  testWidgets('the build is applied to the live session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(() async {
      // Let the notifier's own first load finish before seeding the session.
      ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await ref.read(playerSessionProvider.notifier).loadSession(_session());
      await applyAutoplayBuild(ref,
          items: _items,
          skills: _skills,
          dice: _dice,
          professions: _professions);
      final after = ref.read(playerSessionProvider);
      expect(after.statPoints, 0);
      // The two points are stat picks: Strength when offered, else damage,
      // health or armor; the gear follows what they raised.
      expect(after.strength, inInclusiveRange(10, 12));
      expect(
          after.equippedItemIds,
          containsAll(
              [after.strength >= 12 ? 'giant_maul' : 'fine_sword', 'chain']));
      expect(after.equippedItemIds, isNot(contains('rusty_sword')));
      expect(after.diceSkillAssignments['test_die'],
          {'1': 'channel', '2': 'doom', '3': 'cleave', '4': 'cleave'});
    });
  });

  group('arrival top-up', () {
    const shops = <String, dynamic>{
      'early_forge': {
        'minChapter': 2,
        'stockPool': ['fine_sword'],
      },
      'late_forge': {
        'minChapter': 9,
        'stockPool': ['dawn_blade'],
      },
    };
    const items = <String, dynamic>{
      ..._items,
      'dawn_blade': {
        'isEquippable': true,
        'equipSlot': 'weapon',
        'attackDamage': 40,
      },
      'tower_plate': {
        'isEquippable': true,
        'equipSlot': 'armor',
        'armor': 20,
        'lootChapter': 7,
      },
    };
    PlayerSession fresh() => PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 2,
          'currentXP': 50,
          'gold': 100,
          'strength': 1,
          'inventoryItemIds': ['rusty_sword'],
          'equippedItemIds': ['rusty_sword'],
        });

    test('a weak character reaching chapter 8 is brought to a typical one', () {
      final topUp = planArrivalTopUp(fresh(),
          chapter: 8, items: items, shops: shops, professions: _professions);
      // Level 2 (50 XP in) to level 16: 200 + 300 + ... + 1500 - 50.
      expect(topUp.xp, 11900 - 50);
      expect(topUp.gold, typicalArrival[8]!.gold - 100);
      // The chapter's best per slot, by slot: the chest's plate, the open
      // forge's sword; never the forge that opens later, nor a piece no
      // shop or chest holds (the maul).
      expect(topUp.items, ['tower_plate', 'fine_sword']);
    });

    test(
        'a strong character is never lowered, and a reached tier adds '
        'nothing it already beats', () {
      final strong = PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'level': 18,
        'gold': 9000,
        'inventoryItemIds': ['dawn_blade', 'tower_plate'],
      });
      final topUp = planArrivalTopUp(strong,
          chapter: 8, items: items, shops: shops, professions: _professions);
      expect(topUp.isEmpty, isTrue);
    });
  });

  test(
      'on the real data, a level-1 character jumping to chapter 8 gets a '
      'full kit for its profession', () {
    Map<String, dynamic> table(String name) =>
        jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final items = table('items');
    final professions = table('professions');
    for (final professionId in professions.keys) {
      final topUp = planArrivalTopUp(
          PlayerSession.fromJson(
              {'raceId': 'human', 'professionId': professionId, 'level': 1}),
          chapter: 8,
          items: items,
          shops: table('shops'),
          professions: professions);
      expect(topUp.xp, 12000, reason: professionId); // level 1 to 16
      final slots = {
        for (final id in topUp.items) (items[id] as Map)['equipSlot'],
      };
      expect(slots, containsAll(['Weapon', 'Top', 'Head']),
          reason: '$professionId: ${topUp.items}');
    }
  });

  testWidgets('the top-up keeps the walk\'s offers and queues none of its own',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(() async {
      ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final walked = PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'level': 2,
      }).copyWith(pendingOffers: const [OfferTicket(source: OfferSource.boss)]);
      await ref.read(playerSessionProvider.notifier).loadSession(walked);
      await applyArrivalTopUp(ref,
          chapter: 8,
          items: _items,
          shops: const {},
          professions: _professions);
      final after = ref.read(playerSessionProvider);
      expect(after.level, 16);
      expect(after.pendingOffers.map((t) => t.source), [OfferSource.boss]);
    });
  });
}
