// Four windows of every scene's kit: the fixed window of an x on the strip,
// that every kit paints every window, and the pixel dissolve between two.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart' show SeaWaters;
import 'package:narrative_data_app/widgets/side_view/cliffs_kit.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/fen_kit.dart';
import 'package:narrative_data_app/widgets/side_view/frost_kit.dart';
import 'package:narrative_data_app/widgets/side_view/ruins_kit.dart';
import 'package:narrative_data_app/widgets/side_view/scene_windows.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/street_view/street_facade.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

void _paint(List<SideLayer> layers, ui.Size size, {double t = 1.3}) {
  final canvas = ui.Canvas(ui.PictureRecorder());
  final unit = size.height / sideViewRows;
  for (final layer in layers) {
    layer.paint(canvas, size, 120, t, unit);
  }
}

void main() {
  group('the windows', () {
    test('a window is a fixed stretch of the strip, the four in turn', () {
      expect(
          [for (var i = 0; i < 8; i++) sceneWindowAt(i * sceneWindowSpan + 1)],
          [0, 1, 2, 3, 0, 1, 2, 3]);
      // Anywhere inside a stretch is the same window.
      expect(sceneWindowAt(0), sceneWindowAt(sceneWindowSpan - 0.01));
      expect(sceneWindowAt(sceneWindowSpan), 1);
      // Before the strip's start it still has one.
      expect(sceneWindowAt(-1), 3);
    });

    test('a scene with no x has a fixed window of its id', () {
      for (final id in ['crash_to_sleeper', 'alster', '', 'x']) {
        expect(sceneWindowOfId(id), sceneWindowOfId(id));
        expect(sceneWindowOfId(id), inInclusiveRange(0, 3));
      }
      expect(
          {
            for (final s in ['a', 'b', 'c', 'd', 'e', 'f']) sceneWindowOfId(s)
          }.length,
          greaterThan(1));
    });

    test('a walk along a path passes its stops in order', () {
      const path = [10.0, 20.0, 50.0];
      expect(pathXAt(path, 0), 10);
      expect(pathXAt(path, 0.5), 20);
      expect(pathXAt(path, 0.75), 35);
      expect(pathXAt(path, 1), 50);
      expect(pathXAt(path, 2), 50);
      expect(pathXAt(const [7.0], 0.4), 7);
      expect(pathXAt(const [], 0.4), isNull);
    });

    test('a long road shows its windows in turn, the same every time', () {
      // 40 units of road over 4 days: each day a different window.
      const path = [100.0, 140.0];
      List<int> days() => [
            for (var d = 0; d < 4; d++)
              sceneWindowAt(pathXAt(path, (d + 0.5) / 4)!)
          ];
      expect(days(), days());
      expect(days().toSet().length, greaterThan(2));
    });
  });

  group('the camera at x', () {
    test('the land pans with x, with no jump at a window border', () {
      final seen = <double>[];
      final probe = [
        SideLayer(1, (c, size, scroll, t, u) => seen.add(scroll)),
      ];
      const size = ui.Size(360, 190);
      final canvas = ui.Canvas(ui.PictureRecorder());
      void at(double x) =>
          withSceneAt(probe, 'desert', x).first.paint(canvas, size, 0, 1, 1);
      // Across the border between two windows the offset runs on.
      at(sceneWindowSpan - 0.5);
      at(sceneWindowSpan + 0.5);
      expect(seen[0],
          closeTo((sceneWindowSpan - 0.5) / sceneWindowSpan * 360, 1e-6));
      expect(seen[1] - seen[0], closeTo(1 / sceneWindowSpan * 360, 1e-6));
    });

    test('the landmark of the window shows unless the camera is on the move',
        () {
      final base = desertLayers(progress: 0.5);
      // Window 1 has its landmark; window 0 has none.
      expect(withSceneAt(base, 'desert', sceneWindowSpan + 1),
          hasLength(base.length + 1));
      expect(withSceneAt(base, 'desert', 1), hasLength(base.length));
      expect(withSceneAt(base, 'desert', sceneWindowSpan + 1, landmark: 0),
          hasLength(base.length));
      for (final a in [0.0, 0.3, 1.0]) {
        for (final layer
            in withSceneAt(base, 'desert', sceneWindowSpan + 1, landmark: a)) {
          layer.paint(ui.Canvas(ui.PictureRecorder()), const ui.Size(360, 190),
              90, 1.3, 190 / sideViewRows);
        }
      }
    });
  });

  group('the kits', () {
    final kits = <String, List<SideLayer> Function()>{
      'desert': () => desertLayers(progress: 0.5),
      'ruins': () => ruinsLayers(progress: 0.5),
      'frost': () => frostLayers(progress: 0.5),
      'fen': () => fenLayers(progress: 0.5),
      'cliffs': () => cliffsLayers(progress: 0.5),
      for (final w in SeaWaters.values)
        'sea-${w.name}': () => seaLayers(waters: w),
      for (final s in FacadeStyle.values)
        'street-${s.name}': () => streetLayers(style: s, phase: DayPhase.day),
    };

    test('every kit paints every version at any size', () {
      for (final e in kits.entries) {
        for (var v = 0; v < sceneWindowCount; v++) {
          for (final size in const [
            ui.Size(360, 190),
            ui.Size(412, 260),
            ui.Size(800, 190),
            ui.Size(120, 72),
          ]) {
            _paint(withSceneWindow(e.value(), e.key, v), size);
          }
        }
      }
    });

    test('a version after the first adds its landmark layer', () {
      for (final e in kits.entries) {
        final base = e.value();
        expect(withSceneWindow(base, e.key, 0), hasLength(base.length),
            reason: e.key);
        for (var v = 1; v < sceneWindowCount; v++) {
          expect(withSceneWindow(base, e.key, v), hasLength(base.length + 1),
              reason: '${e.key} $v');
        }
      }
    });

    test('the crossing builds every terrain at every version', () {
      for (final terrain in crossingSceneTerrains) {
        for (var v = 0; v < sceneWindowCount; v++) {
          _paint(crossingLayers(terrain, 0.4, version: v),
              const ui.Size(360, 190));
        }
      }
    });
  });

  group('the dissolve', () {
    SideLayer counting(List<int> log, int id) =>
        SideLayer(0.5, (c, s, scroll, t, u) => log.add(id));

    test('starts as the old version, ends as the new one', () {
      final log = <int>[];
      final layer =
          sceneDissolve([counting(log, 1)], [counting(log, 2)], seconds: 1);
      final canvas = ui.Canvas(ui.PictureRecorder());
      const size = ui.Size(360, 190);
      final unit = size.height / sideViewRows;
      layer.paint(canvas, size, 0, 10, unit);
      // At the start the old one is drawn, and the new one under a mask that
      // is still empty (it is drawn, clipped away).
      expect(log.first, 1);
      log.clear();
      layer.paint(canvas, size, 0, 10.5, unit);
      expect(log, [1, 2]);
      log.clear();
      layer.paint(canvas, size, 0, 12, unit);
      // Done: only the new version.
      expect(log, [2]);
    });
  });
}
