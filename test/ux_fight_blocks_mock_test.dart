// Stats blocks for the fight (UX_SHOTS=<folder>, UX_DIR=a|b|c, UX_GROUPS=1): three
// directions for the block of the hero, a companion and an enemy, a variant per enemy
// group (enemies.json faction and kind), and a full fight screen per direction (a mixed
// fight and a boss). A mock: the screen is drawn here with the real heads, the real
// fight figures and real enemy ids; nothing in lib/ changes. Drawn only with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/fight_figures.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';
import 'package:narrative_data_app/widgets/head_avatar.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

// ---------------------------------------------------------------- tokens ---
// Apollo (docs/art/palette-apollo.md): the colours of the skill icons.
const _apOutline = Color(0xFF090A14);
const _apNight = Color(0xFF10141F);
const _apNavy = Color(0xFF172038);
const _apInk = Color(0xFF202E37);
const _apGold = Color(0xFFE8C170);
const _apCore = Color(0xFFF2C14E);
const _apCream = Color(0xFFEBEDE9);

Color _element(String e) => switch (e) {
      'Fire' => const Color(0xFFCF573C),
      'Water' => const Color(0xFF4F8FBA),
      'Wind' => const Color(0xFFA4DDDB),
      'Earth' => const Color(0xFFAD7757),
      'Electricity' => const Color(0xFFE8C170),
      'Void' => const Color(0xFFA23E8C),
      'Light' => const Color(0xFFD0DA91),
      _ => const Color(0xFF819796),
    };

Color _rarity(String r) => switch (r) {
      'uncommon' => const Color(0xFF75A743),
      'rare' => const Color(0xFF4F8FBA),
      'epic' => const Color(0xFFA23E8C),
      'legendary' => const Color(0xFFDE9E41),
      _ => const Color(0xFF819796),
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ----------------------------------------------------------- shared bits ---
class Tag extends StatelessWidget {
  const Tag(this.label, this.color, {super.key, this.fill = false, this.dot});
  final String label;
  final Color color;
  final bool fill;
  final bool? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color:
            fill ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.14),
        shape: PixelChipBorder(
            side: BorderSide(color: color.withValues(alpha: 0.9), width: 1),
            step: 1.5,
            steps: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot == true) ...[
          Container(width: 6, height: 6, color: color),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 10,
                height: 1.1,
                color: fill ? _apOutline : color)),
      ]),
    );
  }
}

class Cost extends StatelessWidget {
  const Cost(this.n, {super.key, this.size = 22});
  final int n;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: const BorderSide(color: Color(0xFF4F8FBA), width: 1.5),
            step: 2,
            steps: 2),
      ),
      alignment: Alignment.center,
      child: Text('$n',
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: size * 0.55,
              color: const Color(0xFFA4DDDB))),
    );
  }
}

TextStyle _name(BuildContext c, {double size = 14, Color? color}) => TextStyle(
    fontFamily: InkFonts.display,
    fontSize: size,
    height: 1.1,
    color: color ?? Theme.of(c).colorScheme.onSurface);

TextStyle _body(BuildContext c, {double size = 12, Color? color}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: size,
    height: 1.25,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

TextStyle _sys(BuildContext c, {double size = 11, Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: size,
    height: 1.2,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

/// The phone's frame: the app bar of the real Skills screen over the page.
class Phone extends StatelessWidget {
  const Phone({super.key, required this.title, required this.child, this.sub});
  final String title;
  final String? sub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(sub ?? '',
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

Widget pickerHeader(BuildContext context, {int level = 7, String hint = ''}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: ink.seam),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('Level $level',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontFamily: InkFonts.display)),
      const Spacer(),
      Text(hint, style: _sys(context, color: ink.ash)),
    ]),
  );
}

// ------------------------------------------------------------------ data ---
late Map<String, dynamic> _enemies;
late Map<String, dynamic> _factions;

enum Rank { normal, elite, boss }

class Chip {
  const Chip(this.icon, this.color, {this.badge, this.label = ''});
  final IconData icon;
  final Color color;
  final String? badge;
  final String label;
}

