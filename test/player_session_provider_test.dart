// Unit coverage for the PlayerSessionNotifier methods that drive quest
// completion, zone completion, combat rewards, companion recruitment, and
// achievements. This exact logic is where this session's real balance bugs
// lived (completeQuest silently not applying rewardXP; the full_party
// achievement requiring one more active ally than intended) -- both were
// only ever caught by a hand-written Python port of this file, run
// manually and outside CI. This gives the real Dart logic the same
// scrutiny automatically, so a future regression fails the build instead
// of waiting for someone to notice in a 50-playthrough simulation.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

/// A fresh, level-1 [PlayerSession] fixture with every required field
/// filled in sensibly. Only the fields a given test cares about need to be
/// overridden.
PlayerSession baseSession({
  int level = 1,
  int currentXP = 0,
  int gold = 0,
  int maxHealth = 100,
  int? currentHealth,
  int statPoints = 0,
  int skillPoints = 0,
  List<String> completedQuestIds = const [],
  List<String> activeQuestIds = const [],
  List<String> inventoryItemIds = const [],
  List<String> ownedDiceIds = const [],
  List<AllyState> recruitedAllies = const [],
  List<String> activeAllyIds = const [],
  List<String> builtHouseIds = const [],
  List<String> unlockedShopIds = const [],
  List<String> unlockedAchievementIds = const [],
  List<String> completedZoneIds = const [],
  List<String> bannerPiecesCollected = const [],
  List<String> talkedToNpcIds = const [],
  List<String> unlockedSkillIds = const [],
  int skillEssence = 0,
  Map<String, int> skillTiers = const {},
  int luck = 0,
  int charisma = 0,
  int strength = 0,
  int dexterity = 0,
  int constitution = 0,
  int intelligence = 0,
  int wisdom = 0,
}) {
  return PlayerSession(
    level: level,
    currentXP: currentXP,
    gold: gold,
    alignmentScore: 0,
    maxHealth: maxHealth,
    currentHealth: currentHealth ?? maxHealth,
    baseDamage: 10,
    baseArmor: 0,
    luck: luck,
    charisma: charisma,
    strength: strength,
    dexterity: dexterity,
    constitution: constitution,
    intelligence: intelligence,
    wisdom: wisdom,
    potionCount: 0,
    statPoints: statPoints,
    skillPoints: skillPoints,
    maxSkillSlots: 3,
    flags: const [],
    activeQuestIds: activeQuestIds,
    completedQuestIds: completedQuestIds,
    inventoryItemIds: inventoryItemIds,
    equippedItemIds: const [],
    unlockedSkillIds: unlockedSkillIds,
    skillEssence: skillEssence,
    skillTiers: skillTiers,
    unlockedShopIds: unlockedShopIds,
    unlockedQuestIds: const [],
    unlockedEnemyIds: const [],
    diceSkillAssignments: const {},
    raceId: 'human',
    professionId: 'warrior',
    ownedDiceIds: ownedDiceIds,
    equippedDiceId: 'starter_die',
    recruitedAllies: recruitedAllies,
    activeAllyIds: activeAllyIds,
    builtHouseIds: builtHouseIds,
    unlockedAchievementIds: unlockedAchievementIds,
    completedZoneIds: completedZoneIds,
    bannerPiecesCollected: bannerPiecesCollected,
    talkedToNpcIds: talkedToNpcIds,
  );
}

