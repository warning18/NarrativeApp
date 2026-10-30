// UX picture tool (not a guard): the new stage mocks, one picture each, and
// a few under dusk, night and rain.
// UX_SHOTS=<folder> flutter test test/ux_stage_variants_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'ux_stage_variants_parts.dart';

Future<void> _save(WidgetTester tester, String path, NewStage stage,
    {double light = 1, bool rain = false}) async {
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    paintNewStage(canvas, const ui.Size(360, 640), stage,
        light: light, rain: rain);
    final picture = recorder.endRecording();
    final image = await picture.toImage(360, 640);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the new stages', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    for (final stage in NewStage.values) {
      await _save(tester, '$dir/new-${stage.name}.png', stage);
    }
    await _save(tester, '$dir/new-caravanRoad-dusk.png', NewStage.caravanRoad,
        light: 0.75);
    await _save(tester, '$dir/new-ruins-night.png', NewStage.ruins,
        light: 0.45);
    await _save(tester, '$dir/new-woods-rain.png', NewStage.woods, rain: true);
    await _save(tester, '$dir/new-quay-night.png', NewStage.quay, light: 0.6);
  });
}
