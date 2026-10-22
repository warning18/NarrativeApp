// The sea scene kit (docs/proposals/side-view-ux.md, I; board 5): the ship
// small, seen from the side, over a sea that wears the colours of the waters
// she sails (the same five records the fight paints, SeaLook) and the day's
// weather. A sky of dithered bands, what stands on the horizon (a palm islet,
// drowned towers, the ashen cliffs), the water in rows with three bands of
// waves at their own speeds, and what the waters carry (sandbars, kelp, slow
// rings of void light). Rain, fog and ash stay inside the scene.
//
// The ship here is one placeholder hull and sail: the side views of the
// fourteen hulls, with their parts and looks, come later.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../combat/ship_battle.dart' show SeaWeather;
import '../../data/ship_forms.dart' show ShipForm;
import '../sea_battlefield.dart' show SeaLook, SeaWaters;
import '../ship_dress.dart' show ShipDress;
import 'deck_crew.dart';
import 'side_ship.dart';
import 'side_view.dart';

/// The horizon, in scene rows from the top.
const int _horizon = 38;

const _bayer = [
  [0, 2],
  [3, 1],
];

double _rand(int seed) {
  final x = math.sin(seed * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

/// The particles over a sea: rain in a squall, fog in fog, ash off the
/// ashen coast; nothing else.
SideParticles seaParticles(SeaWaters waters, SeaWeather weather) {
  if (weather == SeaWeather.squall) return SideParticles.rain;
  if (weather == SeaWeather.fog) return SideParticles.fog;
  return waters == SeaWaters.ashen ? SideParticles.ash : SideParticles.none;
}

/// What the day meets on the water, drawn beside the ship.
enum SeaMeetingKind {
  /// Nothing but gulls.
  none,

  /// A raider under sail (enemy_ships.json).
  raider,

  /// A derelict, listing, her mast snapped.
  derelict,

  /// Something seen: a light on the horizon, a shadow under the keel.
  sighting,

  /// A sea beast: a fin, a long pale back, arms over the water.
  beast,

  /// The port ahead, the quay and its lantern: the voyage's last scene.
  harbour,
}

/// A meeting: its kind and, for a raider or a beast, the enemy_ships.json id
/// that picks its look.
class SeaMeeting {
  const SeaMeeting(this.kind, {this.id});

  static const SeaMeeting none = SeaMeeting(SeaMeetingKind.none);

  final SeaMeetingKind kind;
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is SeaMeeting && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// The sky's four colours, top to horizon, for [waters] in [weather].
List<Color> _skyStops(SeaWaters waters, SeaWeather weather) {
  if (weather == SeaWeather.fog) {
    return const [
      Color(0xFF8E9A9A),
      Color(0xFFA6B1B0),
      Color(0xFFBBC5C3),
      Color(0xFFCDD5D2),
    ];
  }
  if (weather == SeaWeather.squall) {
    return const [
      Color(0xFF252E38),
      Color(0xFF38444F),
      Color(0xFF55636E),
      Color(0xFF7A8892),
    ];
  }
  return switch (waters) {
    SeaWaters.open => const [
        Color(0xFF1D3B55),
        Color(0xFF3B6E8F),
        Color(0xFF79AECB),
        Color(0xFFC4E1EA),
      ],
    SeaWaters.shallows => const [
        Color(0xFF2A6C86),
        Color(0xFF58A9B4),
        Color(0xFF9ED3C6),
        Color(0xFFF0E7BC),
      ],
    SeaWaters.drowned => const [
        Color(0xFF16231F),
        Color(0xFF28402F),
        Color(0xFF4A6648),
        Color(0xFF86A27A),
      ],
    SeaWaters.abyss => const [
        Color(0xFF07050E),
        Color(0xFF130E24),
        Color(0xFF2A1F4E),
        Color(0xFF4F3C86),
      ],
    SeaWaters.ashen => const [
        Color(0xFF262A2B),
        Color(0xFF3F4647),
        Color(0xFF666E6E),
        Color(0xFF908F88),
      ],
  };
}

/// The layers of a sea, back to front, for [waters] in [weather]. A
/// squall heaves the waves higher.
List<SideLayer> seaLayers({
  required SeaWaters waters,
  SeaWeather weather = SeaWeather.calm,
}) {
  final look = SeaLook.of(waters);
  final rough = weather == SeaWeather.squall;
  final sky = _skyStops(waters, weather);
  return [
    SideLayer(0, (c, s, scroll, t, u) => _sky(c, s, u, sky)),
    SideLayer(
        0.05, (c, s, scroll, t, u) => _farShore(c, s, u, scroll, look, waters)),
    SideLayer(0, (c, s, scroll, t, u) => _water(c, s, u, look)),
    SideLayer(
        0.30,
        (c, s, scroll, t, u) =>
            _waves(c, s, u, scroll, t, look, row: 43, amp: rough ? 2.4 : 1.2)),
    SideLayer(0.12,
        (c, s, scroll, t, u) => _carried(c, s, u, scroll, t, look, waters)),
    SideLayer(
        0.60,
        (c, s, scroll, t, u) =>
            _waves(c, s, u, scroll, t, look, row: 51, amp: rough ? 3.2 : 1.8)),
    SideLayer(
        1.0,
        (c, s, scroll, t, u) =>
            _waves(c, s, u, scroll, t, look, row: 61, amp: rough ? 4 : 2.4)),
  ];
}

void _sky(Canvas canvas, Size size, double u, List<Color> stops) {
  final cols = (size.width / u).ceil();
  final paint = Paint();
  for (var y = 0; y < _horizon; y++) {
    final p = y / _horizon * (stops.length - 1);
    final i = p.floor();
    final f = p - i;
    final lo = stops[i], hi = stops[math.min(i + 1, stops.length - 1)];
    for (var x = 0; x < cols; x++) {
      paint.color = f * 4 > _bayer[y % 2][x % 2] ? hi : lo;
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.5, u + 0.5), paint);
    }
  }
}

/// What stands on the horizon, repeating along it.
void _farShore(Canvas canvas, Size size, double u, double scroll, SeaLook look,
    SeaWaters waters) {
  final w = size.width / u;
  final span = w * 1.9;
  final offset = scroll / u;
  final dark = Paint()..color = Color.lerp(look.deep, Colors.black, 0.35)!;
  final rim = Paint()..color = Color.lerp(look.wave, look.deep, 0.4)!;
  final accent = Paint()..color = look.accent;
  for (var i = 0; i < 5; i++) {
    final px = ((i * span / 5 + 6 - offset) % span + span) % span - 14;
    if (px < -14 || px > w + 2) continue;
    switch (waters) {
      case SeaWaters.open:
        // Low islets.
        final len = 9 + (_rand(i) * 10).floorToDouble();
        sidePixels(canvas, u, dark, px, _horizon - 2, len, 2);
        sidePixels(canvas, u, rim, px + 1, _horizon - 3, len - 3, 1);
      case SeaWaters.shallows:
        // A palm islet drowned to its trunks, and a sandbar.
        sidePixels(canvas, u, accent, px, _horizon - 1, 12, 1);
        if (i.isEven) {
          sidePixels(canvas, u, dark, px + 5, _horizon - 7, 1, 6);
          sidePixels(canvas, u, dark, px + 2, _horizon - 8, 7, 1);
          sidePixels(canvas, u, dark, px + 3, _horizon - 7, 5, 1);
        }
      case SeaWaters.drowned:
        // Tower tops standing out of the water, broken.
        final h = 6 + (_rand(i + 3) * 8).floorToDouble();
        sidePixels(canvas, u, dark, px, _horizon - h, 4, h);
        sidePixels(canvas, u, rim, px, _horizon - h, 4, 1);
        sidePixels(canvas, u, Paint()..color = look.shallow, px + 2,
            _horizon - h, 2, 1);
      case SeaWaters.abyss:
        // Nothing stands: a faint glow on the horizon.
        sidePixels(
            canvas,
            u,
            Paint()..color = look.accent.withValues(alpha: .25),
            px,
            _horizon - 1,
            14,
            1);
      case SeaWaters.ashen:
        // The ashen cliffs, with embers.
        final h = 5 + (_rand(i + 9) * 9).floorToDouble();
        sidePixels(canvas, u, dark, px, _horizon - h, 11, h);
        sidePixels(canvas, u, rim, px, _horizon - h, 11, 1);
        sidePixels(canvas, u, accent, px + 3, _horizon - h + 3, 1, 1);
        sidePixels(canvas, u, accent, px + 8, _horizon - h + 5, 1, 1);
    }
  }
}

/// The water: the lighter shallow colour at the horizon, deepening to the
/// bottom in bands of two rows, a pale line on the horizon itself.
void _water(Canvas canvas, Size size, double u, SeaLook look) {
  final paint = Paint();
  const rows = sideViewRows - _horizon;
  for (var y = _horizon; y < sideViewRows; y += 2) {
    paint.color = Color.lerp(look.shallow, look.deep, (y - _horizon) / rows)!;
    canvas.drawRect(Rect.fromLTWH(0, y * u, size.width, u * 2 + 0.5), paint);
  }
  canvas.drawRect(Rect.fromLTWH(0, _horizon * u, size.width, u),
      Paint()..color = Color.lerp(look.wave, look.foam, 0.4)!);
}

/// A band of waves around [row]: a line in the wave colour that rises and
/// falls with the water, and foam on the crests.
void _waves(
    Canvas canvas, Size size, double u, double scroll, double t, SeaLook look,
    {required int row, required double amp}) {
  final cols = (size.width / u).ceil() + 1;
  final offset = scroll / u;
  final line = Paint()..color = look.wave;
  final foam = Paint()..color = look.foam.withValues(alpha: 0.85);
  for (var i = 0; i < cols; i++) {
    final wx = (i + offset) * 0.11;
    final s = math.sin(wx + t * 0.9) + 0.5 * math.sin(wx * 2.3 - t * 0.6);
    final y = row + amp * s / 1.5;
    canvas.drawRect(
        Rect.fromLTWH(i * u, y.roundToDouble() * u, u + 0.5, u), line);
    if (s > 1.2) {
      canvas.drawRect(
          Rect.fromLTWH(i * u, (y.roundToDouble() - 1) * u, u + 0.5, u), foam);
    }
  }
}

/// What the waters carry: sandbars in the shallows, kelp in the drowned
/// waters, slow rings and motes of light over the abyss.
void _carried(Canvas canvas, Size size, double u, double scroll, double t,
    SeaLook look, SeaWaters waters) {
  final w = size.width / u;
  final span = w * 1.7;
  final offset = scroll / u;
  switch (waters) {
    case SeaWaters.shallows:
      final paint = Paint()..color = look.accent.withValues(alpha: 0.22);
      for (var i = 0; i < 4; i++) {
        final px = ((i * span / 4 + 10 - offset) % span + span) % span - 20;
        sidePixels(canvas, u, paint, px, 66 + (i % 2) * 2, 18 + i * 3, 2);
      }
    case SeaWaters.drowned:
      final paint = Paint()..color = look.accent.withValues(alpha: 0.7);
      for (var i = 0; i < 7; i++) {
        final px = ((i * span / 7 + 4 - offset) % span + span) % span - 4;
        final h = 7 + (_rand(i + 4) * 8).floorToDouble();
        for (var k = 0; k < h; k++) {
          final sway = (math.sin(t * 0.8 + i + k * 0.4) * 1.2).roundToDouble();
          sidePixels(canvas, u, paint, px + sway,
              (sideViewRows - 1 - k).toDouble(), 1, 1);
        }
      }
    case SeaWaters.abyss:
      final ring = Paint()
        ..color = look.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u;
      for (var i = 0; i < 3; i++) {
        final phase = ((t * 0.12 + i / 3) % 1.0);
        final px = ((i * span / 3 + 20 - offset) % span + span) % span - 10;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(px * u, (58 + i * 4) * u),
                width: (6 + phase * 26) * u,
                height: (2 + phase * 7) * u),
            ring..color = look.accent.withValues(alpha: 0.4 * (1 - phase)));
      }
      final mote = Paint();
      for (var i = 0; i < 14; i++) {
        final x = ((_rand(i + 5) * w) + math.sin(t * 0.5 + i) * 6) % w;
        final y = _horizon + 4 + _rand(i + 17) * 28 + math.cos(t * 0.6 + i) * 2;
        final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7));
        mote.color = look.foam.withValues(alpha: twinkle * 0.7);
        sidePixels(canvas, u, mote, x, y, 1, 1);
      }
    case SeaWaters.open:
    case SeaWaters.ashen:
      break;
  }
}

