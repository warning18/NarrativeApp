// One cube skin per die (v1.216, from the Grey Shroud dice sheet): the
// stone it is cut from, the colour of its edge, the mark cut into its
// faces and the light it gives off. A die with no skin of its own reads as
// bone.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// The mark cut into a die's faces.
enum DiePattern {
  none,
  rivets,
  grain,
  cracks,
  runes,
  waves,
  rays,
  stars,
  facets,
  bricks,
  scratch,
  pips,
  leaf,
  bolt,
  bones,
  ink,
  chalk,
}

class DieSkin {
  const DieSkin(this.material, this.base, this.edge, this.pattern, [this.glow]);

  /// What the die is made of, for its sheet.
  final String material;

  /// The stone of the faces, under each face's tint.
  final Color base;

  /// The colour of the edge, the pattern and the glyph's frame.
  final Color edge;
  final DiePattern pattern;

  /// The light it gives off, if any.
  final Color? glow;
}

const DieSkin boneSkin =
    DieSkin('Bone', Color(0xFFCFC6AE), Palette.stone42, DiePattern.pips);

/// The skin of the die [id] (dice.json key).
DieSkin dieSkinOf(String? id) => dieSkins[id] ?? boneSkin;

const Map<String, DieSkin> dieSkins = {
  'starter_die': boneSkin,
  'void_die': DieSkin('Void glass', Color(0xFF171225), Palette.blue71,
      DiePattern.stars, Color(0xFF7A5CFF)),
  'iron_die': DieSkin(
      'Riveted iron', Color(0xFF4B5057), Color(0xFFA6AFBA), DiePattern.rivets),
  'flame_die': DieSkin('Ember', Color(0xFF4D1F12), Palette.orange62,
      DiePattern.cracks, Palette.orange56),
  'tide_die': DieSkin('Sea glass', Color(0xFF13393F), Color(0xFF5ADBCB),
      DiePattern.waves, Color(0xFF2FBFB0)),
  'storm_die': DieSkin('Stormcast', Color(0xFF2B3445), Color(0xFFB4CDFF),
      DiePattern.bolt, Color(0xFF8FB4FF)),
  'stone_die': DieSkin(
      'Dwarven stone', Color(0xFF5B5349), Color(0xFFD1B684), DiePattern.bricks),
  'shadow_die': DieSkin('Black lacquer', Color(0xFF101015), Color(0xFF7A7F99),
      DiePattern.scratch),
  'holy_die': DieSkin('Ivory and gold', Color(0xFFD9D0B8), Palette.goldDark,
      DiePattern.rays, Palette.goldDark),
  'berserker_die': DieSkin(
      'Blood-iron', Color(0xFF4A1515), Palette.red58, DiePattern.scratch),
  'arcane_die': DieSkin('Rune crystal', Color(0xFF20245A), Palette.blue78,
      DiePattern.runes, Color(0xFF6E7DFF)),
  'huntsman_die': DieSkin(
      'Antler and oak', Color(0xFF4B3B28), Palette.orange54, DiePattern.grain),
  'liora_die': DieSkin('Living wood', Color(0xFF30502B), Palette.green63a,
      DiePattern.leaf, Palette.green53),
  'vess_die': DieSkin('Tide-crystal, ink', Color(0xFF1C2650), Palette.cyan76,
      DiePattern.ink, Color(0xFF6A8CFF)),
  'grosh_die':
      DieSkin('Tusk', Palette.stone50a, Color(0xFFE0D6B6), DiePattern.cracks),
  // Vica's die (v1.601): her black and white coat.
  'hound_die': DieSkin('Black and white coat', Color(0xFF1E1E1E),
      Palette.paper93, DiePattern.scratch),
  'apprentice_die':
      DieSkin('Chalk', Color(0xFFD8D4C6), Palette.blue74, DiePattern.chalk),
  'sage_die': DieSkin('Sky-glass', Color(0xFF21324D), Color(0xFF96D9FF),
      DiePattern.stars, Color(0xFF5FB6F2)),
  'tobin_die': DieSkin('Reliquary bronze', Color(0xFF5C4527), Palette.orange65,
      DiePattern.rivets),
  'malrik_die':
      DieSkin('Rust', Color(0xFF4D3123), Color(0xFFCC8250), DiePattern.scratch),
  'gambler_die': DieSkin(
      'Casino ivory', Color(0xFFE6E0D0), Palette.red46, DiePattern.pips),
  'frost_die': DieSkin('Ice', Color(0xFF1F3C52), Palette.cyan88,
      DiePattern.facets, Color(0xFF7FD3FF)),
  'twinfang_die': DieSkin('Bone and fang', Color(0xFFCFC6AE), Color(0xFF3A3A3A),
      DiePattern.scratch),
  'bulwark_die': DieSkin(
      'Tower stone', Color(0xFF505661), Color(0xFFB6BEC9), DiePattern.bricks),
  'pilgrim_die': DieSkin(
      'Wayworn wood', Color(0xFF6D5635), Palette.amber74, DiePattern.grain),
  'tempest_die': DieSkin('Thunder iron', Color(0xFF242B3C), Palette.amber77b,
      DiePattern.bolt, Color(0xFFFFD54F)),
  'ossuary_die': DieSkin(
      'Bone mosaic', Color(0xFFCFC6AE), Color(0xFF7A7364), DiePattern.bones),
  'vigil_die': DieSkin('Candle wax', Palette.amber84, Palette.goldDark,
      DiePattern.rays, Palette.orange71),
  'tearglass_die': DieSkin('Tear-glass', Color(0xFF102B30), Palette.teal79,
      DiePattern.cracks, Palette.teal53),
  'headsman_die': DieSkin(
      'Black iron, red', Color(0xFF1D1D22), Palette.red50, DiePattern.scratch),
  'greenwood_die':
      DieSkin('Greenwood', Color(0xFF2B4B2D), Palette.green64, DiePattern.leaf),
  'chorus_die': DieSkin(
      'Silver bell', Color(0xFFAEB4BE), Palette.blue97, DiePattern.waves),
  // The built d12 (Core, dice sizes): bone until UX draws its own.
  'tally_die': boneSkin,
  // The clans' new dice (Core, clan_dice.dart): placeholders until UX's.
  'lantern_die': DieSkin('Lantern brass', Color(0xFF3A2E1A), Palette.goldDark,
      DiePattern.rays, Palette.orange71),
  'cinder_die': DieSkin('Banked coal', Color(0xFF2A1F1C), Palette.orange62,
      DiePattern.cracks, Palette.orange56),
  'court_die': DieSkin(
      'Mire green', Color(0xFF1E3326), Palette.green74, DiePattern.waves),
};

