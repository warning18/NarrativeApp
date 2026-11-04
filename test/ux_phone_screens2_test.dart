// UX: phone-size checks, second batch (docs/qa/smoke-coverage.md): the screens
// that need a game in progress or arguments. 360 x 740 and 320 x 568, English
// and French, the app's own fonts, no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> writes a picture of each).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/expedition_screen.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/widgets/bounty_board.dart';

import 'qa_smoke_harness.dart';

Future<void> _load(ProviderContainer c) async {
  for (final s in [
    factionsSchema,
    shopsSchema,
    itemsSchema,
    enemiesSchema,
    zonesSchema,
    portsSchema,
    racesSchema,
    professionsSchema,
    skillsSchema,
    diceSchema,
  ]) {
    await c.read(gameDbProvider(s).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  Map<String, dynamic> table(String n) =>
      jsonDecode(File('assets/gamedata/$n.json').readAsStringSync())
          as Map<String, dynamic>;
  final zones = table('zones');
  final ports = table('ports');
  final companions = table('companions').keys.take(4).toList();

  PlayerSession save() => PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'level': 12,
        'gold': 4825,
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        'recruitedAllies': [
          for (final id in companions) {'companionId': id},
        ],
        'activeAllyIds': companions.take(2).toList(),
      });

  SmokeCase screen(String name, Widget w) =>
      SmokeCase(name, w, session: save(), prepare: _load, bare: true);

  testWidgets('journey, camp with a pack, bounty board, expedition, voyage',
      (tester) async {
    await runSmoke(
      tester,
      [
        screen('journey', const JourneyScreen()),
        screen('camp_pack', const CampScreen()),
        screen('bounty_board',
            const Scaffold(body: SafeArea(child: BountyBoard()))),
        for (final id in zones.keys.take(3))
          screen(
              'expedition_$id',
              ExpeditionScreen(
                  zoneId: id,
                  zone: zones[id] as Map<String, dynamic>,
                  random: Random(3))),
        screen(
            'voyage',
            VoyageScreen(
                fromPortId: 'port_ashen_landing',
                toPortId: 'port_smugglers_wharf',
                toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
                debugRandom: Random(1))),
      ],
      sizes: const [Size(360, 740), Size(320, 568)],
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
