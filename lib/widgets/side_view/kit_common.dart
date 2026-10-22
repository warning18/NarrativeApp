// What the biome kits (frost, fen, sea cliffs) share: a sky in dithered
// bands from the top to the horizon, a sun or moon disc with a dithered halo,
// and a path of a light rim with a few dark marks scrolling along it. The
// desert and ruins kits keep their own copies; these are for the newer ones.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'side_view.dart';

const _bayer = [
  [0, 2],
  [3, 1],
];

/// The sky in dithered [bands] (top to bottom) down to [horizon] scene
/// pixels, the ground behind the hills filled with [ground] below it.
void kitSky(Canvas canvas, Size size, double u,
    {required List<Color> bands, required Color ground, int horizon = 48}) {
  final cols = (size.width / u).ceil();
  final paint = Paint();
  for (var y = 0; y < horizon; y++) {
    final p = y / horizon * (bands.length - 1);
    final i = p.floor();
    final f = p - i;
    final lo = bands[i], hi = bands[math.min(i + 1, bands.length - 1)];
    for (var x = 0; x < cols; x++) {
      paint.color = f * 4 > _bayer[y % 2][x % 2] ? hi : lo;
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.5, u + 0.5), paint);
    }
  }
  canvas.drawRect(Rect.fromLTWH(0, horizon * u, size.width, size.height),
      Paint()..color = ground);
}

/// A disc of [radius] scene pixels at [cx] (a share of the width) and [cy],
/// with a dithered halo of [glow]'s colour.
void kitDisc(Canvas canvas, Size size, double u,
    {required double cx,
    required double cy,
    required Color disc,
    required Color glow,
    int radius = 4}) {
  final x0 = (size.width / u * cx).floorToDouble();
  final discPaint = Paint()..color = disc;
  final glowPaint = Paint()..color = glow;
  final r2 = radius * radius;
  final halo = radius * 2 + 1;
  for (var y = -halo; y <= halo; y++) {
    for (var x = -halo; x <= halo; x++) {
      final d = x * x + y * y;
      if (d <= r2) {
        canvas.drawRect(
            Rect.fromLTWH((x0 + x) * u, (cy + y) * u, u + 0.5, u + 0.5),
            discPaint);
      } else if (d <= halo * halo && (x + y) % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH((x0 + x) * u, (cy + y) * u, u + 0.5, u + 0.5),
            glowPaint);
      }
    }
  }
}

/// The path along the bottom: [body] with a [light] rim and a scattering of
/// [dark] marks.
void kitPath(Canvas canvas, Size size, double scroll, double u,
    {required Color body, required Color light, required Color dark}) {
  final w = size.width / u;
  sidePixels(canvas, u, Paint()..color = body, 0, 63, w + 1, 9);
  sidePixels(canvas, u, Paint()..color = light, 0, 63, w + 1, 1);
  final mark = Paint()..color = dark;
  final offset = scroll / u;
  for (var i = 0; i < 14; i++) {
    final px = ((i * 9 - offset) % (w + 12) + (w + 12)) % (w + 12) - 6;
    sidePixels(canvas, u, mark, px, 67 + (i % 3), 4, 1);
  }
}

/// Where the [i]th of [n] things repeating every [span] scene pixels stands
/// once the layer has scrolled [offset] pixels, wrapped to the box.
double kitSlot(int i, int n, double span, double offset, double start) =>
    ((i * span / n + start - offset) % span + span) % span - 12;
