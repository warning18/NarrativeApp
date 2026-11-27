// The oath is its own Yes/No moment: Swear picks it, Not now declines it,
// and with two clans due the second one comes after the first.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_oath_moment.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

void main() {
  Future<List<int?>> play(
      WidgetTester tester, int clans, List<String> taps) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    final data = towerDataFromAssets();
    final at = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    final run = at.copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.oath,
        offer: [
          for (final c in at.oathsLeft.take(clans))
            TowerReward(TowerRewardKind.clanOath, id: c),
        ]);
    final picks = <int?>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: Scaffold(
            body: TowerOathMoment(run: run, data: data, onPick: picks.add)),
      ),
    ));
    for (final k in taps) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
      final f = find.byWidgetPredicate((w) =>
          w.key is ValueKey &&
          (w.key! as ValueKey).value.toString().startsWith(k));
      expect(f, findsOneWidget, reason: k);
      await tester.tap(f);
      await tester.pump();
    }
    return picks;
  }

  testWidgets('Swear picks the oath', (tester) async {
    final picks = await play(tester, 1, ['tower_oath_swear_']);
    expect(picks, [0]);
  });

  testWidgets('two clans: Not now shows the second, then declines',
      (tester) async {
    final picks =
        await play(tester, 2, ['tower_oath_not_now', 'tower_oath_not_now']);
    expect(picks, [null]);
  });

  testWidgets('two clans: Swear on the second picks index 1', (tester) async {
    final picks =
        await play(tester, 2, ['tower_oath_not_now', 'tower_oath_swear_']);
    expect(picks, [1]);
  });

  testWidgets('Not now declines it', (tester) async {
    final picks = await play(tester, 1, ['tower_oath_not_now']);
    expect(picks, [null]);
  });
}