/// The Rusty Eel's own sloop, the hull drawn until the ships table has
/// loaded (and in a test that gives none).
final ShipForm _defaultForm = ShipForm.fromRecord('rusty_eel', const {
  'kind': 'hull',
  'length': 1.0,
  'beam': 0.24,
  'outline': {'u0': 0.5, 'a': 2.2, 'b': 1.7, 'tipw': 0.3, 'bowtip': 0.0},
  'sailPlan': [
    {'kind': 'square', 'at': 0.5, 'size': 1.0}
  ],
  'jibs': 1,
});

/// The ship, in place, bobbing: her hull as [ship] says (see side_ship.dart)
/// in what she wears ([dress]). A flying hull ([flying], or the hull's own
/// record) hangs above the water with her shadow on it.
SideLayer seaActors({
  bool flying = false,
  SeaWeather weather = SeaWeather.calm,
  SeaMeeting meeting = SeaMeeting.none,
  ShipForm? ship,
  ShipDress? dress,
  double condition = 1.0,
  List<DeckCrew> crew = const [],
  Animation<double>? arrival,
}) =>
    SideLayer(0, (canvas, size, scroll, t, u) {
      final rough = weather == SeaWeather.squall;
      final w = size.width / u;
      final form = ship ?? _defaultForm;
      final len = sideShipLength(form);
      final shipX = seaShipX(len, w);
      final bob = math.sin(t * (rough ? 1.8 : 1.1)) * (rough ? 2.2 : 1.0);
      final lift = (flying || form.flying) ? 9.0 : 0.0;
      final sink = sideShipSink(condition);
      final base = 53 - lift + bob.roundToDouble() + sink;
      if (lift > 0) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset((shipX + len / 2) * u, 61 * u),
                width: len * u,
                height: 3 * u),
            Paint()..color = Colors.black.withValues(alpha: 0.25));
      }
      _drawMeeting(canvas, size, u, t, meeting, rough,
          arrive: arrival?.value ?? 1);
      paintSideShip(canvas, u,
          x: shipX,
          base: base,
          form: form,
          dress: dress,
          t: t,
          rough: rough,
          condition: condition,
          crew: crew);
      // The wake: foam along the waterline.
      if (lift == 0) {
        final foam = Paint()..color = Colors.white.withValues(alpha: 0.55);
        for (var k = 0; k < 6; k++) {
          sidePixels(
              canvas,
              u,
              foam,
              shipX - 2 - k * 3 + math.sin(t * 2 + k) * 1.5,
              53 + bob.roundToDouble() + 2 + sink,
              3,
              1);
        }
        sidePixels(
            canvas, u, foam, shipX + len - 3, 55 + bob.roundToDouble(), 4, 1);
      }
    });

