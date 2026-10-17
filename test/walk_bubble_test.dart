// A companion's word on the road (wave 13): as a land walk starts, one of the
// walking companions may say a line, shown as a bubble over their figure for
// a few seconds; the hero alone, or companions with no walk lines, say nothing.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/remark_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
  final routes = _json('assets/gamedata/land_routes.json');
  final crash = landRouteFor(routes, 'crash_to_sleeper')!;
  final book = RemarkBook({
    'maren_walk': {
      'companionID': 'maren',
      'trigger': 'walk',
      'lines': ['Keep to the verge.'],
    },
  });

  Future<void> walk(WidgetTester tester,
      {required bool withMaren,
      RemarkBook? lines,
      Size size = const Size(390, 800),
      String ally = 'maren'}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      remarkBookProvider.overrideWithValue(lines ?? book),
    ]);
    addTearDown(container.dispose);
    container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          if (withMaren) ...{
            'recruitedAllies': [
              AllyState(
                      companionId: ally,
                      currentHealth: AllyState.fullHealthSentinel)
                  .toJson()
            ],
            'activeAllyIds': [ally],
          },
        })));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home:
            LandCrossingScreen(route: crash, events: events, random: Random(4)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a walking companion speaks over their figure, then it goes',
      (tester) async {
    await walk(tester, withMaren: true);
    expect(find.byKey(const Key('walk_bubble')), findsOneWidget);
    expect(find.text('Keep to the verge.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(const Key('walk_bubble')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hero alone says nothing', (tester) async {
    await walk(tester, withMaren: false);
    expect(find.byKey(const Key('walk_bubble')), findsNothing);
  });

  testWidgets(
      'the longest of Narrative\'s real walk lines fits over the scene on a '
      'narrow phone', (tester) async {
    final real = RemarkBook(_json('assets/gamedata/companion_remarks.json'));
    await walk(tester,
        withMaren: true,
        lines: real,
        ally: 'liora',
        size: const Size(320, 700));
    final bubble = find.byKey(const Key('walk_bubble'));
    expect(bubble, findsOneWidget);
    // (The test font is far wider than the real ones: the HUD's own row
    // overflows at 320 px with or without the bubble.)
    tester.takeException();
    final rect = tester.getRect(bubble);
    final scene = tester.getRect(find.byKey(const Key('crossing_scene')));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.top, greaterThanOrEqualTo(scene.top),
        reason: '$rect in $scene');
    expect(rect.bottom, lessThanOrEqualTo(scene.bottom));
  });
}
