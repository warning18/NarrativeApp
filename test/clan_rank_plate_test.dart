// The clan power sign, option A (v1.646): a rank plate with an arrow for the
// move since the last chapter, and the Clans page's line, in English and
// French.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/widgets/clan_rank_plate.dart';

ClanPowerRank _r(String id, int rank, int before, int power, int was) =>
    ClanPowerRank(
        clanId: id,
        rank: rank,
        previousRank: before,
        power: power,
        previousPower: was);

final _ranking = [
  _r('dominion', 1, 2, 60, 55),
  _r('vigil', 2, 1, 50, 58),
  _r('mire', 3, 3, 25, 25),
];

Future<void> _pump(WidgetTester tester, Widget child,
    {AppLanguage lang = AppLanguage.en}) async {
  SharedPreferences.setMockInitialValues({'app_language': lang.name});
  await tester.pumpWidget(ProviderScope(
    overrides: [clanPowerRankingProvider.overrideWithValue(_ranking)],
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the plate shows the rank and an arrow up, down or steady',
      (tester) async {
    await _pump(
        tester,
        const Column(children: [
          ClanRankPlate(clanId: 'dominion'),
          ClanRankPlate(clanId: 'vigil'),
          ClanRankPlate(clanId: 'mire'),
          ClanRankPlate(clanId: 'choir'),
        ]));
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    String arrow(String id) =>
        (tester.widget(find.byKey(Key('clan_rank_arrow_$id'))) as Text).data!;
    expect(arrow('dominion'), '▲');
    expect(arrow('vigil'), '▼');
    expect(arrow('mire'), '–');
    // A clan with no power wears no plate.
    expect(find.byKey(const Key('clan_rank_plate_choir')), findsNothing);
  });

  testWidgets('the Clans page line says the rank and the power change',
      (tester) async {
    await _pump(tester, const ClanRankLine(clanId: 'vigil'));
    expect(find.text('Rank 2 of 3 in power · −8 power since the last chapter'),
        findsOneWidget);
  });

  testWidgets('the line reads in French', (tester) async {
    await _pump(tester, const ClanRankLine(clanId: 'dominion'),
        lang: AppLanguage.fr);
    expect(
        find.text('Rang 1 sur 3 en puissance · +5 de puissance depuis le '
            'dernier chapitre'),
        findsOneWidget);
  });

  testWidgets('a steady clan has no change in its line', (tester) async {
    await _pump(tester, const ClanRankLine(clanId: 'mire'));
    expect(find.text('Rank 3 of 3 in power'), findsOneWidget);
  });
}
