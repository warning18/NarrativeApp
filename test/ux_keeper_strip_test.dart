// The keeper strip of a shop page: the keeper stands at the left when the
// shop's keeper has a figure, else the sign stays. With SMOKE_SHOTS=<folder>
// every shop is drawn at 360 px (English and French).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/shop_detail_screen.dart';
import 'package:narrative_data_app/widgets/keeper_figure.dart';

import 'qa_smoke_harness.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final shops =
      jsonDecode(File('assets/gamedata/shops.json').readAsStringSync())
          as Map<String, dynamic>;
  final all = Platform.environment['SMOKE_SHOTS'] != null;
  // Without pictures: one shop with a figure and one without.
  final ids =
      all ? shops.keys.toList() : ['weaponsmith_forge', 'smugglers_vault'];

  testWidgets('the keeper stands in the strip, or the sign stays',
      (tester) async {
    await runSmoke(
      tester,
      [
        for (final id in ids)
          SmokeCase(
            'keeper_$id',
            ShopDetailScreen(
                shopId: id, shop: shops[id] as Map<String, dynamic>),
            session: PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'level': 12,
              'gold': 900,
            }),
            prepare: (c) async {
              for (final s in [shopsSchema, itemsSchema]) {
                await c.read(gameDbProvider(s).notifier).whenLoaded();
              }
            },
            bare: true,
            after: (tester) async {
              expect(find.byKey(Key('keeper_figure_$id')),
                  keeperHasFigure(id) ? findsOneWidget : findsNothing,
                  reason: id);
            },
          ),
      ],
      sizes: const [Size(360, 900)],
    );
  });

  test('every figure has its picture', () {
    for (final id in shops.keys) {
      if (!keeperHasFigure(id)) continue;
      expect(File('assets/visuals/keepers/$id.png').existsSync(), isTrue,
          reason: id);
    }
  });
}
