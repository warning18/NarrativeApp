// Other designs for the clan offer card (UX_SHOTS=<folder>): the same content
// (banner, gift icon, name, kind and rarity tags, effect, the clan's words, the
// clan's name, +6), the same five rarity frames (Art's PixelLab tiers, assets/
// visuals/cards/) and the same fanned hand, with a different composition:
//   A full-art  B tarot  C seal  D compact
// and today's v1.975 card (the real ClanCardView) for comparison. Real data:
// skills.json, factions.json, the clans' banners, the harmonised icons. Mock
// only: nothing here is used by the app.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

const _night = Color(0xFF10141F);
const _navy = Color(0xFF172038);
const _gold = Color(0xFFE8C170);
const _core = Color(0xFFF2C14E);

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

Color _rarityColor(String r) => switch (r) {
      'uncommon' => const Color(0xFF75A743),
      'rare' => const Color(0xFF4F8FBA),
      'epic' => const Color(0xFFA23E8C),
      'legendary' => const Color(0xFFDE9E41),
      _ => const Color(0xFF819796),
    };

CardTier _tierOf(String r) => CardTier.values
    .firstWhere((t) => t.name == r, orElse: () => CardTier.common);

late Map<String, dynamic> _skills;
late Map<String, dynamic> _factions;

/// One real gift: a skill of skills.json offered by a clan of factions.json.
class Gift {
  Gift(this.clanId, this.skillId)
      : rec = _skills[skillId] as Map<String, dynamic>,
        clan = _factions[clanId] as Map<String, dynamic>;
  final String clanId, skillId;
  final Map<String, dynamic> rec;
  final Map<String, dynamic> clan;

  String get name => skillDisplayName(skillId);
  String get element => rec['element']?.toString() ?? 'None';
  String get rarity => rec['rarity']?.toString() ?? 'common';
  CardTier get tier => _tierOf(rarity);
  String get desc =>
      (rec['description']?.toString() ?? '').replaceAll('{mana}', 'mana');
  Color get color =>
      Color(int.parse((clan['color'] as String).substring(1), radix: 16) |
          0xFF000000);
  String get clanName => clan['name'] as String;
  String get clanShort => clan['short'] as String;
  String get greeting => (clan['greetings'] as List).first as String;
  String get banner => clanBannerId(clanId)!;

  String get effect {
    final s = applySkillTier(rec, 0);
    final dmg = (s['damageMod'] as num?)?.toInt() ?? 0;
    final mul = (s['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
    final heal = (s['healAmount'] as num?)?.toInt() ?? 0;
    return [
      if (dmg > 0) '+$dmg damage',
      if (mul > 1.0) '×${mul.toStringAsFixed(1)}',
      if (heal > 0) 'heals $heal',
    ].join(' · ');
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, this.color, {super.key, this.fill = false});
  final String label;
  final Color color;
  final bool fill;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: ShapeDecoration(
          color: fill
              ? color.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.14),
          shape: PixelChipBorder(
              side: BorderSide(color: color.withValues(alpha: 0.9), width: 1),
              step: 1.5,
              steps: 2),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 10,
                height: 1.1,
                color: fill ? Palette.apolloOutline : color)),
      );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

List<Widget> _tags(Gift g) => [
      const Tag('Skill', Color(0xFF819796)),
      if (g.element != 'None') Tag(g.element, _element(g.element)),
      Tag(_cap(g.rarity), _rarityColor(g.rarity)),
    ];

TextStyle _name(double size, Color color) => TextStyle(
    fontFamily: InkFonts.display, fontSize: size, height: 1.05, color: color);
TextStyle _sys(double size, Color color) => TextStyle(
    fontFamily: InkFonts.system, fontSize: size, height: 1.2, color: color);
TextStyle _prose(double size, Color color, {bool italic = false}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: size,
    height: 1.25,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color);

// --------------------------------------------------------------- pieces ---
Widget _img(String path, double w, double h) => Image.asset(path,
    width: w, height: h, fit: BoxFit.fill, filterQuality: FilterQuality.none);

