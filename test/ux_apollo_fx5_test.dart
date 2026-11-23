// Pictures for the last five effects drawn in the Apollo palette (the bolt,
// the meteor, the quake, the smoke, the mana): each caught at four moments, on a dark and a light stage, at the size a fight draws
// them. Writes PNGs only when UX_SHOTS names a folder.
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

  test('five effects on a dark and a light stage', () async {
    if (dir == null) return;
    const cases = <(VfxStyle, String)>[
      (VfxStyle.bolt, 'Electricity'),
      (VfxStyle.meteor, 'Fire'),
      (VfxStyle.quake, 'Earth'),
      (VfxStyle.smoke, 'None'),
      (VfxStyle.mana, 'None'),
    ];
    PixelStrips.preload(allPixelVfxAssets);
    for (var i = 0; i < 200 && !PixelStrips.ready(allPixelVfxAssets); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    for (final c in cases) {
      PixelVfxTints.request(c.$1, paletteFor(c.$1, c.$2));
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));

    const cell = 130.0;
    const cols = 5;
    for (final t in [0.2, 0.5, 0.75, 0.95]) {
      const rows = 1;
      const w = cell * cols;
      const h = cell * rows * 2;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (var band = 0; band < 2; band++) {
        canvas.drawRect(
            Rect.fromLTWH(0, band * cell * rows, w, cell * rows),
            Paint()
              ..color = band == 0
                  ? const Color(0xFF1B1A22)
                  : const Color(0xFFEFE8DA));
        for (var i = 0; i < cases.length; i++) {
          final c = cases[i];
          final x = (i % cols) * cell;
          final y = band * cell * rows + (i ~/ cols) * cell;
          paintPixelBurst(
            canvas,
            style: c.$1,
            palette: paletteFor(c.$1, c.$2),
            tier: VfxTier.strong,
            hit: !supportVfxStyles.contains(c.$1),
            rect: Rect.fromLTWH(x + 20, y + 20, 90, 90),
            sourceRect: Rect.fromLTWH(x - 60, y + 90, 90, 90),
            t: t,
            s: 90,
            extent: 1,
          );
        }
      }
      final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/fx5-$tag-t${(t * 100).round()}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
