// The sea fight seen from the masthead: the water the battle is fought on
// (each of the Eel's waters with its own swell), the weather over it as
// particles, and the ships drawn from above with their four rooms laid out
// along the deck -- helm at the stern, the hold's hatch, the guns
// amidships and the bulwark at the bow -- their shields as arcs on the side
// that faces the enemy.
//
// Everything here is painted from a time in seconds, so one ticker (the
// panel's) drives the whole sea, and a still frame (reduced motion) is the
// same picture at t = 0.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';

/// The waters a battle is fought on, which set the sea's colour, its kind
/// of waves and what drifts over it.
enum SeaWaters {
  /// The open sea: long, slow swells with foam on their crests.
  open,

  /// Clear shallows over sand: light nets on the bottom, sandbars, rocks.
  shallows,

  /// Murky green over sunken ruins: kelp, and bubbles rising.
  drowned,

  /// Black water over the deep: slow rings, motes of violet light.
  abyss,

  /// The grey chop off the ashen coast: short waves, ash falling.
  ashen,
}

/// [name] (ports.json `waters`) as waters; failing that, the waters of
/// the port [portId] sails to; failing both, the open sea.
SeaWaters seaWatersFor({String? name, String? portId}) {
  for (final w in SeaWaters.values) {
    if (w.name == name) return w;
  }
  return switch (portId) {
    'port_ashen_landing' => SeaWaters.ashen,
    'port_smugglers_wharf' => SeaWaters.shallows,
    'port_drowned_stair' => SeaWaters.drowned,
    'port_black_reliquary' => SeaWaters.abyss,
    _ => SeaWaters.open,
  };
}

/// The colours of a sea.
class SeaLook {
  const SeaLook({
    required this.deep,
    required this.shallow,
    required this.wave,
    required this.foam,
    required this.accent,
  });

  /// The water far from the light, and near it.
  final Color deep;
  final Color shallow;

  /// The wave lines, the foam on crests and wakes, and what is special
  /// to these waters (sand, kelp, void light, ash).
  final Color wave;
  final Color foam;
  final Color accent;

  static SeaLook of(SeaWaters waters) => switch (waters) {
        SeaWaters.open => const SeaLook(
            deep: Color(0xFF0E2A3A),
            shallow: Color(0xFF17435A),
            wave: Color(0xFF2B6583),
            foam: Color(0xFFD7EEF4),
            accent: Color(0xFF7FC3D8)),
        SeaWaters.shallows => const SeaLook(
            deep: Color(0xFF136466),
            shallow: Color(0xFF2A9C93),
            wave: Color(0xFF5CC6B6),
            foam: Color(0xFFF2FBF6),
            accent: Color(0xFFE3CF94)),
        SeaWaters.drowned => const SeaLook(
            deep: Color(0xFF14261D),
            shallow: Color(0xFF26402F),
            wave: Color(0xFF3E6247),
            foam: Color(0xFFBFD6B8),
            accent: Color(0xFF6E8F4E)),
        SeaWaters.abyss => const SeaLook(
            deep: Color(0xFF0A0812),
            shallow: Color(0xFF1C1432),
            wave: Color(0xFF3A2A66),
            foam: Color(0xFFCBB8FF),
            accent: Color(0xFF9A6BFF)),
        SeaWaters.ashen => const SeaLook(
            deep: Color(0xFF1E2426),
            shallow: Color(0xFF394346),
            wave: Color(0xFF5C696B),
            foam: Color(0xFFE4E2DC),
            accent: Color(0xFFB9B1A4)),
      };
}

double _hash(int i, [int salt = 0]) {
  final x = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return x - x.floorToDouble();
}

/// Where the wind blows, in screen terms, for the weather: a tailwind
/// runs with the Eel (to the right), a crosswind across the ships.
Offset _windOf(SeaWeather weather) => switch (weather) {
      SeaWeather.calm => const Offset(6, 0),
      SeaWeather.tailwind => const Offset(70, 0),
      SeaWeather.crosswind => const Offset(34, -46),
      SeaWeather.squall => const Offset(40, 10),
      SeaWeather.fog => const Offset(10, 0),
    };

/// The water under the ships: its colour, its waves and what lies on or
/// under it, moving with [t] (seconds). A squall roughens every sea, a
/// calm one glints.
class SeaSurfacePainter extends CustomPainter {
  const SeaSurfacePainter({
    required this.waters,
    required this.weather,
    required this.t,
  });

