// QA guard (the user's hand test: "whenever I click on the map it triggers a
// detour"): a tap on the Journey's map, a pin, a row or the chart inside one
// place is no road, so it starts no detour (an excursion) and does not move
// the detours' pacing; only leaving for another place rolls one, and then
// only by the design of planRoad (one road one turn, a cooldown after a
// detour, the same road the same turn for a seed).
//
// The first test (one game, one test: a second test in a file draws the bare
// ground, not the room) does two things. It taps everything a player can tap
// without choosing a way: the marks, the rows, the chart or room or land map
// itself, at nine points of it, in a room (scene 100), on a town's chart (the
// wharf hub 2015, White Wells 1200) and on the land (zoomed out); after every
// scene: still in it, no excursion, the pacing as it was. Then the user's own
// click, "Back to the map" (the corner map icon and the bottom button of a
// scene page, key journey_reading_exit / journey_continue), on pages with one
// plain way on (100_dice, 2015_smuggler): the map shows, and the scene, the
// history, the pacing, the clock and the rations are as they were; then the
// step is taken on the map and, the way staying at its place, no road, no
// detour. The second test is planRoad on its own, seeded: what leaving for
// another place may roll. (Walking a real road through the screen is not held
// here; the card flow is qa_journey_choice_view_test's.)
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/detour_pacing.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

/// The Journey's own map surfaces, whichever the scene is on.
final _surfaces = [
  'journey_room',
  'journey_city_chart',
  'journey_world_map',
];