/// A pattern cut into one face, drawn over its unit square: faint, so the
/// glyph on top still reads.
class DiePatternPainter extends CustomPainter {
  const DiePatternPainter(this.pattern, this.color, [this.seed = 1]);

  final DiePattern pattern;
  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == DiePattern.none) return;
    canvas.save();
    canvas.scale(size.width, size.height);
    final hair = 1 / math.max(1.0, size.shortestSide);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = hair * 1.1
      ..color = color.withValues(alpha: 0.55);
    final dot = Paint()..color = color.withValues(alpha: 0.6);
    final rng = math.Random(seed);

    void poly(List<(double, double)> pts) {
      final path = Path()..moveTo(pts.first.$1, pts.first.$2);
      for (final p in pts.skip(1)) {
        path.lineTo(p.$1, p.$2);
      }
      canvas.drawPath(path, line);
    }

    switch (pattern) {
      case DiePattern.none:
        break;
      case DiePattern.rivets:
        for (final x in [.13, .87]) {
          for (final y in [.13, .87]) {
            canvas.drawCircle(Offset(x, y), .045, dot);
          }
        }
      case DiePattern.grain:
        for (final y in [.18, .34, .5, .66, .82]) {
          canvas.drawPath(
              Path()
                ..moveTo(0, y)
                ..cubicTo(.3, y - .06, .6, y + .06, 1, y),
              line);
        }
      case DiePattern.cracks:
        poly([(.5, 0), (.45, .3), (.6, .5), (.4, .75), (.5, 1)]);
        poly([(.45, .3), (.2, .4)]);
        poly([(.6, .5), (.85, .6)]);
      case DiePattern.runes:
        for (final x in [.1, .5]) {
          for (final y in [.1, .62]) {
            poly([(x, y), (x + .06, y + .1), (x, y + .2)]);
            poly([(x + .1, y + .02), (x + .2, y + .02)]);
          }
        }
      case DiePattern.waves:
        for (final y in [.25, .5, .75]) {
          final path = Path()..moveTo(0, y);
          for (var i = 0; i < 4; i++) {
            path.relativeQuadraticBezierTo(.125, i.isEven ? -.07 : .07, .25, 0);
          }
          canvas.drawPath(path, line);
        }
      case DiePattern.rays:
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          poly([(.5, .5), (.5 + math.cos(a) * .9, .5 + math.sin(a) * .9)]);
        }
      case DiePattern.stars:
        for (var i = 0; i < 14; i++) {
          canvas.drawCircle(Offset(rng.nextDouble(), rng.nextDouble()),
              .012 + rng.nextDouble() * .02, dot);
        }
      case DiePattern.facets:
        poly([(0, 0), (1, 1)]);
        poly([(1, 0), (0, 1)]);
        poly([(.5, 0), (.5, 1)]);
        poly([(0, .5), (1, .5)]);
      case DiePattern.bricks:
        poly([(0, .33), (1, .33)]);
        poly([(0, .66), (1, .66)]);
        poly([(.5, 0), (.5, .33)]);
        poly([(.25, .33), (.25, .66)]);
        poly([(.75, .33), (.75, .66)]);
        poly([(.5, .66), (.5, 1)]);
      case DiePattern.scratch:
        poly([(.1, .2), (.55, .05)]);
        poly([(.2, .55), (.9, .3)]);
        poly([(.1, .9), (.7, .7)]);
      case DiePattern.pips:
        for (final p in [(.15, .15), (.85, .85), (.15, .85), (.85, .15)]) {
          canvas.drawCircle(Offset(p.$1, p.$2), .05, dot);
        }
      case DiePattern.leaf:
        poly([(.1, .9), (.5, .5), (.9, .1)]);
        for (final x in [.3, .5, .7]) {
          poly([(x, 1 - x), (x + .05, 1 - x - .2)]);
        }
        poly([(.3, .7), (.5, .75)]);
        poly([(.5, .5), (.7, .55)]);
      case DiePattern.bolt:
        poly([(.6, 0), (.35, .5), (.55, .5), (.4, 1)]);
      case DiePattern.bones:
        poly([(.15, .2), (.4, .45)]);
        poly([(.4, .2), (.15, .45)]);
        poly([(.6, .6), (.85, .85)]);
        poly([(.85, .6), (.6, .85)]);
      case DiePattern.ink:
        for (var i = 0; i < 6; i++) {
          canvas.drawCircle(Offset(rng.nextDouble(), rng.nextDouble()),
              .04 + rng.nextDouble() * .06, dot);
        }
      case DiePattern.chalk:
        canvas.drawPath(
            Path()
              ..moveTo(.15, .3)
              ..relativeQuadraticBezierTo(.2, -.2, .3, 0)
              ..relativeQuadraticBezierTo(.1, .15, .3, 0)
              ..moveTo(.2, .6)
              ..relativeQuadraticBezierTo(.15, .15, .3, 0)
              ..relativeQuadraticBezierTo(.1, -.12, .25, -.05),
            line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DiePatternPainter old) =>
      old.pattern != pattern || old.color != color || old.seed != seed;
}
