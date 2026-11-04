// A tap on a pin of the city chart picks the pin nearest the tap, and no
// other (N11): the busy wharf's pins sit closer together than a pin's reach
// (22 px), and the first pin of the list used to take a tap meant for the
// next. Ways are laid on one district in a tight grid, and the centre of each
// pin is tapped in turn. (It stands in for the test of the generated plan's
// marks, journey_step_taps_test, which could not tell a neighbour's tap in a
// city any more.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlansAssetPath;
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

void main() {
  testWidgets('each pin of a crowded district takes its own tap',
      (tester) async {
    final record = cityPlanRecordsFrom(
        jsonDecode(File(cityPlansAssetPath).readAsStringSync())
            as Map<String, dynamic>)['saltmouth']!;
    final district =
        record.districts.keys.firstWhere((d) => d.contains('wharf'));
    final box = record.districts[district]!;
    expect(box, isNotNull);
    // Pins 14 plan units apart on a grid: about 14 px at the district's zoom,
    // under a pin's reach of 22.
    final centre = record.anchorOf(district);
    final inputs = [
      for (var i = 0; i < 12; i++)
        CityWayInput(
          id: '$i',
          districtId: district,
          kind: CityWayKind.quest,
          name: 'Way $i',
          sceneId: 's$i',
          at: centre + Offset((i % 4) * 14.0, (i ~/ 4) * 14.0),
        ),
    ];
    final chart = CityChart.fromRecord(record,
        districtNames: {district: 'Wharf'}, ways: inputs);
    final picked = <String>[];
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CityChartView(
      key: const ValueKey('chart'),
      chart: chart,
      look: MapLook.night,
      animate: false,
      focus: district,
      cards: false,
      controls: false,
      onPick: (w) => picked.add(w.id),
    ))));
    await tester.pump(const Duration(seconds: 1));
    final view = find.byType(CityChartView);
    Offset? pin(String id) =>
        (tester.state(view) as dynamic).debugPinCentre(id) as Offset?;
    final shown = [
      for (final w in chart.ways)
        if (pin(w.id) != null) w.id,
    ];
    expect(shown.length, greaterThanOrEqualTo(8));
    final top = tester.getTopLeft(view);
    for (final id in shown) {
      picked.clear();
      // The chart tells a double tap by the wall clock: wait it out for real.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.tapAt(top + pin(id)!);
      await tester.pump(const Duration(seconds: 1));
      expect(picked, [id], reason: 'the pin of way $id');
    }
  });
}
