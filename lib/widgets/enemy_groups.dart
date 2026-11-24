// The group an enemy belongs to, and how its fight block looks for it (the
// nameplate's colour, the emblem, the corner ornament), so a glance tells whom
// the party fights while the numbers stay where they always are.
//
// The group is read from the enemy's record: its own `group` (enemies.json,
// for the people of no clan: the Hollow Court, the Turned...), else its
// `faction` (a clan, the Choir, the Pit, the giants, the Tide-Kin), else its
// `kind` (the dead, the void, beasts, constructs). A record that says nothing
// known falls back to "people of no clan". This is UX's table: the look of a
// group is never data.
import 'package:flutter/material.dart';

import '../data/enemy_groups.dart';
import 'pixel_banner.dart';

/// The pixel marks drawn when a group has no banner of its own.
const Map<String, List<String>> _glyphs = {
  'skull': [
    '.#######.',
    '#########',
    '##..#..##',
    '##..#..##',
    '#########',
    '.###.###.',
    '..#.#.#..',
  ],
  'void': [
    '....#....',
    '...###...',
    '..##.##..',
    '.##...##.',
    '##.....##',
    '.##...##.',
    '..##.##..',
    '...###...',
    '....#....',
  ],
  'paw': [
    '.##...##.',
    '.##...##.',
    '....#....',
    '#..###..#',
    '#.#####.#',
    '..#####..',
    '..##.##..',
  ],
  'gear': [
    '..#.#.#..',
    '.#######.',
    '###...###',
    '.#.....#.',
    '###...###',
    '.#######.',
    '..#.#.#..',
  ],
  'mask': [
    '..#####..',
    '.#######.',
    '.##...##.',
    '.##...##.',
    '.#######.',
    '#########',
    '#.#####.#',
  ],
  'halo': [
    '..#####..',
    '.#.....#.',
    '.#.....#.',
    '..#####..',
    '....#....',
    '...###...',
    '..#.#.#..',
  ],
  'horns': [
    '#.......#',
    '##.....##',
    '.##...##.',
    '..#####..',
    '.#######.',
    '.#.#.#.#.',
  ],
  'fist': [
    '.#.#.#...',
    '#########',
    '#########',
    '#########',
    '.#######.',
    '..#####..',
  ],
  'wave': [
    '.........',
    '.##...##.',
    '#..#.#..#',
    '....#....',
    '.##...##.',
    '#..#.#..#',
    '....#....',
  ],
  'crown': ['#...#...#', '##.###.##', '#########', '#########', '.#######.'],
  'flame': [
    '....#....',
    '...##....',
    '..###.#..',
    '.#####.#.',
    '.#######.',
    '.#######.',
    '..#####..',
  ],
  'chain': ['.##...##.', '#..#.#..#', '#..###..#', '#..#.#..#', '.##...##.'],
};

/// A group's look.
@immutable
class EnemyGroup {
  const EnemyGroup(
    this.id,
    this.name,
    this.color, {
    this.banner,
    this.glyph,
    this.ornament = 'studs',
  });

  final String id;
  final String name;

  /// The nameplate's colour (a clan's own, or Apollo for the rest).
  final Color color;

  /// The clan's banner id (its sign is the emblem), else [glyph].
  final String? banner;
  final String? glyph;

  /// The corner ornament: studs, spikes, rivets or notches.
  final String ornament;
}

Color _c(int rgb) => Color(0xFF000000 | rgb);

/// Every group the fight knows. Clan colours are the clans' own
/// (factions.json); the others are Apollo (docs/art/palette-apollo.md).
final Map<String, EnemyGroup> enemyGroups = {
  'dominion': EnemyGroup(
    'dominion',
    'Lantern Dominion',
    _c(0x2F62B5),
    banner: clanBannerId('dominion'),
  ),
  'crows': EnemyGroup(
    'crows',
    'Salt Crows',
    _c(0xB0303F),
    banner: clanBannerId('crows'),
  ),
  'compact': EnemyGroup(
    'compact',
    'Cinder Compact',
    _c(0xB86B3C),
    banner: clanBannerId('compact'),
  ),
  'mire': EnemyGroup(
    'mire',
    'Mire Courts',
    _c(0x3F8F5A),
    banner: clanBannerId('mire'),
  ),
  'vigil': EnemyGroup(
    'vigil',
    'Grey Vigil',
    _c(0x8A8F98),
    banner: clanBannerId('vigil'),
  ),
  'penitents': EnemyGroup(
    'penitents',
    'Ashen Penitents',
    _c(0xCBB68E),
    banner: clanBannerId('penitents'),
  ),
  'choir': EnemyGroup('choir', 'The Choir', _c(0xAD8A10), glyph: 'halo'),
  'pit': EnemyGroup(
    'pit',
    'The Pit',
    _c(0xA94BB4),
    glyph: 'horns',
    ornament: 'spikes',
  ),
  'giants': EnemyGroup(
    'giants',
    'Giants',
    _c(0x6F8796),
    glyph: 'fist',
    ornament: 'rivets',
  ),
  'tidekin': EnemyGroup(
    'tidekin',
    'Tide-Kin',
    _c(0x1C8FA0),
    glyph: 'wave',
    ornament: 'notches',
  ),
  'undead': EnemyGroup(
    'undead',
    'The dead',
    _c(0x819796),
    glyph: 'skull',
    ornament: 'notches',
  ),
  'void': EnemyGroup(
    'void',
    'The Void',
    _c(0xA23E8C),
    glyph: 'void',
    ornament: 'spikes',
  ),
  'beast': EnemyGroup(
    'beast',
    'Beasts',
    _c(0xAD7757),
    glyph: 'paw',
    ornament: 'notches',
  ),
  'construct': EnemyGroup(
    'construct',
    'Constructs',
    _c(0x4F8FBA),
    glyph: 'gear',
    ornament: 'rivets',
  ),
  // The people of no clan, by the groups Core gives them (enemies.json
  // `group`). The ids are the ones Core names; an unknown one is the fallback.
  'hollow_court': EnemyGroup(
    'hollow_court',
    'The Hollow Court',
    _c(0x7A367B),
    glyph: 'mask',
    ornament: 'spikes',
  ),
  'turned': EnemyGroup(
    'turned',
    'The Turned',
    _c(0xE8C170),
    glyph: 'chain',
    ornament: 'notches',
  ),
  'claimants': EnemyGroup(
    'claimants',
    'The Claimants',
    _c(0x884B2B),
    glyph: 'crown',
  ),
  'champions': EnemyGroup(
    'champions',
    'The Champions',
    _c(0xF2C14E),
    glyph: 'crown',
    ornament: 'rivets',
  ),
  'void_cults': EnemyGroup(
    'void_cults',
    'The Void Cults',
    _c(0xA53030),
    glyph: 'flame',
    ornament: 'spikes',
  ),
  'common_folk': EnemyGroup(
    'common_folk',
    'Common folk',
    _c(0x9A8C6E),
    glyph: 'fist',
  ),
  'people': EnemyGroup(
    'people',
    'People of no clan',
    _c(0x7A4841),
    glyph: 'mask',
  ),
};

