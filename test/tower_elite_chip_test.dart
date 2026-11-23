// The shortcut's tougher fight is marked (UX): the offer card wears a gold
// "Elite" chip when the stair makes the foes Elite (a lone foe an Elite, a
// pack an Elite pack: TowerEventView.elite / elitePack), and once the stair is
// taken every foe of an Elite pack wears the chip on its own panel.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_event_card.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();

  TowerRun run(int seed, int floor) => TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: 1,
      );

  /// A seed and floor whose event is a shortcut over a floor with [pack] foes
  /// (a pack, or a lone foe).
  (int, int) shortcutOver({required bool pack}) {
    for (var floor = 28; floor >= 4; floor--) {
      for (var seed = 1; seed < 800; seed++) {
        final r = run(seed, floor);
        if (towerEventKindOf(r) != TowerEventKind.shortcut) continue;
        final f =
            towerFloorsFor(r.seed, data.enemies, events: r.events)[floor - 1];
        if (f.kind == TowerFloorKind.fight && f.isPack == pack && !f.elite) {
          return (seed, floor);
        }
      }
    }
    throw StateError('no shortcut found');
  }

  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  for (final pack in [true, false]) {
    testWidgets(
        'the offer card marks the tougher fight with the Elite chip '
        '(${pack ? 'a pack' : 'a lone foe'})', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final (seed, floor) = shortcutOver(pack: pack);
      final view = towerEventOf(run(seed, floor), data)!;
      expect((view.elite ?? false) || (view.elitePack ?? false), isTrue);
      await tester.pumpWidget(host(TowerEventCard(view, onShortcut: (_) {})));
      await tester.pump();
      expect(find.byKey(const Key('tower_event_shortcut_elite_chip')),
          findsOneWidget);
    });
  }

  testWidgets('after the stair, each foe of an Elite pack wears the chip',
      (tester) async {
    final (seed, floor) = shortcutOver(pack: true);
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'tower_run_v1': jsonEncode(run(seed, floor).toJson()),
    });
    usePhone(tester, const Size(412, 2400));
    final container = ProviderContainer(overrides: [
      towerDataProvider.overrideWith((ref) async => data),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TowerFloorScreen()),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    // Offered: the foes shown are the floor's own, no chip on them yet.
    expect(find.text('Elite'), findsOneWidget); // the offer card's chip only
    await tester.tap(find.byKey(const Key('tower_shortcut_take')));
    await settle();
    final foes = towerFloorOf(container.read(towerProvider).value!.run!, data)
        .enemyIds
        .length;
    expect(foes, greaterThan(1));
    expect(find.text('Elite'), findsNWidgets(foes));
  });
}
