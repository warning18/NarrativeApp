// The seam between two kits (kit_blend.dart): the new land comes in from the
// right, the old one stays on the left until the seam passes, and a pair of
// kits can be blended at any progress. With UX_SHOTS (a folder) set it saves
// the blend of the desert into the ruins as pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/kit_blend.dart';
import 'package:narrative_data_app/widgets/side_view/ruins_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void main() {
  group('the cover', () {
    test('nothing at the start, everything at the end', () {
      for (final c in [0.0, 0.3, 0.6, 1.0]) {
        expect(kitBlendCover(c, 0), 0, reason: 'column $c');
        expect(kitBlendCover(c, 1), 1, reason: 'column $c');
      }
    });

    test('the new land is further in on the right than on the left', () {
      for (final p in [0.2, 0.4, 0.6, 0.8]) {
        expect(
            kitBlendCover(0.9, p), greaterThanOrEqualTo(kitBlendCover(0.1, p)),
            reason: 'progress $p');
      }
      // Half way the right edge is covered and the left edge is not.
      expect(kitBlendCover(1, 0.5), 1);
      expect(kitBlendCover(0, 0.5), 0);
    });

    test('the cover only grows with the progress', () {
      for (final c in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        var last = 0.0;
        for (var p = 0.0; p <= 1.0; p += 0.05) {
          final now = kitBlendCover(c, p);
          expect(now, greaterThanOrEqualTo(last), reason: '$c at $p');
          last = now;
        }
      }
    });
  });

  group('the layer', () {
    SideLayer counting(List<int> log, int id) =>
        SideLayer(0.5, (c, s, scroll, t, u) => log.add(id));

    test('is the old kit before the seam, the new one after, both between', () {
      final log = <int>[];
      final layer = kitBlend(
          [counting(log, 1)], [counting(log, 2)], (scroll) => scroll / 1000);
      final canvas = ui.Canvas(ui.PictureRecorder());
      const size = ui.Size(360, 190);
      final unit = size.height / sideViewRows;
      layer.paint(canvas, size, 0, 1, unit);
      expect(log, [1]);
      log.clear();
      layer.paint(canvas, size, 500, 1, unit);
      expect(log, [1, 2]);
      log.clear();
      layer.paint(canvas, size, 1000, 1, unit);
      expect(log, [2]);
    });

    test('paints the real kits at any progress and size', () {
      final layer = kitBlend(desertLayers(progress: 0.5),
          ruinsLayers(progress: 0.5), (scroll) => scroll / 400);
      for (final size in const [
        ui.Size(360, 190),
        ui.Size(800, 190),
        ui.Size(120, 72)
      ]) {
        for (var s = 0.0; s <= 400; s += 50) {
          layer.paint(ui.Canvas(ui.PictureRecorder()), size, s, 1.3,
              size.height / sideViewRows);
        }
      }
    });
  });

  final dir = Platform.environment['UX_SHOTS'];
  if (dir != null) {
    testWidgets('the desert into the ruins, as pictures', (tester) async {
      final key = GlobalKey();
      final layer = kitBlend(desertLayers(progress: 0.5),
          ruinsLayers(progress: 0.5), (scroll) => scroll);
      await tester.binding.setSurfaceSize(const Size(360, 190));
      for (final p in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 360,
              height: 190,
              child: CustomPaint(
                  painter: _Frame(layer, p), size: const Size(360, 190)),
            ),
          ),
        ));
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(dir).createSync(recursive: true);
          File('$dir/blend-${(p * 100).round()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}

class _Frame extends CustomPainter {
  _Frame(this.layer, this.progress);
  final SideLayer layer;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    layer.paint(canvas, size, progress, 1.3, size.height / sideViewRows);
  }

  @override
  bool shouldRepaint(_Frame old) => old.progress != progress;
}
