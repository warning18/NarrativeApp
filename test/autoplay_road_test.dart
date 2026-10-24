// Autoplay on the road (v1.197): the hazards it meets are the ones the
// game would meet. With the world's places known, a walk between two
// districts of one city is no road for autoplay either (v1.201.2), where
// the landmark rule alone would have thrown a hazard at the party.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/road_hazards.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'geography_test.dart' show biomeJson;

/// The Black Reliquary's gate (6010_gate) and its Dead Heart (6003b): two
/// landmarks, one city (Saltmouth is one landmark since v1.536), here on a
/// headland whose roads hold a hazard.
Geography _world() => Geography.parse(geography: {
      'old': {'level': 'continent', 'parent': '', 'name': 'Old'},
      'coast': {'level': 'country', 'parent': 'old', 'name': 'Coast'},
      'head': {
        'level': 'zone',
        'parent': 'coast',
        'biome': 'arid_coast',
        'name': 'Headland'
      },
      'saltmouth': {
        'level': 'location',
        'parent': 'head',
        'kind': 'city',
        'name': 'Saltmouth',
        'landmark': ''
      },
      'gate': {
        'level': 'district',
        'parent': 'saltmouth',
        'name': 'Gate',
        'landmark': 'reliquary'
      },
      'heart': {
        'level': 'district',
        'parent': 'saltmouth',
        'name': 'Dead Heart',
        'landmark': 'heart'
      },
    }, biomes: {
      'arid_coast':
          biomeJson('Arid coast', 'dunes', hazards: ['sandstorm', 'heat']),
    });

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('a walk between districts throws no hazard at autoplay',
      (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      overrides: [geographyProvider.overrideWithValue(_world())],
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox.shrink();
      }),
    ));
    await tester.pump();
    await tester.runAsync(() async {
      // The session's own first load and save must be over before the
      // scope goes away.
      final session = ref.read(playerSessionProvider.notifier);
      while (!session.isLoaded) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final story = await ref.read(storyDataProvider.future);
      final world = ref.read(geographyProvider);
      expect(isRoadStep('6010_gate', '6003b'), isTrue);
      expect(world.travelsBetween(story, '6010_gate', '6003b'), isFalse);
      final share =
          hazardShareFor(world.roadBiome(story, '6010_gate', '6003b'));
      expect(share, greaterThan(0));

      // Stand at the gate with a history long enough that the landmark
      // rule, on its own, would roll a hazard for this very step.
      final play = ref.read(storyPlayProvider.notifier);
      play.jumpTo('6010_gate');
      final condition = ref.read(chapterConditionProvider);
      var found = false;
      for (var at = ref.read(storyPlayProvider).history.length;
          at < 200;
          at++) {
        if (roadEventFor(
              story: story,
              fromNodeId: '6010_gate',
              toNodeId: '6003b',
              historyLength: at,
              chapter: ref.read(reachedChapterProvider),
              oddsFactor: condition?.roadEventOdds ?? 1,
              championShare: condition?.championShare ?? 0.4,
              shrineShare: condition?.shrineShare ?? 0.3,
              hazardShare: share,
            ) ==
            RoadEventKind.hazard) {
          found = true;
          break;
        }
        play.jumpTo('6010_gate');
      }
      expect(found, isTrue);
      expect(ref.read(reachedChapterProvider), greaterThanOrEqualTo(2));

      final before = ref.read(playerSessionProvider);
      final taken = await meetRoadHazard(ref, story,
          fromNodeId: '6010_gate', toNodeId: '6003b');
      expect(taken, isNull);
      final after = ref.read(playerSessionProvider);
      expect(after.currentHealth, before.currentHealth);
      expect(after.provisions, before.provisions);
      expect(after.watch, before.watch);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