  final SeaWaters waters;
  final SeaWeather weather;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final look = SeaLook.of(waters);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.deep, look.shallow, look.deep],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    final rough = weather == SeaWeather.squall ? 1.8 : 1.0;
    final drift = _windOf(weather).dx / 70;
    // What lies under the water first, the surface's waves over it.
    SeaDepthsPainter(waters: waters, t: t).paint(canvas, size);
    switch (waters) {
      case SeaWaters.open:
        _swells(canvas, size, look, rough, drift);
      case SeaWaters.shallows:
        _shallows(canvas, size, look, rough, drift);
      case SeaWaters.drowned:
        _drowned(canvas, size, look, rough);
      case SeaWaters.abyss:
        _abyss(canvas, size, look, rough);
      case SeaWaters.ashen:
        _chop(canvas, size, look, rough, drift);
    }
    if (weather == SeaWeather.squall) _whitecaps(canvas, size, look);
    if (weather == SeaWeather.calm) _glints(canvas, size, look);
  }

  /// Long swells: wide sine bands rolling slowly down the screen, foam
  /// dashes where they crest.
  void _swells(
      Canvas canvas, Size size, SeaLook look, double rough, double drift) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = look.wave.withValues(alpha: 0.7)
      ..strokeWidth = 3;
    final foam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = look.foam.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    const gap = 46.0;
    final shift = (t * 6) % gap;
    for (var y = -gap + shift; y < size.height + gap; y += gap) {
      final row = ((y - shift) / gap).round();
      final path = Path();
      for (var x = -10.0; x <= size.width + 10; x += 8) {
        final yy = y +
            math.sin(x / 70 + t * 0.6 * (1 + drift) + row) * 6 * rough +
            math.sin(x / 23 + t * 1.3 + row * 2) * 1.5 * rough;
        x < -5 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      canvas.drawPath(path, line);
      for (var k = 0; k < 4; k++) {
        final x = (_hash(row, k) * size.width + t * 10 * (1 + drift)) %
                (size.width + 40) -
            20;
        final yy =
            y + math.sin(x / 70 + t * 0.6 * (1 + drift) + row) * 6 * rough - 3;
        canvas.drawLine(
            Offset(x, yy), Offset(x + 10 + 6 * _hash(k, row), yy), foam);
      }
    }
  }

  /// Shallows: the sun's net on the sand below, sandbars along the edges
  /// with foam lapping them, a few rocks.
  void _shallows(
      Canvas canvas, Size size, SeaLook look, double rough, double drift) {
    final net = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.foam.withValues(alpha: 0.10)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 9; i++) {
      final path = Path();
      final path2 = Path();
      for (var s = 0.0; s <= size.height; s += 10) {
        final x = i * size.width / 8 +
            math.sin(s / 30 + t * 0.9 + i) * 14 +
            math.sin(s / 11 - t * 1.4) * 3;
        s == 0 ? path.moveTo(x, s) : path.lineTo(x, s);
      }
      for (var s = 0.0; s <= size.width; s += 10) {
        final y = i * size.height / 8 +
            math.sin(s / 34 - t * 0.8 + i * 2) * 12 +
            math.sin(s / 13 + t * 1.2) * 3;
        s == 0 ? path2.moveTo(s, y) : path2.lineTo(s, y);
      }
      canvas.drawPath(path, net);
      canvas.drawPath(path2, net);
    }
    final sand = Paint()..color = look.accent.withValues(alpha: 0.55);
    final lap = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.foam.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (final (cx, cy, w, h) in [
      (-10.0, size.height * 0.46, 70.0, 26.0),
      (size.width + 14, size.height * 0.22, 90.0, 30.0),
      (size.width * 0.12, size.height + 8, 120.0, 30.0),
    ]) {
      final r = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      canvas.drawOval(r, sand);
      canvas.drawOval(r.inflate(4 + math.sin(t * 1.5 + cx) * 2.5), lap);
    }
    final rock = Paint()..color = const Color(0xFF3B4A45);
    for (final (cx, cy) in [
      (size.width * 0.9, size.height * 0.62),
      (size.width * 0.06, size.height * 0.16),
    ]) {
      canvas.drawCircle(
          Offset(cx, cy), 10 + math.sin(t * 2 + cx) * 2 * rough, lap);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 11), rock);
    }
  }

  /// Drowned waters: dim stones of a sunken stair under the murk, kelp
  /// swaying from the edges.
  void _drowned(Canvas canvas, Size size, SeaLook look, double rough) {
    final stone = Paint()
      ..style = PaintingStyle.stroke
      ..color = look.foam.withValues(alpha: 0.07)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.14 + 0.13 * i);
      final y = size.height * (0.52 + 0.04 * i);
      canvas.drawRect(Rect.fromLTWH(x, y, 40, 18), stone);
    }
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.3), 34, stone);
    final murk = Paint()
      ..color = look.wave.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    for (var i = 0; i < 5; i++) {
      final x = (i * 97 + t * 5) % (size.width + 120) - 60;
      final y = size.height * (0.1 + 0.2 * i);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 110, height: 30), murk);
    }
    final kelp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = look.accent.withValues(alpha: 0.55)
      ..strokeWidth = 3;
    for (var i = 0; i < 7; i++) {
      final left = i.isEven;
      final baseY = size.height * (0.08 + 0.14 * i);
      final baseX = left ? -4.0 : size.width + 4;
      final path = Path()..moveTo(baseX, baseY);
      for (var s = 1; s <= 6; s++) {
        final reach = s * 7.0;
        final sway = math.sin(t * 0.9 + i + s * 0.6) * 5 * rough;
        path.lineTo(baseX + (left ? reach : -reach), baseY + sway - s * 2);
      }
      canvas.drawPath(path, kelp);
    }
  }

  /// The abyss: slow rings spreading from the deep, a faint whirl.
  void _abyss(Canvas canvas, Size size, SeaLook look, double rough) {
    final centre = Offset(size.width * 0.5, size.height * 0.5);
    final maxR = size.longestSide * 0.75;
    for (var i = 0; i < 6; i++) {
      final r = ((t * 14 * rough + i * maxR / 6) % maxR);
      final fade = 1 - r / maxR;
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = look.wave.withValues(alpha: 0.55 * fade),
      );
    }
    final whirl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = look.accent.withValues(alpha: 0.16);
    for (var arm = 0; arm < 3; arm++) {
      final path = Path();
      for (var s = 0; s <= 40; s++) {
        final a = arm * 2 * math.pi / 3 + s * 0.12 + t * 0.12;
        final r = 8 + s * 4.0;
        final p = centre + Offset(math.cos(a) * r, math.sin(a) * r * 0.6);
        s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, whirl);
    }
  }

  /// The ashen chop: rows of short, steep waves, grey scum between them.
  void _chop(
      Canvas canvas, Size size, SeaLook look, double rough, double drift) {
    final chop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = look.wave.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    final crest = Paint()
      ..color = look.foam.withValues(alpha: 0.28)
      ..strokeWidth = 2;
    const dx = 34.0, dy = 22.0;
    final shiftX = (t * 12 * (1 + drift)) % dx;
    var row = 0;
    for (var y = 6.0; y < size.height + dy; y += dy, row++) {
      final off = row.isEven ? 0.0 : dx / 2;
      for (var x = -dx + off + shiftX; x < size.width + dx; x += dx) {
        final col = (x / dx).floor();
        final h = (4 + 3 * math.sin(t * 2.4 + row * 1.7 + col)) * rough;
        canvas.drawPath(
            Path()
              ..moveTo(x - 7, y)
              ..lineTo(x, y - h)
              ..lineTo(x + 7, y),
            chop);
        if (h > 5.5) {
          canvas.drawLine(
              Offset(x - 2, y - h + 1), Offset(x + 2, y - h + 1), crest);
        }
      }
    }
    final scum = Paint()..color = look.accent.withValues(alpha: 0.10);
    for (var i = 0; i < 6; i++) {
      final x = (_hash(i, 3) * size.width + t * 4) % (size.width + 60) - 30;
      final y = _hash(i, 4) * size.height;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 46, height: 12), scum);
    }
  }

  /// A squall's whitecaps, breaking and gone.
  void _whitecaps(Canvas canvas, Size size, SeaLook look) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    for (var i = 0; i < 22; i++) {
      final life = (t * 0.7 + _hash(i, 9)) % 1;
      final x = _hash(i, 1) * size.width + life * 18;
      final y = _hash(i, 2) * size.height;
      paint.color = look.foam.withValues(alpha: 0.55 * (1 - life));
      canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 18, height: 8),
          math.pi,
          math.pi * 0.8,
          false,
          paint);
    }
  }

  /// A calm sea's glints of sun, winking in and out.
  void _glints(Canvas canvas, Size size, SeaLook look) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final phase = (t * 0.5 + _hash(i, 5)) % 1;
      final a = math.sin(phase * math.pi);
      paint
        ..color = look.foam.withValues(alpha: 0.7 * a)
        ..strokeWidth = 1.5;
      final c = Offset(_hash(i, 6) * size.width, _hash(i, 7) * size.height);
      canvas.drawLine(
          c - Offset(3 * a + 1, 0), c + Offset(3 * a + 1, 0), paint);
      canvas.drawLine(c - Offset(0, 2 * a), c + Offset(0, 2 * a), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SeaSurfacePainter old) =>
      old.t != t || old.waters != waters || old.weather != weather;
}

