// The clan power sign (option A, ranking): a plate with the clan's rank and an
// arrow for how it moved since the last chapter's turn, a page of bars
// ranking every clan with power, and the Clans list wearing the plate. The
// numbers are Core's (clanPowerRanking); the strengths below are set so one
// clan climbs, one falls and one holds.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/widgets/clan_rank.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );

  // The Crows (45 at the start) overtake the Compact (40); the Vigil falls below the Mire;
  // the Dominion holds. Power at the last turn: Crows 38, Vigil 34 (now 22),
  // Dominion 60.
  final politics = PoliticsState.empty.copyWith(
    power: {'crows': 45, 'vigil': 22, 'dominion': 60},
    powerAtTurn: {'crows': 38, 'vigil': 34, 'dominion': 60},
  );

  Widget host(Widget child, {double width = 412}) => ProviderScope(
        overrides: [
          clanDataProvider.overrideWithValue(data),
          politicsProvider.overrideWithValue(politics),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: width, child: child)),
          ),
        ),
      );

  test('the arrow follows the places a clan climbed', () {
    expect(rankMoveOf(2), RankMove.up);
    expect(rankMoveOf(-1), RankMove.down);
    expect(rankMoveOf(0), RankMove.steady);
  });

  testWidgets('a clan\'s plate says its rank and which way it moved',
      (tester) async {
    final ranking = clanPowerRanking(politics, data);
    ClanPowerRank of(String id) => ranking.firstWhere((r) => r.clanId == id);
    expect(of('dominion').rank, 1);
    expect(of('crows').rankChange, greaterThan(0));
    expect(of('vigil').rankChange, lessThan(0));

    await tester.pumpWidget(host(const Column(children: [
      ClanRankPlate(clanId: 'dominion'),
      ClanRankPlate(clanId: 'crows'),
      ClanRankPlate(clanId: 'vigil'),
      // A clan with no power has no plate.
      ClanRankPlate(clanId: 'choir'),
    ])));
    expect(find.byKey(const Key('rank_plate_dominion')), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#${of('crows').rank}'), findsOneWidget);
    expect(find.byKey(const Key('rank_plate_choir')), findsNothing);
    // One arrow of each kind: up for the Crows, down for the Vigil, a dash
    // for the Dominion.
    expect(
        find.descendant(
            of: find.byKey(const Key('rank_plate_crows')),
            matching: find.byKey(const Key('rank_arrow_up'))),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('rank_plate_vigil')),
            matching: find.byKey(const Key('rank_arrow_down'))),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('rank_plate_dominion')),
            matching: find.byKey(const Key('rank_arrow_steady'))),
        findsOneWidget);
  });

  for (final width in [412.0, 320.0]) {
    testWidgets(
        'the bars rank every clan with power, this one framed '
        '(${width.round()} px)', (tester) async {
      await tester.pumpWidget(host(
          SingleChildScrollView(
            child: Column(children: [
              RankedBars(highlight: 'crows', width: width),
              const RankLegend(),
            ]),
          ),
          width: width));
      final ranking = clanPowerRanking(politics, data);
      expect(ranking, hasLength(10));
      for (final r in ranking) {
        expect(find.byKey(Key('ranked_row_${r.clanId}')), findsOneWidget,
            reason: r.clanId);
      }
      // The strongest first, the weakest last.
      final tops = [
        for (final r in ranking)
          tester.getTopLeft(find.byKey(Key('ranked_row_${r.clanId}'))).dy,
      ];
      expect(tops, [...tops]..sort());
      // The attack power and the tiers are named in the legend.
      expect(find.textContaining('10'), findsWidgets);
      expect(find.byKey(const Key('rank_legend')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
