// The standing sign (v1.576, the clan glance): a small disc at the corner of
// a clan's banner that says how the clan stands with the player. One disc for
// each of the eleven standing steps, each its own shape on a 7 x 7 pixel grid
// and the game's own colour for it (standingTiers, the clan card's), so the
// shape carries the level for a colour-blind player. The bad side is a skull,
// crossed blades, one blade, a frown and a watching eye; unknown is a dot;
// the good side is a ringed dot, a hollow heart, a heart, a shield and a
// crowned heart. The two extremes, hunted and sworn, wear a double rim.
import 'package:flutter/material.dart';

import '../data/factions.dart';

/// Each step's shape: seven rows of seven pixels, '#' for a lit one.
const Map<StandingTier, List<String>> standingGlyphs = {
  StandingTier.hunted: [
    '.#####.',
    '#######',
    '#.###.#',
    '#######',
    '.##.##.',
    '..#.#..',
    '..###..',
  ],
  StandingTier.hostile: [
    '##...##',
    '.##.##.',
    '..###..',
    '...#...',
    '..###..',
    '.##.##.',
    '##...##',
  ],
  StandingTier.resented: [
    '......#',
    '.....##',
    '....##.',
    '..###..',
    '.###...',
    '##.#...',
    '#.#....',
  ],
  StandingTier.unfriendly: [
    '.......',
    '.#...#.',
    '.#...#.',
    '.......',
    '..###..',
    '.#...#.',
    '#.....#',
  ],
  StandingTier.wary: [
    '.......',
    '..###..',
    '.#...#.',
    '#..#..#',
    '.#...#.',
    '..###..',
    '.......',
  ],
  StandingTier.unknown: [
    '.......',
    '.......',
    '..###..',
    '..###..',
    '..###..',
    '.......',
    '.......',
  ],
  StandingTier.known: [
    '..###..',
    '.#...#.',
    '#.....#',
    '#..#..#',
    '#.....#',
    '.#...#.',
    '..###..',
  ],
  StandingTier.friendly: [
    '.##.##.',
    '#..#..#',
    '#.....#',
    '.#...#.',
    '..#.#..',
    '...#...',
    '.......',
  ],
  StandingTier.friend: [
    '.##.##.',
    '#######',
    '#######',
    '.#####.',
    '..###..',
    '...#...',
    '.......',
  ],
  StandingTier.trusted: [
    '#######',
    '#.....#',
    '#..#..#',
    '#.###.#',
    '.#...#.',
    '..#.#..',
    '...#...',
  ],
  StandingTier.sworn: [
    '#.#.#.#',
    '#######',
    '.......',
    '.##.##.',
    '.#####.',
    '..###..',
    '...#...',
  ],
};

/// The disc's colour for [tier]: the game's own.
Color standingSignColor(StandingTier tier) => Color(tierColor(tier));

/// The sign for [tier], [size] logical pixels across (16 on a ring crest, 24
/// to 28 on a standard, 44 on an offer's banner).
class StandingSign extends StatelessWidget {
  const StandingSign(this.tier, {super.key, this.size = 18});

  final StandingTier tier;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: Key('standing_sign_${tier.name}'),
        width: size,
        height: size,
        child: CustomPaint(painter: _StandingSignPainter(tier)),
      );
}

class _StandingSignPainter extends CustomPainter {
  const _StandingSignPainter(this.tier);

  final StandingTier tier;

  @override
  void paint(Canvas canvas, Size size) {
    final colour = standingSignColor(tier);
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rim = tier == StandingTier.hunted || tier == StandingTier.sworn;
    final inner = rim ? r - size.width * 0.07 : r;
    canvas.drawCircle(c, inner, Paint()..color = const Color(0xFF14121A));
    canvas.drawCircle(
        c,
        inner - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width < 20 ? 1.2 : 1.5
          ..color = colour);
    if (rim) {
      canvas.drawCircle(
          c,
          r - 0.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width < 20 ? 0.9 : 1
            ..color = colour.withValues(alpha: 0.75));
    }
    final px = (size.width * 0.62) / 7;
    final origin = c - Offset(px * 3.5, px * 3.5);
    final paint = Paint()
      ..color = colour
      ..isAntiAlias = false;
    final rows = standingGlyphs[tier]!;
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(
              Rect.fromLTWH(origin.dx + x * px, origin.dy + y * px, px, px),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StandingSignPainter old) => old.tier != tier;
}
