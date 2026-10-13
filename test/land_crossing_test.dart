// Land expeditions (land_crossing.dart, v1.285.0): the routes and events on
// file, the day's draw, the health that plays the hull, the choice a
// headless walk takes, the crash's crossing in the story, and the screen
// played through.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final routes = _json('assets/gamedata/land_routes.json');
  final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
  final crash = landRouteFor(routes, 'crash_to_sleeper')!;

  test('every route runs on known roads and draws known events', () {
    final roads = {for (final r in worldRoads) r.id: r};
    for (final id in routes.keys) {
      final route = landRouteFor(routes, id)!;
      expect(route.days, greaterThan(0), reason: id);
      expect(route.nameFr, isNotEmpty, reason: id);
      expect(route.roads, isNotEmpty, reason: id);
      expect(landTerrains, contains(route.terrain), reason: id);
      for (final road in route.roads) {
        expect(roads.containsKey(road), isTrue, reason: '$id: $road');
      }
      final ends = {
        for (final road in route.roads) ...[roads[road]!.a, roads[road]!.b],
      };
      expect(ends, containsAll([route.from, route.to]), reason: id);
      for (final event in route.events.keys) {
        expect(events.containsKey(event), isTrue, reason: '$id: $event');
      }
    }
  });

  test('every event has its words in both languages and checks that roll', () {
    for (final event in events.values) {
      expect(event.nameFr, isNotEmpty, reason: event.id);
      expect(event.textFr, isNotEmpty, reason: event.id);
      expect(event.choices, isNotEmpty, reason: event.id);
      for (final choice in event.choices) {
        final where = '${event.id}.${choice.id}';
        expect(choice.textFr, isNotEmpty, reason: where);
        if (choice.hasCheck) {
          expect(abilityScoreKeys, contains(choice.check), reason: where);
          expect(choice.dc, greaterThan(0), reason: where);
          expect(choice.success.noteFr, isNotEmpty, reason: where);
          expect(choice.fail.noteFr, isNotEmpty, reason: where);
        } else {
          expect(choice.outcome.noteFr, isNotEmpty, reason: where);
        }
      }
    }
  });

  test('a crossing draws an event a day, never the same one twice running', () {
    for (var seed = 0; seed < 200; seed++) {
      final drawn = drawCrossing(crash, events.keys, random: Random(seed));
      expect(drawn, hasLength(crash.days));
      for (var i = 1; i < drawn.length; i++) {
        expect(drawn[i], isNot(drawn[i - 1]), reason: 'seed $seed');
      }
    }
    expect(drawCrossing(crash, events.keys, random: Random(3)),
        drawCrossing(crash, events.keys, random: Random(3)));
  });

  test('health is the hull: run out, the party is carried back wounded', () {
    expect(afterLandStep(health: 50, maxHealth: 100, change: -20),
        (health: 30, failed: false));
    expect(afterLandStep(health: 95, maxHealth: 100, change: 20),
        (health: 100, failed: false));
    expect(
        afterLandStep(health: 10, maxHealth: 100, change: -10).failed, isTrue);
    expect(turnBackHealth(140), 70);
    expect(turnBackHealth(1), 1);
    expect(landCheckDc(10, 1), 10);
    expect(landCheckDc(10, 4), 13);
  });

  test('a headless walk takes the most health, and pays only what it has', () {
    int none(String _) => 0;
    final spring = events['spring']!;
    expect(pickLandChoice(spring, modifierFor: none, gold: 0, chapter: 1).id,
        'rest');
    final scavengers = events['scavengers']!;
    // Throwing them a purse costs nothing in health, when there is one.
    expect(
        pickLandChoice(scavengers, modifierFor: none, gold: 100, chapter: 1).id,
        'pay');
    expect(
        pickLandChoice(scavengers, modifierFor: none, gold: 0, chapter: 1).id,
        isNot('pay'));
  });

  test(
      'a rested party almost always makes the crash crossing; a spent one '
      'is carried back able to set out again', () {
    var arrived = 0;
    for (var seed = 0; seed < 1000; seed++) {
      final result = resolveCrossing(crash, events,
          health: 140,
          maxHealth: 140,
          gold: 0,
          modifierFor: (_) => 1,
          random: Random(seed));
      expect(result.days, greaterThanOrEqualTo(crash.days));
      if (result.arrived) arrived++;
    }
    expect(arrived, greaterThan(950));

    final spent = resolveCrossing(crash, events,
        health: 1,
        maxHealth: 140,
        gold: 0,
        modifierFor: (_) => 0,
        random: Random(1));
    if (!spent.arrived) expect(spent.health, turnBackHealth(140));
  });

  test('the second leg, the Sleeper to the White Wells, is drawn and crossed',
      () {
    final wells = landRouteFor(routes, 'sleeper_to_wells')!;
    expect(wells.from, 'sleeper');
    expect(wells.to, 'wells');
    var arrived = 0;
    for (var seed = 0; seed < 500; seed++) {
      final result = resolveCrossing(wells, events,
          health: 140,
          maxHealth: 140,
          gold: 30,
          modifierFor: (_) => 1,
          random: Random(seed));
      expect(result.events, hasLength(wells.days));
      if (result.arrived) arrived++;
    }
    expect(arrived, greaterThan(475));
  });

  test('every way out of the wreck toward the Sleeper crosses the desert', () {
    final story = _json('assets/Cleaned_Narrative_DAG.json');
    var ways = 0;
    for (final node in story.values) {
      if (node is! Map) continue;
      for (final raw in (node['choices'] as List? ?? const [])) {
        final choice = StoryChoice.fromJson(Map<String, dynamic>.from(raw));
        if (choice.nextId != '1120') continue;
        ways++;
        expect(choice.landRouteId, crash.id);
        expect(choice.crossesLand, isTrue);
        expect(choice.toJson()['landRouteId'], crash.id);
        // A crossing is never read straight through.
        expect(isPlainGoOn(choice), isFalse);
      }
    }
    expect(ways, greaterThan(0));
  });

  testWidgets('the crossing screen plays a day at a time to the far side',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    bool? arrived;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (context, r, _) {
          ref = r;
          return Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  arrived = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => LandCrossingScreen(
                              route: crash,
                              events: events,
                              random: Random(4))));
                },
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
            'maxHealth': 1000,
            'currentHealth': 1000,
            'gold': 50,
          }));
    });
    // The scene keeps moving, so the screen never settles: a bounded wait.
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await tester.tap(find.text('go'));
    await settle();
    expect(find.text('Day 1 of ${crash.days}'), findsOneWidget);
    expect(find.byKey(const Key('crossing_health')), findsOneWidget);

    for (var day = 0; day < crash.days; day++) {
      final choice = find.byWidgetPredicate((w) =>
          w is FilledButton &&
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('crossing_choice_') &&
          w.onPressed != null);
      await tester.runAsync(() async {
        await tester.tap(choice.first);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await settle();
      if (day < crash.days - 1) {
        await tester.tap(find.byKey(const Key('crossing_next')));
        await settle();
      }
    }
    // Far too much health to lose on a three-day road: the last day ends
    // on the far side.
    await tester.tap(find.byKey(const Key('crossing_next')));
    await settle();
    expect(find.textContaining('far side'), findsOneWidget);
    await tester.tap(find.byKey(const Key('crossing_done')));
    await settle();
    expect(arrived, isTrue);
  });
}