class Intent {
  const Intent(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
}

/// An enemy group: the faction of enemies.json, else the kind.
class Grp {
  const Grp(this.id, this.name, this.color,
      {this.banner, this.glyph, this.orn = 'studs'});
  final String id, name;
  final Color color;
  final String orn; // the corner ornament: studs, spikes, rivets, notches
  final String? banner; // a clan's own banner (the emblem)
  final String? glyph; // else a pixel emblem
}

const _grpPeople =
    Grp('people', 'People of no clan', Color(0xFF7A4841), glyph: 'mask');

Map<String, Grp> _groups() {
  Color clan(String id) => Color(
      int.parse((_factions[id]['color'] as String).substring(1), radix: 16) |
          0xFF000000);
  return {
    'dominion': Grp('dominion', 'Lantern Dominion', clan('dominion'),
        banner: clanBannerId('dominion')),
    'crows': Grp('crows', 'Salt Crows', clan('crows'),
        banner: clanBannerId('crows')),
    'compact': Grp('compact', 'Cinder Compact', clan('compact'),
        banner: clanBannerId('compact')),
    'mire':
        Grp('mire', 'Mire Courts', clan('mire'), banner: clanBannerId('mire')),
    'vigil': Grp('vigil', 'Grey Vigil', clan('vigil'),
        banner: clanBannerId('vigil')),
    'penitents': Grp('penitents', 'Ashen Penitents', clan('penitents'),
        banner: clanBannerId('penitents')),
    'choir': Grp('choir', 'The Choir (angels)', clan('choir'), glyph: 'halo'),
    'pit': Grp('pit', 'The Pit (demons)', clan('pit'),
        glyph: 'horns', orn: 'spikes'),
    'giants':
        Grp('giants', 'Giants', clan('giants'), glyph: 'fist', orn: 'rivets'),
    'tidekin': Grp('tidekin', 'Tide-Kin', clan('tidekin'),
        glyph: 'wave', orn: 'notches'),
    'undead': const Grp('undead', 'The dead', Color(0xFF819796),
        glyph: 'skull', orn: 'notches'),
    'void': const Grp('void', 'The Void', Color(0xFFA23E8C),
        glyph: 'void', orn: 'spikes'),
    'beast': const Grp('beast', 'Beasts', Color(0xFFAD7757),
        glyph: 'paw', orn: 'notches'),
    'construct': const Grp('construct', 'Constructs', Color(0xFF4F8FBA),
        glyph: 'gear', orn: 'rivets'),
    'people': _grpPeople,
  };
}

Grp groupOf(String enemyId) {
  final e = _enemies[enemyId] as Map<String, dynamic>;
  final g = _groups();
  final faction = (e['faction'] ?? '').toString();
  if (faction.isNotEmpty && g.containsKey(faction)) return g[faction]!;
  final kind = e['kind'].toString();
  return g[kind] ?? _grpPeople;
}

class Unit {
  Unit(this.id, this.name,
      {required this.hp,
      required this.max,
      this.armor = 0,
      this.damage,
      this.chips = const [],
      this.intent,
      this.rank = Rank.normal,
      this.ally = false,
      this.order})
      : group = ally ? null : groupOf(id);
  final String id, name;
  final int hp, max, armor;
  final int? damage;
  final List<Chip> chips;
  final Intent? intent;
  final Rank rank;
  final bool ally;
  final int? order;
  final Grp? group;
}

Unit enemy(String id,
    {required int hp,
    int armor = 0,
    List<Chip> chips = const [],
    Intent? intent,
    Rank rank = Rank.normal}) {
  final e = _enemies[id] as Map<String, dynamic>;
  return Unit(id, e['enemyName'] as String,
      hp: hp,
      max: (e['maxHealth'] as num).toInt(),
      armor: armor,
      chips: chips,
      intent: intent,
      rank: rank);
}

const _chipGuard =
    Chip(Icons.shield, Color(0xFF73BED3), badge: '3', label: 'Guard');
const _chipBurn = Chip(Icons.local_fire_department, Color(0xFFDE9E41),
    badge: '2', label: 'Burn');
const _chipSlow = Chip(Icons.ac_unit, Color(0xFF73BED3), label: 'Slow');
const _chipRally =
    Chip(Icons.campaign, Color(0xFFE8C170), badge: '1', label: 'Rally');
const _chipPoison =
    Chip(Icons.science, Color(0xFF75A743), badge: '2', label: 'Poison');

List<Unit> party() => [
      Unit('hero', 'You',
          hp: 61,
          max: 80,
          armor: 2,
          damage: 4,
          ally: true,
          order: 1,
          chips: const [_chipBurn]),
      Unit('kelda', 'Kelda',
          hp: 44,
          max: 52,
          armor: 1,
          damage: 3,
          ally: true,
          order: 2,
          chips: const [_chipGuard]),
    ];

List<Unit> mixed() => [
      enemy('inquisition_soldier',
          hp: 18,
          armor: 2,
          intent: const Intent(Icons.bolt, 'Strike 6', Color(0xFFCF573C))),
      enemy('street_bandit',
          hp: 14,
          chips: const [_chipPoison],
          intent: const Intent(Icons.shield, 'Guard', Color(0xFF73BED3))),
      enemy('vigil_spearman_halvard',
          hp: 22,
          armor: 1,
          rank: Rank.elite,
          chips: const [_chipRally],
          intent:
              const Intent(Icons.help_outline, 'Unread', Color(0xFF819796))),
      enemy('catacomb_ghoul',
          hp: 9,
          chips: const [_chipSlow],
          intent: const Intent(Icons.bolt, 'Strike 4', Color(0xFFCF573C))),
    ];

List<Unit> bossFight() => [
      enemy('aurel_vane',
          hp: 15,
          armor: 4,
          rank: Rank.boss,
          chips: const [_chipGuard],
          intent: const Intent(Icons.bolt, 'Strike 11', Color(0xFFCF573C))),
      enemy('inquisition_soldier',
          hp: 18,
          armor: 2,
          intent: const Intent(Icons.shield, 'Guard', Color(0xFF73BED3))),
      enemy('inquisition_auxiliary',
          hp: 12,
          intent: const Intent(Icons.bolt, 'Strike 5', Color(0xFFCF573C))),
    ];

// ------------------------------------------------------- pixel emblems -----
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
};

