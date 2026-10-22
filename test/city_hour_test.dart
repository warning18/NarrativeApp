// The town at the hour (wave 16, UX): the city plan takes the part of the day
// from the world clock: a warm wash at dawn, a violet one at dusk, a deep
// blue one at night with its windows and lanterns lit, and an open service
// glowing; nothing by day. UX_SHOTS=<folder> takes a picture of the four.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_painter.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  CityChartPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.descendant(
          of: find.byKey(const Key('city_chart')),
          matching: find.byType(CustomPaint)))
      .map((c) => c.painter)
      .whereType<CityChartPainter>()
      .first;

  Widget plan(DayPhase phase) => MaterialApp(
        home: Scaffold(
          body: CityChartView(
            chart: chart,
            look: MapLook.night,
            animate: false,
            phase: phase,
            services: [
              CityChartService(
                  id: 'tavern',
                  kind: 'tavern',
                  at: chart.districts.first.centre,
                  district: chart.districts.first.id,
                  opens: true),
            ],
          ),
        ),
      );

  testWidgets('every part of the day paints, and a change repaints',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(plan(DayPhase.day));
    final day = painter(tester);
    expect(day.phase, DayPhase.day);
    for (final phase in [DayPhase.dawn, DayPhase.dusk, DayPhase.night]) {
      await tester.pumpWidget(plan(phase));
      await tester.pump(const Duration(milliseconds: 300));
      final p = painter(tester);
      expect(p.phase, phase);
      expect(p.shouldRepaint(day), isTrue, reason: phase.name);
      expect(tester.takeException(), isNull, reason: phase.name);
    }
  });

  testWidgets('pictures of the four parts of the day (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(780, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Column(children: [
            for (final row in [
              [DayPhase.dawn, DayPhase.day],
              [DayPhase.dusk, DayPhase.night],
            ])
              Expanded(
                child: Row(children: [
                  for (final phase in row)
                    Expanded(
                      child: CityChartView(
                        chart: chart,
                        look: MapLook.night,
                        animate: false,
                        controls: false,
                        cards: false,
                        phase: phase,
                        focus: chart.districts[1].id,
                      ),
                    ),
                ]),
              ),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/town-at-the-hour.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