/// What lives under the water, seen through it: the bed's rocks and
/// plants and the fish swimming over them, each of the waters its own.
///
/// - The open sea: a school of silver fish, a great shadow passing deep
///   down, a jellyfish or two; no bottom to be seen.
/// - The shallows: seagrass and rocks on the sand, bright reef fish
///   darting between them.
/// - The drowned waters: weed swaying in the murk, pale eels winding
///   through it.
/// - The abyss: black spires, jellyfish glowing, an angler's lure bobbing
///   in the dark.
/// - The ashen chop: grey rocks crusted with barnacles, dead weed, small
///   dark fish.
class SeaDepthsPainter extends CustomPainter {
  const SeaDepthsPainter({required this.waters, required this.t});

  final SeaWaters waters;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final look = SeaLook.of(waters);
    switch (waters) {
      case SeaWaters.open:
        _shadow(canvas, size, look);
        _jellies(canvas, size, const Color(0xFFBFE3F0), 2, glow: false);
        _school(canvas, size, const Color(0xFFB8D4DE), count: 9, seed: 1);
        _school(canvas, size, const Color(0xFF9CC2CF), count: 6, seed: 2);
        _school(canvas, size, const Color(0xFFD8E8EE), count: 7, seed: 12);
      case SeaWaters.shallows:
        _rocks(canvas, size, const Color(0xFF6E7F6A), 4, seed: 3);
        _grass(canvas, size, const Color(0xFF4F9A5A), 9, seed: 4);
        for (final (i, colour) in const [
          Color(0xFFFF9F43),
          Color(0xFFFFD166),
          Color(0xFF4CC9F0),
          Color(0xFFFF6B8A),
          Color(0xFFFFD166),
          Color(0xFFFF9F43),
        ].indexed) {
          _darter(canvas, size, colour, i);
        }
      case SeaWaters.drowned:
        _grass(canvas, size, const Color(0xFF5E7D3E), 7, seed: 5);
        _eel(canvas, size, const Color(0xFFCFD8B8), 0);
        _eel(canvas, size, const Color(0xFFB7C49A), 1);
        _school(canvas, size, const Color(0xFF8FA58A), count: 5, seed: 6);
      case SeaWaters.abyss:
        _spires(canvas, size);
        _jellies(canvas, size, const Color(0xFFB48CFF), 3, glow: true);
        _angler(canvas, size);
        _school(canvas, size, const Color(0xFF6B4FB0), count: 5, seed: 14);
      case SeaWaters.ashen:
        _rocks(canvas, size, const Color(0xFF4A4F50), 6,
            seed: 7, barnacles: true);
        _grass(canvas, size, const Color(0xFF6B6A5E), 6, seed: 8);
        _school(canvas, size, const Color(0xFF2C3133), count: 7, seed: 9);
        _school(canvas, size, const Color(0xFF8C8A80), count: 5, seed: 13);
    }
  }

  /// A fish [length] long at [at], heading [dir] (radians), its tail
  /// beating with [t].
  void _fish(Canvas canvas, Offset at, double dir, double length, Color colour,
      {double alpha = 0.75, int phase = 0}) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(dir);
    final body = Paint()..color = colour.withValues(alpha: alpha);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: length, height: length * 0.42),
        body);
    final beat = math.sin(t * 9 + phase) * length * 0.12;
    canvas.drawPath(
        Path()
          ..moveTo(-length * 0.42, 0)
          ..lineTo(-length * 0.75, -length * 0.24 + beat)
          ..lineTo(-length * 0.75, length * 0.24 + beat)
          ..close(),
        body);
    canvas.restore();
  }

  /// Where something swimming across the whole sea is at [t]: it crosses
  /// at [speed], wrapping round, bobbing as it goes. Returns the place and
  /// the heading.
  (Offset, double) _swim(Size size, int i, double speed, {int salt = 0}) {
    final span = size.width + 120;
    final left = _hash(i, 40 + salt) < 0.5;
    final run = (t * speed + _hash(i, 41 + salt) * span) % span - 60;
    final x = left ? run : size.width - run;
    final y = size.height * (0.08 + 0.84 * _hash(i, 42 + salt)) +
        math.sin(t * 0.8 + i) * 10;
    final dy = math.cos(t * 0.8 + i) * 0.1;
    return (Offset(x, y), left ? dy : math.pi - dy);
  }

  /// A school: a handful of small fish swimming together.
  void _school(Canvas canvas, Size size, Color colour,
      {required int count, required int seed}) {
    final (lead, dir) = _swim(size, seed, 22, salt: seed);
    for (var k = 0; k < count; k++) {
      final off = Offset(
          -math.cos(dir) * (k % 3) * 11 + (_hash(k, seed) - 0.5) * 14,
          (k ~/ 3 - 1) * 9 + (_hash(k, seed + 1) - 0.5) * 6);
      _fish(canvas, lead + off, dir, 12, colour, alpha: 0.7, phase: k);
    }
  }

  /// A bright reef fish darting: quick, then still, then quick.
  void _darter(Canvas canvas, Size size, Color colour, int i) {
    final (at, dir) = _swim(size, i + 20, 16 + 10 * _hash(i, 50), salt: 3);
    _fish(canvas, at, dir, 17, colour, alpha: 0.9, phase: i);
  }

  /// A great shadow passing slowly far below.
  void _shadow(Canvas canvas, Size size, SeaLook look) {
    final span = size.width + 400;
    final x = (t * 9) % span - 200;
    final y = size.height * 0.55;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 150, height: 42), paint);
    canvas.drawPath(
        Path()
          ..moveTo(x - 70, y)
          ..lineTo(x - 108, y - 22 + math.sin(t) * 5)
          ..lineTo(x - 108, y + 22 + math.sin(t) * 5)
          ..close(),
        paint);
  }

  /// Jellyfish pulsing upward, trailing their strands.
  void _jellies(Canvas canvas, Size size, Color colour, int count,
      {required bool glow}) {
    for (var i = 0; i < count; i++) {
      final life = (t * 0.03 + _hash(i, 60)) % 1;
      final x =
          size.width * (0.15 + 0.7 * _hash(i, 61)) + math.sin(t * 0.5 + i) * 12;
      final y = size.height * (1.05 - 1.1 * life);
      final pulse = 0.85 + 0.15 * math.sin(t * 3 + i);
      final bell = Paint()
        ..color = colour.withValues(alpha: glow ? 0.55 : 0.35)
        ..maskFilter = glow ? const MaskFilter.blur(BlurStyle.normal, 3) : null;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 24 * pulse, height: 18),
          math.pi,
          math.pi,
          true,
          bell);
      final strand = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colour.withValues(alpha: 0.35);
      for (var k = -1; k <= 1; k++) {
        canvas.drawPath(
            Path()
              ..moveTo(x + k * 5, y)
              ..quadraticBezierTo(x + k * 5 + math.sin(t * 2 + k) * 4, y + 10,
                  x + k * 4, y + 20),
            strand);
      }
    }
  }

  /// Rocks on the bed, some crusted white with barnacles.
  void _rocks(Canvas canvas, Size size, Color colour, int count,
      {required int seed, bool barnacles = false}) {
    for (var i = 0; i < count; i++) {
      final edge = i.isEven;
      final x = edge
          ? (i % 4 == 0 ? 0.04 : 0.96) * size.width
          : _hash(i, seed) * size.width;
      final y = size.height * (0.1 + 0.8 * _hash(i, seed + 1));
      final w = 26 + 26 * _hash(i, seed + 2);
      final h = w * (0.55 + 0.2 * _hash(i, seed + 3));
      final rock = Paint()..color = colour.withValues(alpha: 0.7);
      final r = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(h * 0.45)), rock);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              r.deflate(h * 0.18).shift(Offset(-w * 0.08, -h * 0.1)),
              Radius.circular(h * 0.3)),
          Paint()..color = Colors.white.withValues(alpha: 0.06));
      if (barnacles) {
        final dot = Paint()..color = const Color(0xFFD9D4C7);
        for (var k = 0; k < 5; k++) {
          canvas.drawCircle(
              Offset(r.left + r.width * _hash(k, i + seed),
                  r.top + r.height * _hash(k, i + seed + 9)),
              1.4,
              dot);
        }
      }
    }
  }

  /// Seagrass or weed in tufts, swaying.
  void _grass(Canvas canvas, Size size, Color colour, int tufts,
      {required int seed}) {
    final blade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = colour.withValues(alpha: 0.7);
    for (var i = 0; i < tufts; i++) {
      final base = Offset(
          size.width *
              (i.isEven
                  ? 0.02 + 0.12 * _hash(i, seed)
                  : 0.86 + 0.12 * _hash(i, seed)),
          size.height * (0.06 + 0.88 * _hash(i, seed + 1)));
      for (var k = 0; k < 4; k++) {
        final lean = (k - 1.5) * 4 + math.sin(t * 1.2 + i + k) * 4;
        canvas.drawPath(
            Path()
              ..moveTo(base.dx + k * 2, base.dy)
              ..quadraticBezierTo(base.dx + k * 2 + lean, base.dy - 9,
                  base.dx + k * 2 + lean * 1.6, base.dy - 24 - 6 * _hash(k, i)),
            blade);
      }
    }
  }

  /// A pale eel winding through the ruins.
  void _eel(Canvas canvas, Size size, Color colour, int i) {
    final (head, dir) = _swim(size, i + 30, 12, salt: 7);
    final back = Offset(-math.cos(dir), -math.sin(dir));
    final side = Offset(-back.dy, back.dx);
    final path = Path()..moveTo(head.dx, head.dy);
    for (var k = 1; k <= 8; k++) {
      final p =
          head + back * (k * 8.0) + side * (math.sin(t * 4 - k * 0.8 + i) * 4);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.5
          ..color = colour.withValues(alpha: 0.7));
  }

  /// Black spires rising from the deep.
  void _spires(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF05040A).withValues(alpha: 0.7);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF9A6BFF).withValues(alpha: 0.25);
    for (var i = 0; i < 5; i++) {
      final x = size.width *
          (i.isEven ? 0.03 + 0.08 * _hash(i, 80) : 0.88 + 0.08 * _hash(i, 80));
      final y = size.height * (0.1 + 0.8 * _hash(i, 81));
      final r = 10 + 10 * _hash(i, 82);
      final path = Path();
      for (var k = 0; k < 7; k++) {
        final a = k * 2 * math.pi / 7;
        final rr = r * (0.7 + 0.3 * _hash(k, i + 83));
        final p = Offset(x + math.cos(a) * rr, y + math.sin(a) * rr);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, rim);
    }
  }

  /// An angler in the dark: a black body, its lure glowing.
  void _angler(Canvas canvas, Size size) {
    final (at, dir) = _swim(size, 90, 7, salt: 11);
    _fish(canvas, at, dir, 34, const Color(0xFF1A1428), alpha: 0.95);
    final lure = at +
        Offset(math.cos(dir), math.sin(dir)) * 20 +
        Offset(0, -8 + math.sin(t * 2) * 2);
    canvas.drawCircle(
        lure,
        5,
        Paint()
          ..color = const Color(0xFFE8D6FF)
              .withValues(alpha: 0.5 + 0.4 * math.sin(t * 3))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(lure, 1.8, Paint()..color = const Color(0xFFF5EEFF));
  }

  @override
  bool shouldRepaint(covariant SeaDepthsPainter old) =>
      old.t != t || old.waters != waters;
}

