// A town's service pins on its plan (wave 14): signs on the squares and lots
// that show once a district is looked at, tap to open a sheet with what the
// service opens (a shop, the bounty board, a night's rest, a port), or a line
// saying there is nothing to do there yet (the temple).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/town_services.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_painter.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'package:narrative_data_app/widgets/town_service_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  testWidgets('a service shows in the district looked at and a tap opens it',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final wharf = chart.districtById('wharf')!;
    final gate = chart.districtById('gate')!;
    final services = [
      CityChartService(
          id: 'market', kind: 'market', at: wharf.centre, district: 'wharf'),
      CityChartService(
          id: 'temple',
          kind: 'temple',
          at: gate.centre,
          district: 'gate',
          opens: false),
    ];
    CityChartService? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityChartView(
          chart: chart,
          look: MapLook.night,
          animate: false,
          focus: 'wharf',
          services: services,
          onService: (s) => tapped = s,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    final paint = find.descendant(
        of: find.byKey(const Key('city_chart')),
        matching: find.byType(CustomPaint));
    final painter = tester
        .widgetList<CustomPaint>(paint)
        .map((c) => c.painter)
        .whereType<CityChartPainter>()
        .first;
    expect(painter.detailed, isTrue);
    expect(painter.serviceShown(services[0]), isTrue);
    expect(painter.serviceShown(services[1]), isFalse,
        reason: 'another district');

    final origin = tester.getTopLeft(find.byKey(const Key('city_chart')));
    await tester.tapAt(origin + painter.offset + wharf.centre * painter.scale);
    await tester.pump();
    expect(tapped?.id, 'market');
  });

  testWidgets('the whole city shows no signs, only the districts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityChartView(
          chart: chart,
          look: MapLook.night,
          animate: false,
          services: [
            CityChartService(
                id: 'market',
                kind: 'market',
                at: chart.districtById('wharf')!.centre,
                district: 'wharf'),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final painter = tester
        .widgetList<CustomPaint>(find.descendant(
            of: find.byKey(const Key('city_chart')),
            matching: find.byType(CustomPaint)))
        .map((c) => c.painter)
        .whereType<CityChartPainter>()
        .first;
    expect(painter.detailed, isFalse);
    expect(painter.serviceShown(painter.services.first), isFalse);
  });

  Future<void> openSheet(WidgetTester tester, TownService service) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => showTownServiceSheet(context, service),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump(const Duration(milliseconds: 400));
  }

  const pin = CityServicePin('t_temple', 'temple', Offset(10, 10), 'wharf');

  testWidgets('a temple has nothing to open yet; a tavern offers the night',
      (tester) async {
    await openSheet(tester, const TownService(pin, []));
    expect(find.byKey(const Key('town_service_title')), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);
    expect(find.byKey(const Key('town_service_nothing')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('town_service_title'))))
        .pop();
    await tester.pump(const Duration(milliseconds: 400));

    await openSheet(
        tester,
        const TownService(
            CityServicePin('t_tavern', 'tavern', Offset(10, 10), 'wharf'), [
          (action: TownServiceAction.rest, id: 'rest_night', unlocked: true)
        ]));
    expect(find.text('Tavern'), findsOneWidget);
    expect(find.byKey(const Key('town_service_open_rest')), findsOneWidget);
    expect(find.byKey(const Key('town_service_nothing')), findsNothing);
  });
}