Widget _frame(CardTier t) => Positioned(
    left: 1,
    top: 1,
    child: _img('assets/visuals/cards/frame_${t.name}.png', 208, 344));

Widget _plate(CardTier t, double size) =>
    _img('assets/visuals/cards/plate_${t.name}.png', size, size);

Widget _backdrop(CardTier t, double w, double h) =>
    _img('assets/visuals/cards/backdrop_${t.name}.png', w, h);

Widget _flag(Gift g, double h) => SizedBox(
    height: h,
    child: FittedBox(
        fit: BoxFit.contain, child: PixelBanner(id: g.banner, scale: 1)));

/// The clan's sign alone: the banner cropped to its emblem.
Widget _emblem(Gift g, double size) => SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.05),
          child: SizedBox(
              width: pixelBannerSize.width,
              height: pixelBannerSize.height,
              child: PixelBanner(id: g.banner, scale: 1)),
        ),
      ),
    );

Widget _icon(Gift g, double size) => SkillPixelIcon(g.skillId, size: size);

/// The card's shell: 210 x 346, the glow, the navy body, the content, the tier's
/// frame over it all.
Widget _shell(Gift g, bool lit, List<Widget> children, {Color? body}) =>
    SizedBox(
      width: 210,
      height: 346,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color:
                  (lit ? _core : g.color).withValues(alpha: lit ? 0.6 : 0.22),
              blurRadius: lit ? 18 : 8),
        ]),
        child: Stack(children: [
          Positioned(
              left: 1,
              top: 1,
              right: 1,
              bottom: 1,
              child: ColoredBox(color: body ?? _navy)),
          ...children,
          _frame(g.tier),
        ]),
      ),
    );

Widget _standing(Gift g, {double size = 12, bool short = false}) =>
    Text(short ? '+6' : '+6 ${g.clanShort}', style: _sys(size, _core));

// ------------------------------------------------ today: v1.975 (real) ---
Widget todayCard(Gift g, {bool lit = false, bool touched = false}) =>
    ClanCardView(
      tier: g.tier,
      color: g.color,
      flag: clanCardFlag(g.banner, plain: const SizedBox()),
      icon: _icon(g, 48),
      name: g.name,
      tags: [
        const Tag('Skill', Color(0xFF819796)),
        Tag(_cap(g.rarity), _rarityColor(g.rarity)),
      ],
      greeting: g.greeting,
      clanName: g.clanName,
      standing: '+6 ${g.clanShort}',
      lit: lit,
    );

// ------------------------------------------------------- A: full-art ---
/// The art fills the card; the text sits on a dark band at the foot.
Widget fullArtCard(Gift g, {bool lit = false, bool touched = false}) {
  final tint = g.color;
  return _shell(g, lit, [
    // The whole face is picture: the tier's backdrop, then the clan's colour
    // fading into the night.
    Positioned(left: 1, top: 1, child: _backdrop(g.tier, 208, 152)),
    Positioned.fill(
      left: 1,
      top: 1,
      right: 1,
      bottom: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tint.withValues(alpha: 0.28),
              tint.withValues(alpha: 0.12),
              _night.withValues(alpha: 0.0),
            ],
            stops: const [0, 0.35, 0.6],
          ),
        ),
      ),
    ),
    // The banner hangs big at the left, the gift stands large on its plate.
    Positioned(left: 16, top: 12, child: _flag(g, 196)),
    Positioned(
        right: 12,
        top: 46,
        child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(alignment: Alignment.center, children: [
              _plate(g.tier, 120),
              _icon(g, 80),
            ]))),
    Positioned(
      right: 18,
      top: 16,
      child: Tag('SKILL', g.color, fill: true),
    ),
    // The dark band at the foot.
    Positioned(
      left: 1,
      right: 1,
      bottom: 1,
      height: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _night.withValues(alpha: 0.0),
              _night.withValues(alpha: 0.92),
              Palette.apolloOutline,
            ],
            stops: const [0, 0.28, 1],
          ),
        ),
      ),
    ),
    Positioned(
      left: 18,
      right: 18,
      bottom: 16,
      height: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(g.name, style: _name(24, Palette.apolloCream))),
          const SizedBox(height: 3),
          Text(g.effect, style: _sys(12, _gold)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(children: [
              for (final t in _tags(g).skip(1)) ...[
                t,
                const SizedBox(width: 4)
              ],
            ]),
          ),
          const Spacer(),
          Text('“${g.greeting}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _prose(11, Palette.apolloCream, italic: true)),
          const SizedBox(height: 5),
          Row(children: [
            Container(width: 8, height: 8, color: g.color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(g.clanName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sys(
                      9.5, Color.lerp(g.color, Palette.apolloCream, 0.5)!)),
            ),
            _standing(g, size: 12, short: true),
          ]),
        ],
      ),
    ),
  ]);
}