/// What drifts over the ships: the weather's particles (rain and its
/// splashes and lightning, fog banks thickest over the enemy, wind
/// streaks and spray, gulls on a calm day) and the waters' own (ash
/// falling, bubbles rising, void motes, spray). [enemyBand] is the strip
/// the enemy sails in, where a fog lies thickest.
class SeaWeatherPainter extends CustomPainter {
  const SeaWeatherPainter({
    required this.waters,
    required this.weather,
    required this.t,
    this.enemyBand,
  });

  final SeaWaters waters;
  final SeaWeather weather;
  final double t;
  final Rect? enemyBand;

  @override
  void paint(Canvas canvas, Size size) {
    final look = SeaLook.of(waters);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _waters(canvas, size, look);
    switch (weather) {
      case SeaWeather.calm:
        _gulls(canvas, size);
      case SeaWeather.tailwind:
      case SeaWeather.crosswind:
        _wind(canvas, size, look);
      case SeaWeather.squall:
        _rain(canvas, size, look);
      case SeaWeather.fog:
        _fog(canvas, size);
    }
    canvas.restore();
  }

  void _waters(Canvas canvas, Size size, SeaLook look) {
    final paint = Paint();
    switch (waters) {
      case SeaWaters.ashen:
        // Ash falling slow and slanting, turning as it goes.
        for (var i = 0; i < 34; i++) {
          final fall =
              (t * (14 + 8 * _hash(i, 1)) + _hash(i, 2) * size.height) %
                  (size.height + 20);
          final x = (_hash(i, 3) * size.width +
                  math.sin(t * 0.8 + i) * 12 +
                  fall * 0.25) %
              size.width;
          paint.color = look.accent.withValues(alpha: 0.55);
          canvas.save();
          canvas.translate(x, fall - 10);
          canvas.rotate(t * (1 + _hash(i, 4)) + i);
          canvas.drawRect(const Rect.fromLTWH(-1.5, -1, 3, 2), paint);
          canvas.restore();
        }
      case SeaWaters.drowned:
        // Bubbles rising from below and bursting.
        for (var i = 0; i < 16; i++) {
          final life = (t * 0.35 + _hash(i, 1)) % 1;
          final x = _hash(i, 2) * size.width + math.sin(t * 2 + i) * 3;
          final y = size.height * (1 - life * 0.8) - _hash(i, 3) * 40;
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = look.foam.withValues(alpha: 0.45 * (1 - life));
          canvas.drawCircle(Offset(x, y), 1.5 + life * 2.5, paint);
        }
      case SeaWaters.abyss:
        // Motes of violet light drifting up and pulsing.
        for (var i = 0; i < 22; i++) {
          final life = (t * 0.12 + _hash(i, 1)) % 1;
          final x = _hash(i, 2) * size.width + math.sin(t + i) * 8;
          final y = size.height * (1 - life);
          final pulse = 0.5 + 0.5 * math.sin(t * 3 + i);
          paint
            ..style = PaintingStyle.fill
            ..color = look.accent.withValues(alpha: 0.25 + 0.45 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(Offset(x, y), 1.4 + pulse, paint);
        }
        paint.maskFilter = null;
      case SeaWaters.open:
      case SeaWaters.shallows:
        // Spray blown off the crests now and then.
        for (var i = 0; i < 10; i++) {
          final life = (t * 0.6 + _hash(i, 1)) % 1;
          if (life > 0.35) continue;
          final base =
              Offset(_hash(i, 2) * size.width, _hash(i, 3) * size.height);
          for (var k = 0; k < 4; k++) {
            final p = base +
                Offset(life * 40 + k * 3,
                    -math.sin(life / 0.35 * math.pi) * (6 + k * 2));
            paint
              ..style = PaintingStyle.fill
              ..color = look.foam.withValues(alpha: 0.6 * (1 - life / 0.35));
            canvas.drawCircle(p, 1.2, paint);
          }
        }
    }
  }

  /// A calm day's gulls, wheeling high over the ships.
  void _gulls(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6
      ..color = const Color(0xFFEDEBE4).withValues(alpha: 0.8);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    for (var i = 0; i < 3; i++) {
      final a = t * (0.25 + 0.07 * i) + i * 2.1;
      final c = Offset(size.width * (0.3 + 0.2 * i) + math.cos(a) * 60,
          size.height * (0.3 + 0.15 * i) + math.sin(a) * 34);
      final flap = math.sin(t * 7 + i) * 3;
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(14, 22), width: 12, height: 3),
          shadow);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - 7, c.dy + flap)
            ..quadraticBezierTo(c.dx - 3, c.dy - 3, c.dx, c.dy)
            ..quadraticBezierTo(c.dx + 3, c.dy - 3, c.dx + 7, c.dy + flap),
          paint);
    }
  }

  /// Wind: long streaks racing with it, spray torn off with them.
  void _wind(Canvas canvas, Size size, SeaLook look) {
    final wind = _windOf(weather);
    final dir = wind / wind.distance;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    final w = size.width + 200, h = size.height + 200;
    for (var i = 0; i < 22; i++) {
      final speed = 2.5 + _hash(i, 1) * 2;
      final base = Offset(_hash(i, 2) * w, _hash(i, 3) * h) + wind * speed * t;
      final start = Offset(base.dx % w - 100, base.dy % h - 100);
      final len = 26 + _hash(i, 4) * 30;
      paint.color = look.foam.withValues(alpha: 0.18 + _hash(i, 5) * 0.2);
      canvas.drawLine(start, start + dir * len, paint);
    }
  }

  /// A squall: slanting rain, rings where it hits, and now and then the
  /// whole sea lit white.
  void _rain(Canvas canvas, Size size, SeaLook look) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = const Color(0xFFD6E4EE).withValues(alpha: 0.7);
    const slant = Offset(6, 20);
    for (var i = 0; i < 70; i++) {
      final speed = 380 + _hash(i, 1) * 160;
      final y =
          (t * speed + _hash(i, 2) * size.height) % (size.height + 30) - 15;
      final x = (_hash(i, 3) * size.width + y * 0.3) % size.width;
      canvas.drawLine(Offset(x, y), Offset(x, y) + slant, paint);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 24; i++) {
      final life = (t * 2.2 + _hash(i, 6)) % 1;
      ring.color = look.foam.withValues(alpha: 0.4 * (1 - life));
      canvas.drawOval(
          Rect.fromCenter(
              center:
                  Offset(_hash(i, 7) * size.width, _hash(i, 8) * size.height),
              width: 3 + life * 12,
              height: 1.5 + life * 5),
          ring);
    }
    // Lightning on its own clock: a flash every few seconds, half a beat
    // in, so a still sea (reduced motion, t at 0) is never caught in one.
    final beat = (t + 3.15) % 6.3;
    if (beat < 0.22) {
      final a = beat < 0.07 ? 0.34 : (0.22 - beat) / 0.15 * 0.18;
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  /// Fog: pale banks drifting across, thickest over the enemy.
  void _fog(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (var i = 0; i < 7; i++) {
      final speed = 8.0 + i * 3;
      final span = size.width + 360;
      final x = (t * speed + i * 151) % span - 180;
      final overEnemy = i < 4 && enemyBand != null;
      final y = overEnemy
          ? enemyBand!.top + enemyBand!.height * (0.2 + 0.2 * i)
          : size.height * (0.35 + 0.1 * i);
      paint.color =
          const Color(0xFFDDE3E6).withValues(alpha: overEnemy ? 0.30 : 0.16);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 240, height: 56), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SeaWeatherPainter old) =>
      old.t != t ||
      old.waters != waters ||
      old.weather != weather ||
      old.enemyBand != enemyBand;
}