/// Builds a notifier and waits out its constructor's own fire-and-forget
/// `_load()` (which resolves against mocked empty prefs, then loads
/// game_config.json) before handing back a fixture-seeded instance via the
/// public `loadSession` -- avoids both racing that initial load and ever
/// touching the notifier's protected `state` setter directly.
Future<PlayerSessionNotifier> notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('completeQuest', () {
    test('applies gold, XP, and item rewards, and marks the quest complete',
        () async {
      final notifier = await notifierWith(
        baseSession(activeQuestIds: ['q_test']),
      );
      final leveledUp = await notifier.completeQuest(
        'q_test',
        rewardGold: 50,
        rewardXP: 30,
        rewardItemId: 'sword_001',
      );
      expect(leveledUp, isFalse);
      expect(notifier.state.gold, 50);
      expect(notifier.state.currentXP, 30);
      expect(notifier.state.inventoryItemIds, contains('sword_001'));
      expect(notifier.state.completedQuestIds, contains('q_test'));
      expect(notifier.state.activeQuestIds, isNot(contains('q_test')));
    });

    test(
        'XP that crosses the level threshold levels the player up and full-heals them',
        () async {
      // Level 1 needs level*100 = 100 XP to reach level 2.
      final notifier = await notifierWith(
        baseSession(
          level: 1,
          currentXP: 90,
          maxHealth: 100,
          currentHealth: 40,
          activeQuestIds: ['q_test'],
        ),
      );
      final leveledUp = await notifier.completeQuest('q_test', rewardXP: 20);
      expect(leveledUp, isTrue);
      expect(notifier.state.level, 2);
      expect(notifier.state.currentXP, 10); // 90 + 20 - 100
      expect(notifier.state.statPoints, 5);
      expect(notifier.state.skillPoints, 1);
      expect(notifier.state.maxHealth, 120); // +20 per level
      expect(notifier.state.currentHealth, 120); // full-healed on level-up
    });

    test('grantsBannerPieceId adds the piece once, even if called again',
        () async {
      final notifier = await notifierWith(
        baseSession(activeQuestIds: ['q_test']),
      );
      await notifier.completeQuest('q_test',
          grantsBannerPieceId: 'heirloom_shroud');
      expect(notifier.state.bannerPiecesCollected, ['heirloom_shroud']);

      await notifier.completeQuest('q_test',
          grantsBannerPieceId: 'heirloom_shroud');
      expect(notifier.state.bannerPiecesCollected, ['heirloom_shroud']);
    });
  });

  group('completeZone', () {
    test('banks gold, item, and flag rewards and marks the zone complete',
        () async {
      final notifier = await notifierWith(baseSession());
      await notifier.completeZone(
        'z_test',
        rewardGold: 40,
        rewardItemId: 'armor_leather',
        rewardFlag: 'a_test_flag',
      );
      expect(notifier.state.gold, 40);
      expect(notifier.state.inventoryItemIds, contains('armor_leather'));
      expect(notifier.state.flags, contains('a_test_flag'));
      expect(notifier.state.completedZoneIds, contains('z_test'));
    });

    test('a zone only pays out once', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.completeZone('z_test', rewardGold: 40);
      await notifier.completeZone('z_test', rewardGold: 40);
      expect(notifier.state.gold, 40,
          reason: 'the second completion should be a no-op');
    });
  });

  group('applyCombatResult', () {
    test('applies gold, XP, and loot from a win', () async {
      final notifier = await notifierWith(baseSession(currentHealth: 100));
      final leveledUp = await notifier.applyCombatResult(
        hpAfter: 70,
        goldGain: 25,
        xpGain: 10,
        itemsGained: ['potion_minor'],
      );
      expect(leveledUp, isFalse);
      expect(notifier.state.gold, 25);
      expect(notifier.state.currentXP, 10);
      expect(notifier.state.currentHealth, 70);
      expect(notifier.state.inventoryItemIds, contains('potion_minor'));
    });

    test('a level-up from combat XP full-heals the player', () async {
      final notifier = await notifierWith(
        baseSession(level: 1, currentXP: 95, maxHealth: 100),
      );
      final leveledUp =
          await notifier.applyCombatResult(hpAfter: 5, xpGain: 10);
      expect(leveledUp, isTrue);
      expect(notifier.state.level, 2);
      expect(notifier.state.currentHealth, notifier.state.maxHealth);
    });

    test('hpAfter is clamped to a minimum of zero', () async {
      final notifier = await notifierWith(baseSession(currentHealth: 100));
      await notifier.applyCombatResult(hpAfter: -50);
      expect(notifier.state.currentHealth, 0);
    });

    test('a win with enemyId logs a kill for that enemy', () async {
      final notifier = await notifierWith(baseSession(currentHealth: 100));
      await notifier.applyCombatResult(hpAfter: 100, enemyId: 'slum_thug');
      expect(notifier.state.enemyKillCounts['slum_thug'], 1);
    });

    test('repeated wins against the same enemy accumulate', () async {
      final notifier = await notifierWith(baseSession(currentHealth: 100));
      await notifier.applyCombatResult(hpAfter: 100, enemyId: 'slum_thug');
      await notifier.applyCombatResult(hpAfter: 100, enemyId: 'slum_thug');
      await notifier.applyCombatResult(hpAfter: 100, enemyId: 'rat_matriarch');
      expect(notifier.state.enemyKillCounts['slum_thug'], 2);
      expect(notifier.state.enemyKillCounts['rat_matriarch'], 1);
    });

    test('a win with no enemyId leaves enemyKillCounts untouched', () async {
      final notifier = await notifierWith(baseSession(currentHealth: 100));
      await notifier.applyCombatResult(hpAfter: 100);
      expect(notifier.state.enemyKillCounts, isEmpty);
    });
  });

  group('recruitAlly', () {
    const race = {'standardSkillID': 'human_resolve'};
    const profession = {'standardSkillID': 'warrior_technique'};

    test('adds a new ally at full health with starter skills unlocked',
        () async {
      final notifier = await notifierWith(baseSession());
      await notifier.recruitAlly('kelda', race: race, profession: profession);

      expect(notifier.state.recruitedAllies, hasLength(1));
      final ally = notifier.state.recruitedAllies.single;
      expect(ally.companionId, 'kelda');
      expect(ally.currentHealth, AllyState.fullHealthSentinel);
      expect(ally.unlockedSkillIds,
          containsAll(['human_resolve', 'warrior_technique']));
    });

    test('recruiting the same companion twice is a no-op', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.recruitAlly('kelda', race: race, profession: profession);
      await notifier.recruitAlly('kelda', race: race, profession: profession);
      expect(notifier.state.recruitedAllies, hasLength(1));
    });

    test(
        'auto-activates the new ally when the party has room -- Camp is '
        'where the roster is managed, not a precondition for a fresh '
        'recruit actually fighting', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.recruitAlly('kelda', race: race, profession: profession);
      expect(notifier.state.activeAllyIds, ['kelda']);
    });

    test('does not auto-activate once the party is already at capacity',
        () async {
      final notifier =
          await notifierWith(baseSession(activeAllyIds: ['sable', 'liora']));
      await notifier.recruitAlly('kelda', race: race, profession: profession);
      expect(notifier.state.activeAllyIds, ['sable', 'liora']);
    });

    test(
        'does not auto-activate a companion whose required house is not '
        'yet built', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.recruitAlly(
        'kelda',
        race: race,
        profession: profession,
        requiredHouseId: 'keldas_hall',
      );
      expect(notifier.state.activeAllyIds, isEmpty);
    });
  });

  group('talkToNpc', () {
    test('records the NPC as talked to', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.talkToNpc('lysa');
      expect(notifier.state.talkedToNpcIds, ['lysa']);
    });

    test('talking to the same NPC twice does not duplicate it', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.talkToNpc('lysa');
      await notifier.talkToNpc('lysa');
      expect(notifier.state.talkedToNpcIds, ['lysa']);
    });

    test('an empty npc id is a no-op', () async {
      final notifier = await notifierWith(baseSession());
      await notifier.talkToNpc('');
      expect(notifier.state.talkedToNpcIds, isEmpty);
    });
  });

  group('spendStatPoint', () {
    test('luck increases luck by 1 and consumes a stat point', () async {
      final notifier = await notifierWith(baseSession(statPoints: 1, luck: 2));
      await notifier.spendStatPoint(stat: 'luck');
      expect(notifier.state.luck, 3);
      expect(notifier.state.statPoints, 0);
    });

    test('charisma increases charisma by 1 and consumes a stat point',
        () async {
      final notifier =
          await notifierWith(baseSession(statPoints: 1, charisma: 4));
      await notifier.spendStatPoint(stat: 'charisma');
      expect(notifier.state.charisma, 5);
      expect(notifier.state.statPoints, 0);
    });

    test('spending with no stat points available is a no-op', () async {
      final notifier = await notifierWith(baseSession(statPoints: 0, luck: 2));
      await notifier.spendStatPoint(stat: 'luck');
      expect(notifier.state.luck, 2);
    });
  });

  group('checkAchievements', () {
    test('first_companion unlocks once an ally is recruited', () async {
      final notifier = await notifierWith(
        baseSession(recruitedAllies: const [
          AllyState(
              companionId: 'kelda',
              currentHealth: AllyState.fullHealthSentinel),
        ]),
      );
      final newly = await notifier.checkAchievements();
      expect(newly, contains('first_companion'));
    });

    // Regression test for this session's balance fix: full_party used to
    // require activeAllyIds.length >= 3 (a 4-person party) despite its own
    // description promising a *3-member* party (player + 2 active allies).
    test('full_party unlocks with exactly 2 active allies, not 3', () async {
      final withTwo = await notifierWith(
        baseSession(activeAllyIds: const ['kelda', 'sable']),
      );
      expect(await withTwo.checkAchievements(), contains('full_party'));

      final withOne = await notifierWith(
        baseSession(activeAllyIds: const ['kelda']),
      );
      expect(await withOne.checkAchievements(), isNot(contains('full_party')));
    });

    test(
        'an already-unlocked achievement is never reported as newly unlocked again',
        () async {
      final notifier = await notifierWith(
        baseSession(
          completedQuestIds: const ['q_anything'],
          unlockedAchievementIds: const ['first_quest'],
        ),
      );
      final newly = await notifier.checkAchievements();
      expect(newly, isNot(contains('first_quest')));
    });

    test('full_roster only unlocks once totalCompanionCount is reached',
        () async {
      final notifier = await notifierWith(
        baseSession(recruitedAllies: const [
          AllyState(
              companionId: 'kelda',
              currentHealth: AllyState.fullHealthSentinel),
        ]),
      );
      expect(await notifier.checkAchievements(totalCompanionCount: 3),
          isNot(contains('full_roster')));

      final fullNotifier = await notifierWith(
        baseSession(recruitedAllies: const [
          AllyState(
              companionId: 'kelda',
              currentHealth: AllyState.fullHealthSentinel),
          AllyState(
              companionId: 'sable',
              currentHealth: AllyState.fullHealthSentinel),
          AllyState(
              companionId: 'maren',
              currentHealth: AllyState.fullHealthSentinel),
        ]),
      );
      expect(await fullNotifier.checkAchievements(totalCompanionCount: 3),
          contains('full_roster'));
    });
  });

  group('PlayerSession.fromJson objective-tracking migration', () {
    test('a save with no enemyKillCounts key grandfathers its active quests',
        () {
      final session = PlayerSession.fromJson({
        'activeQuestIds': ['q_first_blood', 'q_retrieve_banner'],
        // No 'enemyKillCounts' key at all -- the pre-this-feature shape.
      });
      expect(session.grandfatheredQuestIds,
          containsAll(['q_first_blood', 'q_retrieve_banner']));
      expect(session.enemyKillCounts, isEmpty);
    });

    test(
        'a save that already has enemyKillCounts (even empty) is never '
        're-grandfathered', () {
      final session = PlayerSession.fromJson({
        'activeQuestIds': ['q_new_quest'],
        'enemyKillCounts': <String, dynamic>{},
        'grandfatheredQuestIds': <String>[],
      });
      expect(session.grandfatheredQuestIds, isEmpty);
    });

    test('enemyKillCounts round-trips through toJson/fromJson', () {
      final original =
          baseSession().copyWith(enemyKillCounts: {'slum_thug': 3});
      final restored = PlayerSession.fromJson(original.toJson());
      expect(restored.enemyKillCounts['slum_thug'], 3);
    });
  });

  group('upgradeSkillTier', () {
    test('spends essence and raises the tier by one', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball'],
        skillEssence: 10,
      ));
      await notifier.upgradeSkillTier('fireball');
      expect(notifier.state.skillTiers['fireball'], 1);
      expect(notifier.state.skillEssence, 7); // cost of tier 0->1 is 3
    });

    test('cost rises each subsequent tier', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball'],
        skillEssence: 100,
      ));
      await notifier.upgradeSkillTier('fireball'); // 0->1, costs 3
      await notifier.upgradeSkillTier('fireball'); // 1->2, costs 6
      expect(notifier.state.skillTiers['fireball'], 2);
      expect(notifier.state.skillEssence, 91);
    });

    test('is a no-op if the skill is not unlocked', () async {
      final notifier = await notifierWith(baseSession(skillEssence: 100));
      await notifier.upgradeSkillTier('fireball');
      expect(notifier.state.skillTiers, isEmpty);
      expect(notifier.state.skillEssence, 100);
    });

    test('is a no-op if essence is short', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball'],
        skillEssence: 2,
      ));
      await notifier.upgradeSkillTier('fireball');
      expect(notifier.state.skillTiers['fireball'], isNull);
      expect(notifier.state.skillEssence, 2);
    });

    test('is a no-op once the skill is already at max tier', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball'],
        skillTiers: {'fireball': maxSkillTier},
        skillEssence: 1000,
      ));
      await notifier.upgradeSkillTier('fireball');
      expect(notifier.state.skillTiers['fireball'], maxSkillTier);
    });
  });

  group('mergeSkills', () {
    test('consumes both inputs and unlocks the result', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball', 'shadow_step'],
        skillTiers: {'fireball': 2},
      ));
      await notifier.mergeSkills(
        inputSkillIds: ['fireball', 'shadow_step'],
        resultSkillId: 'blazing_shadow',
      );
      expect(notifier.state.unlockedSkillIds, contains('blazing_shadow'));
      expect(notifier.state.unlockedSkillIds, isNot(contains('fireball')));
      expect(notifier.state.unlockedSkillIds, isNot(contains('shadow_step')));
      // Tier progress on a consumed skill is dropped, not carried over.
      expect(notifier.state.skillTiers.containsKey('fireball'), isFalse);
    });

    test('is a no-op if either input is not unlocked', () async {
      final notifier = await notifierWith(
        baseSession(unlockedSkillIds: ['fireball']),
      );
      await notifier.mergeSkills(
        inputSkillIds: ['fireball', 'shadow_step'],
        resultSkillId: 'blazing_shadow',
      );
      expect(
          notifier.state.unlockedSkillIds, isNot(contains('blazing_shadow')));
      expect(notifier.state.unlockedSkillIds, contains('fireball'));
    });

    test('is a no-op if the result is already unlocked', () async {
      final notifier = await notifierWith(baseSession(
        unlockedSkillIds: ['fireball', 'shadow_step', 'blazing_shadow'],
      ));
      await notifier.mergeSkills(
        inputSkillIds: ['fireball', 'shadow_step'],
        resultSkillId: 'blazing_shadow',
      );
      // Nothing consumed -- inputs stay put.
      expect(notifier.state.unlockedSkillIds, contains('fireball'));
      expect(notifier.state.unlockedSkillIds, contains('shadow_step'));
    });
  });

  group('applyPermadeath', () {
    test(
        'resets the skill build to class basics but keeps level/gold/dice intact',
        () async {
      final notifier = await notifierWith(baseSession(
        level: 5,
        gold: 200,
        unlockedSkillIds: ['warrior_shield_bash', 'fireball', 'power_strike'],
        skillTiers: {'fireball': 2},
        skillEssence: 40,
        skillPoints: 3,
        ownedDiceIds: ['starter_die', 'kelda_die'],
        inventoryItemIds: ['sword_iron'],
      ));
      final result = await notifier.applyPermadeath(
        race: const {'standardSkillID': 'human_resolve'},
        profession: const {
          'standardSkillID': 'warrior_shield_bash',
          'startingSkillPoints': 1,
        },
      );

      expect(result.skillsLost, 3);
      expect(notifier.state.unlockedSkillIds,
          unorderedEquals(['human_resolve', 'warrior_shield_bash']));
      expect(notifier.state.skillTiers, isEmpty);
      expect(notifier.state.skillEssence, 0);
      expect(notifier.state.skillPoints, 1);
      // Untouched by a skill-build reset.
      expect(notifier.state.level, 5);
      expect(notifier.state.gold, 200);
      expect(notifier.state.ownedDiceIds, contains('kelda_die'));
      // Inventory is still cleared, per the existing permadeath behavior.
      expect(notifier.state.inventoryItemIds, isEmpty);
      expect(result.lostItemIds, contains('sword_iron'));
    });
  });

  group('consumeAntidote', () {
    test('decrements antidoteCount by one', () async {
      final notifier =
          await notifierWith(baseSession().copyWith(antidoteCount: 2));
      await notifier.consumeAntidote();
      expect(notifier.state.antidoteCount, 1);
    });

    test('is a no-op once antidoteCount reaches zero', () async {
      final notifier =
          await notifierWith(baseSession().copyWith(antidoteCount: 0));
      await notifier.consumeAntidote();
      expect(notifier.state.antidoteCount, 0);
    });
  });

  group('partyCapacityFor', () {
    test('is the base capacity with no houses built', () {
      expect(partyCapacityFor(const [], const {}), basePartyCapacity);
    });

    test('adds every built house\'s own partyCapacityBonus', () {
      const houses = {
        'keldas_hall': {'houseID': 'keldas_hall', 'partyCapacityBonus': 0},
        'barracks_annex': {
          'houseID': 'barracks_annex',
          'partyCapacityBonus': 1
        },
      };
      expect(
        partyCapacityFor(['keldas_hall', 'barracks_annex'], houses),
        basePartyCapacity + 1,
      );
    });

    test('ignores a house\'s bonus if it hasn\'t been built', () {
      const houses = {
        'barracks_annex': {
          'houseID': 'barracks_annex',
          'partyCapacityBonus': 1
        },
      };
      expect(partyCapacityFor(const [], houses), basePartyCapacity);
    });
  });

  group('buildHouse', () {
    test('spends gold, marks the house built, and unlocks its shop', () async {
      final notifier = await notifierWith(baseSession(gold: 500));
      await notifier.buildHouse('hammersmith', 350,
          unlocksShopId: 'hammersmith_forge');
      expect(notifier.state.gold, 150);
      expect(notifier.state.builtHouseIds, contains('hammersmith'));
      expect(notifier.state.unlockedShopIds, contains('hammersmith_forge'));
    });

    test('a house with no unlocksShopId never touches unlockedShopIds',
        () async {
      final notifier = await notifierWith(baseSession(gold: 500));
      await notifier.buildHouse('barracks_annex', 200);
      expect(notifier.state.builtHouseIds, contains('barracks_annex'));
      expect(notifier.state.unlockedShopIds, isEmpty);
    });

    test('is a no-op if unaffordable', () async {
      final notifier = await notifierWith(baseSession(gold: 100));
      await notifier.buildHouse('hammersmith', 350,
          unlocksShopId: 'hammersmith_forge');
      expect(notifier.state.gold, 100);
      expect(notifier.state.builtHouseIds, isEmpty);
      expect(notifier.state.unlockedShopIds, isEmpty);
    });

    test('is a no-op if the house is already built', () async {
      final notifier = await notifierWith(
          baseSession(gold: 500, builtHouseIds: ['hammersmith']));
      await notifier.buildHouse('hammersmith', 350,
          unlocksShopId: 'hammersmith_forge');
      expect(notifier.state.gold, 500);
      expect(notifier.state.unlockedShopIds, isEmpty);
    });
  });
}
