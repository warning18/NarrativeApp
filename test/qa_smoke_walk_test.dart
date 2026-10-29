// QA: wave 13's widgets (v1.480) on a phone, with the app's own fonts: the
// land walk with its walking party and a companion's bubble, the bubble
// itself with long words, the clan flags, and the level-up screen with its
// ability radar. 360 x 740 and 320 x 568, English and French, no overflow
// (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the pictures).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/widgets/level_up_stats.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/walk_bubble.dart';

import 'qa_smoke_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

AllyState _ally(String id) => AllyState(
    companionId: id, currentHealth: AllyState.fullHealthSentinel, approval: 10);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final route = landRouteFor(_json('land_routes'), 'crash_to_sleeper')!;
  final events = landEventsFrom(_json('land_events'));
  final paths = trainingPathsFrom(_json('training_paths'));

  final party = smokeSession().copyWith(
    recruitedAllies: [_ally('maren'), _ally('malrik')],
    activeAllyIds: const ['maren', 'malrik'],
  );

  testWidgets('wave 13 reads on a phone, EN and FR', (tester) async {
    await runSmoke(
      tester,
      [
        SmokeCase(
          'land_walk_party',
          LandCrossingScreen(route: route, events: events, random: Random(2)),
          session: party,
          bare: true,
        ),
        SmokeCase(
          'land_walk_alone',
          LandCrossingScreen(route: route, events: events, random: Random(5)),
          bare: true,
        ),
        SmokeCase(
          'walk_bubbles',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const WalkBubble(speaker: 'Maren', line: 'Quiet. Hear that?'),
            const SizedBox(height: 12),
            WalkBubble(
              speaker: 'Malrik the Long-Named of the Ember Sisters',
              line: 'The last time we crossed these dunes, half the water was '
                  'gone by the second day and nobody said a word about it '
                  'until the sand had taken the other half as well.',
              width: 296,
              tailX: 200,
            ),
          ]),
        ),
        SmokeCase(
          'clan_flags',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final id in clanBannerFactionIds)
              ClanFlag(factionId: id, height: 56),
            for (final id in clanBannerFactionIds)
              ClanFlag(factionId: id, height: 24, found: false),
          ]),
        ),
        SmokeCase(
          'level_up_radar',
          const LevelUpScreen(),
          session: PlayerSession.fromJson(
              {'statPoints': 3, 'professionId': 'ranger', 'raceId': 'human'}),
          bare: true,
        ),
        SmokeCase(
          'level_up_stats',
          const LevelUpStats(),
          session: PlayerSession.fromJson(
              {'statPoints': 2, 'professionId': 'mage', 'raceId': 'elf'}),
        ),
      ],
      overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