/// How a ship looks from above.
class TopShipLook {
  const TopShipLook({
    required this.id,
    required this.length,
    required this.beam,
    required this.hull,
    required this.deck,
    required this.sail,
    required this.trim,
    this.masts = 1,
    this.sails = true,
    this.glow,
  });

  final String id;

  /// Its length, of the longest ship's, and its beam, of its length.
  final double length;
  final double beam;
  final Color hull;
  final Color deck;
  final Color sail;
  final Color trim;
  final int masts;

  /// False for a ship that sails without canvas (the void barge).
  final bool sails;

  /// A light it gives off, if any.
  final Color? glow;

  static const rustyEel = TopShipLook(
      id: 'rusty_eel',
      length: 1,
      beam: 0.24,
      hull: Color(0xFF6B4A2E),
      deck: Color(0xFF9A7148),
      sail: Color(0xFFD8C8A2),
      trim: Color(0xFFB0472E));
  static const raiderSkiff = TopShipLook(
      id: 'raider_skiff',
      length: 0.86,
      beam: 0.22,
      hull: Color(0xFF5A3A26),
      deck: Color(0xFF86613F),
      sail: Color(0xFFB8A27A),
      trim: Color(0xFF7A2E22));
  static const corsairBrig = TopShipLook(
      id: 'corsair_brig',
      length: 1,
      beam: 0.25,
      hull: Color(0xFF2E2A2C),
      deck: Color(0xFF6E5A46),
      sail: Color(0xFF3A3336),
      trim: Color(0xFFC0392B),
      masts: 2);
  static const inquisitionCutter = TopShipLook(
      id: 'inquisition_cutter',
      length: 0.94,
      beam: 0.2,
      hull: Color(0xFFE0D8C8),
      deck: Color(0xFFB59A74),
      sail: Color(0xFFF4EFE4),
      trim: Color(0xFFB3261E),
      masts: 2);
  static const voidBarge = TopShipLook(
      id: 'void_barge',
      length: 1,
      beam: 0.3,
      hull: Color(0xFF2A2140),
      deck: Color(0xFF4A3E66),
      sail: Color(0xFF6B4FB0),
      trim: Color(0xFF9A6BFF),
      sails: false,
      glow: Color(0xFF9A6BFF));

