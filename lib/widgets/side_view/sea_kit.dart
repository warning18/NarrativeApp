// The sea scene kit (board 5): the same five waters and the same weather the
// battle paints (sea_battlefield.dart), seen from the side: a sky in
// dithered bands, the far shore of the place, the sea in bands with wave
// lines at their own speeds, and the ship small on it. The ship drawn here is
// a placeholder hull; the real ones come from the hulls' own data once the
// user has picked from board 5.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../combat/ship_battle.dart' show SeaWeather;
import '../sea_battlefield.dart' show SeaLook, SeaWaters;
import 'side_view.dart';

const _horizon = 40;

const Map<SeaWaters, List<Color>> _sky = {
  SeaWaters.open: [
    Color(0xFF1A3A52),
    Color(0xFF24506B),
    Color(0xFF3A6C86),
    Color(0xFF6B97AB)
  ],
  SeaWaters.shallows: [
    Color(0xFF2E7C86),
    Color(0xFF4FA3A6),
    Color(0xFF8CCBC2),
    Color(0xFFD4EBD8)
  ],
  SeaWaters.drowned: [
    Color(0xFF1B2A22),
    Color(0xFF2A3E31),
    Color(0xFF3F5A44),
    Color(0xFF5E7A58)
  ],
  SeaWaters.abyss: [
    Color(0xFF07060D),
    Color(0xFF120E22),
    Color(0xFF241A44),
    Color(0xFF3A2A66)
  ],
  SeaWaters.ashen: [
    Color(0xFF2A2D2E),
    Color(0xFF41484A),
    Color(0xFF5F6A6B),
    Color(0xFF868C88)
  ],
};

const _bayer = [
  [0, 2],
  [3, 1],
];

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// What drifts over [waters] in [weather]: the squall's rain, the fog, the
/// ash of the ashen coast, the abyss's motes.
SideParticles seaParticlesFor(SeaWaters waters, SeaWeather weather) {
  if (weather == SeaWeather.squall) return SideParticles.rain;
  if (weather == SeaWeather.fog) return SideParticles.fog;
  return switch (waters) {
    SeaWaters.ashen => SideParticles.ash,
    SeaWaters.abyss => SideParticles.motes,
    _ => SideParticles.none,
  };
}

/// The sea's layers, back to front: the sky and the far shore stand, the
/// waves go by at 0.2, 0.5 and 0.9 of the sail's pace.
List<SideLayer> seaLayers(SeaWaters waters, SeaWeather weather) {
  final look = SeaLook.of(waters);
  final squall = weather == SeaWeather.squall;
  final fog = weather == SeaWeather.fog;
  Color sky(Color c) => squall
      ? _mix(c, look.deep, 0.55)
      : fog
          ? _mix(c, const Color(0xFFC9D2D0), 0.6)
          : c;
  return [
    SideLayer(0, (c, s, scroll, t, u) {
      final bands = [for (final b in _sky[waters]!) sky(b)];
      final cols = (s.width / u).ceil();
      final paint = Paint();
      for (var y = 0; y < _horizon; y++) {
        final p = y / _horizon * (bands.length - 1);
        final i = p.floor();
        final f = p - i;
        final lo = bands[i], hi = bands[math.min(i + 1, bands.length - 1)];
        for (var x = 0; x < cols; x++) {
          paint.color = f * 4 > _bayer[y % 2][x % 2] ? hi : lo;
          c.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.5, u + 0.5), paint);
        }
      }
    }),
    SideLayer(
        0.04, (c, s, scroll, t, u) => _shore(c, s, u, scroll, waters, look)),
    SideLayer(0, (c, s, scroll, t, u) {
      // The sea in bands, deep to shallow to deep.
      final rows = sideViewRows - _horizon;
      final paint = Paint();
      for (var y = 0; y < rows; y++) {
        final k = 0.55 * (1 - ((y / rows) - 0.55).abs() * 1.6);
        paint.color = _mix(look.deep, look.shallow, k.clamp(0.0, 1.0));
        c.drawRect(
            Rect.fromLTWH(0, (_horizon + y) * u, s.width, u + 0.5), paint);
      }
    }),
    for (final (speed, row, step) in const [
      (0.2, 3, 7),
      (0.5, 9, 10),
      (0.9, 18, 14),
    ])
      SideLayer(speed, (c, s, scroll, t, u) {
        final w = s.width / u;
        final offset = scroll / u;
        final wave = Paint()..color = look.wave;
        final foam = Paint()..color = look.foam;
        final bob = squall ? 2.0 : 1.0;
        for (var x0 = -step * 2.0; x0 < w + step; x0 += step * 2) {
          final x = ((x0 - offset) % (w + step * 2)) - step;
          final y = _horizon + row + (math.sin(t * 1.4 + x0) * bob).round();
          sidePixels(c, u, wave, x, y.toDouble(), step.toDouble(), 1);
          if (row.isOdd || speed > 0.6) {
            sidePixels(c, u, foam, x + step / 2, y - 1.0, 1, 1);
          }
        }
      }),
  ];
}

