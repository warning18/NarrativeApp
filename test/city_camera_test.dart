// The district view's camera (city_camera.dart, map-first.md): the
// Journey sends the city chart a shot (the arrival's: the district 25%
// closer, on the party's mark; the full zoom), the chart goes there, and
// says whether it stands at its full zoom, pinched there or sent.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_camera.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  testWidgets('a shot moves the view; the full zoom is told', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final camera = CityChartCamera();
    addTearDown(camera.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityChartView(
          chart: chart,
          look: MapLook.night,
          animate: false,
          camera: camera,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    // The whole city at first.
    expect(camera.zoom, closeTo(1, 0.01));
    expect(camera.fullZoom.value, isFalse);

    final district = chart.districts.first;
    camera.show(CityCameraShot.arrival(district.id,
        partyAt: district.box.center, jump: true));
    await tester.pump();
    await tester.pump();
    final arrived = camera.zoom;
    expect(arrived, greaterThan(1));
    expect(camera.fullZoom.value, isFalse);

    camera.show(CityCameraShot.full(district.id));
    await tester.pump();
    await tester.pump();
    expect(camera.zoom, greaterThan(arrived));
    expect(camera.fullZoom.value, isTrue);

    // Back to the district's own frame: no longer full.
    camera.show(CityCameraShot(districtId: district.id, jump: true));
    await tester.pump();
    await tester.pump();
    expect(camera.fullZoom.value, isFalse);
    expect(camera.zoom, lessThan(arrived));
    expect(camera.shots, 3);
  });

  testWidgets('the arrival eases in over 0.6 s', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final camera = CityChartCamera();
    addTearDown(camera.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityChartView(
          chart: chart,
          look: MapLook.night,
          camera: camera,
        ),
      ),
    ));
    await tester.pump();
    final district = chart.districts.first;
    camera.show(CityCameraShot.arrival(district.id));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final midway = camera.zoom;
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(camera.zoom, greaterThan(midway));
    expect(midway, greaterThan(1));
  });
}
