// A clan's card ends its story with "How it is ruled" (factions.json
// `ruling`, Narrative's, shown as it is): for each of the six clans that
// carry one, on a phone (320 x 568, the app's own fonts), in French and in
// English, with the clan's own text, no overflow.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';

import 'qa_smoke_harness.dart';

Future<void> _load(ProviderContainer container) async {
  for (final schema in [
    factionsSchema,
    subclansSchema,
    relationsSchema,
    titlesSchema,
    intriguesSchema,
    geographySchema,
    biomesSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final factions =
      jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
          as Map<String, dynamic>;
  final ruled = [
    for (final e in factions.entries)
      if (e.value is Map && (e.value as Map)['ruling_fr'] != null) e.key,
  ];

  test('six clans carry a ruling, in both languages', () {
    expect(ruled.length, 6);
    for (final id in ruled) {
      final f = factions[id] as Map<String, dynamic>;
      expect((f['ruling'] as String).trim(), isNotEmpty, reason: id);
      expect((f['ruling_fr'] as String).trim(), isNotEmpty, reason: id);
    }
  });

  testWidgets('the card shows how each clan is ruled, EN and FR at 320 px',
      (tester) async {
    final seen = <String>[];
    await runSmoke(
      tester,
      [
        for (final id in ruled)
          SmokeCase(
            'clan_ruling_$id',
            ClanDetailsCard(factionId: id),
            session: PlayerSession.fromJson(
                {'raceId': 'human', 'professionId': 'warrior'}),
            prepare: _load,
            after: (tester) async {
              final container = ProviderScope.containerOf(
                  tester.element(find.byType(ClanDetailsCard)));
              final french =
                  container.read(appLanguageProvider) == AppLanguage.fr;
              final f = factions[id] as Map<String, dynamic>;
              final block =
                  find.byKey(Key('clan_peek_ruling_$id'), skipOffstage: false);
              expect(block, findsOneWidget, reason: id);
              expect(tester.widget<Text>(block).data,
                  (french ? f['ruling_fr'] : f['ruling']) as String,
                  reason: id);
              expect(
                  find.text(
                      french ? 'COMMENT IL EST GOUVERNÉ' : 'HOW IT IS RULED',
                      skipOffstage: false),
                  findsOneWidget,
                  reason: id);
              seen.add('$id/${french ? 'fr' : 'en'}');
            },
          ),
      ],
      sizes: const [Size(320, 568)],
    );
    expect(seen.length, 12);
  });
}