// ----------------------------------------------------------- B: tarot ---
class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper();
  @override
  Path getClip(Size s) {
    final r = s.width / 2;
    return Path()
      ..moveTo(0, s.height)
      ..lineTo(0, r)
      ..arcToPoint(Offset(s.width, r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(s.width, s.height)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

class _ArchLine extends CustomPainter {
  _ArchLine(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final p = Path()
      ..moveTo(1.5, s.height)
      ..lineTo(1.5, r)
      ..arcToPoint(Offset(s.width - 1.5, r),
          radius: Radius.circular(r - 1.5), clockwise: true)
      ..lineTo(s.width - 1.5, s.height);
    c.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Ribbon extends CustomPainter {
  _Ribbon(this.color, this.dark);
  final Color color;
  final Color dark;
  @override
  void paint(Canvas c, Size s) {
    final fork = 9.0;
    final body = Path()
      ..moveTo(fork, 3)
      ..lineTo(s.width - fork, 3)
      ..lineTo(s.width - fork, s.height - 3)
      ..lineTo(fork, s.height - 3)
      ..close();
    final lp = Path()
      ..moveTo(0, 8)
      ..lineTo(fork + 2, 8)
      ..lineTo(fork + 2, s.height)
      ..lineTo(0, s.height)
      ..lineTo(7, s.height - (s.height - 8) / 2)
      ..close();
    final rp = Path()
      ..moveTo(s.width, 8)
      ..lineTo(s.width - fork - 2, 8)
      ..lineTo(s.width - fork - 2, s.height)
      ..lineTo(s.width, s.height)
      ..lineTo(s.width - 7, s.height - (s.height - 8) / 2)
      ..close();
    final tails = Paint()
      ..color = dark
      ..isAntiAlias = false;
    c.drawPath(lp, tails);
    c.drawPath(rp, tails);
    c.drawPath(
        body,
        Paint()
          ..color = color
          ..isAntiAlias = false);
    c.drawRect(Rect.fromLTWH(fork, 3, s.width - 2 * fork, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// The clan's banner is a header across the top, the gift stands large in an
/// arch in the middle, the name is on a scroll at the foot.
Widget tarotCard(Gift g, {bool lit = false, bool touched = false}) {
  return _shell(g, lit, [
    // Header: the clan's colour, its sign at both ends, its name between.
    Positioned(
      left: 12,
      right: 12,
      top: 12,
      height: 34,
      child: Container(
        color: g.color,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          _emblem(g, 26),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(g.clanName.toUpperCase(),
                    maxLines: 1, style: _sys(10, Palette.apolloOutline)),
              ),
            ),
          ),
          _emblem(g, 26),
        ]),
      ),
    ),
    // The arch window: the tier's backdrop under the clan's tint, the gift.
    Positioned(
      left: 38,
      right: 38,
      top: 54,
      height: 150,
      child: Stack(children: [
        ClipPath(
          clipper: const _ArchClipper(),
          child: Stack(fit: StackFit.expand, children: [
            _backdrop(g.tier, 134, 152),
            ColoredBox(color: g.color.withValues(alpha: 0.2)),
          ]),
        ),
        Center(
            child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(alignment: Alignment.center, children: [
                  _plate(g.tier, 100),
                  _icon(g, 72),
                ]))),
        Positioned.fill(
            child: CustomPaint(
                painter: _ArchLine(
                    Color.lerp(g.color, Palette.apolloCream, 0.25)!))),
      ]),
    ),
    // The scroll with the name.
    Positioned(
      left: 14,
      right: 14,
      top: 192,
      height: 38,
      child: CustomPaint(
        painter: _Ribbon(Color.lerp(g.color, Palette.apolloCream, 0.18)!,
            Color.lerp(g.color, Palette.apolloOutline, 0.45)!),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(g.name, style: _name(20, Palette.apolloOutline))),
          ),
        ),
      ),
    ),
    Positioned(
      left: 18,
      right: 18,
      top: 238,
      bottom: 16,
      child: Column(children: [
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(children: [
              for (var i = 0; i < _tags(g).length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                _tags(g)[i],
              ],
            ])),
        const SizedBox(height: 5),
        Text(g.effect, style: _sys(12, _gold)),
        const SizedBox(height: 4),
        Text('“${g.greeting}”',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _prose(11, Palette.apolloCream, italic: true)),
        const Spacer(),
        _standing(g, size: 11),
      ]),
    ),
  ]);
}

