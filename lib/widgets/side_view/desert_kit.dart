// The desert scene kit (board 6): a warm sky in dithered bands and a low
// sun, far mesas, three bands of dunes scrolling at their own speeds, a
// path of packed sand, and the party's placeholder figures walking in place
// (the hero is the user's ronin, side_sprite.dart). The walk's goal comes forward as the days
// pass ([progress] 0 to 1).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/walking_party_provider.dart'
    show WalkingPartyMember, heroWalkerId;
import 'encounter_figure.dart';
import 'party_look.dart';
import 'side_sprite.dart';
import 'side_view.dart';

/// The desert's colours.
abstract final class DesertLook {
  static const sky = [
    Color(0xFF3E3452),
    Color(0xFF8A4F5E),
    Color(0xFFD77F57),
    Color(0xFFF2B86B),
    Color(0xFFF8DC9A),
  ];
  static const sun = Color(0xFFFFF0B8);
  static const mesa = Color(0xFF8C5A52);
  static const mesaRim = Color(0xFFB07566);
  static const far = Color(0xFFC9805A);
  static const farRim = Color(0xFFE29A6C);
  static const mid = Color(0xFFD99A5E);
  static const midRim = Color(0xFFF0BE80);
  static const near = Color(0xFFB87444);
  static const nearRim = Color(0xFFD99A5E);
  static const path = Color(0xFF8E5A32);
  static const pathDark = Color(0xFF6E4324);
  static const pathLight = Color(0xFFB07845);
}

const _bayer = [
  [0, 2],
  [3, 1],
];

/// The layers, back to front. [progress] brings the goal's silhouette
/// nearer as the days go.
List<SideLayer> desertLayers({double progress = 0}) => [
      SideLayer(0, _sky),
      SideLayer(0.05, _sun),
      SideLayer(0.15, (c, s, scroll, t, u) {
        // Far mesas, and the goal standing among them.
        sideHills(c, s, u, scroll,
            base: 38,
            amp: 2.6,
            wave: 0.05,
            phase: 1,
            fill: DesertLook.mesa,
            rim: DesertLook.mesaRim);
        _goal(c, s, u, progress);
      }),
      SideLayer(0.15, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 42,
            amp: 2.4,
            wave: 0.07,
            phase: 3,
            fill: DesertLook.far,
            rim: DesertLook.farRim);
      }),
      SideLayer(0.4, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 47,
            amp: 3.2,
            wave: 0.045,
            phase: 0.4,
            fill: DesertLook.mid,
            rim: DesertLook.midRim);
      }),
      SideLayer(0.8, (c, s, scroll, t, u) {
        sideHills(c, s, u, scroll,
            base: 54,
            amp: 3.6,
            wave: 0.03,
            phase: 2.1,
            fill: DesertLook.near,
            rim: DesertLook.nearRim);
        _props(c, s, u, scroll);
      }),
      SideLayer(1.0, _path),
    ];

/// Where the hero's feet stand, in scene pixels: the party's head.
const double walkHeroX = 96;

/// Where each of [count] figures of a walking party stands, front to back:
/// the hero at the head, the others behind it, 13 scene pixels apart.
List<double> walkingPartyXs(int count) => [
      for (var i = 0; i < count; i++)
        i == 0 ? walkHeroX : walkHeroX - 12 - 13.0 * i,
    ];

/// Whether the walking sprite [spriteKey] has frames of its own: the hero's
/// (the user's ronin) does; a companion's does not yet (`companion_<id>`,
/// the user's art comes later), and is drawn as a placeholder figure.
bool hasWalkSprite(String spriteKey) => spriteKey == 'hero';

/// The cloak of the placeholder figure of a companion: always the same for
/// the same [id], so the party keeps its colours from one walk to the next.
Color walkPlaceholderColour(String id) {
  const colours = [
    Color(0xFF3E7CB1),
    Color(0xFF6B8E4E),
    Color(0xFF8E5BA8),
    Color(0xFFB7791F),
    Color(0xFF2F8F83),
  ];
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return colours[hash % colours.length];
}

/// The party, in place on the path: the hero (the user's ronin) at its head
/// and the companions behind, walking while the party [moving] and standing
/// when it waits on a choice. [party] says who walks, front to back (see
/// walkingPartyProvider: the hero alone, or with up to two companions); a
/// figure without frames of its own is a placeholder. Without a [party],
/// [figures] placeholders walk behind the hero. Until the hero's sprite is
/// loaded the hero is a placeholder too.
SideLayer desertActors({
  int figures = 3,
  List<WalkingPartyMember>? party,
  bool moving = true,
  EncounterWalk? encounter,
}) {
  SideSprites.preload();
  final members = party ??
      [
        const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
        for (var i = 1; i < figures; i++)
          WalkingPartyMember(id: 'placeholder_$i', spriteKey: 'placeholder_$i'),
      ];
  final xs = walkingPartyXs(members.length);
  return SideLayer(0, (c, s, scroll, t, u) {
    // The companions first, behind (the last of the party first): placeholders,
    // a little bigger so they stand as tall as the ronin until they have
    // sprites of their own.
    for (var i = members.length - 1; i >= 1; i--) {
      c.save();
      c.scale(1.6);
      _figure(c, u, xs[i] / 1.6, 66 / 1.6, walkPlaceholderColour(members[i].id),
          moving ? t + i * 0.4 : 1.3,
          look: partyLookFor(members[i].id));
      c.restore();
    }
    if (!SideSprites.paint(c, u, xs[0], 66, t, moving: moving)) {
      _figure(c, u, xs[0] - 2, 66, const Color(0xFFC0392B), moving ? t : 1.3);
    }
    encounter?.paint(c, s, t, u, partyX: xs.last);
  });
}

