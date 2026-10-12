// Renders the game's own chart painter on two geographies, for a side by
// side: chart B (the Ring, the game's default) and the generated world
// (chart_fmg.dart, from fmg_to_chart.py), with the design's villages, seats,
// bridges and trade roads carried over from B onto the new places.
//
//   flutter test tool/fmg_chart/preview_test.dart
//
// Writes the PNGs to $FMG_OUT (default build/fmg_chart/). Not part of the
// suite (it lives under tool/).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_worlds.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';

import 'chart_fmg.dart';

/// Where [p] lands on the new chart when the landmarks move from [from] to
/// [to]: every landmark's shift, weighted by 1/d^2 (Shepard), so a village
/// stays about where it was to its neighbours.
Offset warp(Offset p, Map<String, Offset> from, Map<String, Offset> to) {
  var sx = 0.0, sy = 0.0, sw = 0.0;
  for (final e in from.entries) {
    final t = to[e.key];
    if (t == null) continue;
    final d = (p - e.value).distanceSquared;
    if (d < 0.01) return t;
    final w = 1 / (d * d);
    sx += (t.dx - e.value.dx) * w;
    sy += (t.dy - e.value.dy) * w;
    sw += w;
  }
  return Offset(p.dx + sx / sw, p.dy + sy / sw);
}

/// [p] if it is on land, else the nearest spot on the nearest coast point's
/// inside (stepped toward the nearest landmark until it is).
Offset onLand(Offset p, ChartGeography g, {bool atSea = false}) {
  bool inLand(Offset q) => g.lands.any((l) => pointInPolygon(q, l));
  if (atSea || inLand(p)) return p;
  var best = g.places.values.first;
  for (final q in g.places.values) {
    if ((q - p).distance < (best - p).distance) best = q;
  }
  var q = p;
  for (var i = 0; i < 40 && !inLand(q); i++) {
    q = Offset.lerp(q, best, 0.08)!;
  }
  return q;
}

ChartGeography carried() {
  final b = chartWorldB;
  Offset move(Offset p, {bool atSea = false}) =>
      onLand(warp(p, b.places, chartWorldFmg.places), chartWorldFmg,
          atSea: atSea);
  return ChartGeography(
    places: chartWorldFmg.places,
    lands: chartWorldFmg.lands,
    rivers: chartWorldFmg.rivers,
    labels: chartWorldFmg.labels,
    zones: chartWorldFmg.zones,
    ranges: chartWorldFmg.ranges,
    features: [
      for (final f in b.features)
        ChartFeature(f.kind, move(f.at, atSea: f.atSea), f.nameEn, f.nameFr,
            noteEn: f.noteEn,
            noteFr: f.noteFr,
            clan: f.clan,
            angle: f.angle,
            landmark: f.landmark,
            atSea: f.atSea),
    ],
    tradeRoads: [
      for (final r in b.tradeRoads)
        (
          warp(r.$1, b.places, chartWorldFmg.places),
          warp(r.$2, b.places, chartWorldFmg.places)
        ),
    ],
  );
}

Future<void> loadFonts() async {
  Future<void> font(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
    }
    await l.load();
  }

  await font('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']);
  await font('Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']);
  await font('PixelifySans',
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']);
}

ChartMapPainter painterFor(ChartGeography g, MapLook look,
        {double zoom = 1, ChartFog fog = ChartFog.none}) =>
    ChartMapPainter(
      frame: ValueNotifier(0),
      walk: const AlwaysStoppedAnimation(0),
      geography: g,
      palette: ChartPalette.of(look),
      language: AppLanguage.en,
      discovered: {for (final l in worldMapLandmarks) l.id},
      legs: roadLegs(const [], {for (final l in worldMapLandmarks) l.id}),
      ahead: null,
      selectedId: '',
      here: null,
      walking: false,
      walkPath: const [],
      chapterFilter: 0,
      reduceMotion: true,
      chapterColor: (_) => const Color(0xFFF2C14E),
      fog: fog,
      zoomOf: () => zoom,
    );

void main() {
  final out = Directory(Platform.environment['FMG_OUT'] ?? 'build/fmg_chart')
    ..createSync(recursive: true);

  Future<void> shoot(
      WidgetTester tester, String name, ChartGeography g, MapLook look,
      {double zoom = 1, ChartFog fog = ChartFog.none}) async {
    final key = GlobalKey();
    final painter = painterFor(g, look, zoom: zoom, fog: fog);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
              width: 256 * 4,
              height: 176 * 4,
              child: CustomPaint(painter: painter)),
        ),
      ),
    ));
    await tester.runAsync(painter.prepareShade);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  }

  testWidgets('chart B and the generated world, side by side', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(256 * 4 * 2, 176 * 4 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final fmg = carried();
    for (final look in [MapLook.night, MapLook.parchment]) {
      await shoot(tester, 'B_${look.name}', chartWorldB, look);
      await shoot(tester, 'FMG_${look.name}', fmg, look);
    }
    // The generated world as the bare data gives it (no carried-over design).
    await shoot(tester, 'FMG_bare_night', chartWorldFmg, MapLook.night);
    // And with the fog of an unfinished chart, as the game opens it.
    await shoot(tester, 'FMG_fogged_night', fmg, MapLook.night,
        fog: ChartFog.uncharted);
    // Counts for the report.
    stdout.writeln(
        'B: lands ${chartWorldB.lands.length} pts ${chartWorldB.lands.fold<int>(0, (a, l) => a + l.length)}, features ${chartWorldB.features.length}, zones ${chartWorldB.zones.length}');
    stdout.writeln(
        'FMG: lands ${fmg.lands.length} pts ${fmg.lands.fold<int>(0, (a, l) => a + l.length)}, features ${fmg.features.length}, zones ${fmg.zones.length}');
    final stranded = [
      for (final f in fmg.features)
        if (!f.atSea && !fmg.lands.any((l) => pointInPolygon(f.at, l))) f.nameEn
    ];
    stdout.writeln('features off land: $stranded');
    final math0 = math.min(1, 2);
    expect(math0, 1);
  });
}