class PixelGlyph extends StatelessWidget {
  const PixelGlyph(this.name, this.color, {super.key, this.px = 2});
  final String name;
  final Color color;
  final double px;
  @override
  Widget build(BuildContext context) {
    final rows = _glyphs[name]!;
    return CustomPaint(
        size: Size(9 * px, rows.length * px),
        painter: _GlyphPainter(rows, color, px));
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.rows, this.color, this.px);
  final List<String> rows;
  final Color color;
  final double px;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#')
          c.drawRect(Rect.fromLTWH(x * px, y * px, px, px), p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// A group's emblem: the clan's own banner (cropped to its sign) or a pixel glyph.
class Emblem extends StatelessWidget {
  const Emblem(this.g, {super.key, this.size = 20, this.color});
  final Grp g;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    if (g.banner != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.05),
            child: SizedBox(
                width: 64,
                height: 128,
                child: PixelBanner(id: g.banner!, scale: 1)),
          ),
        ),
      );
    }
    return SizedBox(
        width: size,
        height: size,
        child: Center(
            child: PixelGlyph(g.glyph!, color ?? _apCream,
                px: (size / 9).floorToDouble().clamp(1, 4))));
  }
}

class OrnamentPainter extends CustomPainter {
  OrnamentPainter(this.type, this.color);
  final String type;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final light = Color.lerp(color, _apCream, 0.55)!;
    final dark = Paint()..color = _apOutline;
    final lp = Paint()..color = light;
    void sq(Paint p, double x, double y, double w, double h) =>
        c.drawRect(Rect.fromLTWH(x, y, w, h), p);
    switch (type) {
      case 'spikes': // stepped points on the top corners
        for (final left in [true, false]) {
          for (var i = 0; i < 3; i++) {
            final w = 8.0 - i * 3;
            final x = left ? 1.0 : s.width - 1 - w;
            sq(dark, x + (left ? 3 : -3), 4.0 + i * 2, w, 2);
          }
        }
      case 'rivets': // studs along the foot
        for (final f in [0.2, 0.4, 0.6, 0.8]) {
          sq(lp, s.width * f - 1.5, s.height - 4.5, 3, 3);
        }
      case 'notches': // bites out of the foot
        for (var x = 14.0; x < s.width - 12; x += 12) {
          sq(dark, x, s.height - 3.5, 5, 3.5);
        }
      default: // studs in the four corners
        for (final x in [3.0, s.width - 6]) {
          for (final y in [3.0, s.height - 6]) {
            sq(lp, x, y, 3, 3);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// -------------------------------------------------------- shared pieces -----
Color _allyColour(BuildContext c) => InkColors.of(c).heal;

Widget headTile(Unit u, double size, {Color? frame}) => Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side:
                BorderSide(color: frame ?? const Color(0xFF394A50), width: 1.5),
            step: 2,
            steps: 2),
      ),
      padding: const EdgeInsets.all(1),
      child: HeadAvatar(id: u.id, name: u.name, size: size - 4),
    );

Widget hpBar(BuildContext c, Unit u, {double h = 14}) {
  final ink = InkColors.of(c);
  final ratio = (u.hp / u.max).clamp(0.0, 1.0);
  final fill = u.ally ? const Color(0xFF75A743) : const Color(0xFFCF573C);
  return Container(
    height: h,
    decoration: ShapeDecoration(
      color: _apOutline,
      shape: PixelChipBorder(
          side: const BorderSide(color: Color(0xFF394A50), width: 1),
          step: 1.5,
          steps: 2),
    ),
    padding: const EdgeInsets.all(1.5),
    child: Stack(children: [
      FractionallySizedBox(widthFactor: ratio, child: Container(color: fill)),
      Center(
        child: Text('${u.hp} / ${u.max}',
            style: TextStyle(
                fontFamily: InkFonts.prose,
                fontWeight: FontWeight.w700,
                fontSize: h < 14 ? 10 : 11,
                height: 1,
                color: _apCream,
                shadows: const [
                  Shadow(color: _apOutline, blurRadius: 0, offset: Offset(1, 1))
                ])),
      ),
    ]),
  );
}

Widget stat(IconData icon, String v, Color color, {double size = 13}) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: size, color: color),
      const SizedBox(width: 1),
      Text(v,
          style: TextStyle(
              fontFamily: InkFonts.system,
              fontSize: size - 2,
              height: 1,
              color: _apCream)),
    ]);