/// What the day meets, on the right of the box (the ship is on the left).
void _drawMeeting(Canvas canvas, Size size, double u, double t,
    SeaMeeting meeting, bool rough,
    {double arrive = 1}) {
  final w = size.width / u;
  final bob = math.sin(t * 1.3 + 1.7).roundToDouble();
  // What she meets comes in from the right edge, as the land's encounters
  // walk in from the left; the gulls and the harbour stay where they are.
  final sliding = arrive < 1 &&
      meeting.kind != SeaMeetingKind.none &&
      meeting.kind != SeaMeetingKind.harbour;
  if (sliding) {
    canvas.save();
    final ease = Curves.easeOutCubic.transform(arrive.clamp(0.0, 1.0));
    canvas.translate((1 - ease) * w * 0.55 * u, 0);
  }
  _paintMeeting(canvas, size, u, t, meeting, rough, w, bob);
  if (sliding) canvas.restore();
}

void _paintMeeting(Canvas canvas, Size size, double u, double t,
    SeaMeeting meeting, bool rough, double w, double bob) {
  switch (meeting.kind) {
    case SeaMeetingKind.none:
      // A pair of gulls crossing.
      final gull = Paint()..color = const Color(0xFFECE7DC);
      for (var i = 0; i < 2; i++) {
        final gx = ((t * (5 + i * 2) + i * 40) % (w + 20)) - 10;
        final gy = 14 + i * 7 + math.sin(t * 2 + i).roundToDouble();
        sidePixels(canvas, u, gull, gx, gy, 2, 1);
        sidePixels(canvas, u, gull, gx + 3, gy - 1, 2, 1);
        sidePixels(canvas, u, gull, gx + 5, gy, 2, 1);
      }
    case SeaMeetingKind.raider:
      // The raider's own hull, bow to the left so she faces the Eel.
      final enemy = sideEnemyOf(meeting.id);
      final len = sideShipLength(enemy.form);
      final cx = (w * 0.76).floorToDouble();
      if (enemy.glow != null) {
        canvas.drawCircle(Offset(cx * u, (50 + bob) * u), 24 * u,
            Paint()..color = enemy.glow!.withValues(alpha: 0.12));
      }
      canvas.save();
      canvas.translate(2 * cx * u, 0);
      canvas.scale(-1, 1);
      paintSideShip(canvas, u,
          x: cx - len / 2,
          base: 53 + bob,
          form: enemy.form,
          dress: enemy.dress,
          t: t,
          rough: rough);
      canvas.restore();
    case SeaMeetingKind.derelict:
      _derelict(canvas, u, (w * 0.66).floorToDouble(), 54 + bob);
    case SeaMeetingKind.sighting:
      _sighting(canvas, size, u, t, w);
    case SeaMeetingKind.beast:
      _beast(canvas, u, (w * 0.66).floorToDouble(), 55 + bob, meeting.id, t);
    case SeaMeetingKind.harbour:
      _harbour(canvas, u, w, t);
  }
}

