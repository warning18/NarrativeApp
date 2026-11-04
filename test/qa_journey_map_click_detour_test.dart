// QA guard (the user's hand test: "whenever I click on the map it triggers a
// detour"): a tap on the Journey's map, a pin, a row or the chart inside one
// place is no road, so it starts no detour (an excursion) and does not move
// the detours' pacing; only leaving for another place rolls one, and then
// only by the design of planRoad (one road one turn, a cooldown after a
// detour, the same road the same turn for a seed).
//
// The first test taps everything a player can tap without choosing a way:
// the marks, the rows, the chart or room or land map itself, at nine points
// of it, in a room (scene 100), on a town's chart (the wharf hub 2015, White
// Wells 1200) and on the land (zoomed out). After every scene: still in it,
// no excursion, the pacing as it was. The second is planRoad on its own,
// seeded: what leaving for another place may roll. (Walking a real road
// through the screen is not held here: v1.809 turned the Blind Beggar's way
// out into a card, and the card flow is the other guard's,
// qa_journey_choice_view_test.)
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
  testWidgets('a tap on the map inside one place starts no detour',
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