void _sky(Canvas canvas, Size size, double scroll, double t, double u) {
  // Dithered bands from the top to the horizon.
  const horizon = 50;
  final bands = DesertLook.sky;
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
      Paint()..color = DesertLook.far);
}

void _sun(Canvas canvas, Size size, double scroll, double t, double u) {
  final cx = (size.width / u * 0.72).floorToDouble();
  const cy = 30.0;
  final glow = Paint()..color = DesertLook.sun.withValues(alpha: 0.22);
  final disc = Paint()..color = DesertLook.sun;
  for (var y = -9; y <= 9; y++) {
    for (var x = -9; x <= 9; x++) {
      final d = x * x + y * y;
      if (d <= 25) {
        canvas.drawRect(
            Rect.fromLTWH((cx + x) * u, (cy + y) * u, u + 0.5, u + 0.5), disc);
      } else if (d <= 81 && (x + y) % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH((cx + x) * u, (cy + y) * u, u + 0.5, u + 0.5), glow);
      }
    }
  }
}

/// The goal on the horizon: a face of rock among the mesas, nearer with
/// [progress].
void _goal(Canvas canvas, Size size, double u, double progress) {
  final w = size.width / u;
  final x = w * (1.05 - 0.62 * progress.clamp(0, 1));
  final scale = 1 + progress.clamp(0, 1) * 0.8;
  final body = Paint()..color = const Color(0xFF6E3F44);
  final rim = Paint()..color = DesertLook.mesaRim;
  final dark = Paint()..color = const Color(0xFF2E1C24);
  final bw = (14 * scale).round(), bh = (16 * scale).round();
  const base = 44.0;
  sidePixels(
      canvas, u, body, x - bw / 2, base - bh, bw.toDouble(), bh.toDouble());
  sidePixels(canvas, u, rim, x - bw / 2, base - bh, bw.toDouble(), 1);
  // Two dark hollows for eyes, and the brow.
  final eye = math.max(2, (2.2 * scale).round()).toDouble();
  sidePixels(canvas, u, dark, x - bw * 0.28, base - bh * 0.62, eye, eye);
  sidePixels(canvas, u, dark, x + bw * 0.12, base - bh * 0.62, eye, eye);
}

void _props(Canvas canvas, Size size, double u, double scroll) {
  // Rocks and a dry bush, repeating every few screens along the ground.
  final w = size.width / u;
  final span = w * 1.7;
  final rock = Paint()..color = const Color(0xFF7A4A2E);
  final rockLight = Paint()..color = const Color(0xFFA06A44);
  final bush = Paint()..color = const Color(0xFF6E5A2A);
  final offset = scroll / u;
  for (var i = 0; i < 6; i++) {
    final px = ((i * span / 3 + 20 - offset) % span + span) % span - 10;
    if (px < -8 || px > w + 4) continue;
    final y = 58.0 + (i % 2) * 2;
    if (i % 3 == 0) {
      sidePixels(canvas, u, rock, px, y - 3, 6, 3);
      sidePixels(canvas, u, rockLight, px + 1, y - 4, 3, 1);
    } else if (i % 3 == 1) {
      sidePixels(canvas, u, bush, px, y - 2, 5, 2);
      sidePixels(canvas, u, bush, px + 1, y - 4, 1, 2);
      sidePixels(canvas, u, bush, px + 3, y - 3, 1, 1);
    } else {
      sidePixels(canvas, u, rock, px, y - 2, 4, 2);
    }
  }
}

void _path(Canvas canvas, Size size, double scroll, double t, double u) {
  final w = size.width / u;
  sidePixels(canvas, u, Paint()..color = DesertLook.path, 0, 63, w + 1, 9);
  sidePixels(canvas, u, Paint()..color = DesertLook.pathLight, 0, 63, w + 1, 1);
  final dark = Paint()..color = DesertLook.pathDark;
  final offset = scroll / u;
  for (var i = 0; i < 14; i++) {
    final px = ((i * 9 - offset) % (w + 12) + (w + 12)) % (w + 12) - 6;
    sidePixels(canvas, u, dark, px, 67 + (i % 3), 3, 1);
  }
}

/// A placeholder walker: a cloaked body, a head, two legs that swap.
void _figure(
    Canvas canvas, double u, double x, double baseY, Color cloak, double t,
    {PartyLook? look}) {
  final step = (t * 6).floor() % 2;
  final skin = Paint()..color = const Color(0xFFE0B48A);
  final body = Paint()..color = cloak;
  final dark = Paint()..color = const Color(0xFF2A1A12);
  final bob = step == 0 ? 0.0 : -1.0;
  // Legs.
  sidePixels(canvas, u, dark, x + 1, baseY - 3 + (step == 0 ? 0 : -1), 1, 3);
  sidePixels(canvas, u, dark, x + 3, baseY - 3 + (step == 0 ? -1 : 0), 1, 3);
  // Cloak and head.
  sidePixels(canvas, u, body, x, baseY - 9 + bob, 5, 6);
  if (look != null) {
    // A companion's own face (party_look.dart).
    paintPartyHead(canvas, u, x + 1, baseY - 12 + bob, look);
    return;
  }
  sidePixels(canvas, u, skin, x + 1, baseY - 12 + bob, 3, 3);
  sidePixels(canvas, u, dark, x + 1, baseY - 13 + bob, 3, 1);
}
