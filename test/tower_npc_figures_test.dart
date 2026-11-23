// The Tower's people on the floor cards (UX, the user's PixelLab characters):
// the Stair-Chandler on the stall, the Tally-Clerk on the bargain, and on the
// parley the officer for a Dominion or Vigil guardian and the floor foe's own
// figure for the other clans (nothing when it has none). The files are the
// set's names.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/tower_peaceful_cards.dart';

Widget host(Widget child) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

TowerParleyCard parley(String clan, {String? foe}) => TowerParleyCard(
      ability: 'charisma',
      dc: 10,
      modifier: 2,
      chance: 0.6,
      landsOn: 5,
      clanId: clan,
      foeId: foe,
    );

void main() {
  test('the names are the files of the folder', () {
    final stems = {
      for (final f in Directory('assets/visuals/tower/npc').listSync())
        if (f.path.endsWith('.png'))
          f.uri.pathSegments.last.replaceAll('.png', ''),
    };
    expect(towerNpcNames, stems);
  });

  testWidgets('the stall and the bargain have their people', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(host(const TowerMerchantRoom(wallet: 5, stock: [])));
    await tester.pump();
    expect(find.byKey(const Key('tower_npc_chandler')), findsOneWidget);
    await tester.pumpWidget(
        host(const TowerBargainCard(maxHealthCost: 7, stat: 'strength')));
    await tester.pump();
    expect(find.byKey(const Key('tower_npc_clerk')), findsOneWidget);
  });

  testWidgets('the officer guards for Dominion and Vigil only', (tester) async {
    SharedPreferences.setMockInitialValues({});
    for (final clan in towerOfficerClans) {
      await tester.pumpWidget(host(parley(clan, foe: 'some_foe')));
      await tester.pump();
      expect(find.byKey(const Key('tower_npc_guardian')), findsOneWidget,
          reason: clan);
    }
    for (final clan in ['mire', 'crows', 'compact', 'penitents']) {
      await tester.pumpWidget(host(parley(clan, foe: 'some_foe')));
      await tester.pump();
      expect(find.byKey(const Key('tower_npc_guardian')), findsNothing,
          reason: clan);
    }
    // No foe given and no officer: no figure at all.
    await tester.pumpWidget(host(parley('mire')));
    await tester.pump();
    expect(find.byKey(const Key('tower_npc_guardian')), findsNothing);
  });
}
