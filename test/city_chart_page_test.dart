// The city plan page is the Town view enlarged (wave 3 of the Maps review):
// its "+" and "−" sit at the foot on the right as on the Journey's map, the
// level strip is under the plan with Town lit, and a rung picked there
// closes the page and takes the Journey to that level.
// (A file of its own: only the first test of a file is given the stored
// city plans.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/city_chart_screen.dart';
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

  final town = find.byKey(const ValueKey('journey_city_chart'));
  final world = find.byType(JourneyWorldMap);
  Finder rung(String name) => find.byKey(Key('journey_tab_$name'));

  Future<void> press(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await settleApp(tester);
  }

  testWidgets(
      'the city plan page is the Town enlarged: buttons at the foot, the strip, a rung back',
      (tester) async {
    await openInTheBeggar(tester, const Size(412, 915));
    await press(tester, rung('town'));
    expect(town, findsOneWidget);
    await press(tester, find.byKey(const ValueKey('journey_city_plan')));
    expect(find.byType(CityChartScreen), findsOneWidget);
    // The strip, Town lit; the rungs the Journey can take from here open.
    final strip = tester.widget<LevelLadder>(find.byType(LevelLadder));
    expect(strip.lit, LadderRung.town);
    expect(strip.open,
        containsAll([LadderRung.world, LadderRung.town, LadderRung.district]));
    // "+" and "−" at the foot on the right, as on the Journey's map.
    final page = tester.getRect(find.byType(CityChartScreen));
    final plus =
        tester.getRect(find.byKey(const Key('city_chart_zoom_in')).last);
    expect(plus.center.dy, greaterThan(page.center.dy));
    expect(plus.center.dx, greaterThan(page.center.dx));
    expect(plus.size, const Size(44, 44));
    // A rung picked on the page closes it and the Journey goes there.
    await press(tester, rung('world'));
    expect(find.byType(CityChartScreen), findsNothing);
    expect(world, findsOneWidget);
    expect(tester.widget<LevelLadder>(find.byType(LevelLadder)).lit,
        LadderRung.world);
    // And back down: the page again, then the District.
    await press(tester, rung('town'));
    await press(tester, find.byKey(const ValueKey('journey_city_plan')));
    await press(tester, rung('district'));
    expect(find.byType(CityChartScreen), findsNothing);
    expect(tester.widget<LevelLadder>(find.byType(LevelLadder)).lit,
        LadderRung.district);
  });
}
