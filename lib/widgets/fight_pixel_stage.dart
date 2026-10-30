// The fight's stages in the scenes' own pixel style (side_view/kit_common.dart):
// the same chunky grid, dithered sky bands, one-pixel rims on the hills and
// flat shapes in three or four tones, so a fight looks like the scenes around
// it. Colours come from FightScenery (fight_backdrop.dart); the day's hour is
// the fight's veil, with the stars and the lamps drawn here.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/field_anomaly.dart' show FightStage;
import 'fight_backdrop.dart' show FightScenery;
import 'side_view/kit_common.dart';
import 'side_view/side_view.dart';

/// The grid is 120 scene pixels across at any width (3 logical pixels on a
/// 360-wide phone, close to the scenes' own 2.6), as tall as the box needs.
const int pixelStageColumns = 120;

/// [stage] painted on [size] as pixel art. [stars] twinkle in the sky (none by
/// day, a few at dusk, many at night); the rest of the hour is the fight's
/// own veil (paintFightBackdrop).
void paintPixelStage(Canvas canvas, Size size, FightStage stage,
    {int stars = 0}) {
  final p = _P(canvas, size, size.width / pixelStageColumns,
      FightScenery.of(stage), stars);
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  switch (stage) {
    case FightStage.fields:
      p.sky(hz: p.hz);
      p.hills(94, 5, 0.07, 0, p.l.far, 0.35);
      p.hills(102, 6, 0.05, 3, p.l.mid, 0.25);
      for (final x in const [14, 25, 31, 92, 103, 109]) {
        p.tree(x.toDouble(), 102 + (x % 3).toDouble());
      }
      p.ground(110);
      p.furrows(110);
      p.speckle(112, p.rows, p.l.dark, 90, 1);
    case FightStage.dunes:
      p.sky(hz: p.hz);
      p.disc(0.76, 62, p.l.light);
      p.hills(96, 7, 0.045, 1, p.l.far, 0.4);
      p.hills(106, 8, 0.06, 5, p.l.mid, 0.3);
      p.ground(116);
      p.ripples(122);
      p.speckle(118, p.rows, p.l.light, 40, 2);
    case FightStage.saltFlats:
      p.sky(hz: p.hz);
      p.disc(0.28, 56, p.l.light);
      p.mesas();
      p.ground(p.hz + 1);
      p.cracks(p.hz + 4);
      p.speckle(p.hz + 2, p.rows, p.l.light, 80, 3);
    case FightStage.waves:
      p.sky(hz: p.hz - 4);
      p.disc(0.2, 66, p.l.light);
      p.sea(p.hz - 4);
      p.sail(76, p.hz - 3);
    case FightStage.ash:
      p.sky(hz: p.hz);
      p.volcano();
      p.hills(104, 4, 0.08, 2, p.l.mid, 0.2);
      p.ground(112);
      p.speckle(114, p.rows, p.l.light, 14, 4, lit: true);
    case FightStage.terraces:
      p.sky(hz: p.hz);
      p.steps(p.hz - 2, p.l.far, 14, 4);
      p.steps(p.hz + 8, p.l.mid, 20, 5);
      p.ground(p.hz + 14);
      p.speckle(p.hz + 16, p.rows, p.l.light, 30, 5, lit: true);
    case FightStage.cliffs:
      p.sky(hz: p.hz);
      p.sea(p.hz, shallow: true);
      p.cliff(true);
      p.cliff(false);
      p.ground(p.hz + 18);
      p.speckle(p.hz + 20, p.rows, p.l.light, 30, 6);
    case FightStage.reeds:
      p.sky(hz: p.hz);
      p.hills(100, 3, 0.05, 4, p.l.far, 0.15);
      p.ground(p.hz + 6);
      p.pools(p.hz + 10);
      p.reeds();
    case FightStage.snow:
      p.sky(hz: p.hz);
      p.peaks();
      p.hills(106, 5, 0.06, 6, p.l.mid, 0.4);
      p.ground(p.hz + 12);
      p.speckle(p.hz + 14, p.rows, p.l.dark, 50, 7);
    case FightStage.glass:
      p.sky(hz: p.hz);
      p.ground(p.hz + 2);
      p.shards();
    case FightStage.hall:
      p.hall();
    case FightStage.ruins:
      p.sky(hz: p.hz);
      p.birds();
      p.hills(98, 4, 0.06, 2, p.l.far, 0.2);
      p.walls();
      p.ground(p.hz + 10);
      p.rubble();
    case FightStage.woods:
      p.sky(hz: p.hz);
      p.hills(98, 3, 0.06, 5, p.l.far, 0.2);
      p.treeRow(100, p.l.far, 9, 13, 1);
      p.ground(p.hz + 6);
      p.treeRow(108, p.l.mid, 14, 7, 2);
      p.shafts();
      p.speckle(p.hz + 8, p.rows, p.l.dark, 90, 8);
      p.trunk(6, 198);
      p.trunk(108, 214);
    case FightStage.ford:
      p.sky(hz: p.hz);
      p.hills(94, 5, 0.06, 0, p.l.far, 0.35);
      p.hills(102, 6, 0.05, 3, p.l.mid, 0.25);
      p.ground(110);
      p.river(124);
      p.bridge(120);
      p.speckle(150, p.rows, p.l.dark, 50, 9);
    case FightStage.burntFields:
      p.sky(hz: p.hz);
      p.smoke();
      p.hills(100, 4, 0.06, 1, p.l.far, 0.15);
      p.ground(p.hz + 6);
      p.furrows(p.hz + 6);
      p.posts();
      p.speckle(p.hz + 8, p.rows, p.l.light, 36, 10, lit: true);
    case FightStage.oasis:
      p.sky(hz: p.hz);
      p.disc(0.78, 64, p.l.light);
      p.hills(96, 7, 0.045, 1, p.l.far, 0.4);
      p.hills(106, 8, 0.06, 5, p.l.mid, 0.3);
      p.ground(116);
      p.pool(150);
      p.palm(20, 150, 40, 1);
      p.palm(34, 144, 30, -1);
      p.palm(100, 152, 36, -1);
    case FightStage.caravanRoad:
      p.sky(hz: p.hz);
      p.disc(0.24, 58, p.l.light);
      p.hills(96, 7, 0.045, 4, p.l.far, 0.4);
      p.caravan(94);
      p.hills(106, 8, 0.06, 7, p.l.mid, 0.3);
      p.ground(116);
      p.ruts(116);
      p.bush(16, 190);
      p.speckle(120, p.rows, p.l.light, 30, 11);
    case FightStage.quay:
      p.sky(hz: p.hz - 6);
      p.disc(0.22, 76, p.l.light);
      p.sea(p.hz - 6);
      p.masts(p.hz - 6);
      p.planks(p.hz + 4);
      p.bollards();
    case FightStage.pass:
      p.sky(hz: p.hz);
      p.peaksFar();
      p.hills(106, 4, 0.07, 6, p.l.mid, 0.2);
      p.ground(112);
      p.road(112);
      p.rockWall(true);
      p.rockWall(false);
  }
  canvas.restore();
}

