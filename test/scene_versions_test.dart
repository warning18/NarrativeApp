// Four versions of every scene (docs/proposals/scene-backgrounds.md): the
// order they follow one another in, that every kit paints every version, the
// pixel dissolve between two, and the counter that makes successive scenes of
// a kit follow the order.
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
import 'package:narrative_data_app/widgets/side_view/scene_versions.dart';
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
  group('the order', () {
    test(
        'each round shows all four versions, never the same one twice in a row',
        () {
      for (final seed in ['crash_to_sleeper', 'alster', 'the_cove', '', 'x']) {
        final shown = [for (var i = 0; i < 40; i++) sceneVersionAt(seed, i)];
        for (var round = 0; round < 10; round++) {
          expect(shown.sublist(round * 4, round * 4 + 4).toSet(), {0, 1, 2, 3},
              reason: '$seed round $round');
        }
        for (var i = 1; i < shown.length; i++) {
          expect(shown[i], isNot(shown[i - 1]), reason: '$seed at $i');
        }
      }
    });

    test('the order is the seed\'s, and different seeds order them differently',
        () {
      List<int> first(String seed) =>
          [for (var i = 0; i < 4; i++) sceneVersionAt(seed, i)];
      expect(first('a'), first('a'));
      expect(
          {
            for (final s in ['a', 'b', 'c', 'd', 'e', 'f']) first(s).join()
          }.length,
          greaterThan(1));
    });

    test('successive scenes of a kit follow the seeded order', () {
      SceneVersions.reset();
      final shown = [
        for (var i = 0; i < 8; i++) SceneVersions.next('sea-open')
      ];
      expect(shown.sublist(0, 4).toSet(), {0, 1, 2, 3});
      expect(shown.sublist(4).toSet(), {0, 1, 2, 3});
      // Another kit counts on its own.
      expect(SceneVersions.next('desert'), inInclusiveRange(0, 3));
      SceneVersions.reset();
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
        for (var v = 0; v < sceneVersionCount; v++) {
          for (final size in const [
            ui.Size(360, 190),
            ui.Size(412, 260),
            ui.Size(800, 190),
            ui.Size(120, 72),
          ]) {
            _paint(withSceneVersion(e.value(), e.key, v), size);
          }
        }
      }
    });

    test('a version after the first adds its landmark layer', () {
      for (final e in kits.entries) {
        final base = e.value();
        expect(withSceneVersion(base, e.key, 0), hasLength(base.length),
            reason: e.key);
        for (var v = 1; v < sceneVersionCount; v++) {
          expect(withSceneVersion(base, e.key, v), hasLength(base.length + 1),
              reason: '${e.key} $v');
        }
      }
    });

    test('the crossing builds every terrain at every version', () {
      for (final terrain in crossingSceneTerrains) {
        for (var v = 0; v < sceneVersionCount; v++) {
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
