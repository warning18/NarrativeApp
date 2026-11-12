// Pictures for the Apollo skills palette: four effects (fire, frost, void,
// heal) caught mid-flight on a dark and a light stage. Writes PNGs only when
// UX_SHOTS names a folder.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/widgets/pixel_sprite.dart';
import 'package:narrative_data_app/widgets/pixel_vfx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'shot';

  test('four effects on a dark and a light stage', () async {
    if (dir == null) return;
    final cases = <(VfxStyle, String, double)>[
      (VfxStyle.fireball, 'Fire', .55),
      (VfxStyle.frost, 'Ice', .5),
      (VfxStyle.voidRift, 'Void', .5),
      (VfxStyle.heal, 'None', .45),
      (VfxStyle.lightning, 'Electricity', .4),
      (VfxStyle.splash, 'Water', .5),
    ];
    PixelStrips.preload(allPixelVfxAssets);
    for (var i = 0; i < 200 && !PixelStrips.ready(allPixelVfxAssets); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    for (final c in cases) {
      PixelVfxTints.request(c.$1, paletteFor(c.$1, c.$2));
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));

    const cell = 150.0;
    final w = cell * cases.length;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var row = 0; row < 2; row++) {
      canvas.drawRect(
          Rect.fromLTWH(0, row * cell, w, cell),
          Paint()
            ..color =
                row == 0 ? const Color(0xFF1B1A22) : const Color(0xFFEFE8DA));
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        paintPixelBurst(
          canvas,
          style: c.$1,
          palette: paletteFor(c.$1, c.$2),
          tier: VfxTier.strong,
          hit: !supportVfxStyles.contains(c.$1),
          rect: Rect.fromLTWH(i * cell + 30, row * cell + 30, 90, 90),
          sourceRect: Rect.fromLTWH(i * cell - 60, row * cell + 100, 90, 90),
          t: c.$3,
          s: 90,
          extent: 1,
        );
      }
    }
    final image =
        await recorder.endRecording().toImage(w.toInt(), (cell * 2).toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/fx-$tag.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
