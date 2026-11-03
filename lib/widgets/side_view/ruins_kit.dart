// The ruins scene kit: a burnt dusk in dithered bands with a dim red sun,
// the broken skyline of a drowned quarter far off, ruined walls and arches
// in two bands scrolling at their own speeds, ash hills, rubble, and a path
// of grey cobbles. The goal (a tower with one lit window) comes forward as
// the days pass ([progress] 0 to 1). The party is the desert kit's
// placeholder figures until the user's sprite arrives.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'side_view.dart';

/// The ruins' colours.
abstract final class _RuinsLook {
  static const sky = [
    Color(0xFF2A2433),
    Color(0xFF4A3340),
    Color(0xFF7A4046),
    Color(0xFFB3593F),
    Color(0xFFE08A4E),
  ];
  static const sun = Color(0xFFF2A15A);
  static const skyline = Color(0xFF3B2B38);
  static const skylineRim = Color(0xFF5A4150);
  static const wall = Color(0xFF4A3A46);
  static const wallRim = Color(0xFF6E5663);
  static const hill = Color(0xFF3A3038);
  static const hillRim = Color(0xFF584A52);
  static const near = Color(0xFF2E262E);
  static const nearRim = Color(0xFF473D46);
  static const path = Color(0xFF4B4147);
  static const pathDark = Color(0xFF332B31);
  static const pathLight = Color(0xFF6A5E64);
  static const window = Color(0xFFF8C070);
}

const _bayer = [
  [0, 2],
  [3, 1],
];

/// The layers, back to front. [progress] brings the goal's tower nearer as
/// the days go.
List<SideLayer> ruinsLayers({double progress = 0}) => [
      const SideLayer(0, _sky),
      const SideLayer(0.05, _sun),
      SideLayer(0.12, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 40,
            amp: 1.6,
            wave: 0.06,
            phase: 1.3,
            fill: _RuinsLook.skyline,
            rim: _RuinsLook.skylineRim);
        _skyline(c, s, u, scroll);
        _tower(c, s, u, progress);
      }),
      SideLayer(0.3, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 46,
            amp: 2.2,
            wave: 0.05,
            phase: 0.6,
            fill: _RuinsLook.hill,
            rim: _RuinsLook.hillRim);
        _walls(c, s, u, scroll);
      }),
      SideLayer(0.8, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 54,
            amp: 3,
            wave: 0.035,
            phase: 2.4,
            fill: _RuinsLook.near,
            rim: _RuinsLook.nearRim);
        _rubble(c, s, u, scroll);
      }),
      const SideLayer(1.0, _path),
    ];

void _sky(Canvas canvas, Size size, double scroll, double t, double u) {
  // Dithered bands from the top to the horizon.
  const horizon = 48;
  const bands = _RuinsLook.sky;
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
      Paint()..color = _RuinsLook.skyline);
}

void _sun(Canvas canvas, Size size, double scroll, double t, double u) {
  // A dim disc half-sunk behind the skyline, with a dithered halo.
  final cx = (size.width / u * 0.3).floorToDouble();
  const cy = 38.0;
  final glow = Paint()..color = _RuinsLook.sun.withValues(alpha: 0.2);
  final disc = Paint()..color = _RuinsLook.sun.withValues(alpha: 0.85);
  for (var y = -9; y <= 9; y++) {
    for (var x = -9; x <= 9; x++) {
      final d = x * x + y * y;
      if (d <= 20) {
        canvas.drawRect(
            Rect.fromLTWH((cx + x) * u, (cy + y) * u, u + 0.5, u + 0.5), disc);
      } else if (d <= 81 && (x + y) % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH((cx + x) * u, (cy + y) * u, u + 0.5, u + 0.5), glow);
      }
    }
  }
}

/// Broken towers and gables of a far quarter, repeating along the horizon.
void _skyline(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.5;
  final body = Paint()..color = _RuinsLook.skyline;
  final rim = Paint()..color = _RuinsLook.skylineRim;
  final offset = scroll / u;
  const heights = [6, 10, 4, 8, 12, 5, 9];
  for (var i = 0; i < 7; i++) {
    final px = ((i * span / 7 + 6 - offset) % span + span) % span - 8;
    if (px < -6 || px > w + 2) continue;
    final h = heights[i].toDouble();
    sidePixels(canvas, u, body, px, 42 - h, 4, h);
    sidePixels(canvas, u, rim, px, 42 - h, 4, 1);
    // A snapped top: one pixel bitten off.
    sidePixels(
        canvas, u, Paint()..color = _RuinsLook.sky[3], px + 2, 42 - h, 2, 1);
  }
}

