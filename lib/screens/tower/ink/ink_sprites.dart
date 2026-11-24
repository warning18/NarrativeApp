// The chibi sprites in ink (v1.1004, UX-2): the sprite as drawn, only its
// colours changed. Near-black, cold greys and paper white by luminance
// percentile (so each sprite keeps its detail), one pixel of ink round it, and
// deep red only on the small parts that are red already (a sash, an eye, a
// weapon edge), a few per cent of the sprite at most. Run at load time, once
// per sprite, and kept.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// The five greys and the red, as 0xRRGGBB.
const List<int> _greys = [0x090A14, 0x202E37, 0x394A50, 0x8B9BA0, 0xEBEDE9];
const int _red = 0xB0141C;
const List<double> _cuts = [0.18, 0.42, 0.72, 0.93];

double _lum(int r, int g, int b) => 0.299 * r + 0.587 * g + 0.114 * b;

/// [rgba] (w x h) recoloured; the result is (w + 2) x (h + 2) with the ink
/// outline. Pure, so the rule is testable without a decoder.
Uint8List inkRecolour(Uint8List rgba, int w, int h, {double redShare = 0.05}) {
  final solid = <double>[];
  final redness = <int>[];
  for (var i = 0; i < w * h; i++) {
    if (rgba[i * 4 + 3] == 0) continue;
    final r = rgba[i * 4], g = rgba[i * 4 + 1], b = rgba[i * 4 + 2];
    solid.add(_lum(r, g, b));
    redness.add(r - (g > b ? g : b));
  }
  final out = Uint8List((w + 2) * (h + 2) * 4);
  if (solid.isEmpty) return out;
  final sorted = List<double>.from(solid)..sort();
  final thresholds = [
    for (final c in _cuts)
      sorted[(c * sorted.length).floor().clamp(0, sorted.length - 1)],
  ];
  redness.sort((a, b) => b.compareTo(a));
  final capAt = redness.length < 2
      ? 0
      : (redShare * redness.length).floor().clamp(1, redness.length - 1);
  final cap = redness[capAt];
  final redMin = cap < 40 ? 40 : cap;

  void put(int x, int y, int rgb) {
    final o = (y * (w + 2) + x) * 4;
    out[o] = (rgb >> 16) & 0xFF;
    out[o + 1] = (rgb >> 8) & 0xFF;
    out[o + 2] = rgb & 0xFF;
    out[o + 3] = 0xFF;
  }

  // The ink ring: every empty pixel next to a solid one.
  bool solidAt(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && rgba[(y * w + x) * 4 + 3] != 0;
  for (var y = -1; y <= h; y++) {
    for (var x = -1; x <= w; x++) {
      if (solidAt(x, y)) continue;
      var near = false;
      for (var dy = -1; dy <= 1 && !near; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (solidAt(x + dx, y + dy)) {
            near = true;
            break;
          }
        }
      }
      if (near) put(x + 1, y + 1, _greys[0]);
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final o = (y * w + x) * 4;
      if (rgba[o + 3] == 0) continue;
      final r = rgba[o], g = rgba[o + 1], b = rgba[o + 2];
      final l = _lum(r, g, b);
      final isRed = r - (g > b ? g : b) >= redMin && l < 135;
      if (isRed) {
        put(x + 1, y + 1, _red);
      } else {
        var i = 0;
        for (final t in thresholds) {
          if (l > t) i++;
        }
        put(x + 1, y + 1, _greys[i]);
      }
    }
  }
  return out;
}

class InkSprites {
  InkSprites._();

  static final Map<String, Future<ui.Image>> _cache = {};

  /// How many sprites were recoloured (the cache's proof in tests).
  @visibleForTesting
  static int recolours = 0;

  /// The ink version of the sprite at [asset]; the second ask for the same
  /// asset is the same future, never a second decode.
  static Future<ui.Image> of(String asset) =>
      _cache.putIfAbsent(asset, () => _make(asset));

  static Future<ui.Image> _make(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    final w = image.width, h = image.height;
    final out = inkRecolour(bytes, w, h);
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      out,
      w + 2,
      h + 2,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    recolours++;
    return done.future;
  }

  @visibleForTesting
  static void reset() {
    _cache.clear();
    recolours = 0;
  }
}
