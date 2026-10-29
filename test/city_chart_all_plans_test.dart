// The city chart draws any of Core's stored plans (city_plans.json), not
// only Saltmouth: each of the seven records builds a chart, opens whole and
// in each of its districts without an error, with a wall or none, with a
// river or none, canals, bridges. UX_SHOTS (a folder) saves each city whole.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'support/fonts.dart';

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.pump(const Duration(milliseconds: 600));
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  });

  testWidgets('every stored plan draws, whole and by district', (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late final Map<String, CityPlanRecord> records;
    await tester.runAsync(() async {
      records = await container.read(cityPlanRecordsProvider.future);
      await container
          .read(gameDbProvider(geographySchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
    });
    final geography = container.read(geographyProvider);
    expect(
        records.keys.toSet(),
        containsAll({
          'saltmouth',
          'alster',
          'ashen_quarter',
          'drowned_cloister',
          'black_reliquary',
          'white_anchorage',
          'candlehold',
        }));
    for (final entry in records.entries) {
      final id = entry.key;
      final names = {
        for (final d in geography.childrenOf(id))
          if (d.level == GeoLevel.district) d.id: d.name,
      };
      final chart = CityChart.fromRecord(entry.value,
          districtNames: names, name: geography.place(id)?.name ?? id);
      await tester.pumpWidget(RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          theme: buildAppTheme(const ColorScheme.dark()),
          home: Scaffold(
            body: CityChartView(
              key: Key('chart_$id'),
              chart: chart,
              look: MapLook.parchment,
              animate: false,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '$id whole');
      await _shot(tester, 'city-$id');
      // Each district framed in turn.
      for (final d in entry.value.districts.keys) {
        await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(const ColorScheme.dark()),
          home: Scaffold(
            body: CityChartView(
              key: Key('chart_${id}_$d'),
              chart: chart,
              look: MapLook.parchment,
              animate: false,
              focus: d,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$id in $d');
      }
    }
  });
}
