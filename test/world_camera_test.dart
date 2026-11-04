// The world camera (world_camera.dart): a kit by the region the x is in, a
// seam at the border of two kits, the same picture for the same x.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/region_strip.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/side_view/world_camera.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final strips = RegionStrips.build(
      geo: geo, chart: chartOf(MapShape.story), story: story);
  final camera = WorldCamera(strips.zones);
  final land = [
    for (final z in strips.zones)
      if (z.strip == StripKind.land) z,
  ];

  void paint(List<SideLayer> layers, {double scroll = 90}) {
    const size = ui.Size(360, 190);
    final canvas = ui.Canvas(ui.PictureRecorder());
    for (final l in layers) {
      l.paint(canvas, size, scroll * l.speed, 1.3, size.height / sideViewRows);
    }
  }

  test('a place is in the kit of its region', () {
    for (final z in land) {
      final mid = (z.start + z.end) / 2;
      // Away from every seam, the region's own kit.
      if (camera.seamAt(mid) != null) continue;
      expect(camera.kitAt(mid), z.kit, reason: z.zoneId);
    }
    expect(camera.kitAt(-50), land.first.kit);
    expect(camera.kitAt(5000), land.last.kit);
  });

  test('a seam stands at each border where the kit changes, and only there',
      () {
    var changes = 0;
    for (var i = 1; i < land.length; i++) {
      if (land[i - 1].kit != land[i].kit) changes++;
    }
    expect(camera.seams, hasLength(changes));
    for (final s in camera.seams) {
      expect(s.from, isNot(s.to));
      expect(s.end - s.start, closeTo(2 * worldSeamHalf, 1e-9));
      expect(camera.seamAt((s.start + s.end) / 2), isNotNull);
      expect(camera.seamAt(s.start - 1), isNull);
      expect(camera.seamAt(s.end + 1), isNull);
      expect(s.progressAt(s.start), 0);
      expect(s.progressAt(s.end), 1);
      expect(s.progressAt((s.start + s.end) / 2), closeTo(0.5, 1e-9));
    }
  });

  test('a walk along the whole strip is painted, seam or not', () {
    final end = land.last.end;
    for (var x = -10.0; x <= end + 10; x += 2.5) {
      final layers = camera.layersAt(x);
      expect(layers, isNotNull, reason: 'x $x');
      paint(layers!);
    }
  });

  test('a seam is one blended layer, the rest the kit\'s own layers', () {
    final s = camera.seams.first;
    expect(camera.layersAt((s.start + s.end) / 2), hasLength(1));
    final before = camera.layersAt(s.start - 3)!;
    expect(before.length, greaterThan(1));
  });

  test('the same x is the same picture on every launch', () {
    for (final x in [0.0, 20.0, 150.0, 300.0, 600.0]) {
      expect(camera.windowAt(x), WorldCamera(strips.zones).windowAt(x));
      expect(camera.kitAt(x), WorldCamera(strips.zones).kitAt(x));
    }
  });

  test('a strip with no land has no kit and no layers', () {
    final none = WorldCamera(const []);
    expect(none.kitAt(3), isNull);
    expect(none.layersAt(3), isNull);
  });

  final dir = Platform.environment['UX_SHOTS'];
  if (dir != null) {
    testWidgets('the land strip walked, as pictures', (tester) async {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(360, 190));
      final xs = <double>[
        for (final s in camera.seams) ...[
          s.start - 4,
          (s.start + s.end) / 2,
          s.end + 4
        ],
      ];
      for (var i = 0; i < xs.length; i++) {
        final layers = camera.layersAt(xs[i])!;
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 360,
              height: 190,
              child: CustomPaint(painter: _Layers(layers)),
            ),
          ),
        ));
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(dir).createSync(recursive: true);
          File('$dir/cam-${i.toString().padLeft(2, '0')}-${xs[i].round()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}

class _Layers extends CustomPainter {
  _Layers(this.layers);
  final List<SideLayer> layers;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in layers) {
      l.paint(canvas, size, 90 * l.speed, 1.3, size.height / sideViewRows);
    }
  }

  @override
  bool shouldRepaint(_Layers old) => true;
}
