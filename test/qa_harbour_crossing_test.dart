// QA: the harbour (v1.283.0), the land crossing (v1.285.0) and the save
// versions they came with, on the game's real data.
//
// Harbour: the camp's founding choice hands over exactly what the harbour
// costs (4 timber and 2 cut stone); the Eel's voyages from the camp are
// refused while the harbour is awaited and affordable; she sails anyway once
// the materials are gone, and when the harbour is built or the camp is not
// founded. Crossing: a party that runs out of health is carried back with
// what it set out with, at most half and at least a quarter (v1.287.0), with
// the days spent, and the choice is not taken; turning back
// applies nothing. Saves: 3 to 4 grants the legacy materials once; 4 to 5
// builds the harbour on load once.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_state.dart' show harborHouseId;
import 'package:narrative_data_app/data/harbour.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/materials.dart';
import 'package:narrative_data_app/data/settlements.dart' show campFoundedFlag;
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart' show housesSchema;
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart'
    show gameDbProvider;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/ship_widgets.dart' show sailTo;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

int _count(List<String> inventory, String id) =>
    inventory.where((e) => e == id).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final houses = _json('assets/gamedata/houses.json');
  final story = _json('assets/Cleaned_Narrative_DAG.json');
  final harbour = houses[harborHouseId] as Map<String, dynamic>;
  final cost = materialCountsOf(harbour, 'materialCost');

  group('the harbour', () {
    test('the founding choice grants exactly what the harbour costs', () {
      final choices = [
        for (final raw in (story['3001'] as Map)['choices'] as List)
          StoryChoice.fromJson(Map<String, dynamic>.from(raw as Map)),
      ];
      final founding =
          choices.where((c) => c.flagsToAdd.contains('camp_founded'));
      expect(founding, hasLength(1));
      expect(founding.single.grantMaterials,
          {'material_timber': 4, 'material_cut_stone': 2});
      expect(founding.single.grantMaterials, cost);
      // No gold on top: the story's grant covers it.
      expect((harbour['buildCost'] as num).toInt(), 0);
    });

    test('the voyage waits on an awaited, affordable harbour, and no other',
        () {
      final pack = [
        for (final e in cost.entries) ...List.filled(e.value, e.key),
      ];
      bool waits({
        List<String> flags = const [campFoundedFlag],
        List<String> built = const [],
        int gold = 0,
        List<String>? inventory,
      }) =>
          voyageWaitsOnHarbour(
              flags: flags,
              builtHouseIds: built,
              gold: gold,
              inventory: inventory ?? pack,
              houses: houses);

      expect(waits(), isTrue, reason: 'awaited and affordable: refused');
      expect(waits(built: [harborHouseId]), isFalse, reason: 'built');
      expect(waits(flags: const []), isFalse, reason: 'camp not founded');
      // The grant spent or sold: the Eel sails anyway.
      expect(waits(inventory: const []), isFalse);
      expect(waits(inventory: pack.skip(1).toList()), isFalse,
          reason: 'one material short');
      expect(
          waits(inventory: [
            ...pack,
            'material_iron_ore',
          ]),
          isTrue,
          reason: 'extra materials do not matter');
      // A table with no harbour record shuts nothing.
      expect(
          voyageWaitsOnHarbour(
              flags: const [campFoundedFlag],
              builtHouseIds: const [],
              gold: 0,
              inventory: pack,
              houses: const {}),
          isFalse);
    });

    testWidgets('a refused voyage says so and goes nowhere', (tester) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (context, r, _) {
            ref = r;
            return Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    // ignore: unused_local_variable
                    final arrived = await sailTo(context, ref,
                        toPortId: 'port_far_away', toPort: const {});
                    _result = arrived;
                  },
                  child: const Text('sail'),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.runAsync(() async {
        ref.read(playerSessionProvider.notifier);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await ref
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'saveVersion': 5,
              'flags': [campFoundedFlag],
              'inventoryItemIds': [
                for (final e in cost.entries) ...List.filled(e.value, e.key),
              ],
              'enemyKillCounts': <String, int>{},
            }));
        // The houses the lock reads, loaded.
        await ref.read(gameDbProvider(housesSchema).notifier).whenLoaded();
      });
      await tester.tap(find.text('sail'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.textContaining('arbo'), findsOneWidget,
          reason: 'the notice names the harbour');
      expect(_result, isNull, reason: 'still waiting on the dialog');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(_result, isFalse);
    });
  });

  group('the land crossing', () {
    const routeId = 'crash_to_sleeper';
    final routes = _json('assets/gamedata/land_routes.json');
    final events = landEventsFrom(_json('assets/gamedata/land_events.json'));

    test('the route data is whole: places, roads, events and French', () {
      for (final entry in routes.entries) {
        final route = landRouteFor(routes, entry.key)!;
        expect(route.nameFr, isNotEmpty, reason: entry.key);
        expect(route.days, greaterThan(0));
        for (final id in route.events.keys) {
          expect(events, contains(id), reason: '${entry.key}: event $id');
        }
        for (final roadId in route.roads) {
          expect(worldRoads.any((r) => r.id == roadId), isTrue,
              reason: '${entry.key}: road $roadId');
        }
      }
      for (final event in events.values) {
        expect(event.nameFr, isNotEmpty, reason: event.id);
        expect(event.textFr, isNotEmpty, reason: event.id);
        expect(event.choices, isNotEmpty, reason: event.id);
        for (final choice in event.choices) {
          expect(choice.textFr, isNotEmpty, reason: '${event.id}/${choice.id}');
        }
      }
    });

    /// A one-day crossing whose one event hurts by [healthPct] of the
    /// party's health.
    LandRoute oneDay() => const LandRoute(
        id: 'qa',
        name: 'QA road',
        from: 'crash',
        to: 'sleeper',
        days: 1,
        events: {'blow': 1});
    Map<String, LandEvent> blow(int healthPct, {int days = 0, int gold = 0}) =>
        {
          'blow':
              LandEvent(id: 'blow', name: 'A blow', text: 'It hits.', choices: [
            LandChoice(
                id: 'take_it',
                text: 'Take it',
                outcome: LandOutcome(
                    healthPct: healthPct,
                    days: days,
                    gold: gold,
                    note: 'Done.')),
          ]),
        };

    Future<({WidgetRef ref, List<bool?> pops})> open(
        WidgetTester tester, LandRoute route, Map<String, LandEvent> events,
        {required int health, int gold = 20}) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      final pops = <bool?>[];
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (context, r, _) {
            ref = r;
            return Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => pops.add(
                      await Navigator.of(context).push<bool>(MaterialPageRoute(
                          builder: (_) => LandCrossingScreen(
                              route: route,
                              events: events,
                              // A natural 1 or 20 settles a check.
                              random: Random(2))))),
                  child: const Text('go'),
                ),
              ),
            );
          }),
        ),
      ));
      await tester.runAsync(() async {
        ref.read(playerSessionProvider.notifier);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await ref
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'maxHealth': 100,
              'currentHealth': health,
              'gold': gold,
              'enemyKillCounts': <String, int>{},
            }));
      });
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      return (ref: ref, pops: pops);
    }

    testWidgets(
        '0 health carries the party back at half, days spent, and '
        'the choice is not taken', (tester) async {
      final run = await open(tester, oneDay(), blow(-100, days: 1), health: 60);
      final before = run.ref.read(playerSessionProvider);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('crossing_choice_take_it')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final after = run.ref.read(playerSessionProvider);
      expect(after.currentHealth, turnBackHealth(100, departureHealth: 60),
          reason: 'set out at 60: back at half of 100');
      expect(after.currentHealth, 50);
      // The road took its days (one a day, plus the extra one).
      expect(after.watch != before.watch || after.day > before.day, isTrue,
          reason: 'time passed');
      expect(find.textContaining('carried'), findsWidgets);
      await tester.tap(find.byKey(const Key('crossing_done')));
      await tester.pumpAndSettle();
      expect(run.pops, [false], reason: 'not arrived: the choice is not taken');
    });

    testWidgets(
        'a party that set out low is carried back at a quarter, not half',
        (tester) async {
      // A spent party that fails the road no longer wakes at half (v1.285's free rest, fixed in
      // v1.287.0): it comes back no better than it set out, but never below
      // a quarter, so it can set out again. Pinned so a change is noticed.
      final run = await open(tester, oneDay(), blow(-100), health: 5);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('crossing_choice_take_it')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(run.ref.read(playerSessionProvider).currentHealth, 25);
    });

    testWidgets('turning back applies nothing', (tester) async {
      final run = await open(tester, oneDay(), blow(-30, gold: -5), health: 77);
      final before = run.ref.read(playerSessionProvider);
      await tester.tap(find.byKey(const Key('crossing_turn_back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('crossing_done')));
      await tester.pumpAndSettle();
      final after = run.ref.read(playerSessionProvider);
      expect(after.currentHealth, before.currentHealth);
      expect(after.maxHealth, before.maxHealth);
      expect(after.gold, before.gold);
      expect(after.day, before.day);
      expect(after.watch, before.watch);
      expect(after.flags, before.flags);
      expect(run.pops, [false]);
    });

    testWidgets('a survivable road arrives and takes its toll', (tester) async {
      final run =
          await open(tester, oneDay(), blow(-20, gold: -5), health: 100);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('crossing_choice_take_it')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('crossing_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('crossing_done')));
      await tester.pumpAndSettle();
      final after = run.ref.read(playerSessionProvider);
      expect(after.currentHealth, 80);
      expect(run.pops, [true]);
    });

    test('every way out of the wreck takes the crossing', () {
      var ways = 0;
      for (final node in story.values) {
        for (final raw in ((node as Map)['choices'] as List? ?? const [])) {
          final choice = StoryChoice.fromJson(Map<String, dynamic>.from(raw));
          if (choice.nextId != '1120') continue;
          ways++;
          expect(choice.landRouteId, routeId);
        }
      }
      expect(ways, greaterThan(0));
    });
  });

  group('save versions', () {
    Map<String, dynamic> save({
      required int version,
      int clock = 0,
      List<String> flags = const [],
      List<String> built = const [],
    }) =>
        {
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 9,
          'saveVersion': version,
          'clockChapter': clock,
          'flags': flags,
          'builtHouseIds': built,
          'inventoryItemIds': ['a_sword'],
          'enemyKillCounts': <String, int>{},
        };

    test('the version of a new save is 6', () {
      expect(
          PlayerSession.fromJson(save(version: 5)).toJson()['saveVersion'], 6);
      expect(playerSessionSaveVersion, 6);
      expect(harbourSaveVersion, 5);
      expect(materialsSaveVersion, 4);
    });

    test('3 to 4: legacy rares once, by the chapter the clock counts in', () {
      for (final (clock, expected) in [
        (0, 0),
        (4, 0),
        (5, 1),
        (6, 1),
        (7, 2),
        (8, 2),
      ]) {
        final s = PlayerSession.fromJson(save(version: 3, clock: clock));
        expect(s.inventoryItemIds.where((e) => e.startsWith('material_')),
            hasLength(expected),
            reason: 'clock chapter $clock');
        // Saved and loaded again: nothing more is granted.
        final again = PlayerSession.fromJson(
            jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
        expect(again.inventoryItemIds.length, s.inventoryItemIds.length,
            reason: 'granted twice at clock $clock');
        expect(again.inventoryItemIds.where((e) => e.startsWith('material_')),
            hasLength(expected));
      }
      // A save of version 4 gets none.
      final v4 = PlayerSession.fromJson(save(version: 4, clock: 8));
      expect(v4.inventoryItemIds, ['a_sword']);
    });

    test('4 to 5: the harbour is built on load, once, only past the founding',
        () {
      final founded = [campFoundedFlag];
      final old = PlayerSession.fromJson(save(version: 4, flags: founded));
      expect(old.builtHouseIds, contains(harborHouseId));
      expect(old.flags, contains('house_$harborHouseId'));
      expect(harbourAwaited(flags: old.flags, builtHouseIds: old.builtHouseIds),
          isFalse);
      // Saved and loaded again: still one harbour.
      final again = PlayerSession.fromJson(
          jsonDecode(jsonEncode(old.toJson())) as Map<String, dynamic>);
      expect(
          again.builtHouseIds.where((e) => e == harborHouseId), hasLength(1));
      // Before the camp is founded: nothing built.
      final early = PlayerSession.fromJson(save(version: 4));
      expect(early.builtHouseIds, isNot(contains(harborHouseId)));
      // A current save past the founding without its harbour is awaiting it.
      final current = PlayerSession.fromJson(save(version: 5, flags: founded));
      expect(current.builtHouseIds, isNot(contains(harborHouseId)));
      expect(
          harbourAwaited(
              flags: current.flags, builtHouseIds: current.builtHouseIds),
          isTrue);
    });

    for (final fixture in const [
      'test/fixtures/session_v1_198.json',
      'test/fixtures/session_v1_204.json',
    ]) {
      test('$fixture loads, gets the grants once and keeps its harbour state',
          () {
        final raw = _json(fixture);
        final s = PlayerSession.fromJson(raw);
        final again = PlayerSession.fromJson(
            jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
        expect(again.inventoryItemIds.length, s.inventoryItemIds.length);
        expect(again.builtHouseIds, s.builtHouseIds);
        expect(again.toJson()['saveVersion'], 6);
        final founded =
            (raw['flags'] as List? ?? const []).contains(campFoundedFlag);
        if (!founded) {
          expect(s.builtHouseIds, isNot(contains(harborHouseId)));
        } else {
          expect(s.builtHouseIds, contains(harborHouseId));
        }
      });
    }

    test('materials of the pack count one by one', () {
      final pack = [
        'material_timber', 'material_timber', 'material_timber',
        'material_timber', 'material_cut_stone', 'material_cut_stone', //
      ];
      expect(missingMaterials(pack, cost), isEmpty);
      expect(_count(withoutMaterials(pack, cost), 'material_timber'), 0);
      expect(missingMaterials(pack.skip(1).toList(), cost), isNotEmpty);
    });
  });
}

bool? _result;
