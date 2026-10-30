// The frost scene kit (the tear's winter in summer): a pale, cold dawn in
// dithered bands with a low white sun, far white peaks, snowed pines and a
// pilgrims' cairn on a ridge, drifts and frozen rocks near, and a path of
// packed snow with dark tracks. The goal, a shelter with one lit window and
// a thread of smoke, comes forward as the days pass ([progress] 0 to 1).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit_common.dart';
import 'side_view.dart';

/// The frost's colours.
abstract final class _FrostLook {
  static const sky = [
    Color(0xFF25344A),
    Color(0xFF51698A),
    Color(0xFF8DA6C2),
    Color(0xFFC3D3E0),
    Color(0xFFEAF0F2),
  ];
  static const sun = Color(0xFFF7FAFB);
  static const peak = Color(0xFF9FB2C6);
  static const peakRim = Color(0xFFE3ECF2);
  static const ridge = Color(0xFF7D93AB);
  static const ridgeRim = Color(0xFFDCE6EE);
  static const pine = Color(0xFF2F4A4C);
  static const pineSnow = Color(0xFFE8F0F2);
  static const trunk = Color(0xFF3A3236);
  static const near = Color(0xFFCFDCE6);
  static const nearRim = Color(0xFFF4F8FA);
  static const path = Color(0xFFE2EBF1);
  static const pathDark = Color(0xFF9DB0C2);
  static const pathLight = Color(0xFFFFFFFF);
  static const stone = Color(0xFF6A7A8A);
  static const window = Color(0xFFF8C878);
  static const smoke = Color(0xFFB8C6D2);
}

/// The layers, back to front. [progress] brings the goal's shelter nearer.
List<SideLayer> frostLayers({double progress = 0}) => [
      SideLayer(
          0,
          (c, s, scroll, t, u) =>
              kitSky(c, s, u, bands: _FrostLook.sky, ground: _FrostLook.peak)),
      SideLayer(
          0.05,
          (c, s, scroll, t, u) => kitDisc(c, s, u,
              cx: 0.72,
              cy: 40,
              disc: _FrostLook.sun.withValues(alpha: 0.9),
              glow: _FrostLook.sun.withValues(alpha: 0.22),
              radius: 3)),
      SideLayer(0.12, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 36,
            amp: 7,
            wave: 0.07,
            phase: 0.4,
            fill: _FrostLook.peak,
            rim: _FrostLook.peakRim);
        _shelter(c, s, u, progress);
      }),
      SideLayer(0.3, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 46,
            amp: 2.4,
            wave: 0.05,
            phase: 1.9,
            fill: _FrostLook.ridge,
            rim: _FrostLook.ridgeRim);
        _pines(c, s, u, scroll);
      }),
      SideLayer(0.8, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 55,
            amp: 3,
            wave: 0.04,
            phase: 2.8,
            fill: _FrostLook.near,
            rim: _FrostLook.nearRim);
        _rocks(c, s, u, scroll);
      }),
      SideLayer(
          1.0,
          (c, s, scroll, t, u) => kitPath(c, s, scroll, u,
              body: _FrostLook.path,
              light: _FrostLook.pathLight,
              dark: _FrostLook.pathDark)),
    ];

/// The goal: a low shelter with a snowed roof, a lit window and a thread of
/// smoke, nearer with [progress].
void _shelter(Canvas canvas, Size size, double u, double progress) {
  final w = size.width / u;
  final p = progress.clamp(0.0, 1.0);
  final x = w * (1.05 - 0.6 * p);
  final scale = 1 + p * 0.8;
  final bw = (12 * scale).round().toDouble();
  final bh = (7 * scale).round().toDouble();
  const base = 44.0;
  sidePixels(canvas, u, Paint()..color = _FrostLook.trunk, x - bw / 2,
      base - bh, bw, bh);
  // The snowed roof, a step wider than the walls.
  sidePixels(canvas, u, Paint()..color = _FrostLook.pineSnow, x - bw / 2 - 1,
      base - bh - 2, bw + 2, 2);
  final win = math.max(2, (2 * scale).round()).toDouble();
  sidePixels(canvas, u, Paint()..color = _FrostLook.window, x - win / 2,
      base - bh * 0.7, win, win);
  // Smoke: three grey pixels leaning away.
  final smoke = Paint()..color = _FrostLook.smoke;
  for (var i = 0; i < 3; i++) {
    sidePixels(canvas, u, smoke, x + bw / 4 + i, base - bh - 4 - i * 2, 1, 1);
  }
}

/// Snowed pines in a band along the ridge, and a pilgrims' cairn among them.
void _pines(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.6;
  final offset = scroll / u;
  final needles = Paint()..color = _FrostLook.pine;
  final snow = Paint()..color = _FrostLook.pineSnow;
  final trunk = Paint()..color = _FrostLook.trunk;
  final stone = Paint()..color = _FrostLook.stone;
  for (var i = 0; i < 6; i++) {
    final px = kitSlot(i, 6, span, offset, 6);
    if (px < -12 || px > w + 2) continue;
    if (i == 4) {
      // The cairn: three stones piled, a cap of snow.
      sidePixels(canvas, u, stone, px, 48 - 2, 5, 2);
      sidePixels(canvas, u, stone, px + 1, 48 - 4, 3, 2);
      sidePixels(canvas, u, snow, px + 1, 48 - 5, 3, 1);
      continue;
    }
    final h = 9.0 + (i % 3) * 3;
    sidePixels(canvas, u, trunk, px + 3, 48 - 2, 1, 2);
    // Three tiers, each narrower, each with a rim of snow.
    for (var tier = 0; tier < 3; tier++) {
      final tw = 8.0 - tier * 2;
      final ty = 48 - 2 - (tier + 1) * h / 3;
      sidePixels(canvas, u, needles, px + (8 - tw) / 2, ty, tw, h / 3);
      sidePixels(canvas, u, snow, px + (8 - tw) / 2, ty, tw, 1);
    }
  }
}

/// Frozen rocks and snow humps along the near ground.
void _rocks(Canvas canvas, Size size, double u, double scroll) {
  final w = size.width / u;
  final span = w * 1.7;
  final offset = scroll / u;
  final rock = Paint()..color = _FrostLook.stone;
  final snow = Paint()..color = _FrostLook.pineSnow;
  for (var i = 0; i < 6; i++) {
    final px = kitSlot(i, 3, span, offset, 18) + 2;
    if (px < -10 || px > w + 4) continue;
    final y = 59.0 + (i % 2) * 2;
    if (i % 2 == 0) {
      sidePixels(canvas, u, rock, px, y - 3, 6, 3);
      sidePixels(canvas, u, snow, px, y - 4, 5, 1);
    } else {
      sidePixels(canvas, u, snow, px, y - 2, 8, 2);
      sidePixels(
          canvas, u, Paint()..color = _FrostLook.nearRim, px + 1, y - 3, 4, 1);
    }
  }
}