class _P {
  _P(this.c, this.size, this.u, this.l, this.stars)
      : cols = (size.width / u).ceil(),
        rows = (size.height / u).ceil();

  final Canvas c;
  final Size size;
  final double u;
  final FightScenery l;
  final int stars;
  final int cols, rows;

  int get hz => (rows * 0.48).round();

  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  void r(Color color, num x, num y, num w, num h) => sidePixels(
      c,
      u,
      Paint()..color = color,
      x.toDouble(),
      y.toDouble(),
      w.toDouble(),
      h.toDouble());

  double rnd(int i, [int salt = 0]) {
    final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  /// The sky in dithered bands to [hz], then the stars of the hour.
  void sky({required int hz}) {
    final bands = [
      for (final t in const [0.0, 0.3, 0.55, 0.8, 1.0])
        mix(l.skyTop, l.skyLow, t),
    ];
    kitSky(c, size, u, bands: bands, ground: l.ground, horizon: hz);
    for (var i = 0; i < stars; i++) {
      r(Colors.white.withValues(alpha: 0.4 + 0.5 * rnd(i, 3)), rnd(i, 1) * cols,
          2 + rnd(i, 2) * (hz * 0.7), 1, 1);
    }
  }

  void disc(double cx, double cy, Color colour) => kitDisc(c, size, u,
      cx: cx, cy: cy, disc: colour, glow: mix(l.skyLow, colour, 0.5));

  void hills(int base, double amp, double wave, double phaseShift, Color fill,
      double rimMix) {
    sideHills(c, size, u, 0,
        base: base.toDouble(),
        amp: amp,
        wave: wave,
        phase: phaseShift,
        fill: fill,
        rim: mix(fill, l.light, rimMix));
  }

  /// The ground from [y0] to the bottom in dithered bands, dark at the front.
  void ground(int y0) {
    final tones = [
      for (final t in const [0.0, 0.3, 0.6, 1.0]) mix(l.ground, l.dark, t),
    ];
    final span = rows - y0;
    final paint = Paint();
    for (var y = y0; y < rows; y++) {
      final q = (y - y0) / span * (tones.length - 1);
      final i = q.floor();
      final f = q - i;
      final lo = tones[i], hi = tones[math.min(i + 1, tones.length - 1)];
      for (var x = 0; x < cols; x++) {
        const bayer = [
          [0, 2],
          [3, 1]
        ];
        paint.color = f * 4 > bayer[y % 2][x % 2] ? hi : lo;
        c.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.5, u + 0.5), paint);
      }
    }
  }

  void speckle(int y0, int y1, Color colour, int n, int seed,
      {bool lit = false}) {
    final paint = Paint();
    for (var i = 0; i < n; i++) {
      final x = rnd(i, seed) * cols;
      final y = y0 + math.pow(rnd(i, seed + 40), 1.3) * (y1 - y0);
      paint.color = colour.withValues(alpha: lit ? 0.9 : 0.35);
      sidePixels(c, u, paint, x, y.toDouble(), lit ? 1 : 2, 1);
    }
  }

  void tri(double cx, int top, int base, double halfW, Color fill,
      {Color? rim}) {
    for (var y = top; y <= base; y++) {
      final half = halfW * (y - top) / math.max(1, base - top);
      r(fill, cx - half, y.toDouble(), half * 2 + 1, 1);
      if (rim != null) {
        r(rim, cx - half, y.toDouble(), 1, 1);
      }
    }
  }

  // --- fields, woods, ford ---------------------------------------------------

  void tree(double x, double y) {
    r(l.dark, x, y - 3, 1, 3);
    r(l.dark, x - 3, y - 9, 7, 6);
    r(l.dark, x - 2, y - 11, 5, 2);
    r(mix(l.mid, l.light, 0.25), x - 2, y - 9, 2, 1);
  }

  void furrows(int y0) {
    final colour = mix(l.ground, l.dark, 0.55);
    for (var i = -9; i <= 9; i++) {
      for (var y = y0; y < rows; y++) {
        r(colour, cols / 2 + i * (y - y0) * 0.5, y.toDouble(), 1, 1);
      }
    }
  }

  void treeRow(int y, Color colour, int count, int scale, int seed) {
    for (var i = 0; i < count; i++) {
      final x = cols * ((i + 0.5 + (rnd(i, seed) - 0.5) * 0.6) / count);
      final h = scale * (0.8 + 0.6 * rnd(i, seed + 5));
      r(colour, x, y - h, 2, h);
      r(colour, x - h * 0.45, y - h * 1.25, h * 0.9 + 2, h * 0.5);
      r(mix(colour, l.light, 0.25), x - h * 0.3, y - h * 1.25, h * 0.4, 1);
    }
  }

  void shafts() {
    for (var k = 0; k < 4; k++) {
      final x0 = 14 + k * 26;
      for (var y = 0; y < hz + 40; y += 2) {
        r(l.light.withValues(alpha: 0.10), x0 + y * 0.35, y.toDouble(), 7, 2);
      }
    }
  }

  void trunk(double x, double bottom) {
    r(l.dark, x, 40, 7, bottom - 40);
    r(mix(l.dark, l.mid, 0.4), x, 40, 1, bottom - 40);
  }

  void river(int y) {
    const deep = Color(0xFF3E6F90), shallow = Color(0xFF6FA5BD);
    for (var x = 0; x < cols; x++) {
      final top = y + 4 * math.sin(x * 0.07);
      r(shallow, x.toDouble(), top, 1, 3);
      r(deep, x.toDouble(), top + 3, 1, 16);
      r(mix(deep, l.dark, 0.4), x.toDouble(), top + 19, 1, 3);
    }
    for (var i = 0; i < 18; i++) {
      r(l.light, rnd(i, 7) * cols, y + 6 + rnd(i, 8) * 14, 4, 1);
    }
  }

  void bridge(int y) {
    r(l.far, 4, y - 6, 62, 6);
    r(mix(l.far, l.light, 0.3), 4, y - 6, 62, 1);
    r(l.dark, 4, y, 62, 12);
    for (var k = 0; k < 3; k++) {
      final cx = 16 + k * 20.0;
      for (var dy = 0; dy < 8; dy++) {
        final half = math.sqrt(math.max(0, 64 - (7 - dy) * (7 - dy) * 1.3));
        r(const Color(0xFF3E6F90), cx - half * 0.55, y + 12 - dy.toDouble(),
            half * 1.1, 1);
      }
    }
  }

  // --- desert -----------------------------------------------------------------

  void ripples(int y0) {
    final colour = mix(l.ground, l.dark, 0.5);
    for (var y = y0; y < rows; y += 7) {
      for (var k = 0; k < 6; k++) {
        r(colour, (k * 23 + (y * 5) % 17).toDouble(), y.toDouble(), 6, 1);
      }
    }
  }

  void mesas() {
    for (var i = 0; i < 5; i++) {
      final w = 12.0 + rnd(i, 1) * 10, h = 7.0 + rnd(i, 2) * 5;
      final x = 6 + i * 24.0 + rnd(i, 3) * 6;
      r(l.far, x, hz - h, w, h + 1);
      r(mix(l.far, l.light, 0.4), x, hz - h, w, 1);
      r(mix(l.far, l.dark, 0.3), x + w - 2, hz - h + 1, 2, h);
    }
  }

  void cracks(int y0) {
    final colour = mix(l.ground, l.dark, 0.45);
    for (var k = 0; k < 14; k++) {
      var x = rnd(k, 5) * cols;
      var y = y0 + math.pow(rnd(k, 6), 1.2) * (rows - y0 - 6);
      for (var s = 0; s < 6 + (y - y0) * 0.08; s++) {
        r(colour, x, y.toDouble(), 1, 1);
        x += rnd(k * 9 + s, 7) < 0.5 ? 1 : -1;
        y += rnd(k * 9 + s, 8) < 0.4 ? 1 : 0;
      }
    }
  }

  void pool(int y) {
    const water = Color(0xFF3C95A0);
    for (var dy = -5; dy <= 5; dy++) {
      final half = 28 * math.sqrt(math.max(0, 1 - (dy / 6) * (dy / 6)));
      r(water, 58 - half, y + dy.toDouble(), half * 2, 1);
      if (dy == -3) {
        r(const Color(0xFF8BD2D2), 58 - half * 0.8, y + dy.toDouble(),
            half * 1.6, 1);
      }
    }
  }

  void palm(double x, double bottom, double height, int lean) {
    for (var y = 0.0; y < height; y++) {
      final t = y / height;
      r(l.dark, x + lean * 6 * t * t, bottom - y, 2, 1);
    }
    final top = x + lean * 6;
    final y = bottom - height;
    for (var i = -3; i <= 3; i++) {
      for (var s = 1; s < 11; s++) {
        r(
            l.dark,
            top + i * s * 0.9,
            y -
                (6 - i.abs() * 1.4) * s / 10 * 3 +
                s * s * 0.07 * (1 + i.abs() * 0.3),
            2,
            2);
      }
    }
  }

  void caravan(int y) {
    for (var i = 0; i < 5; i++) {
      final x = 62.0 + i * 11;
      r(l.dark, x, y - 4, 7, 3);
      r(l.dark, x + 2, y - 6, 2, 2);
      r(l.dark, x + 6, y - 8, 1, 5);
      r(l.dark, x + 6, y - 9, 2, 1);
      for (final lx in const [0, 2, 5, 6]) {
        r(l.dark, x + lx, y - 1, 1, 3);
      }
    }
  }

  void ruts(int y0) {
    for (var y = y0; y < rows; y++) {
      final t = (y - y0) * 0.5;
      r(mix(l.ground, l.dark, 0.55), cols / 2 - 1 - t, y.toDouble(),
          1 + t * 0.2, 1);
      r(mix(l.ground, l.dark, 0.55), cols / 2 + t * 0.8, y.toDouble(),
          1 + t * 0.2, 1);
    }
  }

  void bush(double x, double y) {
    for (var i = 0; i < 9; i++) {
      final a = -math.pi * (0.1 + 0.8 * i / 8);
      for (var s = 2; s < 9; s++) {
        r(l.dark, x + math.cos(a) * s, y + math.sin(a) * s, 1, 1);
      }
    }
  }

  // --- sea, cliffs, quay ------------------------------------------------------

  void sea(int y0, {bool shallow = false}) {
    final deep = shallow ? mix(l.skyLow, l.mid, 0.5) : l.far;
    final tones = [
      mix(deep, l.light, 0.15),
      deep,
      mix(deep, l.dark, 0.4),
      mix(deep, l.dark, 0.7)
    ];
    final end = shallow ? y0 + 16 : rows;
    for (var y = y0; y < end; y++) {
      final q = (y - y0) / (end - y0) * (tones.length - 1);
      final i = q.floor();
      final f = q - i;
      final lo = tones[i], hi = tones[math.min(i + 1, tones.length - 1)];
      final paint = Paint();
      for (var x = 0; x < cols; x++) {
        const bayer = [
          [0, 2],
          [3, 1]
        ];
        paint.color = f * 4 > bayer[y % 2][x % 2] ? hi : lo;
        c.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.5, u + 0.5), paint);
      }
    }
    for (var i = 0; i < (shallow ? 6 : 26); i++) {
      final y = y0 + 3 + (i * 9) % (end - y0 - 4);
      r(mix(l.light, l.skyLow, 0.3), rnd(i, 4) * cols, y.toDouble(),
          4 + (i % 3) * 2, 1);
    }
  }

  void sail(double x, int y) {
    r(l.dark, x - 2, y, 9, 2);
    for (var k = 0; k < 7; k++) {
      r(mix(l.light, l.dark, 0.2), x + 2, y - 8 + k.toDouble(), 1 + k * 0.5, 1);
    }
    r(l.dark, x + 2, y - 9, 1, 9);
  }

  void cliff(bool left) {
    for (var x = 0; x < 34; x++) {
      final top = 18 + (x * 1.5) + 5 * math.sin(x * 0.45 + (left ? 0 : 2));
      final col = left ? x : cols - 1 - x;
      final fill = left ? l.mid : l.far;
      final h = hz + 20 - top;
      r(fill, col.toDouble(), top, 1, h);
      r(mix(fill, l.light, 0.35), col.toDouble(), top, 1, 1);
      if (x % 6 == 2) {
        r(mix(fill, l.dark, 0.45), col.toDouble(), top + 3, 1, h * 0.6);
      }
    }
  }

  void masts(int y0) {
    for (var i = 0; i < 5; i++) {
      final x = 10.0 + i * 24 + rnd(i, 1) * 5;
      final h = 28 + rnd(i, 2) * 22;
      r(l.dark, x, y0 - h, 1, h);
      r(l.dark, x - 4, y0 - h * 0.72, 9, 1);
      for (var k = 0; k < h * 0.4; k++) {
        r(mix(l.dark, l.far, 0.4), x + 1, y0 - h * 0.9 + k, 1 + k * 0.28, 1);
      }
    }
  }

  void planks(int y0) {
    ground(y0);
    final line = mix(l.ground, l.dark, 0.75);
    for (var i = -14; i <= 14; i++) {
      for (var y = y0; y < rows; y++) {
        r(line, cols / 2 + i * (y - y0 + 20) * 0.28, y.toDouble(), 1, 1);
      }
    }
    for (var k = 1; k < 9; k++) {
      final y = y0 + math.pow(k / 9, 1.8) * (rows - y0);
      r(line, 0, y.toDouble(), cols.toDouble(), 1);
    }
  }

  void bollards() {
    for (var i = 0; i < 5; i++) {
      final x = 10.0 + i * 24;
      final y = hz + 24 + (i % 3) * 22.0;
      r(l.dark, x, y, 4, 7);
      r(mix(l.dark, l.light, 0.3), x, y, 4, 1);
    }
  }

  // --- ash, terraces, glass, hall ---------------------------------------------

  void volcano() {
    tri(40, 50, hz + 2, 46, l.far, rim: mix(l.far, l.light, 0.25));
    r(l.light, 36, 50, 9, 2);
    r(mix(l.light, l.dark, 0.4), 38, 52, 5, 1);
    for (var y = 12; y < 50; y++) {
      for (var x = 36; x < 46; x++) {
        if ((x + y) % 2 == 0 && rnd(x * 7 + y, 9) < 0.7 - (50 - y) * 0.012) {
          r(mix(l.skyLow, Colors.white, 0.2), x + math.sin(y * 0.2) * 2,
              y.toDouble(), 1, 1);
        }
      }
    }
  }

  void steps(int y0, Color fill, int w, int count) {
    for (var k = 0; k < count + 3; k++) {
      final x = -2 + k * (w + 2.0);
      final h = 10.0 + 8 * rnd(k, 3);
      r(fill, x, y0 - h, w.toDouble(), h + 20);
      r(mix(fill, l.light, 0.3), x, y0 - h, w.toDouble(), 1);
      r(mix(fill, l.light, 0.7), x + 3, y0 - h + 4, 1, 2);
      r(mix(fill, l.light, 0.7), x + 8, y0 - h + 4, 1, 2);
    }
  }

  void shards() {
    for (var i = 0; i < 12; i++) {
      final cx = 6 + i * 10.0 + rnd(i, 1) * 4;
      final h = 22 + rnd(i, 2) * 34;
      final fill = i.isEven ? l.dark : mix(l.dark, l.light, 0.25);
      tri(cx, (hz + 2 - h).round(), hz + 2, 2.5 + rnd(i, 3) * 2, fill);
      r(mix(fill, Colors.white, 0.5), cx, hz + 2 - h + 2, 1, h * 0.5);
    }
  }

  void hall() {
    final bands = [
      for (final t in const [0.0, 0.5, 1.0]) mix(l.skyTop, l.skyLow, t)
    ];
    kitSky(c, size, u, bands: bands, ground: l.ground, horizon: hz + 14);
    for (var k = 0; k < 4; k++) {
      final x = 8 + k * 30.0;
      r(l.mid, x, 34, 9, hz + 14 - 34.0);
      r(mix(l.mid, l.light, 0.2), x, 34, 1, hz + 14 - 34.0);
      r(l.dark, x + 8, 34, 1, hz + 14 - 34.0);
      // The arch between the columns.
      for (var dy = 0; dy < 10; dy++) {
        final half = 10 *
            math.sqrt(math.max(0, 1 - ((10 - dy) / 10) * ((10 - dy) / 10)));
        r(mix(l.far, l.dark, 0.4), x + 4 + 15 - half, 24 + dy.toDouble(),
            half * 2, 1);
      }
    }
    ground(hz + 14);
    final line = mix(l.ground, l.dark, 0.7);
    for (var i = -10; i <= 10; i++) {
      for (var y = hz + 14; y < rows; y++) {
        r(line, cols / 2 + i * (y - hz - 8) * 0.32, y.toDouble(), 1, 1);
      }
    }
    for (var k = 1; k < 9; k++) {
      r(line, 0, hz + 14 + math.pow(k / 9, 1.8) * (rows - hz - 14),
          cols.toDouble(), 1);
    }
  }

  // --- reeds, snow, ruins, burnt, pass ----------------------------------------

  void pools(int y0) {
    for (var k = 0; k < 6; k++) {
      final cx = 14 + rnd(k, 1) * 92, cy = y0 + 8 + k * 17.0;
      final w = 7 + k * 1.6;
      for (var dy = -2; dy <= 2; dy++) {
        final half = w * math.sqrt(math.max(0, 1 - (dy / 3) * (dy / 3)));
        r(mix(l.mid, l.light, dy == -2 ? 0.55 : 0.3), cx - half, cy + dy,
            half * 2, 1);
      }
    }
  }

  void reeds() {
    for (var i = 0; i < 70; i++) {
      final x = rnd(i, 1) * cols;
      final y = hz + 30 + rnd(i, 2) * (rows - hz - 30);
      final h = 8 + rnd(i, 3) * 20 * (y / rows);
      r(i.isEven ? l.mid : l.dark, x, y - h, 1, h);
      if (i % 3 == 0) r(l.dark, x, y - h, 1, 3);
    }
  }

  void peaks() {
    final xs = [14.0, 42.0, 74.0, 104.0];
    final hs = [34, 50, 40, 30];
    for (var i = 0; i < 4; i++) {
      final base = hz;
      final top = base - hs[i];
      tri(xs[i], top, base, hs[i] * 0.95, l.far, rim: mix(l.far, l.light, 0.3));
      tri(xs[i], top, top + (hs[i] * 0.3).round(), hs[i] * 0.95 * 0.3,
          Colors.white);
    }
  }

  void birds() {
    for (var i = 0; i < 7; i++) {
      final x = rnd(i, 3) * cols, y = 14 + rnd(i, 4) * 30;
      r(l.dark, x, y, 1, 1);
      r(l.dark, x - 1, y - 1, 1, 1);
      r(l.dark, x + 1, y - 1, 1, 1);
      r(l.dark, x - 2, y - 1, 1, 1);
      r(l.dark, x + 2, y - 1, 1, 1);
    }
  }

  void walls() {
    for (var i = 0; i < 6; i++) {
      final x = 2 + i * 20.0;
      final top = hz - 14 - rnd(i, 1) * 24;
      final w = 12 + rnd(i, 2) * 8;
      r(i.isEven ? l.mid : l.far, x, top, w, hz + 8 - top);
      for (var k = 0; k < w; k += 3) {
        if (rnd(i * 20 + k, 4) < 0.5) {
          r(l.skyLow, x + k, top, 3, 2 + rnd(k, 5) * 4);
        }
      }
      r(mix(l.mid, l.light, 0.25), x, top + 2, 1, hz + 6 - top);
      if (i == 2) {
        for (var dy = 0; dy < 9; dy++) {
          final half =
              4 * math.sqrt(math.max(0, 1 - ((9 - dy) / 9) * ((9 - dy) / 9)));
          r(l.skyLow, x + 6 - half, top + 8 + dy.toDouble(), half * 2, 1);
        }
        r(l.skyLow, x + 2, top + 17, 8, 12);
      }
    }
  }

  void rubble() {
    for (var i = 0; i < 24; i++) {
      final x = rnd(i, 1) * cols;
      final y = hz + 14 + math.pow(rnd(i, 2), 1.3) * (rows - hz - 20);
      final s = 2 + (y - hz) / 18 * (0.6 + rnd(i, 3));
      tri(x, (y - s).round(), y.round(), s, i.isEven ? l.dark : l.mid);
    }
  }

  void smoke() {
    for (var k = 0; k < 4; k++) {
      final x0 = 14 + k * 30.0;
      for (var y = 10; y < hz; y++) {
        final sway = math.sin(y * 0.09 + k) * 3;
        for (var x = 0; x < 6; x++) {
          if ((x + y) % 2 == 0) {
            r(l.dark.withValues(alpha: 0.5), x0 + x + sway, y.toDouble(), 1, 1);
          }
        }
      }
    }
  }

  void posts() {
    for (var i = 0; i < 9; i++) {
      final x = 6 + i * 13.0;
      final y = hz + 16 + (i % 3) * 20.0;
      final h = 5 + (i % 3) * 3;
      r(l.mid, x, y - h, 1, h);
      r(l.mid, x + (i.isEven ? 1 : -1), y - h - 1, 1, 1);
    }
  }

  void peaksFar() {
    final xs = [0, 18, 36, 56, 72, 92, 110, 120];
    final hs = [18, 38, 22, 46, 28, 40, 20, 30];
    for (var i = 0; i < xs.length - 1; i++) {
      for (var x = xs[i]; x < xs[i + 1]; x++) {
        final t = (x - xs[i]) / (xs[i + 1] - xs[i]);
        final up = i.isEven;
        final h = up
            ? hs[i] + (hs[i + 1] - hs[i]) * t
            : hs[i] + (hs[i + 1] - hs[i]) * t;
        r(l.far, x.toDouble(), hz - h, 1, h + 1);
        r(mix(l.far, l.light, 0.35), x.toDouble(), hz - h, 1, 1);
      }
    }
  }

  void road(int y0) {
    for (var y = y0; y < rows; y++) {
      final t = (y - y0).toDouble();
      final cx = 60 + 18 * math.sin(t * 0.03);
      final half = 2 + t * 0.2;
      r(mix(l.ground, l.light, 0.35), cx - half, y.toDouble(), half * 2, 1);
      r(mix(l.ground, l.dark, 0.35), cx - half, y.toDouble(), 1, 1);
      r(mix(l.ground, l.dark, 0.35), cx + half - 1, y.toDouble(), 1, 1);
    }
  }

  void rockWall(bool left) {
    for (var x = 0; x < 30; x++) {
      final top = 20 + x * 1.4 + 6 * math.sin(x * 0.4 + (left ? 0 : 2));
      final col = left ? x : cols - 1 - x;
      final fill = left ? l.mid : mix(l.mid, l.dark, 0.4);
      final bottom = rows * 0.82;
      r(fill, col.toDouble(), top, 1, bottom - top);
      r(mix(fill, l.light, 0.35), col.toDouble(), top, 1, 1);
      if (x % 5 == 1) {
        r(mix(fill, l.dark, 0.4), col.toDouble(), top + 4, 1,
            (bottom - top) * 0.7);
      }
    }
  }

  /// What shines through the dark: lamps, torches, the lava.
  void lights(FightStage stage, {required bool lit}) {
    const warm = Color(0xFFFFC66B);
    switch (stage) {
      case FightStage.quay:
        for (final x in const [12.0, 104.0]) {
          final y = hz + 20.0;
          r(l.dark, x, y - 12, 1, 28);
          r(l.dark, x - 1, y - 14, 3, 3);
          r(warm, x, y - 13, 1, 1);
          if (lit) {
            for (var dy = -7; dy <= 7; dy++) {
              for (var dx = -7; dx <= 7; dx++) {
                final d = dx * dx + dy * dy;
                if (d < 49 && (dx + dy) % 2 == 0) {
                  r(warm.withValues(alpha: 0.5 * (1 - d / 49)), x + dx,
                      y - 13 + dy, 1, 1);
                }
              }
            }
          }
        }
      case FightStage.hall:
        for (var k = 0; k < 4; k++) {
          final x = 12.0 + k * 30;
          r(warm, x + 4, 62, 2, 3);
          if (lit || true) {
            for (var dy = -6; dy <= 6; dy++) {
              for (var dx = -6; dx <= 6; dx++) {
                final d = dx * dx + dy * dy;
                if (d < 36 && (dx + dy) % 2 == 0) {
                  r(warm.withValues(alpha: 0.4 * (1 - d / 36)), x + 5 + dx,
                      63 + dy, 1, 1);
                }
              }
            }
          }
        }
      case FightStage.ash:
        r(const Color(0xFFFF8A3C), 37, 50, 7, 1);
      default:
        break;
    }
  }
}

/// The lamps and torches of [stage], over the veil of the dark so they shine
/// through it.
void paintPixelLights(Canvas canvas, Size size, FightStage stage,
    {required bool lit}) {
  final p = _P(
      canvas, size, size.width / pixelStageColumns, FightScenery.of(stage), 0);
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  p.lights(stage, lit: lit);
  canvas.restore();
}