  static const enemies = [
    raiderSkiff,
    corsairBrig,
    inquisitionCutter,
    voidBarge
  ];

  /// The look of the enemy [id] (enemy_ships.json `shipName`) or, for one
  /// without its own, the one nearest its size.
  static TopShipLook forEnemy(String? id, ShipState ship) {
    for (final look in enemies) {
      if (look.id == id) return look;
    }
    final hull = ship.maxHull;
    if (hull <= 65) return raiderSkiff;
    if (hull <= 85) return corsairBrig;
    if (hull <= 110) return inquisitionCutter;
    return voidBarge;
  }
}

/// The rooms along a ship seen from above, stern to bow, as fractions of
/// its box: the helm at the stern, the hold's hatch, the guns amidships,
/// the bulwark at the bow. The hull band is the middle of the box; the
/// rest is room for the shields' arcs and the sails' overhang.
const Map<ShipRoom, (double, double)> _roomSpan = {
  ShipRoom.helm: (0.03, 0.25),
  ShipRoom.hold: (0.26, 0.46),
  ShipRoom.guns: (0.47, 0.68),
  ShipRoom.bulwark: (0.69, 0.90),
};

/// The height of a ship's box for a ship [length] long: its beam and the
/// space around it.
double topShipBoxHeight(double length, TopShipLook look) =>
    length * look.beam * 2.1;

/// The hull's band in a ship's box: the middle, one beam high.
Rect topShipHullBand(Size box, TopShipLook look) {
  final beam = box.width * look.beam;
  return Rect.fromCenter(
      center: box.center(Offset.zero), width: box.width, height: beam);
}

/// [room]'s tap zone in a ship's box, mirrored (bow to the left) when
/// [flip].
Rect topShipRoomRect(ShipRoom room, Size box, TopShipLook look,
    {required bool flip}) {
  final band = topShipHullBand(box, look);
  final (a, b) = _roomSpan[room]!;
  final left = flip ? 1 - b : a;
  final inset = room == ShipRoom.bulwark ? band.height * 0.08 : 0.0;
  return Rect.fromLTRB(box.width * left, band.top + inset,
      box.width * (left + b - a), band.bottom - inset);
}

/// One ship from above: its wake, hull, deck and rooms' furniture
/// (wheel, hatch, guns, the bulwark's plates), sails, and its shields as
/// arcs on the side toward the enemy ([facingDown] for the enemy, whose
/// broadside faces down the screen). A ship below half its hull is
/// battered: holes in the deck, the sails torn.
class TopShipPainter extends CustomPainter {
  const TopShipPainter({
    required this.look,
    required this.flip,
    required this.facingDown,
    required this.t,
    required this.layers,
    required this.maxLayers,
    required this.battered,
    required this.down,
    required this.burning,
    required this.water,
    required this.shield,
    required this.foam,
    required this.roomColors,
    this.refit = 0,
    this.speed = 1,
  });

