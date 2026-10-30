// UX picture tool (not a guard): every scene's four versions side by side as
// one strip per hour, for the backdrops page.
// UX_SHOTS=<folder> flutter test test/ux_scene_versions_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;

import 'ux_scene_versions_parts.dart';

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the scene versions', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final phase in [DayPhase.day, DayPhase.dusk, DayPhase.night]) {
        for (final id in sceneIds) {
          const size = ui.Size(360, 190);
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          canvas.scale(2);
          for (var v = 0; v < sceneVersions; v++) {
            canvas.save();
            canvas.translate(v * size.width, 0);
            canvas.clipRect(ui.Offset.zero & size);
            paintSceneVersion(canvas, size, id, v, phase: phase);
            canvas.restore();
          }
          final image =
              await recorder.endRecording().toImage(720 * sceneVersions, 380);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/strip-$id-${phase.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    });
  });
}
