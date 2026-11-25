// The city plan (Maps release 3): an unexplored district lets its streets
// and blocks show through the fog; the plan is drawn once and only the
// party's ring is redrawn as it breathes; + closes in on the party.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/city_chart_screen.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_painter.dart';

void main() {
  test('the fog is thin enough for streets and blocks to show through', () {
    expect(CityChartPainter.fogAlpha, lessThanOrEqualTo(0.6));
    expect(CityChartPainter.fogAlpha, greaterThanOrEqualTo(0.4));
  });

  testWidgets('the plan is kept, the ring breathes alone, + goes to the party',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(storyDataProvider.future);
      await container.read(cityPlanRecordsProvider.future);
      await container
          .read(gameDbProvider(geographySchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
    });
    container.read(storyPlayProvider.notifier).jumpTo('2015');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CityChartScreen()),
    ));
    for (var k = 0; k < 6; k++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    CityChartPainter painterOf(String key) =>
        tester.widget<CustomPaint>(find.byKey(Key(key))).painter!
            as CityChartPainter;
    // Two layers: the plan without the party's mark, and the mark alone.
    final plan = painterOf('city_chart_plan');
    expect(plan.layer, CityChartLayer.base);
    expect(painterOf('city_chart_party').layer, CityChartLayer.party);

    // A breath redraws the ring, not the plan, and rebuilds no widget: the
    // ring's painter follows the breath itself (the same painter before
    // and after, its beat moved on), and the plan's is not asked again.
    final ring = painterOf('city_chart_party');
    final beatBefore = ring.beat!.value;
    await tester.pump(const Duration(milliseconds: 300));
    final planAfter = painterOf('city_chart_plan');
    expect(identical(painterOf('city_chart_party'), ring), isTrue);
    expect(ring.beat!.value, isNot(beatBefore));
    expect(planAfter.beat, isNull);
    expect(identical(planAfter, plan), isTrue);

    // The ring is redrawn 20 times a second, not at every refresh of the
    // screen: over one second of 60 refreshes it moves 20 times, and only
    // those ask for a frame.
    var beats = 0, frames = 0;
    void onBeat() => beats++;
    ring.beat!.addListener(onBeat);
    for (var i = 0; i < 60; i++) {
      // A refresh's worth of time goes by; was a frame asked for?
      await tester.binding.delayed(const Duration(microseconds: 16667));
      if (tester.binding.hasScheduledFrame) frames++;
      await tester.pump();
    }
    ring.beat!.removeListener(onBeat);
    expect(beats, inInclusiveRange(19, 21));
    expect(frames, inInclusiveRange(19, 21));
    // A whole breath still takes two seconds, from 0 up to 1 and round.
    final seen = <double>{};
    void onStep() => seen.add(ring.beat!.value);
    ring.beat!.addListener(onStep);
    await tester.pump(const Duration(seconds: 2));
    ring.beat!.removeListener(onStep);
    expect(seen.every((v) => v >= 0 && v < 1), isTrue);

    // The party is on the plan, and + closes in on its place.
    final party = plan.partyPoint;
    expect(party, isNotNull);
    final box = tester.getSize(find.byKey(const Key('city_chart')));
    Offset onScreen(CityChartPainter p) => party! * p.scale + p.offset;
    final before = (onScreen(plan) - box.center(Offset.zero)).distance;
    await tester.tap(find.byKey(const Key('city_chart_zoom_in')));
    for (var k = 0; k < 6; k++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final zoomed = painterOf('city_chart_plan');
    expect(zoomed.scale, greaterThan(plan.scale));
    final after = (onScreen(zoomed) - box.center(Offset.zero)).distance;
    // A zoom about the middle of the view would have pushed the party 1.6
    // times further from it; this one pulls it towards the middle, as far
    // as the plan's edge allows.
    expect(after, lessThan(before * 1.6 - 1));
    expect(onScreen(zoomed).dx, inInclusiveRange(0, box.width));
    expect(onScreen(zoomed).dy, inInclusiveRange(0, box.height));
    expect(tester.takeException(), isNull);
  });
}