  final TopShipLook look;
  final bool flip;
  final bool facingDown;
  final double t;
  final int layers;
  final int maxLayers;
  final bool battered;
  final Set<ShipRoom> down;
  final Set<ShipRoom> burning;

  /// How full the hold is, 0 to 1.
  final double water;
  final Color shield;
  final Color foam;
  final Map<ShipRoom, Color> roomColors;

  /// How far the Eel has been refitted, 0 to 2 (a crow's nest, then iron
  /// plates on the bulwark).
  final int refit;

  /// How fast she goes, for her wake: the helm's evasion, 0 to 2.
  final double speed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final band = topShipHullBand(size, look);
    final len = size.width * look.length;
    // Shorter ships sit centred on the rooms' span.
    final x0 = (size.width - len) / 2;
    final beam = band.height;
    final cy = band.center.dy;
    // The side toward the enemy, for the shields and the guns: down the
    // screen when the ship faces down. The mirror only turns it end for
    // end, so it has no say in this.
    final side = facingDown ? 1.0 : -1.0;

    _wake(canvas, x0, cy, beam);
    if (look.glow != null) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x0 + len / 2, cy),
            width: len * 1.1,
            height: beam * 2.2),
        Paint()
          ..color = look.glow!.withValues(alpha: 0.18 + 0.08 * math.sin(t * 2))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    final hull = Path()
      ..moveTo(x0 + len * 0.02, cy - beam * 0.36)
      ..quadraticBezierTo(
          x0 - len * 0.01, cy, x0 + len * 0.02, cy + beam * 0.36)
      ..lineTo(x0 + len * 0.55, cy + beam / 2)
      ..quadraticBezierTo(x0 + len * 0.86, cy + beam * 0.42, x0 + len, cy)
      ..quadraticBezierTo(
          x0 + len * 0.86, cy - beam * 0.42, x0 + len * 0.55, cy - beam / 2)
      ..close();
    // A shadow on the water, then the hull and the deck inside its rail.
    canvas.drawPath(hull.shift(const Offset(3, 4)),
        Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.drawPath(hull, Paint()..color = look.hull);
    final deck = Path()
      ..moveTo(x0 + len * 0.045, cy - beam * 0.27)
      ..quadraticBezierTo(
          x0 + len * 0.025, cy, x0 + len * 0.045, cy + beam * 0.27)
      ..lineTo(x0 + len * 0.55, cy + beam * 0.38)
      ..quadraticBezierTo(x0 + len * 0.82, cy + beam * 0.3, x0 + len * 0.94, cy)
      ..quadraticBezierTo(
          x0 + len * 0.82, cy - beam * 0.3, x0 + len * 0.55, cy - beam * 0.38)
      ..close();
    canvas.drawPath(deck, Paint()..color = look.deck);
    canvas.save();
    canvas.clipPath(deck);
    final plank = Paint()
      ..color = look.hull.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var k = -3; k <= 3; k++) {
      final y = cy + k * beam * 0.11;
      canvas.drawLine(Offset(x0, y), Offset(x0 + len, y), plank);
    }
    // Each room's floor tinted its colour, dark when it is knocked out.
    for (final room in ShipRoom.values) {
      final r = _roomOnDeck(room, size, band);
      canvas.drawRect(
          r,
          Paint()
            ..color = down.contains(room)
                ? Colors.black.withValues(alpha: 0.5)
                : roomColors[room]!.withValues(alpha: 0.16));
      if (burning.contains(room)) {
        canvas.drawRect(
            r,
            Paint()
              ..color = const Color(0xFFFF7A2E).withValues(
                  alpha: 0.18 + 0.1 * math.sin(t * 9 + room.index)));
      }
    }
    if (battered) {
      final hole = Paint()..color = Colors.black.withValues(alpha: 0.55);
      for (final (fx, fy) in [(0.36, 0.2), (0.62, -0.18), (0.8, 0.1)]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x0 + len * fx, cy + beam * fy),
                width: beam * 0.22,
                height: beam * 0.15),
            hole);
      }
    }
    canvas.restore();
    canvas.drawPath(
        hull,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawPath(
        deck,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = look.trim.withValues(alpha: 0.7));

    _helm(canvas, _roomOnDeck(ShipRoom.helm, size, band));
    _hatch(canvas, _roomOnDeck(ShipRoom.hold, size, band));
    _guns(canvas, _roomOnDeck(ShipRoom.guns, size, band), cy, beam, side);
    _bulwark(canvas, _roomOnDeck(ShipRoom.bulwark, size, band), cy, beam);
    if (look.sails) _sails(canvas, x0, len, cy, beam);
    if (look.glow != null) _runes(canvas, x0, len, cy, beam);
    canvas.restore();

    // The shields: arcs off the broadside toward the enemy (drawn after
    // the flip is undone, the side is the same either way).
    _shields(canvas, size, band, side);
  }

  Rect _roomOnDeck(ShipRoom room, Size size, Rect band) {
    // In the flipped canvas the rooms lie as if bow-right.
    final r = topShipRoomRect(room, size, look, flip: false);
    return Rect.fromLTRB(r.left, band.top, r.right, band.bottom);
  }

  void _wake(Canvas canvas, double x0, double cy, double beam) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final reach = 50 + 50 * speed;
    for (var i = 0; i < 3; i++) {
      final spread = beam * (0.3 + i * 0.18);
      final wobble = math.sin(t * 2 + i) * 2;
      paint
        ..strokeWidth = 3.0 - i * 0.7
        ..color = foam.withValues(alpha: 0.32 - i * 0.08);
      for (final s in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(x0 + 4, cy + s * beam * 0.3)
              ..quadraticBezierTo(x0 - reach * 0.5, cy + s * (spread + wobble),
                  x0 - reach, cy + s * (spread * 1.4 + wobble)),
            paint);
      }
    }
    // Churn right behind the stern.
    for (var i = 0; i < 6; i++) {
      final life = (t * 1.2 + i / 6) % 1;
      canvas.drawCircle(
          Offset(x0 - 4 - life * reach * 0.7,
              cy + math.sin(i * 2.3 + t) * beam * 0.12),
          2.5 * (1 - life) + 0.5,
          Paint()..color = foam.withValues(alpha: 0.5 * (1 - life)));
    }
  }

  void _helm(Canvas canvas, Rect r) {
    final c = Offset(r.center.dx - r.width * 0.12, r.center.dy);
    final rad = r.height * 0.16;
    final spoke = Paint()
      ..color = const Color(0xFFE2C99A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, rad, spoke);
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 4 + t * 0.2;
      final d = Offset(math.cos(a), math.sin(a)) * (rad + 3);
      canvas.drawLine(c - d, c + d, spoke);
    }
  }

  void _hatch(Canvas canvas, Rect r) {
    final hatch = Rect.fromCenter(
        center: r.center, width: r.width * 0.56, height: r.height * 0.42);
    canvas.drawRect(hatch, Paint()..color = const Color(0xFF231710));
    if (water > 0) {
      final w = hatch.deflate(2);
      final level = w.height * water.clamp(0.0, 1.0);
      canvas.drawRect(
          Rect.fromLTRB(w.left, w.bottom - level, w.right, w.bottom),
          Paint()..color = const Color(0xFF4AA3C0).withValues(alpha: 0.85));
      canvas.drawLine(
          Offset(w.left, w.bottom - level + math.sin(t * 4) * 0.8),
          Offset(w.right, w.bottom - level - math.sin(t * 4) * 0.8),
          Paint()
            ..color = foam.withValues(alpha: 0.8)
            ..strokeWidth = 1);
    }
    final grate = Paint()
      ..color = const Color(0xFFA07A4E)
      ..strokeWidth = 1;
    for (var k = 1; k < 4; k++) {
      final x = hatch.left + hatch.width * k / 4;
      canvas.drawLine(Offset(x, hatch.top), Offset(x, hatch.bottom), grate);
    }
    canvas.drawRect(
        hatch,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFA07A4E)
          ..strokeWidth = 1.2);
  }

  void _guns(Canvas canvas, Rect r, double cy, double beam, double towards) {
    final barrel = Paint()..color = const Color(0xFF1C1B1F);
    final ring = Paint()
      ..color = const Color(0xFF55525A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0; k < 3; k++) {
      final x = r.left + r.width * (0.2 + 0.3 * k);
      final y0 = cy + towards * beam * 0.12;
      final y1 = cy + towards * beam * 0.5;
      final body =
          Rect.fromLTRB(x - 3, math.min(y0, y1), x + 3, math.max(y0, y1));
      canvas.drawRRect(
          RRect.fromRectAndRadius(body, const Radius.circular(2)), barrel);
      canvas.drawRRect(
          RRect.fromRectAndRadius(body, const Radius.circular(2)), ring);
    }
  }

  void _bulwark(Canvas canvas, Rect r, double cy, double beam) {
    final plate = Paint()
      ..color = refit >= 2 || look.id != TopShipLook.rustyEel.id
          ? const Color(0xFF8C98A6)
          : const Color(0xFF6E5A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(Offset(r.left + 4, cy + s * beam * 0.34),
          Offset(r.right - 2, cy + s * beam * 0.18), plate);
    }
    // The bowsprit.
    canvas.drawLine(
        Offset(r.right - r.width * 0.2, cy),
        Offset(r.right + r.width * 0.45, cy),
        Paint()
          ..color = const Color(0xFF3A2818)
          ..strokeWidth = 2.5);
  }

  void _sails(Canvas canvas, double x0, double len, double cy, double beam) {
    final spots = look.masts == 2 ? [0.4, 0.66] : [0.5];
    final billow = 0.5 + 0.5 * math.sin(t * 1.3);
    for (final (i, f) in spots.indexed) {
      final x = x0 + len * f;
      // The yard across, the sail bellied forward of it.
      final span = beam * (look.masts == 2 && i == 0 ? 1.15 : 1.3);
      final belly = beam * (0.32 + 0.06 * billow);
      final sail = Path()
        ..moveTo(x, cy - span / 2)
        ..quadraticBezierTo(x + belly, cy, x, cy + span / 2)
        ..quadraticBezierTo(x + belly * 0.35, cy, x, cy - span / 2)
        ..close();
      canvas.drawPath(sail.shift(const Offset(5, 7)),
          Paint()..color = Colors.black.withValues(alpha: 0.2));
      canvas.drawPath(sail,
          Paint()..color = look.sail.withValues(alpha: battered ? 0.7 : 0.92));
      canvas.drawPath(
          sail,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = look.trim.withValues(alpha: 0.8));
      if (battered) {
        canvas.drawLine(
            Offset(x + belly * 0.3, cy - span * 0.2),
            Offset(x + belly * 0.5, cy + span * 0.05),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.6)
              ..strokeWidth = 2);
      }
      canvas.drawLine(
          Offset(x, cy - span / 2 - 2),
          Offset(x, cy + span / 2 + 2),
          Paint()
            ..color = const Color(0xFF3A2818)
            ..strokeWidth = 2.5);
      canvas.drawCircle(
          Offset(x, cy), 3.5, Paint()..color = const Color(0xFF2A1C10));
    }
    if (look.id == TopShipLook.rustyEel.id && refit >= 1) {
      // The crow's nest on the mainmast.
      canvas.drawCircle(
          Offset(x0 + len * spots.last, cy),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFA07A4E));
    }
  }

  void _runes(Canvas canvas, double x0, double len, double cy, double beam) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = look.glow!.withValues(alpha: 0.5 + 0.3 * math.sin(t * 2));
    final c = Offset(x0 + len * 0.55, cy);
    canvas.drawCircle(c, beam * 0.3, paint);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 - t * 0.5;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * beam * 0.3, 2, paint);
    }
  }

  void _shields(Canvas canvas, Size size, Rect band, double side) {
    final total = math.max(maxLayers, layers);
    final edge = side > 0 ? band.bottom : band.top;
    for (var i = 0; i < total; i++) {
      final up = i < layers;
      final near = band.height * 0.08 + i * 7;
      final far = band.height * 0.42 + i * 9;
      final path = Path()
        ..moveTo(size.width * 0.1, edge + side * near)
        ..quadraticBezierTo(size.width * 0.5, edge + side * far,
            size.width * 0.9, edge + side * near);
      if (up) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = shield.withValues(alpha: 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = up ? 3 : 1.5
            ..color = shield.withValues(
                alpha: up ? 0.85 + 0.15 * math.sin(t * 2.5 + i) : 0.22));
    }
  }

  @override
  bool shouldRepaint(covariant TopShipPainter old) => true;
}
