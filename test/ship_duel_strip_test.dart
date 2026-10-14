// The fight's strip of the two hulls in side view (SeaDuelScene): every
// enemy of the sea, every range, battered or not, in any waters, paints.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';

void main() {
  test('the strip needs a tall screen', () {
    expect(duelStripMinHeight, greaterThan(600));
  });

  const enemies = [
    ('raider_skiff', false),
    ('corsair_brig', false),
    ('inquisition_cutter', false),
    ('void_barge', false),
    ('brinejaw', true),
    ('pale_leviathan', true),
    ('tide_kraken', true),
  ];

  for (final (id, beast) in enemies) {
    testWidgets('the Eel and $id face each other at every range',
        (tester) async {
      for (final range in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SeaDuelScene(
              waters: SeaWaters.open,
              weather: range == 1.0 ? SeaWeather.squall : SeaWeather.calm,
              enemyId: id,
              enemyIsBeast: beast,
              enemyCondition: range == 0.5 ? 0.25 : 1.0,
              condition: range == 0.0 ? 0.4 : 1.0,
              range: range,
            ),
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byKey(const Key('duel_scene')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$id at $range');
      }
    });
  }

  testWidgets('every waters paints the strip', (tester) async {
    for (final waters in SeaWaters.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SeaDuelScene(waters: waters, enemyId: 'corsair_brig'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: waters.name);
    }
  });
}
