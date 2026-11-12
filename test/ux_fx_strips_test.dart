// The effect strips of v1.915 (Art's): the die landings and the three hit
// strips in the slots of the old ones, the six skill strips (9 frames), their
// tinting by brightness rank and the flame's and heal's fade-out in code.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/pixel_vfx.dart';

(int, int) _size(String path) {
  final b = ByteData.sublistView(File(path).readAsBytesSync());
  return (b.getUint32(16), b.getUint32(20));
}

void main() {
  test('the die landings, the hits and the six skill strips have their frames',
      () {
    for (final k in [
      'strike',
      'ward',
      'bloom',
      'arcs',
      'miasma',
      'shock',
      'drain',
      'fizzle'
    ]) {
      final (w, h) = _size('assets/visuals/pixel_fx/die_$k.png');
      expect((w, h), (320, 40), reason: 'die_$k: 8 frames of 40');
    }
    for (final k in ['crit']) {
      final (w, h) = _size('assets/visuals/pixel_fx/vfx_$k.png');
      expect((w, h), (384, 48), reason: 'vfx_$k: 8 frames of 48');
    }
    // Art's Apollo strips: the six pilots, the eighteen of v1.946 and the last five.
    for (final k in [
      'flame',
      'frost',
      'lightning',
      'heal',
      'shield',
      'void_rift',
      'slash',
      'heavy_slash',
      'pierce',
      'claw',
      'whirl',
      'impact',
      'arrow',
      'volley',
      'fireball',
      'holy_fire',
      'splash',
      'poison',
      'wind',
      'drain',
      'shadow',
      'radiance',
      'shout',
      'stone_shield',
      'quake',
      'smoke',
      'zap',
      'meteor_proj',
      'mana'
    ]) {
      final (w, h) = _size('assets/visuals/pixel_fx/vfx_$k.png');
      expect((w, h), (432, 48), reason: 'vfx_$k: 9 frames of 48');
    }
  });

  test('a strip in the old four tones maps them one to one', () {
    // highlight, middle, shadow, deep
    final px = Uint8List.fromList([
      0xFF, 0xFF, 0xFF, 255, //
      0xC9, 0xD1, 0xDC, 255,
      0x5E, 0x6B, 0x7E, 255,
      0x2A, 0x30, 0x3B, 255,
      0, 0, 0, 0,
    ]);
    final r = PixelVfxTints.toneRanks(px);
    expect(r[0xFFFFFF], 0);
    expect(r[0xC9D1DC], 1);
    expect(r[0x5E6B7E], 2);
    expect(r[0x2A303B], 3);
    expect(r.length, 4);
  });

  test('any other palette is ranked by brightness, the ink to the deep tone',
      () {
    // five colours and an ink, as Art's skill strips are drawn
    final colours = [
      0xFFF0C8,
      0xFFC040,
      0xE06020,
      0x902010,
      0x401010,
      0x100808
    ];
    final px = Uint8List.fromList([
      for (final c in colours) ...[
        (c >> 16) & 0xFF,
        (c >> 8) & 0xFF,
        c & 0xFF,
        255
      ],
    ]);
    final r = PixelVfxTints.toneRanks(px);
    expect(r[0xFFF0C8], 0, reason: 'the brightest is the highlight');
    expect(r[0x100808], 3, reason: 'the ink is the deep tone');
    expect(r.values.toSet(), {0, 1, 2, 3}, reason: 'all four tones are used');
    // never darker colours on lighter tones
    final order = [for (final c in colours) r[c]!];
    for (var i = 1; i < order.length; i++) {
      expect(order[i], greaterThanOrEqualTo(order[i - 1]));
    }
  });

  test('the fade is nothing for two thirds of the strip, then goes out', () {
    expect(pixelFadeOut(0), 0);
    expect(pixelFadeOut(0.66), 0);
    expect(pixelFadeOut(0.85), inExclusiveRange(0, 1));
    expect(pixelFadeOut(1), 1);
    var last = 0.0;
    for (var i = 0; i <= 20; i++) {
      final v = pixelFadeOut(i / 20);
      expect(v, greaterThanOrEqualTo(last));
      last = v;
    }
  });

  test('only the strips that end with the object in view fade', () {
    // The flame and the heal, and the Apollo strips of v1.946 that end on
    // their object (the rest end on their own).
    const fading = {
      'flame',
      'heal',
      'slash',
      'heavy_slash',
      'pierce',
      'claw',
      'poison',
      'splash',
      'stone_shield',
      'arrow',
      'volley',
      'wind',
      'holy_fire',
    };
    for (final e in pixelPlans.entries) {
      for (final l in e.value) {
        if (l.fade) {
          expect(fading, contains(l.name), reason: '${e.key} ${l.name}');
        }
      }
    }
    // The flight layers of the arrow, the volley and the fireball never fade.
    for (final style in ['arrow', 'volley', 'fireball']) {
      final plan =
          pixelPlans.entries.firstWhere((e) => e.key.name == style).value.first;
      expect(plan.fade, isFalse, reason: '$style flies');
    }
  });
}
