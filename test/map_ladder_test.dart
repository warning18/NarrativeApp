// The ladder of maps (Maps release 2): one strip, World · Town · District ·
// Room; a rung is one tap from any other, + and − go one rung down or up,
// and the world and the town are joined by a move: the ball closes in on the
// place and the town grows out of it; going up, the ball pulls back out.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/widgets/journey_fx.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'package:narrative_data_app/widgets/level_ladder.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

void main() {
  Future<void> openInTheBeggar(WidgetTester tester, Size size) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, size);
    final container = await openGame(tester, overrides: [storedCityPlans]);
    container.read(storyPlayProvider.notifier).jumpTo('100');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
  }

  final room = find.byKey(const ValueKey('journey_room'));
  final town = find.byKey(const ValueKey('journey_city_chart'));
  final world = find.byType(JourneyWorldMap);
  Finder rung(String name) => find.byKey(Key('journey_tab_$name'));

  Future<void> press(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await settleApp(tester);
  }

  testWidgets('four rungs a tap apart; the world pulls back and dives in',
      (tester) async {
    await openInTheBeggar(tester, const Size(412, 915));
    // In the room: the four rungs in order, left to right.
    for (final name in ['world', 'town', 'district', 'room']) {
      expect(rung(name), findsOneWidget, reason: name);
    }
    final xs = [
      for (final name in ['world', 'town', 'district', 'room'])
        tester.getTopLeft(rung(name)).dx,
    ];
    expect(xs, [...xs]..sort());
    expect(room, findsOneWidget);
    // The room's label names the building, not its town, and no rain, snow
    // or ash is drawn under its roof.
    // (The breadcrumb above the map names both; the label is the second
    // "The Blind Beggar" and there is no second "Alster".)
    expect(find.text('The Blind Beggar'), findsNWidgets(2));
    expect(find.text('Alster'), findsOneWidget);
    final fx = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<JourneyFxPainter>();
    expect(fx.every((p) => p.weather == JourneyWeather.none), isTrue);

    // Town from inside the room: the party steps out and the whole town
    // is shown (the rung was greyed before).
    await press(tester, rung('town'));
    expect(room, findsNothing);
    expect(town, findsOneWidget);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);
    // On the town, + is the district; the way inside waits a rung lower.
    expect(find.byKey(const Key('journey_go_inside')), findsNothing);

    // World from the town: the ball is up at once, and the town shrinks
    // into its mark over it for a fifth of a second.
    await tester.tap(rung('world'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(world, findsOneWidget);
    expect(town, findsNothing);
    expect(find.byKey(const ValueKey('journey_town_leaving')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 500));
    await settleApp(tester);
    expect(world, findsOneWidget);
    expect(town, findsNothing);
    expect(find.byKey(const ValueKey('journey_town_leaving')), findsNothing);

    // The full map is the World rung enlarged: it carries the strip, World
    // lit, and a rung picked there is gone to on the Journey.
    await press(tester, find.byKey(const Key('journey_full_map')));
    expect(find.byType(FullMapScreen), findsOneWidget);
    expect(
        tester
            .widget<LevelLadder>(find.descendant(
                of: find.byType(FullMapScreen),
                matching: find.byType(LevelLadder)))
            .lit,
        LadderRung.world);
    await press(tester, rung('town').last);
    expect(find.byType(FullMapScreen), findsNothing);
    expect(town, findsOneWidget);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);

    // Room from the town.
    await press(tester, rung('room'));
    expect(room, findsOneWidget);

    // District from the room, then + is the way back inside.
    await press(tester, rung('district'));
    expect(room, findsNothing);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsNothing);
    await press(tester, find.byKey(const Key('journey_go_inside')));
    expect(room, findsOneWidget);

    // World from the room, and Room from the world.
    await press(tester, rung('world'));
    expect(world, findsOneWidget);
    await press(tester, rung('room'));
    expect(world, findsNothing);
    expect(room, findsOneWidget);

    // The world pulls back out of the place, and dives into it. (One test:
    // only the first test of a file is handed the stored city plans.)
    double zoom() => journeyGlobeOf(tester.element(world))!.zoom;

    // Up: the ball opens close on the place and pulls back to fill its box.
    await tester.tap(rung('world'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final close = zoom();
    expect(close, greaterThan(JourneyWorldMapZoom.district));
    await tester.pump(const Duration(milliseconds: 150));
    expect(zoom(), lessThan(close));
    await tester.pump(const Duration(milliseconds: 400));
    final filled = zoom();
    expect(filled, lessThan(JourneyWorldMapZoom.district));

    // Down: + to the closest zoom, then once more is the dive: the ball
    // goes past its closest zoom before the town takes over.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('journey_zoom_in')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(zoom(), closeTo(JourneyWorldMapZoom.max, 0.01));
    await tester.tap(find.byKey(const Key('journey_zoom_in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(world, findsOneWidget);
    expect(zoom(), greaterThan(JourneyWorldMapZoom.max * 1.5));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 500));
    await settleApp(tester);
    // It lands on the whole town, with no words about a door.
    expect(world, findsNothing);
    expect(town, findsOneWidget);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);
    expect(find.textContaining('step back out'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the strip fits a narrow phone on one line', (tester) async {
    await openInTheBeggar(tester, const Size(320, 640));
    final strip = tester.getRect(find.byKey(const Key('journey_level_tabs')));
    expect(strip.right, lessThanOrEqualTo(320));
    final ys = {
      for (final name in ['world', 'town', 'district', 'room'])
        tester.getTopLeft(rung(name)).dy.round(),
    };
    expect(ys, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
