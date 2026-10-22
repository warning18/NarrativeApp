// The fen scene kit: a grey-green dusk in dithered bands with a pale moon,
// far lines of dead trees and reed, black pools with reeds between, reed
// clumps and a boardwalk path of planks. The goal, a lantern on a post that
// bobs a little, comes forward as the days pass ([progress] 0 to 1).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit_common.dart';
import 'side_view.dart';

/// The fen's colours.
abstract final class FenLook {
  static const sky = [
    Color(0xFF151D1F),
    Color(0xFF2B3A3A),
    Color(0xFF55675C),
    Color(0xFF8E9C82),
    Color(0xFFB9BFA0),
  ];
  static const moon = Color(0xFFE6E8D2);
  static const far = Color(0xFF28342F);
  static const farRim = Color(0xFF3F4F46);
  static const water = Color(0xFF111B1D);
  static const waterGleam = Color(0xFF3B5254);
  static const bank = Color(0xFF232C26);
  static const bankRim = Color(0xFF3A473C);
  static const reed = Color(0xFF6B7B4E);
  static const reedDark = Color(0xFF3F4A30);
  static const near = Color(0xFF1B231E);
  static const nearRim = Color(0xFF2E3A2F);
  static const plank = Color(0xFF5A4A3A);
  static const plankLight = Color(0xFF7C6850);
  static const plankDark = Color(0xFF362B22);
  static const lantern = Color(0xFFF5D27A);
  static const post = Color(0xFF3A3028);
}

/// The layers, back to front. [progress] brings the goal's lantern nearer.
List<SideLayer> fenLayers({double progress = 0}) => [
      SideLayer(
          0,
          (c, s, scroll, t, u) =>
              kitSky(c, s, u, bands: FenLook.sky, ground: FenLook.far)),
      SideLayer(
          0.05,
          (c, s, scroll, t, u) => kitDisc(c, s, u,
              cx: 0.28,
              cy: 20,
              disc: FenLook.moon.withValues(alpha: 0.9),
              glow: FenLook.moon.withValues(alpha: 0.18),
              radius: 3)),
      SideLayer(0.12, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 43,
            amp: 1.2,
            wave: 0.08,
            phase: 0.9,
            fill: FenLook.far,
            rim: FenLook.farRim);
        _deadTrees(c, s, u, scroll);
        _lantern(c, s, u, progress, t);
      }),
      SideLayer(0.3, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 48,
            amp: 1.6,
            wave: 0.06,
            phase: 2.1,
            fill: FenLook.bank,
            rim: FenLook.bankRim);
        _pools(c, s, u, scroll, t);
      }),
      SideLayer(0.8, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 56,
            amp: 2.2,
            wave: 0.04,
            phase: 0.3,
            fill: FenLook.near,
            rim: FenLook.nearRim);
        _reeds(c, s, u, scroll);
      }),
      SideLayer(1.0, _boardwalk),
    ];

/// The goal: a lantern hung from a post, its light bobbing, nearer with
/// [progress].
void _lantern(Canvas canvas, Size size, double u, double progress, double t) {
  final w = size.width / u;
  final p = progress.clamp(0.0, 1.0);
  final x = w * (1.05 - 0.6 * p);
  final scale = 1 + p * 0.8;
  final ph = (20 * scale).round().toDouble();
  const base = 45.0;
  final bob = math.sin(t * 1.6).roundToDouble();
  sidePixels(canvas, u, Paint()..color = FenLook.post, x, base - ph, 1.0, ph);
  sidePixels(canvas, u, Paint()..color = FenLook.post, x, base - ph, 3.0, 1);
  final lamp = math.max(2, (2 * scale).round()).toDouble();
  // A halo of pale pixels around the flame.
  final halo = Paint()..color = FenLook.lantern.withValues(alpha: 0.25);
  sidePixels(canvas, u, halo, x + 2 - lamp, base - ph + 1 + bob - lamp,
      lamp * 3, lamp * 3);
  sidePixels(canvas, u, Paint()..color = FenLook.lantern, x + 2,
      base - ph + 1 + bob, lamp, lamp * 1.5);
}

/// Dead trees and reed heads standing on the far bank.
void _deadTrees(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.5;
  final offset = scroll / u;
  final bark = Paint()..color = FenLook.farRim;
  for (var i = 0; i < 7; i++) {
    final px = kitSlot(i, 7, span, offset, 5) + 4;
    if (px < -6 || px > w + 2) continue;
    final h = 6.0 + (i % 3) * 3;
    sidePixels(canvas, u, bark, px, 43 - h, 1, h);
    // Two bare boughs, one each side.
    sidePixels(canvas, u, bark, px - 2, 43 - h + 2, 2, 1);
    sidePixels(canvas, u, bark, px + 1, 43 - h + 4, 2, 1);
  }
}

/// Black pools between the banks, with a pale gleam that drifts.
void _pools(Canvas canvas, Size size, double u, double scroll, double t) {
  final w = size.width / u;
  final span = w * 1.4;
  final offset = scroll / u;
  final water = Paint()..color = FenLook.water;
  final gleam = Paint()..color = FenLook.waterGleam;
  for (var i = 0; i < 4; i++) {
    final px = kitSlot(i, 4, span, offset, 8);
    if (px < -16 || px > w + 2) continue;
    final len = 14.0 + (i % 2) * 6;
    sidePixels(canvas, u, water, px, 51, len, 3);
    final gx = px + 2 + ((math.sin(t * 0.8 + i) + 1) * (len - 6) / 2);
    sidePixels(canvas, u, gleam, gx, 51, 3, 1);
  }
}

/// Reed clumps along the near bank.
void _reeds(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.7;
  final offset = scroll / u;
  final reed = Paint()..color = FenLook.reed;
  final dark = Paint()..color = FenLook.reedDark;
  for (var i = 0; i < 8; i++) {
    final px = kitSlot(i, 4, span, offset, 12) + (i % 2) * 5;
    if (px < -8 || px > w + 4) continue;
    final y = 60.0;
    final h = 5.0 + (i % 3) * 2;
    for (var k = 0; k < 4; k++) {
      sidePixels(canvas, u, k.isEven ? reed : dark, px + k * 1.0,
          y - h + (k % 2) * 2, 1, h - (k % 2) * 2);
    }
    // A seed head on the tallest stalk.
    sidePixels(canvas, u, dark, px + 1, y - h - 1, 1, 2);
  }
}

/// A boardwalk: planks along the bottom, each with a dark seam.
void _boardwalk(Canvas canvas, Size size, double scroll, double t, double u) {
  final w = size.width / u;
  sidePixels(canvas, u, Paint()..color = FenLook.plank, 0, 63, w + 1, 9);
  sidePixels(canvas, u, Paint()..color = FenLook.plankLight, 0, 63, w + 1, 1);
  final seam = Paint()..color = FenLook.plankDark;
  final offset = scroll / u;
  for (var i = 0; i < 16; i++) {
    final px = ((i * 8 - offset) % (w + 12) + (w + 12)) % (w + 12) - 6;
    sidePixels(canvas, u, seam, px, 63, 1, 9);
  }
  sidePixels(canvas, u, Paint()..color = FenLook.plankDark, 0, 71, w + 1, 1);
}