Widget statusChip(Chip c, {double size = 16}) => Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 2),
      decoration: ShapeDecoration(
        color: c.color.withValues(alpha: 0.2),
        shape: PixelChipBorder(
            side: BorderSide(color: c.color, width: 1), step: 1.5, steps: 2),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Icon(c.icon, size: size - 5, color: c.color),
        if (c.badge != null)
          Positioned(
              right: 0,
              bottom: -1,
              child: Text(c.badge!,
                  style: const TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 8,
                      height: 1,
                      color: _apCream,
                      shadows: [
                        Shadow(color: _apOutline, offset: Offset(1, 1))
                      ]))),
      ]),
    );

Widget intentChip(Intent i) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: i.color.withValues(alpha: 0.18),
        shape: PixelChipBorder(
            side: BorderSide(color: i.color, width: 1), step: 1.5, steps: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i.icon, size: 11, color: i.color),
        const SizedBox(width: 2),
        Text(i.text,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 9,
                height: 1,
                color: _apCream)),
      ]),
    );

Widget intentFit(Intent i) => Flexible(
    child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: intentChip(i)));

Widget nameFit(Widget text) => FittedBox(
    fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: text);

Widget rankMark(Rank r, Color color) => switch (r) {
      Rank.normal => const SizedBox.shrink(),
      Rank.elite => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star, size: 11, color: color),
          Text('ELITE',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 8,
                  height: 1,
                  color: color)),
        ]),
      Rank.boss => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium, size: 12, color: color),
          Text('BOSS',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 8,
                  height: 1,
                  color: color)),
        ]),
    };

Widget chipsRow(Unit u, {int max = 3, double size = 16}) => Row(children: [
      for (final c in u.chips.take(max)) statusChip(c, size: size),
      if (u.chips.length > max)
        Text('+${u.chips.length - max}',
            style: const TextStyle(
                fontFamily: InkFonts.system, fontSize: 9, color: _apGold)),
    ]);

Color frameOf(BuildContext c, Unit u) =>
    u.ally ? _allyColour(c) : (u.group?.color ?? InkColors.of(c).ember);

// =============================================================== DIRECTION A
// Plate: today's block in the game's pixel frame, the numbers in fixed places.

