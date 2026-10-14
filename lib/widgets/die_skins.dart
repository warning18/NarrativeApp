// One cube skin per die (v1.216, from the Grey Shroud dice sheet): the
// stone it is cut from, the colour of its edge, the mark cut into its
// faces and the light it gives off. A die with no skin of its own reads as
// bone.
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    DieSkin('Bone', Color(0xFFCFC6AE), Color(0xFF7C735B), DiePattern.pips);

/// The skin of the die [id] (dice.json key).
DieSkin dieSkinOf(String? id) => dieSkins[id] ?? boneSkin;

const Map<String, DieSkin> dieSkins = {
  'starter_die': boneSkin,
  'void_die': DieSkin('Void glass', Color(0xFF171225), Color(0xFF8D6CFF),
      DiePattern.stars, Color(0xFF7A5CFF)),
  'iron_die': DieSkin(
      'Riveted iron', Color(0xFF4B5057), Color(0xFFA6AFBA), DiePattern.rivets),
  'flame_die': DieSkin('Ember', Color(0xFF4D1F12), Color(0xFFFF8A3D),
      DiePattern.cracks, Color(0xFFFF6A1F)),
  'tide_die': DieSkin('Sea glass', Color(0xFF13393F), Color(0xFF5ADBCB),
      DiePattern.waves, Color(0xFF2FBFB0)),
  'storm_die': DieSkin('Stormcast', Color(0xFF2B3445), Color(0xFFB4CDFF),
      DiePattern.bolt, Color(0xFF8FB4FF)),
  'stone_die': DieSkin(
      'Dwarven stone', Color(0xFF5B5349), Color(0xFFD1B684), DiePattern.bricks),
  'shadow_die': DieSkin('Black lacquer', Color(0xFF101015), Color(0xFF7A7F99),
      DiePattern.scratch),
  'holy_die': DieSkin('Ivory and gold', Color(0xFFD9D0B8), Color(0xFFF2C14E),
      DiePattern.rays, Color(0xFFF2C14E)),
  'berserker_die': DieSkin(
      'Blood-iron', Color(0xFF4A1515), Color(0xFFE8473F), DiePattern.scratch),
  'arcane_die': DieSkin('Rune crystal', Color(0xFF20245A), Color(0xFF8E9CFF),
      DiePattern.runes, Color(0xFF6E7DFF)),
  'huntsman_die': DieSkin(
      'Antler and oak', Color(0xFF4B3B28), Color(0xFFB5935F), DiePattern.grain),
  'liora_die': DieSkin('Living wood', Color(0xFF30502B), Color(0xFF95D16F),
      DiePattern.leaf, Color(0xFF6FBF4E)),
  'vess_die': DieSkin('Tide-crystal, ink', Color(0xFF1C2650), Color(0xFF86D6FF),
      DiePattern.ink, Color(0xFF6A8CFF)),
  'grosh_die':
      DieSkin('Tusk', Color(0xFF8F8771), Color(0xFFE0D6B6), DiePattern.cracks),
  'apprentice_die':
      DieSkin('Chalk', Color(0xFFD8D4C6), Color(0xFF7C8CFF), DiePattern.chalk),
  'sage_die': DieSkin('Sky-glass', Color(0xFF21324D), Color(0xFF96D9FF),
      DiePattern.stars, Color(0xFF5FB6F2)),
  'tobin_die': DieSkin('Reliquary bronze', Color(0xFF5C4527), Color(0xFFE5B566),
      DiePattern.rivets),
  'malrik_die':
      DieSkin('Rust', Color(0xFF4D3123), Color(0xFFCC8250), DiePattern.scratch),
  'gambler_die': DieSkin(
      'Casino ivory', Color(0xFFE6E0D0), Color(0xFFC0392B), DiePattern.pips),
  'frost_die': DieSkin('Ice', Color(0xFF1F3C52), Color(0xFFC4EBFF),
      DiePattern.facets, Color(0xFF7FD3FF)),
  'twinfang_die': DieSkin('Bone and fang', Color(0xFFCFC6AE), Color(0xFF3A3A3A),
      DiePattern.scratch),
  'bulwark_die': DieSkin(
      'Tower stone', Color(0xFF505661), Color(0xFFB6BEC9), DiePattern.bricks),
  'pilgrim_die': DieSkin(
      'Wayworn wood', Color(0xFF6D5635), Color(0xFFDCCB9F), DiePattern.grain),
  'tempest_die': DieSkin('Thunder iron', Color(0xFF242B3C), Color(0xFFFFE48A),
      DiePattern.bolt, Color(0xFFFFD54F)),
  'ossuary_die': DieSkin(
      'Bone mosaic', Color(0xFFCFC6AE), Color(0xFF7A7364), DiePattern.bones),
  'vigil_die': DieSkin('Candle wax', Color(0xFFE8DFC4), Color(0xFFF2C14E),
      DiePattern.rays, Color(0xFFFFC96B)),
  'tearglass_die': DieSkin('Tear-glass', Color(0xFF102B30), Color(0xFFA0F5E8),
      DiePattern.cracks, Color(0xFF38D6C0)),
  'headsman_die': DieSkin('Black iron, red', Color(0xFF1D1D22),
      Color(0xFFCF3E2F), DiePattern.scratch),
  'greenwood_die': DieSkin(
      'Greenwood', Color(0xFF2B4B2D), Color(0xFFA8D96D), DiePattern.leaf),
  'chorus_die': DieSkin(
      'Silver bell', Color(0xFFAEB4BE), Color(0xFFF5F7FB), DiePattern.waves),
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
