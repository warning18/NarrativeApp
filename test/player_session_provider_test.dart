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
    potionCount: 0,
    statPoints: statPoints,
    skillPoints: skillPoints,
    maxSkillSlots: 3,
    flags: const [],
    activeQuestIds: activeQuestIds,
    completedQuestIds: completedQuestIds,
    inventoryItemIds: inventoryItemIds,
    equippedItemIds: const [],
    unlockedSkillIds: const [],
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
}
