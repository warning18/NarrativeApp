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

    // A breath redraws the ring, not the plan: the plan's painter is asked
    // again with the same view and says there is nothing to repaint.
    final pulseBefore = painterOf('city_chart_party').pulse;
    await tester.pump(const Duration(milliseconds: 300));
    final planAfter = painterOf('city_chart_plan');
    expect(painterOf('city_chart_party').pulse, isNot(pulseBefore));
    expect(planAfter.pulse, 0);
    expect(planAfter.shouldRepaint(plan), isFalse);

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
