// The Tower's floor-event cards (tower_event_card.dart): a setback's test
// shows Core's odds (the percent is TowerEventView.chance, the DC and the
// fall floor are Core's), the rival its rounds and its landing, a result line
// says how the last event ended, a floor met again says it pays nothing; and
// the floor screen shows them for a run whose events are on (and nothing for
// a run whose events are off).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
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

  /// A seed and floor whose event is [kind].
  (int, int) floorWith(TowerEventKind kind) {
    for (var seed = 1; seed < 300; seed++) {
      for (var floor = 1; floor < 29; floor++) {
        if (towerEventKindOf(run(seed, floor)) == kind) return (seed, floor);
      }
    }
    throw StateError('no $kind found');
  }

  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  testWidgets('a setback shows Core\'s odds, its DC and where a fall lands',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (seed, floor) = floorWith(TowerEventKind.test);
    final view = towerEventOf(run(seed, floor), data)!;
    await tester.pumpWidget(host(TowerEventCard(view)));
    await tester.pump();
    expect(find.byKey(const Key('tower_event_test')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('tower_event_chance'))).data,
        '${(view.chance! * 100).round()}%');
    expect(find.textContaining('${view.dc}', findRichText: true), findsWidgets);
    expect(find.textContaining('floor ${view.fallTo}', findRichText: true),
        findsOneWidget);
  });

  testWidgets('a rival shows its rounds and its landing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (seed, floor) = floorWith(TowerEventKind.rival);
    final view = towerEventOf(run(seed, floor), data)!;
    await tester.pumpWidget(host(TowerEventCard(view)));
    await tester.pump();
    expect(find.byKey(const Key('tower_event_rival')), findsOneWidget);
    expect(find.textContaining('${view.rounds} rounds', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('floor ${view.landsOn}', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('no skip', findRichText: true), findsOneWidget);
  });

  testWidgets('the result line says how the last event ended', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(host(const TowerEventResultLine(TowerEventResult(
        kind: TowerEventKind.test,
        roll: 6,
        total: 9,
        passed: false,
        from: 14,
        to: 12))));
    await tester.pump();
    expect(find.text('You fall from floor 14 to floor 12'), findsOneWidget);
    expect(find.text('You roll 6, total 9.'), findsOneWidget);
    await tester.pumpWidget(host(const TowerEventResultLine(TowerEventResult(
        kind: TowerEventKind.rival, passed: true, from: 16, to: 18))));
    await tester.pump();
    expect(find.textContaining('floor 17 is skipped'), findsOneWidget);
  });

  testWidgets('the floor screen shows a rival, and nothing when events are off',
      (tester) async {
    final (seed, floor) = floorWith(TowerEventKind.rival);
    for (final on in [true, false]) {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({
        'tower_run_v1':
            jsonEncode(run(seed, floor).copyWith(events: on ? 1 : 0).toJson()),
      });
      usePhone(tester, const Size(400, 1400));
      final container = ProviderContainer(overrides: [
        towerDataProvider.overrideWith((ref) async => data),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TowerFloorScreen()),
      ));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('tower_event_rival')),
          on ? findsOneWidget : findsNothing,
          reason: 'events ${on ? 'on' : 'off'}');
    }
  });
}