/// The look of an enemy record: the group Core reads from it (`enemyGroupOf`,
/// lib/data/enemy_groups.dart: its own `group`, else its `faction`, else its
/// `kind`); a group nobody here dresses falls back to its `kind`, then to
/// "people of no clan".
EnemyGroup groupLookOf(Map<String, dynamic>? enemy) {
  if (enemy == null) return enemyGroups['people']!;
  return enemyGroups[enemyGroupOf(enemy)] ??
      enemyGroups[(enemy['kind'] ?? '').toString().trim()] ??
      enemyGroups['people']!;
}

/// The pixel mark [name], [px] dp a pixel, in [color].
class GroupGlyph extends StatelessWidget {
  const GroupGlyph(this.name, this.color, {super.key, this.px = 2});

  final String name;
  final Color color;
  final double px;

  @override
  Widget build(BuildContext context) {
    final rows = _glyphs[name] ?? _glyphs['mask']!;
    return CustomPaint(
      size: Size(9 * px, rows.length * px),
      painter: _GlyphPainter(rows, color, px),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.rows, this.color, this.px);

  final List<String> rows;
  final Color color;
  final double px;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(Rect.fromLTWH(x * px, y * px, px, px), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.rows != rows || old.color != color || old.px != px;
}

/// A group's emblem in a [size] square: the clan's own banner cropped to its
/// sign, or the group's pixel mark in [color].
class GroupEmblem extends StatelessWidget {
  const GroupEmblem(
    this.group, {
    super.key,
    this.size = 14,
    required this.color,
  });

  final EnemyGroup group;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final banner = group.banner;
    if (banner != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.05),
            child: SizedBox(
              width: pixelBannerSize.width,
              height: pixelBannerSize.height,
              child: PixelBanner(id: banner, scale: 1),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: GroupGlyph(
          group.glyph ?? 'mask',
          color,
          px: (size / 9).floorToDouble().clamp(1.0, 4.0),
        ),
      ),
    );
  }
}

/// A group's corner ornament, painted over its block.
class OrnamentPainter extends CustomPainter {
  OrnamentPainter(this.type, this.light, this.dark);

  final String type;
  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final lp = Paint()
      ..color = light
      ..isAntiAlias = false;
    final dp = Paint()
      ..color = dark
      ..isAntiAlias = false;
    void sq(Paint p, double x, double y, double w, double h) =>
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), p);
    switch (type) {
      case 'spikes': // stepped points in the nameplate's top corners
        for (final left in [true, false]) {
          for (var i = 0; i < 3; i++) {
            final w = 8.0 - i * 3;
            final x = left ? 1.0 : size.width - 1 - w;
            sq(dp, x + (left ? 3 : -3), 4.0 + i * 2, w, 2);
          }
        }
      case 'rivets': // studs along the foot
        for (final f in [0.2, 0.4, 0.6, 0.8]) {
          sq(lp, size.width * f - 1.5, size.height - 4.5, 3, 3);
        }
      case 'notches': // bites out of the foot
        for (var x = 14.0; x < size.width - 12; x += 12) {
          sq(dp, x, size.height - 3.5, 5, 3.5);
        }
      default: // studs in the four corners
        for (final x in [3.0, size.width - 6]) {
          for (final y in [3.0, size.height - 6]) {
            sq(lp, x, y, 3, 3);
          }
        }
    }
  }

  @override
  bool shouldRepaint(OrnamentPainter old) =>
      old.type != type || old.light != light || old.dark != dark;
}