Future<void> _clear(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    final screen = find.byType(JourneyScreen);
    if (screen.evaluate().isEmpty) return;
    Navigator.of(tester.element(screen)).popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _arrive(
    WidgetTester tester, ProviderContainer container, String id) async {
  container.read(storyPlayProvider.notifier).jumpTo(id);
  await settleApp(tester);
  await tester.pump(const Duration(seconds: 6));
  await _clear(tester);
}

/// What a map tap must not change.
({String node, bool excursion, String pacing}) _state(
    ProviderContainer container) {
  final play = container.read(storyPlayProvider);
  return (
    node: play.currentNodeId,
    excursion: play.isInExcursion,
    pacing: '${container.read(playerSessionProvider).detourPacing.toJson()}',
  );
}

/// Taps what the player taps on the map without choosing a way: every mark
/// and row, then nine points of each map surface on screen.
Future<void> _tapEverything(WidgetTester tester) async {
  final keys = <String>[];
  void walk(Element e) {
    final k = e.widget.key;
    if (k is ValueKey<String> &&
        (RegExp(r'^journey_step_\d+$').hasMatch(k.value) ||
            RegExp(r'^journey_city_row_\d+$').hasMatch(k.value) ||
            RegExp(r'^journey_row_banner_\d+$').hasMatch(k.value))) {
      keys.add(k.value);
    }
    e.visitChildren(walk);
  }

  walk(tester.binding.rootElement!);
  for (final k in keys) {
    final f = _key(k);
    if (f.evaluate().isEmpty) continue;
    await tester.tapAt(tester.getCenter(f.first));
    await tester.pump(const Duration(milliseconds: 250));
  }
  for (final s in _surfaces) {
    if (_key(s).evaluate().isEmpty) continue;
    final rect = tester.getRect(_key(s).first);
    for (final fy in const [0.25, 0.5, 0.75]) {
      for (final fx in const [0.25, 0.5, 0.75]) {
        if (_key(s).evaluate().isEmpty) break;
        await tester.tapAt(
            Offset(rect.left + rect.width * fx, rect.top + rect.height * fy));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
  }
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets(
      'a tap on the map, or the return to it from a page, starts no detour',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(412, 892));
    final container = await openGame(tester, overrides: [storedCityPlans]);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);

    final failures = <String>[];
    for (final id in ['100', '2015', '1200']) {
      await _arrive(tester, container, id);
      final before = _state(container);
      expect(before.node, id);
      await _tapEverything(tester);
      await _clear(tester);
      final after = _state(container);
      if (after.node != id) {
        failures.add('scene $id: a tap moved the party to ${after.node}');
      }
      if (after.excursion) failures.add('scene $id: a tap started a detour');
      if (after.pacing != before.pacing) {
        failures.add('scene $id: a tap moved the detour pacing\n'
            '  before ${before.pacing}\n  after  ${after.pacing}');
      }
    }

    // The land: zoom out of the room until the world map, and tap it.
    await _arrive(tester, container, '100');
    for (var i = 0;
        i < 4 && _key('journey_world_map').evaluate().isEmpty;
        i++) {
      final out = _key('journey_place_zoom_out');
      if (out.evaluate().isEmpty) break;
      await tester.tap(out);
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(_key('journey_world_map'), findsOneWidget,
        reason: 'the zoom reaches the land');
    final before = _state(container);
    await _tapEverything(tester);
    await _clear(tester);
    final after = _state(container);
    if (after.excursion) failures.add('the land map: a tap started a detour');
    if (after.pacing != before.pacing) {
      failures.add('the land map: a tap moved the detour pacing');
    }

    // The return to the map from a scene page (the user's click).
    /// Everything the road would touch: the scene, the history, the pacing,
    /// the clock and the pack.
    String snap() {
      final s = container.read(playerSessionProvider);
      final p = container.read(storyPlayProvider);
      return 'node ${p.currentNodeId}, history ${p.history.length}, '
          'excursion ${p.isInExcursion}, pacing ${s.detourPacing.toJson()}, '
          'day ${s.day} watch ${s.watch}, provisions ${s.provisions}';
    }

    Future<void> openPage() async {
      expect(_key('journey_read'), findsOneWidget);
      await tester.tap(_key('journey_read'));
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(_key('journey_reading_exit'), findsOneWidget,
          reason: 'the scene is read as a page');
    }

    // The map is up: a room, a chart, the land, or the bare ground a place
    // draws before its plan has loaded.
    bool onMap() => [..._surfaces, 'journey_ground']
        .any((s) => _key(s).evaluate().isNotEmpty);

    // Scenes with one plain way on, at their place: a room's, a town's.
    for (final id in ['100_dice', '2015_smuggler']) {
      await _arrive(tester, container, id);
      final before = snap();
      for (final button in ['journey_reading_exit', 'journey_continue']) {
        await openPage();
        await tester.tap(_key(button));
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 3));
        await _clear(tester);
        if (!onMap()) {
          final out = <String>{};
          void walk(Element e) {
            final k = e.widget.key;
            if (k is ValueKey<String> && k.value.startsWith('journey_')) {
              out.add(k.value);
            }
            e.visitChildren(walk);
          }

          walk(tester.binding.rootElement!);
          failures.add('$id: "$button" does not show the map: '
              '${(out.toList()..sort()).join(' ')}');
        }
        final after = snap();
        if (after != before) {
          failures.add('$id: "$button" changed the game\n'
              '  before $before\n  after  $after');
        }
      }
      // Then the step is taken on the map, as the design says: this way
      // stays at its place, so no road: the next scene, no detour, the
      // pacing and the pack as they were.
      // A fresh arrival (from another scene, so the page state is new).
      await _arrive(tester, container, '100');
      await _arrive(tester, container, id);
      // (Where the way is a card of the scene, its list is opened and the
      // card picked first.)
      if (_key('journey_go').evaluate().isEmpty) {
        if (_key('journey_open_choices').evaluate().isNotEmpty) {
          await tester.tap(_key('journey_open_choices'));
          await tester.pump(const Duration(milliseconds: 600));
        }
        if (_key('journey_choice_card_0').evaluate().isNotEmpty) {
          await tester.tap(_key('journey_choice_card_0'));
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      expect(_key('journey_go'), findsOneWidget, reason: '$id: Go is ready');
      await tester.tap(_key('journey_go'));
      await tester.pump();
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settleApp(tester);
      final play = container.read(storyPlayProvider);
      if (play.currentNodeId == id) {
        failures.add('$id: Go on the map did not take the step');
      }
      if (play.isInExcursion) {
        failures.add('$id: a way that stays at its place started a detour');
      }
      final taken = snap().replaceAll(RegExp(r'node [^,]*, history \d+, '), '');
      final was = before.replaceAll(RegExp(r'node [^,]*, history \d+, '), '');
      if (taken != was) {
        failures.add('$id: a way that stays at its place moved the road\n'
            '  before $was\n  after  $taken');
      }
    }
    expect(tester.takeException(), isNull);
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('planRoad: one road one turn, a rest after a detour, a seed repeats',
      () {
    const road = DetourRoad(chapter: 2);
    List<RoadTurnKind> run(int seed) {
      final random = Random(seed);
      var pacing = const DetourPacing();
      final kinds = <RoadTurnKind>[];
      for (var i = 0; i < 300; i++) {
        final before = pacing.inChapter(road.chapter);
        final turn = planRoad(
            pacing: pacing,
            road: road,
            scenes: const {},
            flags: const {},
            random: random);
        final next = turn.next;
        expect(next.inChapter(road.chapter).roads - before.roads, 1,
            reason: 'road $i counts once');
        if (kinds.isNotEmpty && kinds.last == RoadTurnKind.detour) {
          expect(turn.kind, isNot(RoadTurnKind.detour),
              reason: 'road $i follows a detour: a rest (seed $seed)');
        }
        kinds.add(turn.kind);
        pacing = next;
      }
      return kinds;
    }

    for (final seed in const [1, 7, 23]) {
      final a = run(seed);
      expect(run(seed), a, reason: 'seed $seed repeats');
      final detours = a.where((k) => k == RoadTurnKind.detour).length;
      expect(detours, lessThanOrEqualTo(150),
          reason: 'at most every other road (seed $seed)');
    }
  });
}
