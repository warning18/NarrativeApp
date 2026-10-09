// The sphere wrapped in the chart (v1.206): painted coarse until its skin
// is rendered, then as a textured mesh with the heights lifting it; the
// skin kept per look and detail; and the flat chart's shaded relief at
// every level of detail.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';

ChartMapPainter _painter(
        {GlobeView? globe, double zoom = 1, MapLook look = MapLook.night}) =>
    ChartMapPainter(
      frame: ValueNotifier(0),
      walk: const AlwaysStoppedAnimation(0),
      geography: chartOf(MapShape.archipelago),
      palette: ChartPalette.of(look),
      language: AppLanguage.en,
      discovered: {for (final l in worldMapLandmarks) l.id},
      legs: const [],
      ahead: null,
      selectedId: '',
      here: worldMapLandmarks.first,
      walking: false,
      walkPath: const [],
      chapterFilter: 0,
      reduceMotion: true,
      chapterColor: (_) => Colors.red,
      fog: ChartFog.wash,
      globe: globe,
      zoomOf: () => globe?.zoom ?? zoom,
    );

Future<void> _pump(
    WidgetTester tester, ChartMapPainter painter, Size size) async {
  await tester.pumpWidget(MaterialApp(
    home: Center(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(painter: painter),
      ),
    ),
  ));
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('the flat chart shades its relief, once it is rendered',
      (tester) async {
    // Before the shading is rendered the chart paints without it.
    await _pump(tester, _painter(zoom: 1), const Size(256, 176));
    final painter = _painter(zoom: 3);
    final shade = await tester.runAsync(painter.prepareShade);
    expect(shade, isNotNull);
    expect(shade!.width, 512);
    expect(shade.height, 352);
    // Kept per chart.
    expect(
        identical(shade, await tester.runAsync(painter.prepareShade)), isTrue);
    for (final zoom in [1.0, 3.0, 6.0]) {
      await _pump(tester, _painter(zoom: zoom), const Size(256, 176));
    }
    await _pump(tester, _painter(zoom: 3, look: MapLook.parchment),
        const Size(256, 176));
  });

  testWidgets('the sphere paints coarse before its skin and wrapped after',
      (tester) async {
    final globe =
        GlobeView.at(const Offset(100, 70), 1.4, const Offset(150, 150));
    final painter = _painter(globe: globe);
    // No skin yet: the coarse sphere, lit.
    await _pump(tester, painter, const Size(300, 300));
    // The skin rendered, the sphere wears it.
    final skin = await tester.runAsync(painter.prepareSkin);
    expect(skin, isNotNull);
    expect(skin!.width, 256 * 3);
    await _pump(tester, painter, const Size(300, 300));
    // Kept: the same skin again for the same look and detail.
    final again = await tester.runAsync(painter.prepareSkin);
    expect(identical(skin, again), isTrue);
    // Closer in, a finer skin.
    final close =
        GlobeView.at(const Offset(100, 70), 5, const Offset(150, 150));
    final closePainter = _painter(globe: close);
    final fine = await tester.runAsync(closePainter.prepareSkin);
    expect(fine!.width, greaterThan(skin.width));
    await _pump(tester, closePainter, const Size(300, 300));
    // Turned, the mesh follows.
    await _pump(
        tester, _painter(globe: close.turned(0.4, -0.2)), const Size(300, 300));
  });
}
