// The build "Play to chapter" hands back (autoplay_build.dart): stat points
// to the profession's stat, the best carried gear the player may wear, the
// best skills on the die within the rarity limits, and the same build for
// the same session every time.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/autoplay_build.dart';
import 'package:narrative_data_app/data/autoplay_engine.dart';
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
  test('stat points go to the profession\'s stat, Wisdom when it has none', () {
    final build = _plan(_session());
    expect(build.statToRaise, 'strength');
    expect(build.statPoints, 2);
    expect(_plan(_session(profession: 'cleric')).statToRaise, 'wisdom');
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
      expect(after.strength, 12);
      expect(after.equippedItemIds, containsAll(['giant_maul', 'chain']));
      expect(after.equippedItemIds, isNot(contains('rusty_sword')));
      expect(after.diceSkillAssignments['test_die'],
          {'1': 'channel', '2': 'doom', '3': 'cleave', '4': 'cleave'});
    });
  });
}