// ------------------------------------------------------------ C: seal ---
class _SealPainter extends CustomPainter {
  _SealPainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    // A wax seal in pixels: an uneven disc, a lighter rim, a drip at the foot.
    const cell = 3.0;
    final n = (s.width / cell).floor();
    final mid = (n - 1) / 2;
    final dark = Color.lerp(color, Palette.apolloOutline, 0.35)!;
    final light = Color.lerp(color, Palette.apolloCream, 0.3)!;
    final fill = Paint()..isAntiAlias = false;
    for (var y = 0; y < n + 3; y++) {
      for (var x = 0; x < n; x++) {
        final dx = x - mid, dy = y - mid;
        final a = math.atan2(dy, dx);
        final r = mid - 0.5 + math.sin(a * 5) * 0.9 + math.cos(a * 3) * 0.6;
        final d = math.sqrt(dx * dx + dy * dy);
        var paintIt = d <= r;
        // a drip below
        if (!paintIt && y > mid && (x - mid).abs() < 1.2 && y < n + 2) {
          paintIt = d <= mid + 2.4;
        }
        if (!paintIt) continue;
        fill.color = d > r - 1.2 ? light : (d > r - 2.6 ? dark : color);
        c.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), fill);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget _seal(Gift g, double size) => SizedBox(
      width: size,
      height: size + 9,
      child: Stack(alignment: Alignment.topCenter, children: [
        CustomPaint(size: Size(size, size), painter: _SealPainter(g.color)),
        Positioned(
          top: size * 0.2,
          child: Opacity(
              opacity: 0.85,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Palette.apolloOutline.withValues(alpha: 0.55),
                    BlendMode.srcATop),
                child: _emblem(g, size * 0.6),
              )),
        ),
      ]),
    );

/// A letter offered by the clan: the gift on top, the clan's words in a larger
/// hand, and the clan's wax seal on the face.
Widget sealCard(Gift g, {bool lit = false, bool touched = false}) {
  return _shell(g, lit, [
    Positioned(
        left: 1,
        top: 1,
        child: Opacity(opacity: 0.8, child: _backdrop(g.tier, 208, 152))),
    Positioned.fill(
      left: 1,
      top: 1,
      right: 1,
      bottom: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              g.color.withValues(alpha: 0.24),
              _night.withValues(alpha: 0),
            ],
            stops: const [0, 0.5],
          ),
        ),
      ),
    ),
    Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
            child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(alignment: Alignment.center, children: [
                  _plate(g.tier, 100),
                  _icon(g, 72),
                ])))),
    Positioned(
        left: 16,
        right: 16,
        top: 126,
        child: Column(children: [
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(g.name, style: _name(23, Palette.apolloCream))),
          const SizedBox(height: 4),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(children: [
                for (var i = 0; i < _tags(g).length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _tags(g)[i],
                ],
              ])),
          const SizedBox(height: 4),
          Text(g.effect, style: _sys(12, _gold)),
        ])),
    // The letter: a rule, the clan's words, a signature.
    Positioned(
      left: 20,
      right: 20,
      top: 214,
      child: Container(height: 1, color: g.color.withValues(alpha: 0.6)),
    ),
    Positioned(
      left: 20,
      right: 86,
      top: 222,
      bottom: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“${g.greeting}”',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: _prose(12.5, Palette.apolloCream, italic: true)),
          const Spacer(),
          Text('— ${g.clanName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _sys(9.5, Color.lerp(g.color, Palette.apolloCream, 0.5)!)),
        ],
      ),
    ),
    Positioned(right: 14, bottom: 22, child: _seal(g, 69)),
    Positioned(
      right: 14,
      bottom: 12,
      width: 69,
      child: Center(child: _standing(g, size: 11, short: true)),
    ),
  ]);
}

