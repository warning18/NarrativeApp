// The one-colour pixel glyphs (v1.907, lib/widgets/pixel_glyph.dart): a glyph
// whose file is in the bundle is drawn as that mask, tinted; one whose file
// Art has not delivered yet shows its Material stand-in, same size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/icon_sizes.dart';
import 'package:narrative_data_app/widgets/pixel_glyph.dart';

Widget _app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('the lock is the pixel mask, nearest neighbour, tinted',
      (tester) async {
    expect(File(PixelGlyphs.lock.asset).existsSync(), isTrue);
    await tester.pumpWidget(_app(const PixelGlyph(PixelGlyphs.lock,
        size: IconSize.s32, color: Colors.red)));
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, IconSize.s32);
    expect(image.filterQuality, FilterQuality.none);
    expect(image.color, Colors.red);
    expect(image.colorBlendMode, BlendMode.modulate);
  });

  testWidgets('a glyph without its file shows the Material stand-in',
      (tester) async {
    for (final g in PixelGlyphs.values) {
      if (File(g.asset).existsSync()) continue;
      await tester.pumpWidget(
          _app(PixelGlyph(g, size: IconSize.s16, color: Colors.blue)));
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(g.fallback), findsOneWidget, reason: g.name);
    }
  });

  test('every glyph file that exists is a 16x16 palette PNG', () {
    for (final g in PixelGlyphs.values) {
      final f = File(g.asset);
      if (!f.existsSync()) continue;
      final b = f.readAsBytesSync();
      final w = (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
      final h = (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23];
      expect([w, h], [16, 16], reason: g.file);
      expect(b[25], 3, reason: '${g.file} must be PNG8');
    }
  });
}
