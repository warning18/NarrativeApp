// The seam between two kits (docs/proposals/scene-transitions.md, 3b): as the
// camera moves along the world's strip from one region's land into the next,
// the new kit comes in from the right edge in an ordered dither (the same
// Bayer blocks as the scene dissolve), a band of mixed land between the two,
// and the world is one place with no cut. The camera (3c) gives it the
// progress; here it is a function of the layer's own scroll.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'side_view.dart';

/// How wide the mixed band is, as a share of the screen's width.
const double _kitBlendBand = 0.35;

const _bayer = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];

/// The share of a block at [column] (0 left to 1 right) that shows the new
/// kit once the seam has crossed [progress] (0 to 1) of the screen: the new
/// land enters at the right edge, the band behind it half-covered, the left
/// still the old land until the seam has gone by.
double kitBlendCover(double column, double progress) {
  final p = progress.clamp(0.0, 1.0);
  // The seam's front runs from just past the right edge (p = 0) to just
  // past the left one (p = 1), the band trailing it.
  final front = 1 + _kitBlendBand - p * (1 + _kitBlendBand);
  return ((column - front) / _kitBlendBand + 1).clamp(0.0, 1.0);
}

/// [from] turning into [to] across the screen as [progressAt] of the layer's
/// scroll goes from 0 to 1. Painted as one layer (give it the scene's raw
/// scroll: each inner layer takes its own share). At 0 it is just [from], at
/// 1 just [to].
SideLayer kitBlend(List<SideLayer> from, List<SideLayer> to,
    double Function(double) progressAt) {
  return SideLayer(1, (canvas, size, scroll, t, u) {
    void paintAll(List<SideLayer> layers) {
      for (final layer in layers) {
        layer.paint(canvas, size, scroll * layer.speed, t, u);
      }
    }

    final k = progressAt(scroll).clamp(0.0, 1.0);
    if (k <= 0) return paintAll(from);
    if (k >= 1) return paintAll(to);
    paintAll(from);
    final block = math.max(2.0, 3 * u);
    final path = Path();
    for (var y = 0; y * block < size.height; y++) {
      for (var x = 0; x * block < size.width; x++) {
        final cover = kitBlendCover((x + 0.5) * block / size.width, k);
        if (cover > (_bayer[y % 4][x % 4] + 0.5) / 16) {
          path.addRect(Rect.fromLTWH(x * block, y * block, block, block));
        }
      }
    }
    canvas.save();
    canvas.clipPath(path);
    paintAll(to);
    canvas.restore();
  });
}