// ---------------------------------------------------------- D: compact ---
/// Fewer lines, larger type: the gift, its name, one tag row. The effect and
/// the clan's words come up over the card only when it is touched.
Widget compactCard(Gift g, {bool lit = false, bool touched = false}) {
  final on = touched || lit;
  return _shell(g, lit, [
    Positioned(left: 1, top: 1, child: _backdrop(g.tier, 208, 152)),
    Positioned.fill(
      left: 1,
      top: 1,
      right: 1,
      bottom: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              g.color.withValues(alpha: 0.3),
              _night.withValues(alpha: 0)
            ],
            stops: const [0, 0.55],
          ),
        ),
      ),
    ),
    // The clan: a short banner at the corner and nothing else of it.
    Positioned(left: 16, top: 12, child: _flag(g, 80)),
    Positioned(
        top: 34,
        right: 16,
        child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(alignment: Alignment.center, children: [
              _plate(g.tier, 120),
              _icon(g, 88),
            ]))),
    Positioned(
      left: 14,
      right: 14,
      top: 172,
      child: Column(children: [
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(g.name, style: _name(30, Palette.apolloCream))),
        const SizedBox(height: 8),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(children: [
              const Tag('Skill', Color(0xFF819796)),
              const SizedBox(width: 4),
              Tag(_cap(g.rarity), _rarityColor(g.rarity)),
            ])),
      ]),
    ),
    Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Row(children: [
        Expanded(
          child: Text(g.clanShort.toUpperCase(),
              style: _sys(10, Color.lerp(g.color, Palette.apolloCream, 0.5)!)),
        ),
        _standing(g, size: 13),
      ]),
    ),
    // Touched: the effect and the clan's words rise over the foot.
    if (on)
      Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        height: 168,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: ShapeDecoration(
            color: Palette.apolloOutline.withValues(alpha: 0.94),
            shape: PixelChipBorder(
                side: BorderSide(color: g.color, width: 2), step: 3, steps: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.name, style: _name(18, Palette.apolloCream)),
              const SizedBox(height: 3),
              Text(g.effect, style: _sys(14, _gold)),
              const SizedBox(height: 6),
              Text('“${g.greeting}”',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _prose(13, Palette.apolloCream, italic: true)),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: Text(g.clanName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _sys(
                          9.5, Color.lerp(g.color, Palette.apolloCream, 0.5)!)),
                ),
                _standing(g, size: 13),
              ]),
            ],
          ),
        ),
      ),
  ]);
}

// ------------------------------------------------------------- layouts ---
typedef CardBuilder = Widget Function(Gift g, {bool lit, bool touched});

const _variants = <(String, String, CardBuilder)>[
  ('today', 'v1.975 today', todayCard),
  ('a-fullart', 'A  Full-art', fullArtCard),
  ('b-tarot', 'B  Tarot', tarotCard),
  ('c-seal', 'C  Seal', sealCard),
  ('d-compact', 'D  Compact', compactCard),
];