/// The goal: a tall broken tower with one lit window, nearer with
/// [progress].
void _tower(Canvas canvas, Size size, double u, double progress) {
  final w = size.width / u;
  final p = progress.clamp(0.0, 1.0);
  final x = w * (1.05 - 0.6 * p);
  final scale = 1 + p * 0.8;
  final bw = (7 * scale).round().toDouble();
  final bh = (22 * scale).round().toDouble();
  const base = 44.0;
  final body = Paint()..color = const Color(0xFF2B2030);
  sidePixels(canvas, u, body, x - bw / 2, base - bh, bw, bh);
  sidePixels(canvas, u, Paint()..color = _RuinsLook.skylineRim, x - bw / 2,
      base - bh, bw, 1);
  // The broken crown: two uneven teeth.
  sidePixels(canvas, u, body, x - bw / 2, base - bh - 2, 2, 2);
  sidePixels(canvas, u, body, x + bw / 2 - 2, base - bh - 1, 2, 1);
  final win = math.max(2, (2 * scale).round()).toDouble();
  sidePixels(canvas, u, Paint()..color = _RuinsLook.window, x - win / 2,
      base - bh * 0.7, win, win * 1.5);
}

/// Ruined walls with a gap or an arch, repeating along the ground.
void _walls(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.6;
  final body = Paint()..color = _RuinsLook.wall;
  final rim = Paint()..color = _RuinsLook.wallRim;
  final hole = Paint()..color = _RuinsLook.hill;
  final offset = scroll / u;
  for (var i = 0; i < 4; i++) {
    final px = ((i * span / 4 + 14 - offset) % span + span) % span - 12;
    if (px < -12 || px > w + 2) continue;
    final h = 8.0 + (i % 3) * 3;
    sidePixels(canvas, u, body, px, 50 - h, 10, h);
    sidePixels(canvas, u, rim, px, 50 - h, 10, 1);
    if (i % 2 == 0) {
      // An arch: a hole with a rounded head.
      sidePixels(canvas, u, hole, px + 3, 50 - 5, 4, 5);
      sidePixels(canvas, u, hole, px + 4, 50 - 6, 2, 1);
    } else {
      // A bitten top.
      sidePixels(canvas, u, hole, px + 6, 50 - h, 3, 2);
    }
  }
}

/// Fallen stone and a charred stump, along the near ground.
void _rubble(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.7;
  final stone = Paint()..color = const Color(0xFF574B53);
  final light = Paint()..color = const Color(0xFF7A6B72);
  final stump = Paint()..color = const Color(0xFF1E181E);
  final offset = scroll / u;
  for (var i = 0; i < 6; i++) {
    final px = ((i * span / 3 + 18 - offset) % span + span) % span - 10;
    if (px < -8 || px > w + 4) continue;
    final y = 58.0 + (i % 2) * 2;
    if (i % 3 == 0) {
      sidePixels(canvas, u, stone, px, y - 3, 6, 3);
      sidePixels(canvas, u, light, px + 1, y - 4, 3, 1);
    } else if (i % 3 == 1) {
      sidePixels(canvas, u, stump, px, y - 4, 2, 4);
      sidePixels(canvas, u, stump, px + 2, y - 2, 1, 2);
    } else {
      sidePixels(canvas, u, stone, px, y - 2, 4, 2);
    }
  }
}

void _path(Canvas canvas, Size size, double scroll, double t, double u) {
  final w = size.width / u;
  sidePixels(canvas, u, Paint()..color = _RuinsLook.path, 0, 63, w + 1, 9);
  sidePixels(canvas, u, Paint()..color = _RuinsLook.pathLight, 0, 63, w + 1, 1);
  final dark = Paint()..color = _RuinsLook.pathDark;
  final offset = scroll / u;
  for (var i = 0; i < 14; i++) {
    final px = ((i * 9 - offset) % (w + 12) + (w + 12)) % (w + 12) - 6;
    sidePixels(canvas, u, dark, px, 67 + (i % 3), 4, 1);
  }
}