/// A derelict: the hull heeled over, the mast snapped, a rag of sail.
void _derelict(Canvas canvas, double u, double x, double base) {
  final hull = Paint()..color = const Color(0xFF4A3426);
  final plank = Paint()..color = const Color(0xFF2E2016);
  final rim = Paint()..color = const Color(0xFF7A5A3A);
  final mast = Paint()..color = const Color(0xFF241A12);
  final rag = Paint()..color = const Color(0xFFB8AF98);
  for (var r = 0; r < 5; r++) {
    sidePixels(canvas, u, hull, x + r * 1.2, base - 3 + r * 0.6, 26.0 - r, 1);
  }
  sidePixels(canvas, u, plank, x + 3, base - 1, 18, 1);
  sidePixels(canvas, u, rim, x, base - 3, 26, 1);
  // The stump, and the mast lying across the water.
  sidePixels(canvas, u, mast, x + 12, base - 11, 1, 9);
  sidePixels(canvas, u, mast, x + 13, base - 12, 1, 1);
  for (var k = 0; k < 14; k++) {
    sidePixels(canvas, u, mast, x + 14 + k, base - 12 + k * 0.7, 1, 1);
  }
  sidePixels(canvas, u, rag, x + 10, base - 9, 2, 5);
  sidePixels(canvas, u, rag, x + 9, base - 6, 1, 3);
  // A barrel adrift.
  sidePixels(canvas, u, hull, x + 33, base, 3, 3);
  sidePixels(canvas, u, rim, x + 33, base, 3, 1);
}

