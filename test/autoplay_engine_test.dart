// Regression coverage for a bug found via the real in-app "Play to Chapter"
// tool: starting autoplay from a brand-new session (before the player has
// picked a race/profession) reported "stuck" against whatever enemy
// happened to be first on the walked path, no matter how weak that enemy
// was. The real cause had nothing to do with combat balance -- neither
// autoplayToNode nor autoplayToChapter used to handle the
// `opensCharacterCreation` choice at node 0, so the simulated session never
// got a race/profession/equipped die, and `_simulateFight` auto-loses any
// fight once the equipped die has no faces. This pumps the real widget tree
// (same as widget_test.dart) to get a genuine WidgetRef, then drives
// autoplayToChapter from the very start of the game and asserts it actually
// makes progress instead of getting stuck on the very first fight.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'autoplayToChapter creates a character before its first fight, '
      'instead of getting stuck in combat with no equipped die',
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

      final result = await autoplayToChapter(
        capturedRef,
        story: story,
        targetChapter: 2,
        strategy: AutoplayStrategy.random,
        dice: dice,
        skills: skills,
        items: items,
        enemies: enemies,
        races: races,
        professions: professions,
      );

      expect(result.status, isNot(AutoplayStatus.stuckInCombat),
          reason: 'stuck against ${result.stuckEnemyName} after '
              '${result.stepsApplied} steps -- autoplay must create a '
              'character before its first fight');
      expect(result.stepsApplied, greaterThan(0));

      final sessionAfter = capturedRef.read(playerSessionProvider);
      expect(sessionAfter.raceId, isNotEmpty);
      expect(sessionAfter.professionId, isNotEmpty);
      expect(sessionAfter.equippedDiceId ?? '', isNotEmpty);
    });
  });
}
