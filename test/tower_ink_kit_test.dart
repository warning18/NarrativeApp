// The Tower's ink kit (v1.1004): the sprite recolour rule, and its cache.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_images.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

void main() {
  const greys = {0x090A14, 0x202E37, 0x394A50, 0x8B9BA0, 0xEBEDE9};
  const red = 0xB0141C;

  test('a sprite recolours to the five greys, one pixel of ink, a little red',
      () {
    const w = 8, h = 8;
    final src = Uint8List(w * h * 4);
    for (var y = 2; y < 6; y++) {
      for (var x = 2; x < 6; x++) {
        final o = (y * w + x) * 4;
        // A gradient of greys, with one clearly red pixel.
        final v = 40 + (y * 4 + x) * 12;
        src[o] = v;
        src[o + 1] = v;
        src[o + 2] = v;
        src[o + 3] = 255;
      }
    }
    const o = (3 * w + 3) * 4;
    src[o] = 200;
    src[o + 1] = 20;
    src[o + 2] = 20;
    final out = inkRecolour(src, w, h);
    expect(out.length, (w + 2) * (h + 2) * 4);
    var reds = 0, solid = 0;
    for (var i = 0; i < out.length; i += 4) {
      if (out[i + 3] == 0) continue;
      solid++;
      final rgb = (out[i] << 16) | (out[i + 1] << 8) | out[i + 2];
      if (rgb == red) {
        reds++;
      } else {
        expect(greys, contains(rgb), reason: 'pixel ${i ~/ 4}');
      }
    }
    expect(reds, 1, reason: 'the one red pixel stays red');
    // 16 sprite pixels and a ring of 5 x 5 + ... = 36 - 16 = 20 around them.
    expect(solid, 36);
    // The corner of the result is empty: the ring stops one pixel out.
    expect(out[3], 0);
  });

  test('an empty sprite stays empty', () {
    final out = inkRecolour(Uint8List(4 * 4 * 4), 4, 4);
    expect(out.every((b) => b == 0), isTrue);
  });

  test('a sprite is recoloured once: the second use is the cache', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    InkSprites.reset();
    const asset = 'assets/visuals/heroes/warrior_stand_east.png';
    final first = await InkSprites.of(asset);
    expect(InkSprites.recolours, 1);
    final second = await InkSprites.of(asset);
    expect(InkSprites.recolours, 1, reason: 'the cache is hit');
    expect(identical(first, second), isTrue);
    // The result is the sprite plus a pixel of ink on each side.
    expect(first.width, greaterThan(2));
  });

  test('the frames are decoded once', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    InkImages.reset();
    await InkImages.preload();
    expect(InkImages.ready, isTrue);
    final n = InkImages.decodes;
    expect(n, 2);
    await InkImages.preload();
    expect(InkImages.decodes, n, reason: 'a second preload decodes nothing');
  });
}
