// The sea cliffs scene kit: a bright salt morning in dithered bands with a
// pale sun, the sea far below with a horizon of sparkles, headlands of
// weed-hung rock, a ledge of grass and shingle with gulls turning above it,
// and a path along the edge. The goal, a lighthouse with its lamp lit,
// comes forward as the days pass ([progress] 0 to 1).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit_common.dart';
import 'side_view.dart';

/// The sea cliffs' colours.
abstract final class _CliffsLook {
  static const sky = [
    Color(0xFF2F4A63),
    Color(0xFF5F8299),
    Color(0xFF9DBBC8),
    Color(0xFFD3DFDA),
    Color(0xFFF1E8CF),
  ];
  static const sun = Color(0xFFFFF3D2);
  static const sea = Color(0xFF3C6A80);
  static const seaDeep = Color(0xFF2B5166);
  static const spark = Color(0xFFDDF0F0);
  static const headland = Color(0xFF5E655F);
  static const headlandRim = Color(0xFF7F8A7C);
  static const cliff = Color(0xFF6B635A);
  static const cliffRim = Color(0xFF8F8576);
  static const weed = Color(0xFF445A3A);
  static const grass = Color(0xFF6C8A4B);
  static const grassDark = Color(0xFF4A6234);
  static const path = Color(0xFF9A8E78);
  static const pathLight = Color(0xFFC4B898);
  static const pathDark = Color(0xFF6E6452);
  static const tower = Color(0xFFEDE6D6);
  static const towerBand = Color(0xFFB4483C);
  static const lamp = Color(0xFFFFD36A);
  static const gull = Color(0xFFF4F4EE);
}

/// The layers, back to front. [progress] brings the goal's lighthouse nearer.
List<SideLayer> cliffsLayers({double progress = 0}) => [
      SideLayer(
          0,
          (c, s, scroll, t, u) =>
              kitSky(c, s, u, bands: _CliffsLook.sky, ground: _CliffsLook.sea)),
      SideLayer(
          0.05,
          (c, s, scroll, t, u) => kitDisc(c, s, u,
              cx: 0.68,
              cy: 14,
              disc: _CliffsLook.sun.withValues(alpha: 0.95),
              glow: _CliffsLook.sun.withValues(alpha: 0.2),
              radius: 3)),
      SideLayer(0.1, (c, s, scroll, t, u) {
        _sea(c, s, u, scroll, t);
        _lighthouse(c, s, u, progress);
      }),
      SideLayer(0.3, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 47,
            amp: 3.4,
            wave: 0.045,
            phase: 0.8,
            fill: _CliffsLook.headland,
            rim: _CliffsLook.headlandRim);
        _gulls(c, s, u, scroll, t);
      }),
      SideLayer(0.8, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 55,
            amp: 2.2,
            wave: 0.05,
            phase: 2.2,
            fill: _CliffsLook.cliff,
            rim: _CliffsLook.grass);
        _ledge(c, s, u, scroll);
      }),
      SideLayer(
          1.0,
          (c, s, scroll, t, u) => kitPath(c, s, scroll, u,
              body: _CliffsLook.path,
              light: _CliffsLook.pathLight,
              dark: _CliffsLook.pathDark)),
    ];

/// The sea below the headlands: a band to the horizon with sparkles that
/// come and go.
void _sea(Canvas canvas, Size size, double u, double scroll, double t) {
  final w = size.width / u;
  sidePixels(canvas, u, Paint()..color = _CliffsLook.sea, 0, 42, w + 1, 12);
  sidePixels(canvas, u, Paint()..color = _CliffsLook.seaDeep, 0, 48, w + 1, 6);
  final spark = Paint()..color = _CliffsLook.spark;
  final offset = scroll / u;
  for (var i = 0; i < 12; i++) {
    final px = ((i * 11 - offset) % (w + 8) + (w + 8)) % (w + 8) - 4;
    if (math.sin(t * 1.4 + i * 2.1) < 0.2) continue;
    sidePixels(canvas, u, spark, px, 43 + (i % 4) * 2, 2, 1);
  }
}

/// The goal: a lighthouse with a red band and its lamp lit, nearer with
/// [progress], standing on the far headland.
void _lighthouse(Canvas canvas, Size size, double u, double progress) {
  final w = size.width / u;
  final p = progress.clamp(0.0, 1.0);
  final x = w * (1.05 - 0.6 * p);
  final scale = 1 + p * 0.8;
  final bw = (5 * scale).round().toDouble();
  final bh = (18 * scale).round().toDouble();
  const base = 46.0;
  sidePixels(canvas, u, Paint()..color = _CliffsLook.tower, x - bw / 2,
      base - bh, bw, bh);
  sidePixels(canvas, u, Paint()..color = _CliffsLook.towerBand, x - bw / 2,
      base - bh * 0.55, bw, math.max(2, bh * 0.15));
  // The lamp room: a lit block under a small cap.
  final lamp = math.max(2, (3 * scale).round()).toDouble();
  sidePixels(canvas, u, Paint()..color = _CliffsLook.lamp, x - lamp / 2,
      base - bh - lamp, lamp, lamp);
  sidePixels(canvas, u, Paint()..color = _CliffsLook.towerBand,
      x - lamp / 2 - 1, base - bh - lamp - 1, lamp + 2, 1);
}

/// Gulls turning above the headland: two pixels of wing that beat.
void _gulls(Canvas canvas, Size size, double u, double scroll, double t) {
  final w = size.width / u;
  final gull = Paint()..color = _CliffsLook.gull;
  final offset = scroll / u;
  for (var i = 0; i < 4; i++) {
    final px = ((i * w / 3 + 10 - offset * 0.6 + math.sin(t * 0.7 + i) * 3) %
                    (w + 10) +
                (w + 10)) %
            (w + 10) -
        5;
    final py = 30.0 + (i % 3) * 4 + math.sin(t * 1.3 + i * 1.7) * 1.5;
    final up = math.sin(t * 5 + i * 2) > 0;
    sidePixels(canvas, u, gull, px, py + (up ? 0 : 1), 2, 1);
    sidePixels(canvas, u, gull, px + 2, py + (up ? 1 : 0), 2, 1);
  }
}

/// Grass tufts, weed and a few shingle stones along the ledge.
void _ledge(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.7;
  final offset = scroll / u;
  final grass = Paint()..color = _CliffsLook.grass;
  final dark = Paint()..color = _CliffsLook.grassDark;
  final weed = Paint()..color = _CliffsLook.weed;
  final stone = Paint()..color = _CliffsLook.cliffRim;
  for (var i = 0; i < 8; i++) {
    final px = kitSlot(i, 4, span, offset, 10) + (i % 2) * 4;
    if (px < -8 || px > w + 4) continue;
    final y = 59.0 + (i % 2);
    switch (i % 3) {
      case 0:
        sidePixels(canvas, u, grass, px, y - 3, 1, 3);
        sidePixels(canvas, u, dark, px + 1, y - 2, 1, 2);
        sidePixels(canvas, u, grass, px + 2, y - 4, 1, 4);
      case 1:
        // Weed hanging over the lip.
        sidePixels(canvas, u, weed, px, y - 1, 1, 4);
        sidePixels(canvas, u, weed, px + 2, y - 1, 1, 3);
      default:
        sidePixels(canvas, u, stone, px, y - 2, 3, 2);
        sidePixels(canvas, u, stone, px + 4, y - 1, 2, 1);
    }
  }
}
