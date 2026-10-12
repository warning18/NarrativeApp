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

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/chart_worlds.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';

import 'chart_fmg.dart';
import 'chart_story.dart';

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

/// The story world with the features that have a story role, taken from chart B (names, notes, clans) and set
/// where story_world.py puts them.
ChartGeography storyWorld() {
  final g = chartWorldStory;
  final seen = <String>{};
  return ChartGeography(
    places: g.places,
    lands: g.lands,
    rivers: g.rivers,
    labels: g.labels,
    zones: g.zones,
    ranges: g.ranges,
    features: [
      for (final f in chartWorldB.features)
        if (storyFeatureAt['${f.kind.name}|${f.nameEn}'] != null &&
            seen.add('${f.kind.name}|${f.nameEn}'))
          ChartFeature(f.kind, storyFeatureAt['${f.kind.name}|${f.nameEn}']!,
              f.nameEn, f.nameFr,
              noteEn: f.noteEn,
              noteFr: f.noteFr,
              clan: f.clan,
              angle: f.angle,
              landmark: f.landmark,
              atSea: f.atSea),
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
        {double zoom = 1, ChartFog fog = ChartFog.none, GlobeView? globe}) =>
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
      zoomOf: () => globe?.zoom ?? zoom,
      globe: globe,
    );

void main() {
  final out = Directory(Platform.environment['FMG_OUT'] ?? 'build/fmg_chart')
    ..createSync(recursive: true);

  Future<void> shoot(
      WidgetTester tester, String name, ChartGeography g, MapLook look,
      {double zoom = 1, ChartFog fog = ChartFog.none, GlobeView? globe}) async {
    final key = GlobalKey();
    final painter = painterFor(g, look, zoom: zoom, fog: fog, globe: globe);
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
    if (globe != null) await tester.runAsync(painter.prepareSkin);
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

  testWidgets('chart B and the story world, side by side', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(256 * 4 * 2, 176 * 4 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final story = storyWorld();
    for (final look in [MapLook.night, MapLook.parchment]) {
      await shoot(tester, 'B_${look.name}', chartWorldB, look);
      await shoot(tester, 'STORY_${look.name}', story, look);
    }
    await shoot(tester, 'STORY_bare_night', chartWorldStory, MapLook.night);
    await shoot(tester, 'STORY_fogged_night', story, MapLook.night,
        fog: ChartFog.uncharted);
    stdout.writeln(
        'STORY: lands ${story.lands.length} pts ${story.lands.fold<int>(0, (a, l) => a + l.length)}, features ${story.features.length}, zones ${story.zones.length}, ranges ${story.ranges.length}, rivers ${story.rivers.length}');
    final off = [
      for (final f in story.features)
        if (!f.atSea &&
            f.kind != ChartFeatureKind.giant &&
            f.name(AppLanguage.en) != 'The Brig' &&
            f.name(AppLanguage.en) != 'Lowtide' &&
            !story.lands.any((l) => pointInPolygon(f.at, l)))
          f.nameEn
    ];
    stdout.writeln('features off land: $off');
  });

  testWidgets('the story world on the globe, and its climate', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(256 * 4 * 2, 176 * 4 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final story = storyWorld();
    // The whole globe, then turned toward each land.
    final views = {
      'whole': GlobeView.at(const Offset(128, 88), 1, const Offset(128, 88)),
      'north': GlobeView.at(const Offset(130, 34), 2.4, const Offset(128, 88)),
      'south': GlobeView.at(const Offset(110, 134), 2.4, const Offset(128, 88)),
    };
    for (final e in views.entries) {
      await shoot(tester, 'GLOBE_story_${e.key}', story, MapLook.night,
          globe: e.value);
    }
    await shoot(tester, 'GLOBE_B_whole', chartWorldB, MapLook.night,
        globe: views['whole']);
    // Where each place sits and what the game's climate model makes of it.
    for (final entry in [('B', chartWorldB), ('STORY', story)]) {
      final g = entry.$2;
      final climate = ChartClimate.of(g);
      stdout.writeln(
          '--- climate on ${entry.$1}: id lat lon | biome temp humidity elev');
      for (final id in [
        'camp',
        'quarter',
        'spire',
        'akagiri',
        'reliquary',
        'highhearth',
        'rimewell',
        'shore',
        'wrack',
        'kindly',
        'cloister',
        'candlehold',
        'hovel',
        'crash',
        'sleeper',
        'wells',
        'wharf',
        'upper',
        'storm'
      ]) {
        final p = g.places[id]!;
        final (lon, lat) = GlobeView.lonLatOf(p);
        final c = climate.sample(p);
        stdout.writeln(
            '$id ${(lat * 180 / math.pi).toStringAsFixed(0)} ${(lon * 180 / math.pi).toStringAsFixed(0)} | ${c.biome} ${c.temperature.toStringAsFixed(0)}C hum ${c.humidity.toStringAsFixed(2)} elev ${c.elevation.toStringAsFixed(2)}');
      }
    }
    // The climate down a line of the globe, pole to pole: Earth's bands.
    final climate = ChartClimate.of(story);
    stdout
        .writeln('--- climate bands on STORY: spot lat | biome temp humidity');
    for (final e in {
      'north: the Frost Reach': const Offset(130, 14),
      'north: the Ash Flats': const Offset(135, 36),
      'north: the Cove': const Offset(121, 44),
      'tropics: the Lantern Isles': const Offset(56, 77),
      'east land, dry north': const Offset(222, 68),
      'east land, jungle on the equator': const Offset(222, 92),
      'east land, temperate south': const Offset(222, 118),
      'equator: Saltmouth': const Offset(156, 92),
      'subtropics: the Waste': const Offset(125, 112),
      'temperate: Alster': const Offset(87, 131),
      'cool: the Old Continent south': const Offset(150, 140),
      'west land, dry coast': const Offset(26, 108),
      'west land, temperate': const Offset(26, 136),
      'south pole land': const Offset(150, 162),
    }.entries) {
      final (_, lat) = GlobeView.lonLatOf(e.value);
      final c = climate.sample(e.value);
      stdout.writeln(
          '${e.key}: ${(lat * 180 / math.pi).toStringAsFixed(0)} | ${c.biome} ${c.temperature.toStringAsFixed(0)}C hum ${c.humidity.toStringAsFixed(2)}');
    }
    // The lands' extent and their margin to the chart's edges.
    for (final entry in [('B', chartWorldB), ('STORY', story)]) {
      var x0 = 999.0, x1 = -1.0, y0 = 999.0, y1 = -1.0;
      for (final l in entry.$2.lands) {
        for (final p in l) {
          x0 = math.min(x0, p.dx);
          x1 = math.max(x1, p.dx);
          y0 = math.min(y0, p.dy);
          y1 = math.max(y1, p.dy);
        }
      }
      stdout.writeln(
          '${entry.$1} land extent x ${x0.toStringAsFixed(0)}..${x1.toStringAsFixed(0)} of 256, y ${y0.toStringAsFixed(0)}..${y1.toStringAsFixed(0)} of 176 (margins ${x0.toStringAsFixed(0)} ${(256 - x1).toStringAsFixed(0)} ${y0.toStringAsFixed(0)} ${(176 - y1).toStringAsFixed(0)})');
    }
  });

  testWidgets('the story world turning on the globe', (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(256 * 4 * 2, 176 * 4 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final story = storyWorld();
    // Stills: each land, then the whole sphere in both looks.
    final stills = {
      'west': GlobeView.at(const Offset(45, 105), 1.9, const Offset(128, 88)),
      'east': GlobeView.at(const Offset(205, 85), 1.9, const Offset(128, 88)),
      'polar_south':
          GlobeView.at(const Offset(140, 150), 2.2, const Offset(128, 88)),
      'crossing':
          GlobeView.at(const Offset(135, 75), 1.9, const Offset(128, 88)),
    };
    for (final e in stills.entries) {
      await shoot(tester, 'GLOBE_story_${e.key}', story, MapLook.night,
          globe: e.value);
    }
    await shoot(tester, 'GLOBE_story_whole_parchment', story, MapLook.parchment,
        globe: GlobeView.at(const Offset(128, 88), 1, const Offset(128, 88)));
    // A turn of the sphere, east to west, tilted a little to the north, in both looks.
    for (final look in [MapLook.night, MapLook.parchment]) {
      for (var i = 0; i <= 18; i++) {
        final lon = (80 - i * 160 / 18) * math.pi / 180;
        final view = GlobeView(
            lon0: lon,
            lat0: 0.22,
            radius: GlobeView.baseRadius * 1.0,
            centre: const Offset(128, 88));
        await shoot(tester, 'TURN_${look.name}_${i.toString().padLeft(2, '0')}',
            story, look,
            globe: view);
      }
    }
  });
}