/// Something seen: a light far off on the horizon, with its path on the
/// water, and a long shadow slipping under the Eel's keel.
void _sighting(Canvas canvas, Size size, double u, double t, double w) {
  final lx = (w * 0.78).floorToDouble();
  final pulse = 0.6 + 0.4 * math.sin(t * 1.4);
  canvas.drawCircle(Offset(lx * u, (_horizon - 1) * u), 7 * u,
      Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.18 * pulse));
  sidePixels(canvas, u, Paint()..color = const Color(0xFFFFE9A8), lx - 1,
      _horizon - 2, 2, 2);
  final path = Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.32);
  for (var k = 0; k < 8; k++) {
    sidePixels(canvas, u, path, lx - 1 - (k % 2), _horizon + 2 + k * 3,
        2 + (k % 2) * 2, 1);
  }
  final shadow = Paint()..color = Colors.black.withValues(alpha: 0.28);
  final sx = ((t * 3) % (w + 60)) - 40;
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset((sx + 20) * u, 63 * u), width: 46 * u, height: 4 * u),
      shadow);
}

/// A sea beast, by its enemy_ships.json id: a fin, a long pale back with an
/// eye, or arms over the water.
void _beast(
    Canvas canvas, double u, double x, double base, String? id, double t) {
  final foam = Paint()..color = Colors.white.withValues(alpha: 0.55);
  switch (id) {
    case 'pale_leviathan':
      final back = Paint()..color = const Color(0xFFDDE5E8);
      final shade = Paint()..color = const Color(0xFFB4C2C8);
      for (var i = 0; i < 44; i++) {
        final h = (9 * math.sin(math.pi * i / 43)).round();
        if (h <= 0) continue;
        sidePixels(canvas, u, back, x + i, base - h, 1, h + 1);
        sidePixels(canvas, u, shade, x + i, base - 1, 1, 1);
      }
      sidePixels(canvas, u, Paint()..color = const Color(0xFF1B1E24), x + 6,
          base - 5, 3, 3);
      sidePixels(canvas, u, Paint()..color = const Color(0xFFE0B040), x + 7,
          base - 4, 1, 1);
    case 'tide_kraken':
      final arm = Paint()..color = const Color(0xFF4A2A52);
      final sucker = Paint()..color = const Color(0xFFB89AC0);
      for (var a = 0; a < 3; a++) {
        final ax = x + a * 9.0;
        for (var k = 0; k < 16 - a * 2; k++) {
          final sway = math.sin(t * 1.1 + a * 1.7 + k * 0.35) * (1 + k * 0.2);
          sidePixels(canvas, u, arm, ax + sway, base - k, k < 10 ? 2 : 1, 1);
          if (k % 4 == 2) {
            sidePixels(canvas, u, sucker, ax + sway, base - k, 1, 1);
          }
        }
      }
    default:
      // A dorsal fin cutting the swell, a wake behind it.
      final fin = Paint()..color = const Color(0xFF3A4650);
      for (var k = 0; k < 11; k++) {
        sidePixels(canvas, u, fin, x + k * 0.45, base - 11 + k, 1 + k * 0.6, 1);
      }
  }
  for (var k = 0; k < 5; k++) {
    sidePixels(canvas, u, foam, x + 12 + k * 3, base + 1 + (k % 2), 3, 1);
  }
  sidePixels(canvas, u, foam, x - 3, base + 1, 4, 1);
}

