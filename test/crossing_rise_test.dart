// The road trip as one camera travel (v1.846): a road the story crosses
// (the Dune Sea road to the White Wells) sets the party out on the chart and
// the crossing rises over it, instead of the flight running to the far place
// and a new screen setting out again. Elsewhere a crossing is a plain page.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

import 'package:narrative_data_app/screens/crossing_rise_route.dart';

/// The height of the page the rise has uncovered so far.
double _risen(WidgetTester tester) {
  final rise =
      find.byWidgetPredicate((w) => w is Align && w.heightFactor != null);
  return tester.getSize(rise.last).height;
}

void main() {
  testWidgets('the rise uncovers the page from the top, scene first',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(body: Center(child: Text('chart'))),
    ));
    nav.currentState!.push(CrossingRiseRoute<bool>(
        builder: (_) => const Scaffold(
                body: Column(children: [
              SizedBox(key: ValueKey('scene'), height: 100, width: 300),
              Expanded(child: Center(child: Text('days'))),
            ]))));
    await tester.pump();
    await tester.pump(crossingRiseDuration ~/ 4);
    // A part of the page is down, the chart still shows below it.
    final partway = _risen(tester);
    expect(partway, lessThan(600));
    expect(partway, greaterThan(0));
    expect(find.text('chart', skipOffstage: false), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_risen(tester), 600);
  });

  testWidgets('with reduced motion the crossing is there at once',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(body: Text('chart')),
    ));
    nav.currentState!.push(CrossingRiseRoute<bool>(
        still: true, builder: (_) => const Scaffold(body: Text('days'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('days'), findsOneWidget);
  });

  testWidgets('the Dune Sea road sets out on the chart and the crossing rises',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));
    final pace = worldMoveTimeScale;
    addTearDown(() => worldMoveTimeScale = pace);
    worldMoveTimeScale = 1;
    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    play.jumpTo('1130');
    await settleApp(tester);
    play.jumpTo('1140');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    await tester.tap(find.byKey(const ValueKey('journey_step_2')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    final crossing = find.byType(LandCrossingScreen);
    var seconds = 0.0;
    for (var i = 0; i < 400 && crossing.evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
      seconds += 0.05;
    }
    expect(crossing, findsOneWidget);
    // The flight only set out: the whole walk of this road is 6 s or more.
    expect(seconds, lessThan(4));
    expect(ModalRoute.of(tester.element(crossing)), isA<CrossingRiseRoute>());
    // Turning back: the page rises off and the map is under it.
    Navigator.of(tester.element(crossing)).pop(false);
    await settleApp(tester);
    expect(find.byType(LandCrossingScreen), findsNothing);
    expect(container.read(crossingRiseProvider), isFalse);
  });
}
