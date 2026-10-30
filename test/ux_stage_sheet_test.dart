// UX picture tool (not a guard): the fight stages the app draws today, one
// picture each, by day and clear, then one stage under each sky and light.
// UX_SHOTS=<folder> flutter test test/ux_stage_sheet_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/widgets/fight_backdrop.dart';

Future<void> _save(WidgetTester tester, String path, FightStage stage,
    {WeatherKind? sky, double light = 1}) async {
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    paintFightBackdrop(canvas, const ui.Size(360, 640),
        stage: stage,
        sky: sky,
        anomalyId: null,
        t: 4.2,
        level: 0,
        light: light);
    final picture = recorder.endRecording();
    final image = await picture.toImage(360, 640);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the stages today', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    for (final stage in FightStage.values) {
      await _save(tester, '$dir/stage-${stage.name}.png', stage);
      for (final (name, light) in const [
        ('day', 1.0),
        ('dusk', 0.75),
        ('night', 0.45)
      ]) {
        await _save(tester, '$dir/smooth-${stage.name}-$name.png', stage,
            light: light);
      }
    }
    for (final sky in WeatherKind.values) {
      await _save(tester, '$dir/sky-${sky.name}.png', FightStage.fields,
          sky: sky);
    }
    await _save(tester, '$dir/cliffs-rain.png', FightStage.cliffs,
        sky: WeatherKind.rain);
    await _save(tester, '$dir/dunes-dusk.png', FightStage.dunes, light: 0.75);
    for (final (name, light) in const [
      ('dusk', 0.75),
      ('night', 0.45),
      ('dark', 0.15)
    ]) {
      await _save(tester, '$dir/light-$name.png', FightStage.fields,
          light: light);
    }
  });
}
