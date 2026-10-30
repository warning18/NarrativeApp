// UX picture tool (not a guard): every side-view scene kit the app draws
// behind its scenes (the crossings, detours, memories, the sea, the streets),
// as a still background at day, dusk and night, for the backgrounds page.
// UX_SHOTS=<folder> flutter test test/ux_backgrounds_scenes_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/widgets/sea_battlefield.dart' show SeaWaters;
import 'package:narrative_data_app/widgets/side_view/cliffs_kit.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/fen_kit.dart';
import 'package:narrative_data_app/widgets/side_view/frost_kit.dart';
import 'package:narrative_data_app/widgets/side_view/kit_hour.dart';
import 'package:narrative_data_app/widgets/side_view/ruins_kit.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/street_view/street_facade.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Future<void> _save(WidgetTester tester, String path, List<SideLayer> layers,
    SideLayer? overlay) async {
  await tester.runAsync(() async {
    const size = ui.Size(360, 190);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(2);
    final unit = size.height / sideViewRows;
    for (final layer in layers) {
      layer.paint(canvas, size, 0, 1.3, unit);
    }
    overlay?.paint(canvas, size, 0, 1.3, unit);
    final image = await recorder.endRecording().toImage(720, 380);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the scene kits', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    // The canvas is painted at twice its size: the scene is 360 x 190 logical.
    tester.view.devicePixelRatio = 1;
    final kits = <String, List<SideLayer> Function()>{
      'desert': () => desertLayers(progress: 0.3),
      'ruins': () => ruinsLayers(progress: 0.3),
      'frost': () => frostLayers(progress: 0.3),
      'fen': () => fenLayers(progress: 0.3),
      'cliffs': () => cliffsLayers(progress: 0.3),
    };
    for (final phase in [DayPhase.day, DayPhase.dusk, DayPhase.night]) {
      for (final e in kits.entries) {
        await _save(tester, '$dir/scene-${e.key}-${phase.name}.png',
            withHourStars(e.value(), phase), hourWash(phase));
      }
      for (final waters in SeaWaters.values) {
        await _save(tester, '$dir/scene-sea-${waters.name}-${phase.name}.png',
            withHourStars(seaLayers(waters: waters), phase), hourWash(phase));
      }
      for (final style in FacadeStyle.values) {
        await _save(
            tester,
            '$dir/scene-street-${style.name}-${phase.name}.png',
            streetLayers(style: style, phase: phase),
            streetOverlay(style: style, phase: phase));
      }
    }
  });
}
