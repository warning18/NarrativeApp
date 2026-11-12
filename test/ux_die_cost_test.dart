// What a roll costs the frame (v1.952): four solids tumbling, full (glyph
// plaques on the facets) and cheap (the slow-phone drawing: none, and a
// shorter tumble), against the flat polygon the slow phone used to get.
// Prints the build, layout and paint time of a frame when DIE_COST=1 (the
// numbers are the PR's); the plain run only checks they draw.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_poly3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

List<DieCubeFace> _faces(int n) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(
            glyph: Text('${i + 1}'), color: FaceKind.values[i % 6].color)
    ];

void main() {
  final report = Platform.environment['DIE_COST'] == '1';

  for (final (shape, n) in [(DieShape.d20, 20), (DieShape.d12, 12)]) {
    testWidgets('four ${shape.name} tumbling: frame cost', (tester) async {
      Widget four(Widget Function(double t) die, double t) => Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(children: [
              for (var i = 0; i < 4; i++)
                SizedBox(width: 130, height: 130, child: die(t)),
            ]),
          );
      Widget solid(double t, {required bool glyphs}) => PolyDie3D(
            shape: shape,
            faces: _faces(n),
            skin: dieSkinOf('tearglass_die'),
            size: 80,
            t: t,
            showGlyphs: glyphs,
            turns: glyphs ? null : 1.2,
          );
      Widget flat(double t) => PolyDie(
          shape: shape,
          size: 80,
          skin: dieSkinOf('tearglass_die'),
          progress: t,
          still: true);

      final results = <String, double>{};
      for (final (name, build) in <(String, Widget Function(double))>[
        ('flat polygon (the old slow-phone die)', flat),
        ('solid, full', (t) => solid(t, glyphs: true)),
        ('solid, cheap (slow phone)', (t) => solid(t, glyphs: false)),
      ]) {
        // Warm up, then 90 frames of the tumble.
        for (var i = 0; i < 10; i++) {
          await tester.pumpWidget(four(build, i / 100));
        }
        final watch = Stopwatch()..start();
        const frames = 90;
        for (var i = 0; i < frames; i++) {
          await tester.pumpWidget(four(build, i / frames));
        }
        watch.stop();
        results[name] = watch.elapsedMicroseconds / frames / 1000;
        expect(tester.takeException(), isNull);
      }
      if (report) {
        results.forEach((k, v) => debugPrint(
            '${shape.name} x4  $k: ${v.toStringAsFixed(2)} ms a frame'));
      }
    });
  }
}