/// The port ahead: a stone quay, houses with lit windows, a tower with its
/// lantern.
void _harbour(Canvas canvas, double u, double w, double t) {
  final x0 = (w * 0.56).floorToDouble();
  final stone = Paint()..color = const Color(0xFF5E5A56);
  final stoneLight = Paint()..color = const Color(0xFF807A72);
  final wall = Paint()..color = const Color(0xFF3F3A44);
  final roof = Paint()..color = const Color(0xFF2A2630);
  final window = Paint()..color = const Color(0xFFF2B85A);
  sidePixels(canvas, u, stone, x0, 52, w - x0 + 2, 6);
  sidePixels(canvas, u, stoneLight, x0, 52, w - x0 + 2, 1);
  var x = x0 + 4;
  var i = 0;
  while (x < w - 6) {
    final tower = i == 2;
    final bw = tower ? 6.0 : 9.0 + (_rand(i) * 4).floorToDouble();
    final bh = tower ? 24.0 : 9.0 + (_rand(i + 5) * 6).floorToDouble();
    sidePixels(canvas, u, wall, x, 52 - bh, bw, bh);
    sidePixels(canvas, u, roof, x - 1, 52 - bh - 2, bw + 2, 2);
    for (var wy = 0; wy < (bh / 5).floor(); wy++) {
      if (_rand(i * 7 + wy) > 0.35) {
        sidePixels(canvas, u, window, x + 2, 52 - bh + 3 + wy * 5, 1, 2);
      }
    }
    if (tower) {
      final glow = 0.7 + 0.3 * math.sin(t * 2.2);
      canvas.drawCircle(
          Offset((x + 3) * u, (52 - bh - 4) * u),
          7 * u,
          Paint()
            ..color = const Color(0xFFF2B85A).withValues(alpha: 0.22 * glow));
      sidePixels(canvas, u, Paint()..color = const Color(0xFFFFE9A8), x + 2,
          52 - bh - 5, 2, 2);
    }
    x += bw + 3;
    i++;
  }
  // A mooring post.
  sidePixels(
      canvas, u, Paint()..color = const Color(0xFF2E2016), x0 - 3, 49, 2, 5);
}