/// The fan of the hand: the middle card lit (touched).
Widget hand(List<Gift> gifts, CardBuilder card, {int lit = 1}) {
  const rest = 0.66, up = 0.84;
  const w = 332.0;
  final n = gifts.length;
  const restW = 210 * rest;
  final step = (w - restW) / (n - 1);
  final left0 = (w - (restW + step * (n - 1))) / 2;
  Widget one(int i) {
    final isUp = lit == i;
    final k = isUp ? up : rest;
    final angle = (i - (n - 1) / 2) * 0.11 * (isUp ? 0.25 : 1);
    return Positioned(
      left: (left0 + step * i - (isUp ? 18.5 : 0)).clamp(0.0, w - 210 * up),
      bottom: isUp ? 24 : 0,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 210 * k,
          height: 346 * k,
          child: FittedBox(child: card(gifts[i], lit: isUp, touched: isUp)),
        ),
      ),
    );
  }

  final order = [
    for (var i = 0; i < n; i++)
      if (i != lit) i,
    lit,
  ];
  return SizedBox(
    width: w,
    height: 346 * up + 40,
    child: Stack(
        clipBehavior: Clip.none, children: [for (final i in order) one(i)]),
  );
}

Widget handScreen(
    BuildContext context, List<Gift> gifts, CardBuilder card, String title) {
  final theme = Theme.of(context);
  final g = gifts[1];
  return Scaffold(
    appBar: AppBar(title: const Text('The clans come to you')),
    body: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      children: [
        Text(title, style: _sys(11, theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        hand(gifts, card),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: g.color),
            onPressed: () {},
            child: Text('Take ${g.name} from ${g.clanName}',
                textAlign: TextAlign.center, maxLines: 2),
          ),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- the test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('card variants', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    _skills = jsonDecode(File('assets/gamedata/skills.json').readAsStringSync())
        as Map<String, dynamic>;
    _factions =
        jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    final scheme = AppPalette.stitchedInk.schemeFor(Brightness.dark);
    // One common, one rare and one legendary skill, from three clans.
    final gifts = [
      Gift('compact', 'heavy_attack'),
      Gift('dominion', 'fireball'),
      Gift('penitents', 'cleric_second_dawn'),
    ];

    Future<void> shot(String name, Size size, Widget Function(BuildContext) b,
        {double ratio = 2}) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Material(color: Colors.transparent, child: Builder(builder: b)),
        ),
      ));
      for (var i = 0; i < 4; i++) {
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

    Widget row(CardBuilder card, {bool touched = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in gifts)
              Padding(
                padding: const EdgeInsets.all(10),
                child: card(g, touched: touched),
              ),
          ],
        );

    for (final (id, title, card) in _variants) {
      // The three gifts at real size (1 dp = 1 px) and at 2x.
      for (final (suffix, ratio) in [('1x', 1.0), ('2x', 2.0)]) {
        await shot('cards-$id-$suffix', const Size(700, 386), (c) {
          return ColoredBox(
              color: Theme.of(c).colorScheme.surface,
              child: Center(child: row(card)));
        }, ratio: ratio);
      }
      // The hand as it sits on the level-up screen (the middle card touched).
      await shot('hand-$id', const Size(360, 700),
          (c) => handScreen(c, gifts, card, title));
    }
    // Compact again, with the three cards touched.
    await shot('cards-d-compact-touched-2x', const Size(700, 386), (c) {
      return ColoredBox(
          color: Theme.of(c).colorScheme.surface,
          child: Center(child: row(compactCard, touched: true)));
    });
    // All the designs, one row each, for comparison.
    await shot('compare', const Size(700, 1980), (c) {
      return ColoredBox(
        color: Theme.of(c).colorScheme.surface,
        child: Column(children: [
          for (final (_, title, card) in _variants)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(children: [
                  SizedBox(
                      width: 88,
                      child: Text(title,
                          style: _sys(
                              11, Theme.of(c).colorScheme.onSurfaceVariant))),
                  for (final g in gifts)
                    Expanded(
                        child: FittedBox(
                            child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: card(g)))),
                ]),
              ),
            ),
        ]),
      );
    }, ratio: 1);
  });
}
