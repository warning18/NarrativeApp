// UX: the whole fight screen with a pack of three foes and two allies, on a
// phone with the app's own fonts: 360 x 740 and 320 x 568, English and
// French, before and after "Enter Battle", no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> writes a picture of each). The foes are the three with
// the longest French names.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'qa_smoke_harness.dart';

Future<void> _load(ProviderContainer container) async {
  for (final schema in [
    factionsSchema,
    subclansSchema,
    housesSchema,
    diceSchema,
    skillsSchema,
    skillTreesSchema,
    shopsSchema,
    racesSchema,
    professionsSchema,
    enemiesSchema,
    itemsSchema,
    zonesSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final enemies =
      jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>;
  final longest = [
    for (final e in enemies.entries)
      if (e.value is Map && (e.value as Map)['enemyName_fr'] != null)
        (e.key, ((e.value as Map)['enemyName_fr'] as String).length),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  final ids = [for (final e in longest.take(3)) e.$1];
  final dice = (jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
          as Map<String, dynamic>)
      .keys
      .toList();

  testWidgets('a pack of three foes reads on a phone, EN and FR',
      (tester) async {
    final session = PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'level': 12,
      'gold': 420,
      'ownedDiceIds': {'starter_die', ...dice.take(8)}.toList(),
      'equippedDiceId': 'starter_die',
      'recruitedAllies': [
        {'companionId': 'kelda'},
        {'companionId': 'vica'},
      ],
      'activeAllyIds': ['kelda', 'vica'],
    });
    Widget fight() => FightScreen(
          enemyId: ids.first,
          enemy: enemies[ids.first] as Map<String, dynamic>,
          additionalEnemyIds: ids.skip(1).toList(),
          additionalEnemies: {
            for (final id in ids.skip(1))
              id: enemies[id] as Map<String, dynamic>,
          },
          random: Random(7),
        );
    await runSmoke(
      tester,
      [
        SmokeCase('pack_pre_fight', fight(),
            session: session, prepare: _load, bare: true),
        SmokeCase(
          'pack_board',
          fight(),
          session: session,
          prepare: _load,
          bare: true,
          act: (tester) async {
            final container = ProviderScope.containerOf(
                tester.element(find.byType(FightScreen)));
            final french =
                container.read(appLanguageProvider) == AppLanguage.fr;
            final enter =
                find.text(french ? 'Entrer au combat' : 'Enter Battle');
            if (enter.evaluate().isNotEmpty) {
              await tester.ensureVisible(enter);
              await tester.pump();
              await tester.tap(enter, warnIfMissed: false);
              for (var i = 0; i < 6; i++) {
                await tester.pump(const Duration(milliseconds: 400));
              }
            }
          },
        ),
      ],
      sizes: const [Size(360, 740), Size(320, 568)],
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
