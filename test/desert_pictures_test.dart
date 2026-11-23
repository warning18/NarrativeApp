// The desert road crossing's painted layers (desert_pictures.dart): the same
// stack at the same speeds as the code kit, painted from the code kit until
// the pictures are in, and the pictures tile at any scroll.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/desert_pictures.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void paintAll(List<SideLayer> layers, double scroll) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const size = Size(412, 190);
  for (final l in layers) {
    l.paint(canvas, size, scroll * l.speed, 1, size.height / sideViewRows);
  }
  recorder.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(DesertPictures.reset);

  test('the painted stack has the code stack\'s layers at its speeds', () {
    final code = desertLayers(progress: 0.4);
    final painted = desertLayers(progress: 0.4, painted: true);
    expect([for (final l in painted) l.speed], [for (final l in code) l.speed]);
    // Only the road crossing asks for the pictures.
    expect(crossingLayers('desert', 0.4).length, code.length);
  });

  test('the four files are there, the far layer ends where the sand begins',
      () {
    final sizes = {
      'sky': (160, 52),
      'far': (208, 24),
      'mid': (192, 20),
      'near': (260, 24),
    };
    expect(DesertPictures.far.top + sizes['far']!.$2, DesertPictures.sandRow);
    for (final e in sizes.entries) {
      expect(File('assets/visuals/crossing/desert/${e.key}.png').existsSync(),
          isTrue,
          reason: e.key);
    }
  });

  test('until the pictures are in the code kit paints, then the pictures',
      () async {
    expect(DesertPictures.loaded, isFalse);
    paintAll(desertLayers(progress: 0.5, painted: true), 0);
    await DesertPictures.preload();
    expect(DesertPictures.loaded, isTrue);
    for (final scroll in [0.0, 37.0, 1234.5, 99999.0]) {
      paintAll(desertLayers(progress: 0.5, painted: true), scroll);
    }
  });
}
