// The fight's effects in pixel art (v1.221, see widgets/pixel_vfx.dart):
// every style has a plan of strips that exist, the strips are recoloured to
// an element's palette, and a burst draws once its strips are in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/widgets/pixel_sprite.dart';
import 'package:narrative_data_app/widgets/pixel_vfx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every style has a plan, and every strip it names is a file', () {
    for (final style in VfxStyle.values) {
      final plan = pixelPlans[style];
      expect(plan != null || style == VfxStyle.volley, isTrue,
          reason: '${style.name} has no pixel plan');
    }
    for (final asset in allPixelVfxAssets) {
      expect(File('assets/visuals/pixel_fx/$asset.png').existsSync(), isTrue,
          reason: '$asset.png is missing (run tool/gen_fight_fx.py)');
    }
  });

  test('an element recolours the strips; plain steel stays as it is', () {
    expect(PixelVfxTints.tonesFor(paletteForElement('None')), isNull);
    final fire = PixelVfxTints.tonesFor(paletteForElement('Fire'))!;
    expect(fire.length, 4);
    // The middle tone is the palette's own colour.
    expect(fire[1], 0xFF7043);
    expect(fire[0], isNot(fire[2]));
  });

  test('the extent sets the pixel size, from one to four and a half', () {
    // A plain strike on a small card is drawn small, a legendary spell on a
    // big one large.
    expect(pixelSizeFor(40, 0.3), 1);
    expect(pixelSizeFor(90, vfxExtentFor(VfxStyle.slash, 0.85)), 1);
    expect(pixelSizeFor(90, vfxExtentFor(VfxStyle.meteor, 1.45)), 3);
    expect(pixelSizeFor(200, 3), 4.5);
  });

  testWidgets('every style draws in pixel art once its strips are in',
      (tester) async {
    final fire = paletteFor(VfxStyle.slash, 'Fire');
    final plain = paletteFor(VfxStyle.slash, 'None');
    await tester.runAsync(() async {
      PixelStrips.preload(allPixelVfxAssets);
      for (var i = 0; i < 100 && !PixelStrips.ready(allPixelVfxAssets); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(PixelStrips.ready(allPixelVfxAssets), isTrue);
      for (final style in VfxStyle.values) {
        PixelVfxTints.request(style, fire);
      }
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (VfxStyle.values.every((style) => pixelAssetsFor(style)
            .every((a) => PixelVfxTints.of(a, fire) != null))) {
          break;
        }
      }
    });
    for (final palette in [fire, plain]) {
      for (final style in VfxStyle.values) {
        for (final tier in VfxTier.values) {
          for (final t in [0.0, 0.2, 0.5, 0.8, 1.0]) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            final drew = paintPixelBurst(
              canvas,
              style: style,
              palette: palette,
              tier: tier,
              hit: !supportVfxStyles.contains(style),
              rect: const Rect.fromLTWH(100, 200, 90, 90),
              sourceRect: const Rect.fromLTWH(100, 500, 90, 90),
              t: t,
              s: 90,
              extent: 1,
            );
            recorder.endRecording().dispose();
            expect(drew, isTrue,
                reason: '${style.name} ${tier.name} t=$t in pixel art');
          }
        }
      }
    }
  });

  testWidgets('a tinted strip really is recoloured', (tester) async {
    final fire = paletteForElement('Fire');
    late ui.Image steel;
    ui.Image? tinted;
    await tester.runAsync(() async {
      PixelStrips.preload(['vfx_impact']);
      for (var i = 0; i < 100 && PixelStrips.of('vfx_impact') == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      steel = PixelStrips.of('vfx_impact')!;
      PixelVfxTints.of('vfx_impact', fire);
      for (var i = 0; i < 100 && tinted == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        tinted = PixelVfxTints.of('vfx_impact', fire);
      }
    });
    expect(tinted, isNotNull);
    expect(tinted!.width, steel.width);
    expect(tinted!.height, steel.height);
    Future<Set<int>> colours(ui.Image image) async {
      final data =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final out = <int>{};
      for (var i = 0; i < data.lengthInBytes; i += 4) {
        if (data.getUint8(i + 3) == 0) continue;
        out.add((data.getUint8(i) << 16) |
            (data.getUint8(i + 1) << 8) |
            data.getUint8(i + 2));
      }
      return out;
    }

    final before = await tester.runAsync(() => colours(steel));
    final after = await tester.runAsync(() => colours(tinted!));
    expect(before, contains(0xC9D1DC));
    expect(after, isNot(contains(0xC9D1DC)));
    expect(after, contains(0xFF7043));
  });
}