/// The length in scene pixels of the ship the scene draws for [form] (the
/// Eel's own sloop when null).
double seaShipLength(ShipForm? form) => sideShipLength(form ?? _defaultForm);

/// How long what she meets takes to come in from the right edge.
const Duration seaArrivalTime = Duration(milliseconds: 1600);

/// The scene over a voyage's day: a sea of [waters] in [weather], the ship
/// in place with her [crew] on deck, and [beside] (what she meets) on the
/// right. What she meets sails in from the right edge when the scene opens
/// on a day with one (not with reduced motion), as the land's encounters
/// walk in from the left.
class SeaSideScene extends StatefulWidget {
  const SeaSideScene({
    super.key,
    required this.waters,
    this.weather = SeaWeather.calm,
    this.flying = false,
    this.meeting = SeaMeeting.none,
    this.moving = true,
    this.ship,
    this.dress,
    this.condition = 1.0,
    this.crew = const [],
    this.beside,
    this.height = 140,
  });

  final SeaWaters waters;
  final SeaWeather weather;
  final bool flying;
  final SeaMeeting meeting;
  final bool moving;

  /// Her hull and what she wears; the Rusty Eel's sloop in her own wood
  /// when null.
  final ShipForm? ship;
  final ShipDress? dress;

  /// The hull she has left, 0 to 1: below 0.8 she shows it (scorch, a hole,
  /// patched sails, smoke, fire, lower in the water).
  final double condition;

  /// Who stands on her deck (see [deckCrewOf]); nobody when empty.
  final List<DeckCrew> crew;
  final Widget? beside;
  final double height;

  @override
  State<SeaSideScene> createState() => _SeaSideSceneState();
}

class _SeaSideSceneState extends State<SeaSideScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival =
      AnimationController(vsync: this, duration: seaArrivalTime, value: 1);
  bool _started = false;

  bool get _arrives =>
      widget.moving &&
      widget.meeting.kind != SeaMeetingKind.none &&
      widget.meeting.kind != SeaMeetingKind.harbour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_arrives && !MediaQuery.of(context).disableAnimations) {
      _arrival.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(SeaSideScene old) {
    super.didUpdateWidget(old);
    if (old.meeting != widget.meeting &&
        _arrives &&
        !MediaQuery.of(context).disableAnimations) {
      _arrival.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          SideViewScene(
            key: const Key('sea_scene'),
            layers: seaLayers(waters: widget.waters, weather: widget.weather),
            actors: seaActors(
                flying: widget.flying,
                weather: widget.weather,
                meeting: widget.meeting,
                ship: widget.ship,
                dress: widget.dress,
                condition: widget.condition,
                crew: widget.crew,
                arrival: _arrival),
            particles: seaParticles(widget.waters, widget.weather),
            intensity: widget.weather == SeaWeather.squall ? 0.9 : 0.6,
            pace: widget.weather == SeaWeather.tailwind ? 56 : 30,
            moving: widget.moving,
            height: widget.height,
          ),
          if (widget.beside != null)
            Positioned(right: 10, top: 8, child: widget.beside!),
        ],
      ),
    );
  }
}