void _shore(Canvas canvas, Size size, double u, double scroll, SeaWaters waters,
    SeaLook look) {
  final w = size.width / u;
  final offset = scroll / u;
  final land = Paint()..color = _mix(_sky[waters]![1], look.deep, 0.5);
  switch (waters) {
    case SeaWaters.shallows:
      final sand = Paint()..color = const Color(0xFFA8965F);
      final palm = Paint()..color = const Color(0xFF3E7A4A);
      for (var x = 0.0; x < w; x += 1) {
        final wx = x + offset;
        final h = 2 + 2 * ((math.sin(wx * 0.18) + 1) / 2);
        if (wx % 90 > 40 && wx % 90 < 75) {
          sidePixels(canvas, u, sand, x, _horizon - h, 1, h);
        }
      }
      final px = ((60 - offset) % 90 + 90) % 90;
      sidePixels(canvas, u, Paint()..color = const Color(0xFF5A4A2A), px,
          _horizon - 9, 1, 6);
      sidePixels(canvas, u, palm, px - 3, _horizon - 10, 7, 1);
    case SeaWaters.drowned:
      for (final (x0, h) in const [(10.0, 14.0), (28.0, 9.0), (60.0, 12.0)]) {
        final px = ((x0 - offset) % 90 + 90) % 90;
        sidePixels(canvas, u, land, px, _horizon - h, 4, h);
      }
    case SeaWaters.ashen:
      for (var x = 0.0; x < w; x += 1) {
        final wx = x + offset;
        final h = 4 + 4 * ((math.sin(wx * 0.11) + 1) / 2);
        sidePixels(canvas, u, land, x, _horizon - h, 1, h);
      }
      for (final x0 in const [14.0, 40.0, 70.0]) {
        final px = ((x0 - offset) % 90 + 90) % 90;
        sidePixels(canvas, u, Paint()..color = const Color(0xFFE0762B), px,
            _horizon - 9, 1, 1);
      }
    case SeaWaters.open:
      for (var x = 0.0; x < w; x += 1) {
        final wx = x + offset;
        if (wx % 120 < 28) {
          final h = 3 + 3 * ((math.sin(wx * 0.22) + 1) / 2);
          sidePixels(canvas, u, land, x, _horizon - h, 1, h);
        }
      }
    case SeaWaters.abyss:
      final haze = Paint()..color = const Color(0xFF2A1E4A);
      for (var y = _horizon - 6; y < _horizon; y++) {
        for (var x = 0.0; x < w; x += 1) {
          if (((x + offset).floor() + y) % 5 == 0) {
            sidePixels(canvas, u, haze, x, y.toDouble(), 1, 1);
          }
        }
      }
  }
}

/// The ship: a placeholder hull and sail, riding the swell. [lift] raises it
/// (a flying hull) and casts its shadow on the water.
SideLayer seaShip({double lift = 0}) => SideLayer(0, (c, s, scroll, t, u) {
      final w = s.width / u;
      final x = w * 0.42;
      final bob = (math.sin(t * 1.8) * 1.2).round().toDouble();
      final y = _horizon + 22.0 - lift + bob;
      if (lift > 0) {
        sidePixels(c, u, Paint()..color = const Color(0x55000000), x - 2,
            _horizon + 24, 28, 1);
      }
      final hull = Paint()..color = const Color(0xFF6B4423);
      final plank = Paint()..color = const Color(0xFF8B5A2B);
      final mast = Paint()..color = const Color(0xFF3E2723);
      final sail = Paint()..color = const Color(0xFFE8DCC0);
      final sailShade = Paint()..color = const Color(0xFFC2AE86);
      // Hull, planking, mast, sail, a pennant.
      sidePixels(c, u, hull, x, y - 4, 24, 4);
      sidePixels(c, u, plank, x + 1, y - 4, 22, 1);
      sidePixels(c, u, hull, x - 3, y - 6, 4, 2);
      sidePixels(c, u, mast, x + 11, y - 22, 1, 18);
      sidePixels(c, u, sail, x + 4, y - 21, 7, 13);
      sidePixels(c, u, sailShade, x + 4, y - 9, 7, 1);
      sidePixels(c, u, sail, x + 12, y - 19, 6, 10);
      sidePixels(
          c, u, Paint()..color = const Color(0xFFC0392B), x + 12, y - 23, 3, 1);
    });
