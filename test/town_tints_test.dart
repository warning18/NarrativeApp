// Towns tinted by the clan that rules them (wave 15, UX): a district of the
// city plan takes its ruler's wash and outline (a district no one rules keeps
// its own colour), the world chart's towns take the tint of the town their
// scenes happen in, and the Journey's town view says who holds the town.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/town_rulers.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/providers/landmark_towns_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_painter.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

TownRuler _ruler(String place, String clan, int color) => TownRuler(
      placeId: place,
      cityId: 'saltmouth',
      clanId: clan,
      source: clan.isEmpty ? TownRulerSource.none : TownRulerSource.own,
      color: color,
      accent: shadeColor(color),
      isDistrict: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  test('a ruled district takes its clan\'s colours, a neutral one none', () {
    final rulers = cityChartRulersOf(chart, {
      'wharf': _ruler('wharf', 'tidekin', 0xFF1C8FA0),
      'gate': _ruler('gate', 'crows', 0xFFB0303F),
      'tern': _ruler('tern', '', townNeutralColor),
      'elsewhere': _ruler('elsewhere', 'compact', 0xFFB86B3C),
    });
    expect(rulers.keys.toSet(), {'wharf', 'gate'});
    expect(rulers['wharf']!.fill, const Color(0xFF1C8FA0));
    expect(rulers['wharf']!.accent, Color(shadeColor(0xFF1C8FA0)));
    // The two near colours differ by their outline as well as their wash.
    expect(rulers['gate']!.accent, isNot(rulers['wharf']!.accent));
  });

  testWidgets(
      'the city plan paints with the rulers and repaints when they '
      'change hands', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget plan(Map<String, CityChartRuler> rulers) => MaterialApp(
          home: Scaffold(
            body: CityChartView(
              chart: chart,
              look: MapLook.night,
              animate: false,
              rulers: rulers,
            ),
          ),
        );
    CityChartPainter painter() => tester
        .widgetList<CustomPaint>(find.descendant(
            of: find.byKey(const Key('city_chart')),
            matching: find.byType(CustomPaint)))
        .map((c) => c.painter)
        .whereType<CityChartPainter>()
        .first;

    await tester.pumpWidget(plan(const {}));
    final bare = painter();
    expect(bare.rulers, isEmpty);
    final rulers = cityChartRulersOf(
        chart, {'wharf': _ruler('wharf', 'crows', 0xFFB0303F)});
    await tester.pumpWidget(plan(rulers));
    await tester.pump(const Duration(milliseconds: 300));
    final tinted = painter();
    expect(tinted.rulers.keys, ['wharf']);
    expect(tinted.shouldRepaint(bare), isTrue);
    expect(tester.takeException(), isNull);
  });

  test('the world chart\'s towns take the tint of the town they stand in',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Listened to, so the tables behind it load (the story, the geography,
    // the clans, the plans).
    final sub = container.listen(landmarkRulersProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(storyDataProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final tints = container.read(landmarkRulersProvider);
    // At the start: Candlehold is the Dominion's, Emberwick the Compact's.
    expect(tints['candlehold']?.clanId, 'dominion');
    expect(tints['emberwick']?.clanId, 'compact');
    // Never a neutral town.
    expect(tints.values.where((r) => r.isNeutral), isEmpty);
    // A landmark that is no town is not tinted.
    expect(tints.containsKey('crash'), isFalse);
  });
}
