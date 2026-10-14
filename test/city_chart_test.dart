// The city chart (lib/widgets/city_chart): the record reads, the view opens
// on the whole city, zooms in and out, and fogs the districts not found.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/screens/city_chart_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityChart chart;

  setUpAll(() async {
    chart = await CityChart.load(rootBundle, CityChart.saltmouthStub);
  });

  test('Saltmouth reads: six districts, twenty-three ways on real buildings',
      () {
    expect(chart.districts.map((d) => d.id),
        ['gate', 'tern', 'wharf', 'yard', 'alleys', 'cards']);
    expect(chart.ways, hasLength(23));
    for (final w in chart.ways) {
      expect(chart.buildingOf(w), isNotNull, reason: w.id);
      expect(chart.buildingOf(w)!.district, w.district, reason: w.id);
    }
    expect(chart.waysIn('wharf'), hasLength(6));
    for (final d in chart.districts) {
      expect(d.box.width, greaterThan(90));
      final room = chart.bounds.inflate(60);
      expect(room.contains(d.box.topLeft) && room.contains(d.box.bottomRight),
          isTrue,
          reason: d.id);
    }
  });

  /// A phone-sized page.
  Widget host(WidgetTester tester, Widget child) {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets(
      'it opens on the whole city; a district tap zooms to it and the '
      'way back returns', (tester) async {
    CityChartWay? gone;
    await tester.pumpWidget(host(
        tester,
        CityChartView(
          chart: chart,
          look: MapLook.night,
          animate: false,
          onWay: (w) => gone = w,
        )));
    expect(
        find.byKey(const Key('city_chart_whole')).hitTestable(), findsNothing);
    // Tap the wharf's centre (fitted view: plan * scale + offset).
    final wharf = chart.districtById('wharf')!;
    final topLeft = tester.getTopLeft(find.byKey(const Key('city_chart')));
    final fitted = 390 / chart.width;
    final scale = fitted < 760 / chart.height ? fitted : 760 / chart.height;
    final origin = Offset(
        (390 - chart.width * scale) / 2, (760 - chart.height * scale) / 2);
    await tester.tapAt(topLeft + origin + wharf.centre * scale);
    await tester.pump();
    expect(find.byKey(const Key('city_chart_district_card')), findsOneWidget);
    expect(find.text('Smugglers’ Wharf'), findsOneWidget);
    expect(find.text('6 ways'), findsOneWidget);
    expect(find.byKey(const Key('city_chart_whole')).hitTestable(),
        findsOneWidget);
    // Pins show in the district: tap the first way's pin.
    final way = chart.waysIn('wharf').first;
    final b = chart.buildingOf(way)!;
    final zoom = 390 / wharf.box.width < 760 / wharf.box.height
        ? 390 / wharf.box.width
        : 760 / wharf.box.height;
    final pin = Offset(390 / 2, 760 * 0.42) +
        (b.at - wharf.box.center) * zoom +
        const Offset(0, -16);
    await tester.tapAt(topLeft + pin);
    await tester.pump();
    expect(find.byKey(const Key('city_chart_way_card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('city_chart_go')));
    expect(gone?.id, way.id);
    await tester.tap(find.byKey(const Key('city_chart_whole')));
    await tester.pump();
    expect(
        find.byKey(const Key('city_chart_whole')).hitTestable(), findsNothing);
  });

  testWidgets('a district not found lies under fog and does not open',
      (tester) async {
    await tester.pumpWidget(host(
        tester,
        CityChartView(
          chart: chart,
          look: MapLook.night,
          animate: false,
          explored: const {'tern', 'wharf'},
        )));
    final gate = chart.districtById('gate')!;
    final topLeft = tester.getTopLeft(find.byKey(const Key('city_chart')));
    final fitted = 390 / chart.width;
    final scale = fitted < 760 / chart.height ? fitted : 760 / chart.height;
    final origin = Offset(
        (390 - chart.width * scale) / 2, (760 - chart.height * scale) / 2);
    await tester.tapAt(topLeft + origin + gate.centre * scale);
    await tester.pump();
    expect(find.byKey(const Key('city_chart_fog_card')), findsOneWidget);
    expect(find.text('Not explored yet'), findsOneWidget);
    expect(
        find.byKey(const Key('city_chart_whole')).hitTestable(), findsNothing);
  });

  testWidgets('the zoom buttons zoom in and out', (tester) async {
    await tester.pumpWidget(host(tester,
        CityChartView(chart: chart, look: MapLook.parchment, animate: false)));
    await tester.tap(find.byKey(const Key('city_chart_zoom_in')));
    await tester.pump();
    expect(find.byKey(const Key('city_chart_whole')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('city_chart_zoom_out')));
    await tester.pump();
    expect(
        find.byKey(const Key('city_chart_whole')).hitTestable(), findsNothing);
  });

  testWidgets(
      'the screen opens on the whole city and fogs three districts '
      'on request', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CityChartScreen())));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(find.byKey(const Key('city_chart')), findsOneWidget);
    expect(find.text('Saltmouth'), findsOneWidget);
    await tester.tap(find.byKey(const Key('city_chart_fog_toggle')));
    await tester.pump();
    // The Landward Gate is under fog now: its tap says so.
    final gate = chart.districtById('gate')!;
    final scale = 390 / chart.width;
    final origin = Offset(0, (760 - 56 - chart.height * scale) / 2 + 56);
    await tester.tapAt(origin + gate.centre * scale);
    await tester.pump();
    expect(find.byKey(const Key('city_chart_fog_card')), findsOneWidget);
  });

  // Not a check: writes the pictures the author looks at.
  testWidgets('pictures', (tester) async {
    final out = Platform.environment['CITY_SHOTS'];
    if (out == null) return;
    for (final (family, files) in [
      (InkFonts.system, ['PixelifySans-Regular.ttf']),
      (InkFonts.prose, ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
      (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(Future.value(ByteData.sublistView(
            File('assets/fonts/$file').readAsBytesSync())));
      }
      await loader.load();
    }
    tester.view.physicalSize = const Size(780, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> shot(String name, MapLook look,
        {Set<String>? explored,
        String? zoomTo,
        String? hereWay,
        String? goalWay}) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: CityChartView(
              chart: chart,
              look: look,
              explored: explored,
              hereDistrict: zoomTo ?? 'tern',
              hereWayId: hereWay,
              goalWayId: goalWay,
              animate: false,
            ),
          ),
        ),
      ));
      if (zoomTo != null) {
        final d = chart.districtById(zoomTo)!;
        final s = 780 / chart.width < 860 / chart.height
            ? 780 / chart.width
            : 860 / chart.height;
        await tester.tapAt(
            Offset((780 - chart.width * s) / 2, (860 - chart.height * s) / 2) +
                d.centre * s);
        await tester.pump();
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1.5);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    for (final look in MapLook.values) {
      await shot('${look.name}_all', look);
      await shot('${look.name}_fog', look,
          explored: {'tern', 'wharf', 'alleys'});
    }
    final wharf = chart.waysIn('wharf');
    await shot('wharf', MapLook.night,
        zoomTo: 'wharf', hereWay: wharf.first.id, goalWay: wharf[2].id);
    await shot('alleys', MapLook.parchment, zoomTo: 'alleys');
    await shot('tern', MapLook.night, zoomTo: 'tern');
  });
}
