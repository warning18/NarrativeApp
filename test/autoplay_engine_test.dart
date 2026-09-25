// Regression coverage for a bug found via the real in-app "Play to Chapter"
// tool: starting autoplay from a brand-new session (before the player has
// picked a race/profession) reported "stuck" against whatever enemy
// happened to be first on the walked path, no matter how weak that enemy
// was. The real cause had nothing to do with combat balance -- neither
// autoplayToNode nor autoplayToChapter used to handle the
// `opensCharacterCreation` choice at node 0, so the simulated session never
// got a race/profession/equipped die, and `_simulateFight` auto-loses any
// fight once the equipped die has no faces.
//
// This pumps the real widget tree (same as widget_test.dart) to get a
// genuine WidgetRef, then drives autoplayToNode from the very start of the
// game to node "100" -- the node immediately past node 0's
// opensCharacterCreation choice, reached in a single hop with no combat
// along the way -- and asserts a character actually gets created. An
// earlier version of this test targeted a whole chapter via
// autoplayToChapter instead, which pulled in real (unseeded) combat along
// an arbitrary path; that made the test flaky, since a fresh level-1
// character can legitimately lose a tough, unlucky early fight 8/8 retries
// for reasons that have nothing to do with this bug. Targeting the node
// right after character creation tests the actual fix directly, with no
// combat RNG involved at all.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/data/chapter_spine.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'autoplayToNode creates a character while walking through node 0\'s '
      'opensCharacterCreation choice', (WidgetTester tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    // The asset/data loads and the autoplay run itself do real async I/O
    // (rootBundle asset reads, SharedPreferences persistence) that isn't
    // driven by widget frames -- testWidgets runs inside a fake-async zone
    // where a bare `await` on that kind of future never resolves without
    // something pumping frames or time forward. tester.runAsync() steps
    // outside that fake zone so these awaits actually complete.
    await tester.runAsync(() async {
      final story = await capturedRef.read(storyDataProvider.future);
      final dice = await capturedRef
          .read(gameDbRepositoryProvider(diceSchema))
          .loadRecords();
      final skills = await capturedRef
          .read(gameDbRepositoryProvider(skillsSchema))
          .loadRecords();
      final items = await capturedRef
          .read(gameDbRepositoryProvider(itemsSchema))
          .loadRecords();
      final enemies = await capturedRef
          .read(gameDbRepositoryProvider(enemiesSchema))
          .loadRecords();
      final races = await capturedRef
          .read(gameDbRepositoryProvider(racesSchema))
          .loadRecords();
      final professions = await capturedRef
          .read(gameDbRepositoryProvider(professionsSchema))
          .loadRecords();

      // Sanity check: a fresh session genuinely starts with no character,
      // so this test actually exercises the character-creation-during-
      // autoplay path rather than trivially passing.
      final sessionBefore = capturedRef.read(playerSessionProvider);
      expect(sessionBefore.raceId, isEmpty);
      expect(sessionBefore.equippedDiceId ?? '', isEmpty);

      final result = await autoplayToNode(
        capturedRef,
        story: story,
        targetNodeId: '100',
        dice: dice,
        skills: skills,
        items: items,
        enemies: enemies,
        races: races,
        professions: professions,
      );

      expect(result.status, AutoplayStatus.reachedTarget);
      expect(result.stepsApplied, 1);

      final sessionAfter = capturedRef.read(playerSessionProvider);
      expect(sessionAfter.raceId, isNotEmpty);
      expect(sessionAfter.professionId, isNotEmpty);
      expect(sessionAfter.equippedDiceId ?? '', isNotEmpty);
    });
  });

  testWidgets(
      'autoplayToChapter undoes a lost run and forces the last one through',
      (WidgetTester tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      Future<Map<String, dynamic>> load(DbSchema schema) =>
          capturedRef.read(gameDbRepositoryProvider(schema)).loadRecords();
      final story = await capturedRef.read(storyDataProvider.future);
      final attempts = <int>[];

      // No combat retries: every fight of a normal attempt is lost, so the
      // first attempt stops at its first fight and only the forced one
      // can get through.
      final result = await autoplayToChapter(
        capturedRef,
        story: story,
        targetChapter: 2,
        strategy: AutoplayStrategy.random,
        dice: await load(diceSchema),
        skills: await load(skillsSchema),
        items: await load(itemsSchema),
        enemies: await load(enemiesSchema),
        races: await load(racesSchema),
        professions: await load(professionsSchema),
        maxCombatRetries: 0,
        maxAttempts: 2,
        onAttempt: attempts.add,
      );

      expect(attempts, [1, 2]);
      expect(result.status, AutoplayStatus.reachedTarget);
      expect(result.attempts, 2);
      expect(result.forcedWins, greaterThan(0));
      final node = capturedRef.read(storyPlayProvider).currentNodeId;
      expect(chapterForNode(node), greaterThanOrEqualTo(2));
      expect(capturedRef.read(playerSessionProvider).raceId, isNotEmpty);
    });
  });

  testWidgets('taking a main quest from the camp explores the chapter first',
      (WidgetTester tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      Future<Map<String, dynamic>> load(DbSchema schema) =>
          capturedRef.read(gameDbRepositoryProvider(schema)).loadRecords();
      final story = await capturedRef.read(storyDataProvider.future);
      // The saved session loads once, on first read: let it, so it does not
      // land over what the walk earns.
      capturedRef.read(playerSessionProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      capturedRef.read(storyPlayProvider.notifier).jumpTo('4999_camp');

      final result = await autoplayToNode(
        capturedRef,
        story: story,
        targetNodeId: '5003',
        dice: await load(diceSchema),
        skills: await load(skillsSchema),
        items: await load(itemsSchema),
        enemies: await load(enemiesSchema),
        races: await load(racesSchema),
        professions: await load(professionsSchema),
        zones: await load(zonesSchema),
      );

      expect(result.status, AutoplayStatus.reachedTarget);
      final session = capturedRef.read(playerSessionProvider);
      // The fourth chapter's expeditions are cleared, not its main zone.
      expect(session.completedZoneIds, contains('z_ossuary_galleries'));
      expect(session.completedZoneIds, isNot(contains('z_drowned_stair')));
      expect(session.completedZoneIds, isNot(contains('z_cinder_row')));
      // ... and the places they find are found.
      expect(session.flags, containsAll(['found_5100', 'found_5010']));
      expect(session.flags, isNot(contains('found_3005')));
    });
  });
}
