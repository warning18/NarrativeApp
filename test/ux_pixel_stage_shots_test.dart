// UX picture tool (not a guard): the fight stages redrawn in the scenes' pixel
// style (ux_pixel_stage_parts.dart), one picture each at day, dusk and night.
// UX_SHOTS=<folder> flutter test test/ux_pixel_stage_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;

import 'ux_pixel_stage_parts.dart';

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the pixel stages', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final phase in [DayPhase.day, DayPhase.dusk, DayPhase.night]) {
        for (final stage in PStage.values) {
          const size = ui.Size(360, 640);
          final recorder = ui.PictureRecorder();
          paintPixelStage(ui.Canvas(recorder), size, stage, phase: phase);
          final image = await recorder.endRecording().toImage(360, 640);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/combat-${stage.name}-${phase.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    });
  });
}
