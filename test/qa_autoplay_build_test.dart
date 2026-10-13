// QA: the build "Play to chapter" hands back (autoplay_build.dart), on the
// game's real data. For every profession and every die, with all of the
// game's gear carried and every skill known, the live session it leaves
// must hold together: no item twice or two in a slot, each worn piece one
// the player may wear, every point spent, every face valid and no skill past
// its rarity's limit; a session with nothing carried and one with no die
// must not throw; and the session must survive a save and a load.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/data/autoplay_build.dart';
import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/data/chapter_spine.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/models/ally_state.dart'
    show meetsItemAlignment, meetsItemStatRequirement;
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final items = _data('items');
  final skills = _data('skills');
  final dice = _data('dice');
  final professions = _data('professions');

  final gear = [
    for (final e in items.entries)
      if ((e.value as Map)['isEquippable'] == true) e.key,
  ];

  Map<String, dynamic> save({
    required String profession,
    required String? die,
    List<String>? inventory,
    List<String>? wearing,
  }) => {
    'raceId': 'human',
    'professionId': profession,
    'level': 12,
    'statPoints': 7,
    'strength': 8,
    'dexterity': 8,
    'constitution': 8,
    'intelligence': 8,
    'wisdom': 8,
    'inventoryItemIds': inventory ?? [...gear, ...gear.take(10)],
    'equippedItemIds': wearing ?? const <String>[],
    'equippedDiceId': die,
    'ownedDiceIds': [if (die != null) die],
    'unlockedSkillIds': skills.keys.toList(),
    'enemyKillCounts': <String, int>{},
  };

  /// Everything the finished session must satisfy.
  void check(PlayerSession after, String label) {
    expect(after.statPoints, 0, reason: '$label: points left');
    final worn = after.equippedItemIds;
    expect(worn.toSet().length, worn.length, reason: '$label: a piece twice');
    final slots = <String>{};
    for (final id in worn) {
      final slot = (items[id] as Map)['equipSlot'].toString();
      expect(slots.add(slot), isTrue, reason: '$label: two pieces in $slot');
      expect(after.inventoryItemIds, contains(id), reason: '$label: $id');
      final item = items[id] as Map<String, dynamic>;
      expect(
        meetsItemStatRequirement(
          item,
          strength: after.strength,
          dexterity: after.dexterity,
          constitution: after.constitution,
          intelligence: after.intelligence,
        ),
        isTrue,
        reason: '$label: $id worn below its stat requirement',
      );
      expect(
        meetsItemAlignment(item, after.alignmentLabel),
        isTrue,
        reason: '$label: $id worn against its alignment',
      );
    }
    final dieId = after.equippedDiceId;
    if (dieId == null) return;
    final faces = ((dice[dieId] as Map)['faces'] as List)
        .cast<Map<String, dynamic>>();
    final assigned = after.diceSkillAssignments[dieId] ?? const {};
    for (final entry in assigned.entries) {
      final i = int.parse(entry.key);
      expect(
        i,
        inInclusiveRange(0, faces.length - 1),
        reason: '$label: face ${entry.key} does not exist',
      );
      expect(
        isAssignableFace(faces[i]),
        isTrue,
        reason: '$label: face $i is not open',
      );
      expect(
        after.unlockedSkillIds,
        contains(entry.value),
        reason: '$label: ${entry.value} not known',
      );
      final others = {...assigned}..remove(entry.key);
      expect(
        canSetSkillOnFace(entry.value, i, faces, others, skills),
        isTrue,
        reason: '$label: ${entry.value} on face $i is not allowed',
      );
    }
    final perSkill = <String, int>{};
    for (final id in assigned.values) {
      perSkill[id] = (perSkill[id] ?? 0) + 1;
    }
    perSkill.forEach((id, n) {
      expect(
        n,
        lessThanOrEqualTo(maxFacesForSkill(skills[id])),
        reason: '$label: $id on $n faces',
      );
    });
  }

  testWidgets('every profession, every die, all the gear: a sound build', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      var runs = 0;
      var withGear = 0;
      var withSkills = 0;
      for (final profession in professions.keys) {
        for (final die in dice.keys) {
          await notifier.loadSession(
            PlayerSession.fromJson(save(profession: profession, die: die)),
          );
          await applyAutoplayBuild(
            ref,
            items: items,
            skills: skills,
            dice: dice,
            professions: professions,
          );
          final after = ref.read(playerSessionProvider);
          check(after, '$profession / $die');
          if (after.equippedItemIds.isNotEmpty) withGear++;
          if ((after.diceSkillAssignments[die] ?? const {}).isNotEmpty) {
            withSkills++;
          }
          // A save made after the jump loads and comes back the same.
          final again = PlayerSession.fromJson(
            jsonDecode(jsonEncode(after.toJson())) as Map<String, dynamic>,
          );
          expect(again.equippedItemIds, after.equippedItemIds);
          expect(again.diceSkillAssignments, after.diceSkillAssignments);
          expect(again.statPoints, after.statPoints);
          runs++;
        }
      }
      expect(runs, professions.length * dice.length);
      // Not vacuous: the build really wore gear and set skills.
      expect(withGear, runs);
      expect(withSkills, greaterThan(runs ~/ 2));
    });
  });

  testWidgets('a build applied twice changes nothing the second time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      for (final profession in professions.keys) {
        await notifier.loadSession(
          PlayerSession.fromJson(
            save(profession: profession, die: 'starter_die'),
          ),
        );
        Future<void> apply() => applyAutoplayBuild(
          ref,
          items: items,
          skills: skills,
          dice: dice,
          professions: professions,
        );
        await apply();
        final first = ref.read(playerSessionProvider);
        await apply();
        final second = ref.read(playerSessionProvider);
        expect(
          second.equippedItemIds,
          first.equippedItemIds,
          reason: profession,
        );
        expect(
          second.diceSkillAssignments,
          first.diceSkillAssignments,
          reason: profession,
        );
        expect(second.strength, first.strength, reason: profession);
      }
    });
  });

  testWidgets('nothing carried, no die, no profession: no throw', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      for (final profession in professions.keys) {
        // Empty inventory, no die.
        await notifier.loadSession(
          PlayerSession.fromJson(
            save(profession: profession, die: null, inventory: const []),
          ),
        );
        await applyAutoplayBuild(
          ref,
          items: items,
          skills: skills,
          dice: dice,
          professions: professions,
        );
        check(ref.read(playerSessionProvider), '$profession / empty');
        // Empty inventory but wearing something the bag no longer holds.
        await notifier.loadSession(
          PlayerSession.fromJson(
            save(
              profession: profession,
              die: 'starter_die',
              inventory: const [],
              wearing: [gear.first],
            ),
          ),
        );
        await applyAutoplayBuild(
          ref,
          items: items,
          skills: skills,
          dice: dice,
          professions: professions,
        );
      }
      // A die the data does not have.
      await notifier.loadSession(
        PlayerSession.fromJson(save(profession: 'warrior', die: 'no_such_die')),
      );
      await applyAutoplayBuild(
        ref,
        items: items,
        skills: skills,
        dice: dice,
        professions: professions,
      );
      // A session with no character yet.
      await notifier.loadSession(
        PlayerSession.fromJson({'enemyKillCounts': <String, int>{}}),
      );
      await applyAutoplayBuild(
        ref,
        items: items,
        skills: skills,
        dice: dice,
        professions: professions,
      );
      // The planner alone, with a profession it does not know.
      final plan = planAutoplayBuild(
        PlayerSession.fromJson(save(profession: 'nobody', die: null)),
        items: items,
        skills: skills,
        dice: dice,
        professions: professions,
      );
      expect(plan.statToRaise, 'wisdom');
    });
  });

  // The real tool, end to end: a seeded walk to a chapter from a brand-new
  // game, then the session it hands back.
  for (final chapter in const [3, 5, 8]) {
    for (final seed in const [1, 2, 3]) {
      testWidgets('Play to chapter $chapter, seed $seed: a sound hand-back', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        late WidgetRef ref;
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, r, _) {
                ref = r;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          Future<Map<String, dynamic>> load(DbSchema schema) =>
              ref.read(gameDbRepositoryProvider(schema)).loadRecords();
          final story = await ref.read(storyDataProvider.future);
          final result = await autoplayToChapter(
            ref,
            story: story,
            targetChapter: chapter,
            strategy: AutoplayStrategy.random,
            dice: await load(diceSchema),
            skills: await load(skillsSchema),
            items: await load(itemsSchema),
            enemies: await load(enemiesSchema),
            races: await load(racesSchema),
            professions: await load(professionsSchema),
            seed: seed,
          );
          expect(result.status, AutoplayStatus.reachedTarget);
          final after = ref.read(playerSessionProvider);
          expect(
            chapterForNode(ref.read(storyPlayProvider).currentNodeId),
            greaterThanOrEqualTo(chapter),
          );
          check(after, 'chapter $chapter, seed $seed, ${after.professionId}');
          expect(after.equippedDiceId, isNotEmpty);
          // The jump hands back a character, not an empty one.
          expect(after.professionId, isNotEmpty);
          debugPrint(
            'chapter $chapter seed $seed: ${after.professionId}, '
            'level ${after.level}, worn ${after.equippedItemIds.length}, '
            'faces ${(after.diceSkillAssignments[after.equippedDiceId] ?? {}).length}, '
            'attempts ${result.attempts}',
          );
        });
      });
    }
  }

  // ---- The arrival top-up (#205): level, gold and gear to a typical run's.
  final shops = _data('shops');

  PlayerSession weak(String profession, {int level = 1, int gold = 0}) =>
      PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': profession,
        'level': level,
        'gold': gold,
        'statPoints': 0,
        'strength': 6,
        'dexterity': 6,
        'constitution': 6,
        'intelligence': 6,
        'wisdom': 6,
        'enemyKillCounts': <String, int>{},
      });

  test('the top-up only goes up, is deterministic, and fits the chapter', () {
    for (final profession in professions.keys) {
      for (final chapter in [2, 3, 4, 5, 6, 7, 8]) {
        final target = typicalArrival[chapter]!;
        ArrivalTopUp plan(PlayerSession s) => planArrivalTopUp(
          s,
          chapter: chapter,
          items: items,
          shops: shops,
          professions: professions,
        );
        final low = plan(weak(profession));
        expect(low.gold, target.gold, reason: '$profession ch$chapter gold');
        expect(low.xp, greaterThanOrEqualTo(0));
        for (final id in low.items) {
          expect((items[id] as Map)['isEquippable'], true, reason: id);
        }
        final slots = [
          for (final id in low.items) (items[id] as Map)['equipSlot'],
        ];
        expect(
          slots.toSet().length,
          slots.length,
          reason: '$profession ch$chapter: two pieces for one slot',
        );
        final again = plan(weak(profession));
        expect(
          [again.xp, again.gold, again.items.join(',')],
          [low.xp, low.gold, low.items.join(',')],
        );
        // A stronger character is never lowered: nothing to add.
        final strong = plan(weak(profession, level: 30, gold: 99999));
        expect(strong.xp, 0, reason: '$profession ch$chapter: xp');
        expect(strong.gold, 0, reason: '$profession ch$chapter: gold');
        // A character already at the level keeps its XP.
        final atLevel = plan(
          weak(profession, level: target.level, gold: target.gold),
        );
        expect(atLevel.xp, 0);
        expect(atLevel.gold, 0);
      }
    }
  });

  testWidgets('the top-up lands on exactly the typical level and gold', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      for (final profession in professions.keys) {
        for (final chapter in [3, 5, 8]) {
          final target = typicalArrival[chapter]!;
          await notifier.loadSession(weak(profession));
          await applyArrivalTopUp(
            ref,
            chapter: chapter,
            items: items,
            shops: shops,
            professions: professions,
          );
          final after = ref.read(playerSessionProvider);
          expect(
            after.level,
            target.level,
            reason: '$profession ch$chapter: level',
          );
          expect(
            after.gold,
            target.gold,
            reason: '$profession ch$chapter: gold',
          );
          expect(after.currentXP, 0, reason: '$profession ch$chapter: xp');
          // Each level brought its 5 points.
          expect(after.statPoints, 5 * (target.level - 1));
        }
        // A stronger character is untouched.
        await notifier.loadSession(weak(profession, level: 20, gold: 50000));
        await applyArrivalTopUp(
          ref,
          chapter: 8,
          items: items,
          shops: shops,
          professions: professions,
        );
        final strong = ref.read(playerSessionProvider);
        expect([strong.level, strong.gold], [20, 50000]);
      }
    });
  });

  // The real tool: chapters 3, 5 and 8, seeded, twice.
  for (final chapter in const [3, 8]) {
    testWidgets('Play to chapter $chapter arrives typical and the same twice', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        Future<Map<String, dynamic>> load(DbSchema schema) =>
            ref.read(gameDbRepositoryProvider(schema)).loadRecords();
        final story = await ref.read(storyDataProvider.future);
        final target = typicalArrival[chapter]!;
        final seen = <String>[];
        for (final seed in const [1, 2, 3, 1]) {
          ref.read(playerSessionProvider.notifier);
          await ref
              .read(playerSessionProvider.notifier)
              .loadSession(
                PlayerSession.fromJson({'enemyKillCounts': <String, int>{}}),
              );
          ref.read(storyPlayProvider.notifier).loadState('0', const []);
          final result = await autoplayToChapter(
            ref,
            story: story,
            targetChapter: chapter,
            strategy: AutoplayStrategy.random,
            dice: await load(diceSchema),
            skills: await load(skillsSchema),
            items: await load(itemsSchema),
            enemies: await load(enemiesSchema),
            races: await load(racesSchema),
            professions: await load(professionsSchema),
            seed: seed,
          );
          expect(result.status, AutoplayStatus.reachedTarget);
          final after = ref.read(playerSessionProvider);
          check(after, 'chapter $chapter, seed $seed');
          expect(
            after.level,
            greaterThanOrEqualTo(target.level),
            reason: 'chapter $chapter seed $seed: level',
          );
          expect(after.gold, greaterThanOrEqualTo(target.gold));
          final summary =
              '${after.professionId}|${after.level}|${after.gold}|'
              '${after.equippedItemIds.join(",")}|'
              '${after.diceSkillAssignments[after.equippedDiceId]}|'
              '${after.pendingOffers.length}';
          seen.add(summary);
          debugPrint(
            'chapter $chapter seed $seed: ${after.professionId} '
            'level ${after.level} gold ${after.gold} '
            'worn ${after.equippedItemIds.length} '
            'inventory ${after.inventoryItemIds.length} '
            'offers waiting ${after.pendingOffers.length}',
          );
        }
        // The same seed, the same character.
        expect(seen[3], seen[0]);
      });
    });
  }
}