class BlockA extends StatelessWidget {
  const BlockA(this.u,
      {super.key, this.w = 164, this.grouped = false, this.dead = false});
  final Unit u;
  final double w;
  final bool grouped;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    final frame =
        grouped || u.ally ? frameOf(context, u) : InkColors.of(context).ember;
    final gold = u.rank != Rank.normal ? _apCore : frame;
    return Container(
      width: w,
      height: 78,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
      decoration: ShapeDecoration(
        color: Color.lerp(_apNavy, frame, u.ally ? 0.04 : 0.1),
        shape: PixelChipBorder(
            side: BorderSide(
                color: gold, width: u.rank == Rank.normal ? 1.5 : 2.5),
            step: 3,
            steps: 3),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        headTile(u, 38, frame: frame),
        const SizedBox(width: 6),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (u.order != null)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF577277))),
                  child: Text('${u.order}',
                      style: _sys(context, size: 8, color: _apCream)),
                ),
              Expanded(
                child: nameFit(Text(u.name,
                    maxLines: 1,
                    style: _name(context,
                        size: 13,
                        color: u.ally ? _allyColour(context) : _apCream))),
              ),
              if (u.damage != null)
                stat(Icons.bolt, '${u.damage}', const Color(0xFFCF573C),
                    size: 12),
              if (u.rank != Rank.normal) rankMark(u.rank, _apCore),
            ]),
            const SizedBox(height: 3),
            hpBar(context, u),
            const SizedBox(height: 4),
            Row(children: [
              stat(
                  Icons.shield_outlined, '${u.armor}', const Color(0xFF73BED3)),
              const SizedBox(width: 4),
              Expanded(child: chipsRow(u, max: u.intent != null ? 1 : 4)),
              if (u.intent != null) intentFit(u.intent!),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// =============================================================== DIRECTION B
// Banner edge: a banner strip down the left edge carries the side or the group.

class BlockB extends StatelessWidget {
  const BlockB(this.u, {super.key, this.w = 164, this.grouped = false});
  final Unit u;
  final double w;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final frame = frameOf(context, u);
    final strip = u.ally
        ? _allyColour(context)
        : (grouped ? frame : InkColors.of(context).ember);
    final g = u.group;
    return Container(
      width: w,
      height: 78,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(
                color:
                    u.rank == Rank.normal ? const Color(0xFF394A50) : _apCore,
                width: u.rank == Rank.normal ? 1.5 : 2.5),
            step: 2,
            steps: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          width: 22,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [strip, Color.lerp(_apNight, strip, 0.35)!])),
          child: Column(children: [
            const SizedBox(height: 4),
            if (u.ally)
              Icon(u.id == 'hero' ? Icons.person : Icons.pets,
                  size: 14, color: _apOutline)
            else if (grouped && g != null)
              Emblem(g, size: 16, color: _apOutline)
            else
              const Icon(Icons.close, size: 14, color: _apOutline),
            const Spacer(),
            if (u.rank != Rank.normal) ...[
              Icon(u.rank == Rank.boss ? Icons.workspace_premium : Icons.star,
                  size: 14, color: _apCore),
              const SizedBox(height: 3),
            ],
            if (u.order != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${u.order}',
                    style: _sys(context, size: 10, color: _apOutline)),
              ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 6, 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                headTile(u, 34, frame: strip),
                const Spacer(),
                if (u.damage != null)
                  stat(Icons.bolt, '${u.damage}', const Color(0xFFCF573C),
                      size: 11)
                else if (u.intent != null)
                  Icon(u.intent!.icon, size: 12, color: u.intent!.color),
              ]),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nameFit(Text(u.name,
                          maxLines: 1,
                          style: _name(context,
                              size: 13,
                              color:
                                  u.ally ? _allyColour(context) : _apCream))),
                      const SizedBox(height: 3),
                      hpBar(context, u),
                      const Spacer(),
                      Row(children: [
                        stat(Icons.shield_outlined, '${u.armor}',
                            const Color(0xFF73BED3)),
                        const SizedBox(width: 4),
                        Expanded(
                            child: chipsRow(u, max: u.intent != null ? 0 : 3)),
                        if (u.intent != null) intentFit(u.intent!),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// =============================================================== DIRECTION C
// Nameplate and gems: a nameplate on top (the group's colour, emblem, rank), the
// armour and the damage as gems on the head, the intent as a tab on the foot.

class BlockC extends StatelessWidget {
  const BlockC(this.u, {super.key, this.w = 164, this.grouped = false});
  final Unit u;
  final double w;
  final bool grouped;

  Widget gem(IconData icon, String v, Color color) => Container(
        width: 22,
        height: 22,
        decoration: ShapeDecoration(
          color: _apNight,
          shape: PixelChipBorder(
              side: BorderSide(color: color, width: 1.5), step: 2, steps: 2),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 9, color: color),
          Text(v,
              style: const TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 8,
                  height: 1,
                  color: _apCream)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final base = u.ally
        ? _allyColour(context)
        : (grouped ? frameOf(context, u) : InkColors.of(context).ember);
    final g = u.group;
    final plateText = _apOutline;
    final orn = !u.ally && grouped && g != null ? g.orn : null;
    return Container(
      width: w,
      height: 78,
      foregroundDecoration: orn == null ? null : null,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(
                color: u.rank == Rank.normal ? base : _apCore,
                width: u.rank == Rank.normal ? 2 : 3),
            step: 3,
            steps: 3),
      ),
      child: CustomPaint(
        foregroundPainter: orn == null ? null : OrnamentPainter(orn, base),
        child: Column(children: [
          Container(
            height: 19,
            margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: base,
            child: Row(children: [
              if (!u.ally && grouped && g != null) ...[
                Emblem(g, size: 14, color: plateText),
                const SizedBox(width: 3),
              ] else if (u.order != null) ...[
                Text('${u.order}',
                    style: _sys(context, size: 9, color: plateText)),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: nameFit(Text(u.name,
                    maxLines: 1,
                    style: TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 13,
                        height: 1,
                        color: plateText))),
              ),
              if (u.rank != Rank.normal) rankMark(u.rank, plateText),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  headTile(u, 34, frame: base),
                  Positioned(
                      left: -3,
                      bottom: -13,
                      child: gem(Icons.shield_outlined, '${u.armor}',
                          const Color(0xFF73BED3))),
                  if (u.damage != null)
                    Positioned(
                        right: -9,
                        bottom: -13,
                        child: gem(Icons.bolt, '${u.damage}',
                            const Color(0xFFCF573C))),
                ]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        hpBar(context, u, h: 15),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(
                              child: chipsRow(u,
                                  max: u.intent != null ? 1 : 4, size: 15)),
                          if (u.intent != null) intentFit(u.intent!),
                        ]),
                      ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget block(String dir, Unit u, {double w = 164, bool grouped = false}) =>
    switch (dir) {
      'a' => BlockA(u, w: w, grouped: grouped),
      'b' => BlockB(u, w: w, grouped: grouped),
      _ => BlockC(u, w: w, grouped: grouped),
    };

// ----------------------------------------------------------- the screens ---
Widget fightScreen(BuildContext context, String dir, List<Unit> foes,
    {required String title, bool grouped = true}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  final w = (MediaQuery.of(context).size.width - 24 - 8) / 2;
  final p = party();
  final n = foes.length < 3 ? 3 : foes.length;
  return Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(children: [
        Text('Open country · Rain', style: _sys(context, color: ink.ash)),
        const Spacer(),
        Text('Round 2', style: _sys(context, color: ink.gold)),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            i < p.length
                ? block(dir, p[i], w: w)
                : Opacity(
                    opacity: 0.4,
                    child: Container(
                        width: w,
                        height: 78,
                        decoration: BoxDecoration(
                            border: Border.all(color: ink.seam),
                            borderRadius: BorderRadius.circular(4)))),
          ],
        ]),
        const SizedBox(width: 8),
        Column(children: [
          for (var i = 0; i < foes.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            block(dir, foes[i], w: w, grouped: grouped),
          ],
        ]),
      ]),
    ),
    const SizedBox(height: 8),
    Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A3322), Color(0xFF181F14)]),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: FightFigures(
                allies: const ['hero', 'kelda'],
                foes: [for (final f in foes) f.id],
                height: fightFigureHeight(MediaQuery.of(context).size.width)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Roll the party’s dice, then keep or reroll.',
                style: _sys(context, color: _apCream)),
          ),
        ]),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
            onPressed: () {},
            child: Text('Roll Dice', style: theme.textTheme.labelLarge)),
      ),
    ),
  ]);
}