/// The fight's own strip (v1.301): the two real hulls facing each other in
/// side view above the battlefield. The Eel's is on the left in what she
/// wears and as battered as she is; the enemy's is on the right, a raider
/// with her own hull (see [sideEnemyOf]) or a sea beast, bow toward the
/// Eel, as battered as she is. [range] is how far apart they lie: 0 close,
/// 0.5 medium, 1 long; the gap eases as it changes.
class SeaDuelScene extends StatelessWidget {
  const SeaDuelScene({
    super.key,
    required this.waters,
    this.weather = SeaWeather.calm,
    this.ship,
    this.dress,
    this.condition = 1.0,
    this.enemyId,
    this.enemyCondition = 1.0,
    this.enemyIsBeast = false,
    this.range = 0.5,
    this.height = 96,
  });

  final SeaWaters waters;
  final SeaWeather weather;
  final ShipForm? ship;
  final ShipDress? dress;
  final double condition;
  final String? enemyId;
  final double enemyCondition;
  final bool enemyIsBeast;
  final double range;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: range, end: range),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, r, _) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SideViewScene(
          key: const Key('duel_scene'),
          layers: seaLayers(waters: waters, weather: weather),
          actors: _duelActors(
            ship: ship,
            dress: dress,
            condition: condition,
            enemyId: enemyId,
            enemyCondition: enemyCondition,
            enemyIsBeast: enemyIsBeast,
            range: r,
            weather: weather,
          ),
          particles: seaParticles(waters, weather),
          intensity: weather == SeaWeather.squall ? 0.9 : 0.5,
          pace: 18,
          height: height,
        ),
      ),
    );
  }
}

SideLayer _duelActors({
  ShipForm? ship,
  ShipDress? dress,
  required double condition,
  String? enemyId,
  required double enemyCondition,
  required bool enemyIsBeast,
  required double range,
  required SeaWeather weather,
}) =>
    SideLayer(0, (canvas, size, scroll, t, u) {
      final rough = weather == SeaWeather.squall;
      final w = size.width / u;
      final form = ship ?? _defaultForm;
      final len = sideShipLength(form);
      // Centre to centre: nearly bow to bow when close, far apart at long.
      final half = w * (0.12 + 0.18 * range);
      final eelCx = (w * 0.5 - half).floorToDouble();
      final enemyCx = (w * 0.5 + half).floorToDouble();
      final amp = rough ? 2.0 : 1.0;
      final eelBob = math.sin(t * (rough ? 1.8 : 1.1)) * amp;
      final foeBob = math.sin(t * (rough ? 1.7 : 1.2) + 2.1) * amp;
      final lift = form.flying ? 9.0 : 0.0;
      final eelBase =
          53 - lift + eelBob.roundToDouble() + sideShipSink(condition);
      if (lift > 0) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(eelCx * u, 61 * u),
                width: len * u,
                height: 3 * u),
            Paint()..color = Colors.black.withValues(alpha: 0.25));
      }
      paintSideShip(canvas, u,
          x: eelCx - len / 2,
          base: eelBase,
          form: form,
          dress: dress,
          t: t,
          rough: rough,
          condition: condition);
      if (enemyIsBeast) {
        _beast(
            canvas, u, enemyCx - 20, 55 + foeBob.roundToDouble(), enemyId, t);
      } else {
        final enemy = sideEnemyOf(enemyId);
        final elen = sideShipLength(enemy.form);
        final base = 53 + foeBob.roundToDouble() + sideShipSink(enemyCondition);
        if (enemy.glow != null) {
          canvas.drawCircle(Offset(enemyCx * u, (50 + foeBob) * u), 24 * u,
              Paint()..color = enemy.glow!.withValues(alpha: 0.12));
        }
        canvas.save();
        canvas.translate(2 * enemyCx * u, 0);
        canvas.scale(-1, 1);
        paintSideShip(canvas, u,
            x: enemyCx - elen / 2,
            base: base,
            form: enemy.form,
            dress: enemy.dress,
            t: t,
            rough: rough,
            condition: enemyCondition);
        canvas.restore();
      }
      // The foam at each waterline.
      final foam = Paint()..color = Colors.white.withValues(alpha: 0.5);
      for (final cx in [eelCx, enemyCx]) {
        for (var k = 0; k < 4; k++) {
          sidePixels(
              canvas,
              u,
              foam,
              cx - len / 2 - 2 - k * 3 + math.sin(t * 2 + k) * 1.2,
              55 + eelBob.roundToDouble(),
              3,
              1);
        }
      }
    });