/// The groups: one card per group with a real enemy of it, the group's name and who
/// falls in it.
Widget groupSheet(BuildContext context, String dir) {
  final ink = InkColors.of(context);
  final reps = <String, String>{
    'dominion': 'inquisition_soldier',
    'crows': 'street_bandit',
    'compact': 'compact_quarryman_brodin',
    'mire': 'mire_returned_sedge',
    'vigil': 'vigil_spearman_halvard',
    'penitents': 'inquisition_penitent',
    'choir': 'angel_sentinel',
    'pit': 'demon_imp',
    'giants': 'frost_kept_giant',
    'tidekin': 'kraken_arm',
    'undead': 'catacomb_ghoul',
    'void': 'void_stalker',
    'beast': 'plague_hound',
    'construct': 'iron_golem',
    'people': 'hollow_court_zealot',
  };
  final members = <String, List<String>>{};
  for (final id in _enemies.keys) {
    members.putIfAbsent(groupOf(id).id, () => []).add(id);
  }
  Widget cell(String gid) {
    final g = _groups()[gid]!;
    final id = reps[gid]!;
    final e = _enemies[id] as Map<String, dynamic>;
    final u = enemy(id,
        hp: ((e['maxHealth'] as num) * 0.7).round(),
        armor: gid == 'construct' ? 3 : 1,
        chips: const [_chipGuard],
        intent: const Intent(Icons.bolt, 'Strike 6', Color(0xFFCF573C)));
    final names = [
      for (final m in members[gid]!) (_enemies[m] as Map)['enemyName'] as String
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        block(dir, u, w: 168, grouped: true),
        const SizedBox(width: 8),
        SizedBox(
          width: 168,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${g.name} · ${names.length}',
                style: _sys(context, size: 11, color: _apGold)),
            const SizedBox(height: 2),
            Text(names.take(5).join(', ') + (names.length > 5 ? ' …' : ''),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: _body(context, size: 10.5)),
          ]),
        ),
      ]),
    );
  }

  final ids = reps.keys.toList();
  final half = (ids.length / 2).ceil();
  return Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.all(14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [for (final g in ids.take(half)) cell(g)]),
      const SizedBox(width: 16),
      Column(children: [for (final g in ids.skip(half)) cell(g)]),
    ]),
  );
}

/// The three blocks of each direction, side by side at 164 dp and at 190 dp (412 phones).
Widget blocksSheet(BuildContext context, {double w = 164}) {
  final p = party();
  final foe = mixed();
  Widget col(String dir) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            switch (dir) {
              'a' => 'A · Plate',
              'b' => 'B · Banner edge',
              _ => 'C · Nameplate and gems'
            },
            style: _sys(context, size: 11, color: _apGold)),
        const SizedBox(height: 6),
        block(dir, p[0], w: w),
        const SizedBox(height: 6),
        block(dir, p[1], w: w),
        const SizedBox(height: 6),
        block(dir, foe[0], w: w),
        const SizedBox(height: 6),
        block(dir, foe[2], w: w),
        const SizedBox(height: 6),
        block(dir, bossFight()[0], w: w),
      ]);
  return Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.all(14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      col('a'),
      const SizedBox(width: 14),
      col('b'),
      const SizedBox(width: 14),
      col('c'),
    ]),
  );
}

// ------------------------------------------------------------------ test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('fight blocks', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    _enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    _factions =
        jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    final scheme = AppPalette.stitchedInk.schemeFor(Brightness.dark);
    FightSpriteImages.reset();

    Future<void> shot(String name, Widget Function(BuildContext) build,
        {required Size size, double ratio = 2, String? title}) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Builder(
              builder: (c) => title != null
                  ? Phone(title: title, child: build(c))
                  : Scaffold(
                      body: Align(
                          alignment: Alignment.topLeft, child: build(c)))),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: ratio);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    final dir = Platform.environment['UX_DIR'] ?? 'a';
    if (Platform.environment['UX_GROUPS'] == '1') {
      await shot('groups-$dir', (c) => groupSheet(c, dir),
          size: const Size(780, 760));
      return;
    }
    await shot('blocks', blocksSheet,
        size: const Size(3 * 164 + 2 * 14 + 28, 5 * 84 + 60));
    await shot('blocks-320', (c) => blocksSheet(c, w: 144),
        size: const Size(3 * 144 + 2 * 14 + 28, 5 * 84 + 60));
    for (final d in ['a', 'b', 'c']) {
      await shot(
          'screen-$d-mixed',
          (c) => fightScreen(c, d, mixed(),
              title: 'Fight: Open road', grouped: d != 'a'),
          size: const Size(360, 780),
          title: 'Fight: Open road');
      await shot(
          'screen-$d-boss',
          (c) => fightScreen(c, d, bossFight(),
              title: 'Fight: Inquisitor-General Aurel Vane', grouped: d != 'a'),
          size: const Size(360, 780),
          title: 'Fight: Aurel Vane');
    }
  });
}
