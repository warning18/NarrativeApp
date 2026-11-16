// The clan's offer: the card hand for new things, the list for levels, and a split offer
// for a mixed one (UX_SHOTS=<folder>). Real clans, skills, perk and item; the base card as
// drawn. A mock: nothing here is used by the app. Previously: three directions (a|b|c):
// exactly three suitors from three clans, each with one gift: a new skill, or the
// ascension (the next level) of a skill the character knows. Real data: the clans of
// factions.json (name, colour, banner, what they say), the Mage's skills of skills.json,
// the game's theme and fonts, the harmonised icons, the Apollo palette. Mock only:
// nothing here is used by the app. Drawn only with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
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

// ------------------------------------------------------------------ data ---
enum St { known, ready, locked }

class Sk {
  Sk(this.id, this.rec, this.st, {this.tier = 0}) : name = skillDisplayName(id);
  final String id;
  final String name;
  final Map<String, dynamic> rec;
  final St st;
  final int tier;
  String get element => rec['element']?.toString() ?? 'None';
  String get rarity => rec['rarity']?.toString() ?? 'common';
  int get cost => (rec['cost'] as num?)?.toInt() ?? 0;
  String get desc =>
      (rec['description']?.toString() ?? '').replaceAll('{mana}', 'mana');

  String effect([int? t]) {
    final s = applySkillTier(rec, t ?? tier);
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

late Map<String, dynamic> _skills;
late Map<String, dynamic> _factions;

Sk sk(String id, St st, {int tier = 0}) =>
    Sk(id, _skills[id] as Map<String, dynamic>, st, tier: tier);

class Clan {
  Clan(this.id, Map<String, dynamic> f)
      : name = f['name'] as String,
        short = f['short'] as String,
        greeting = (f['greetings'] as List).first as String,
        motto = f['motto'] as String,
        color = Color(int.parse((f['color'] as String).substring(1), radix: 16) |
            0xFF000000);
  final String id, name, short, greeting, motto;
  final Color color;
  String get banner => clanBannerId(id)!;
}

enum Kind { skill, ascension }

class Gift {
  Gift(this.clan, this.skill, this.kind, {this.raises});
  final Clan clan;
  final Sk skill;
  final Kind kind;
  final Sk? raises; // an ascension: the skill it raises
}

/// A Mage at level 7: the Dominion sponsors Evocation, the Crows Tempest, the
/// Penitents Aegis (their `sponsors` in factions.json); an ascension is offered by
/// the clan behind the skill it raises (offers.dart).
List<Gift> _offer() => [
      Gift(Clan('dominion', _factions['dominion'] as Map<String, dynamic>),
          sk('fireball', St.ready), Kind.skill),
      Gift(Clan('crows', _factions['crows'] as Map<String, dynamic>),
          sk('mage_frost_nova', St.ready), Kind.skill),
      Gift(Clan('penitents', _factions['penitents'] as Map<String, dynamic>),
          sk('mage_mending_tide', St.ready), Kind.ascension,
          raises: sk('mending_touch', St.known)),
    ];

String _kindLabel(Kind k) => k == Kind.skill ? 'NEW SKILL' : 'ASCENSION';

Widget bannerOf(Clan c, {double h = 112, bool dim = false}) => Opacity(
      opacity: dim ? 0.5 : 1,
      child: SizedBox(
        height: h,
        child: FittedBox(
            fit: BoxFit.contain, child: PixelBanner(id: c.banner, scale: 1)),
      ),
    );

Color _tint(Clan c, double t) => Color.lerp(_apNight, c.color, t)!;
// ----------------------------------------------------------- shared bits ---
class Plate extends StatelessWidget {
  const Plate(this.s, {super.key, this.size = 56, this.dim = false});
  final Sk s;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tint = _element(s.element);
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          shape: PixelChipBorder(
              side: const BorderSide(color: _apOutline, width: 1.5),
              step: size > 70 ? 3 : 2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_apNavy, tint, 0.38)!,
              Color.lerp(_apNight, tint, 0.14)!,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: SkillPixelIcon(s.id, size: size * 0.72),
      ),
    );
  }
}

class Pips extends StatelessWidget {
  const Pips(this.tier, {super.key, this.size = 6, this.show = true});
  final int tier;
  final double size;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < maxSkillTier; i++)
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: i < tier ? _apCore : Colors.transparent,
            border: Border.all(
                color: i < tier ? _apGold : const Color(0xFF577277), width: 1),
          ),
        ),
    ]);
  }
}

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



// ============================================================ new model ===
class Cl {
  Cl(this.id, this.name, this.short, this.greeting, this.color, {this.banner});
  factory Cl.faction(String id) {
    final f = _factions[id] as Map<String, dynamic>;
    return Cl(
        id,
        f['name'] as String,
        f['short'] as String,
        (f['greetings'] as List).first as String,
        Color(int.parse((f['color'] as String).substring(1), radix: 16) | 0xFF000000),
        banner: clanBannerId(id));
  }
  factory Cl.wayfarer() => Cl('wayfarer', 'The Wayfarer', 'Wayfarer',
      'No banner, no price. Take what helps.', const Color(0xFF8D6E63));
  final String id, name, short, greeting;
  final Color color;
  final String? banner;
  String get the => name.startsWith('The ') ? 'the ${name.substring(4)}' : name;
}

enum GK { skill, ascension, rank, object }

class Gf {
  Gf(this.clan, this.kind,
      {required this.name,
      required this.effect,
      required this.desc,
      required this.icon,
      required this.tint,
      required this.tags,
      this.raises,
      this.before,
      this.after});
  final Cl clan;
  final GK kind;
  final String name, effect, desc;
  final Widget Function(double) icon;
  final Color tint;
  final List<Widget> tags;
  final String? raises; // what it raises (ascension, rank)
  final String? before, after; // the numbers before and after, for a level

  bool get isLevel => kind == GK.ascension || kind == GK.rank;
  String get label => switch (kind) {
        GK.skill => 'NEW SKILL',
        GK.ascension => 'ASCENSION',
        GK.rank => 'RANK UP',
        GK.object => 'OBJECT',
      };

  static List<Widget> _skillTags(Sk s) => [
        if (s.element != 'None') Tag(s.element, _element(s.element), dot: true),
        Tag(_cap(s.rarity), _rarity(s.rarity)),
      ];

  factory Gf.skill(Cl clan, String id) {
    final s = sk(id, St.ready);
    return Gf(clan, GK.skill,
        name: s.name,
        effect: s.effect(),
        desc: s.desc,
        icon: (z) => SkillPixelIcon(id, size: z),
        tint: _element(s.element),
        tags: _skillTags(s));
  }

  factory Gf.ascension(Cl clan, String id, String raisesId) {
    final s = sk(id, St.ready);
    final r = sk(raisesId, St.known);
    return Gf(clan, GK.ascension,
        name: s.name,
        effect: s.effect(),
        desc: s.desc,
        icon: (z) => SkillPixelIcon(id, size: z),
        tint: _element(s.element),
        tags: _skillTags(s),
        raises: r.name,
        before: '${r.name}: ${r.effect(1)}',
        after: '${s.name}: ${s.effect()}');
  }

  factory Gf.rank(Cl clan) => Gf(clan, GK.rank,
      name: 'Iron Hide II',
      effect: '+10% to block a blow',
      desc: 'A blocked blow loses half.',
      icon: (z) => Icon(Icons.security, size: z * 0.7, color: _apCream),
      tint: const Color(0xFF8D6E63),
      tags: const [Tag('Perk', Color(0xFF819796)), Tag('Rank 2 of 3', Color(0xFFE8C170))],
      raises: 'Iron Hide',
      before: 'Iron Hide I: +10% to block',
      after: 'Iron Hide II: +20% to block');

  factory Gf.object(Cl clan) => Gf(clan, GK.object,
      name: 'Iron Cap',
      effect: '+1 armour · earth resist 1',
      desc: 'A smith’s plain cap, offered, not sold.',
      icon: (z) => ItemPixelIcon('helm_iron_cap', 'Armor', size: z),
      tint: const Color(0xFFAD7757),
      tags: [const Tag('Head', Color(0xFF819796)), Tag('Uncommon', _rarity('uncommon'))]);
}

Widget bannerFor(Cl c, {double h = 100}) => SizedBox(
    height: h,
    child: c.banner != null
        ? FittedBox(fit: BoxFit.contain, child: PixelBanner(id: c.banner!, scale: 1))
        : AspectRatio(aspectRatio: 0.5, child: CustomPaint(painter: _PennantPainter(c.color))));

class _PennantPainter extends CustomPainter {
  _PennantPainter(this.c);
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    final pole = Paint()..color = const Color(0xFFD7B594);
    cv.drawRect(Rect.fromLTWH(s.width * 0.2, 0, 3, s.height), pole);
    final flag = Path()
      ..moveTo(s.width * 0.2 + 3, s.height * 0.08)
      ..lineTo(s.width * 0.95, s.height * 0.22)
      ..lineTo(s.width * 0.2 + 3, s.height * 0.36)
      ..close();
    cv.drawPath(flag, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_) => false;
}

class GiftPlate extends StatelessWidget {
  const GiftPlate(this.g, {super.key, this.size = 56, this.dim = false});
  final Gf g;
  final double size;
  final bool dim;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dim ? 0.45 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shape: PixelChipBorder(
                side: const BorderSide(color: _apOutline, width: 1.5), step: size > 70 ? 3 : 2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(_apNavy, g.tint, 0.38)!, Color.lerp(_apNight, g.tint, 0.14)!],
            ),
          ),
          alignment: Alignment.center,
          child: g.icon(size * 0.72),
        ),
      );
}

Color _clanLight(Cl c) => Color.lerp(c.color, _apCream, 0.45)!;
Color _tintCl(Cl c, double t) => Color.lerp(_apNight, c.color, t)!;

// ================================================================= offers ===
Cl _c(String id) => Cl.faction(id);

/// New skills from three clans (a Mage at level 7).
List<Gf> skillOffer() => [
      Gf.skill(_c('dominion'), 'fireball'),
      Gf.skill(_c('crows'), 'mage_frost_nova'),
      Gf.skill(_c('penitents'), 'mage_mana_shield'),
    ];

/// Levels: two ascensions (the most a class has) and a perk rank from the Wayfarer.
List<Gf> levelOffer() => [
      Gf.ascension(_c('dominion'), 'mage_pyre_heart', 'inner_fire'),
      Gf.ascension(_c('penitents'), 'mage_mending_tide', 'mending_touch'),
      Gf.rank(Cl.wayfarer()),
    ];

// ================================================================= the card ===
const double kCardW = 210, kCardH = 346;

Widget tagsRow(Gf g) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < g.tags.length; i++) ...[if (i > 0) const SizedBox(width: 4), g.tags[i]],
    ]));

/// The base card, as drawn and approved: one template for every clan and gift.
class ClanCard2 extends StatelessWidget {
  const ClanCard2(this.g, {super.key, this.lit = false});
  final Gf g;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final c = g.clan;
    return Container(
      width: kCardW,
      height: kCardH,
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(color: lit ? _apCore : c.color, width: 3), step: 4, steps: 3),
        shadows: [
          BoxShadow(
              color: (lit ? _apCore : c.color).withValues(alpha: lit ? 0.55 : 0.25),
              blurRadius: lit ? 16 : 8),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: c.color.withValues(alpha: 0.35))),
        child: Column(children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_tintCl(c, 0.6), _tintCl(c, 0.14)])),
            child: Stack(children: [
              Positioned(left: 16, top: 6, child: bannerFor(c, h: 138)),
              Positioned(right: 14, bottom: 14, child: GiftPlate(g, size: 86)),
              Positioned(right: 6, top: 6, child: Tag(g.label, c.color, fill: true)),
            ]),
          ),
          Container(
            height: 32,
            width: double.infinity,
            color: c.color,
            alignment: Alignment.center,
            child: Text(g.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: InkFonts.display, fontSize: 19, height: 1, color: _apOutline)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(children: [
                Text(g.effect,
                    textAlign: TextAlign.center,
                    style: _sys(context, size: 12.5, color: _apCream)),
                if (g.raises != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Raises ${g.raises}',
                        textAlign: TextAlign.center,
                        style: _sys(context, size: 11, color: _apGold)),
                  ),
                const SizedBox(height: 4),
                Text(g.desc,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 12)),
                const SizedBox(height: 6),
                tagsRow(g),
                const Spacer(),
                Container(height: 1, color: c.color.withValues(alpha: 0.5)),
                const SizedBox(height: 6),
                Text('“${c.greeting}”',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 11.5).copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Text(c.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sys(context, size: 9.5, color: _clanLight(c))),
                  ),
                  Text('+6', style: _sys(context, size: 11, color: _apCore)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ================================================================== the hand ===
/// The fan: [lit] is the touched card (it rises and comes in front), [picked] the
/// taken one (it rises, glows, the others drop and fade).
Widget handOf(List<Gf> gifts, {int lit = -1, int? picked, double height = 330}) {
  const s = 0.66, sl = 0.84;
  final n = gifts.length;
  final step = n == 1 ? 0.0 : (n == 2 ? 104.0 : 96.5);
  final total = 139.0 + step * (n - 1);
  final left0 = (332 - total) / 2;
  Widget card(int i) {
    final isUp = picked != null ? picked == i : lit == i;
    final k = isUp ? sl : s;
    final centre = (n - 1) / 2;
    final angle = (i - centre) * 0.11 * (isUp ? 0.25 : 1);
    final dropped = picked != null && picked != i;
    return Positioned(
      left: (left0 + step * i - (isUp ? 18.5 : 0)).clamp(0.0, 332 - kCardW * sl),
      bottom: isUp ? 24 : (dropped ? -26 : 0),
      child: Opacity(
        opacity: dropped ? 0.28 : 1,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: kCardW * k,
            height: kCardH * k,
            child: FittedBox(child: ClanCard2(gifts[i], lit: isUp)),
          ),
        ),
      ),
    );
  }

  final up = picked ?? lit;
  final order = [for (var i = 0; i < n; i++) if (i != up) i, if (up >= 0 && up < n) up];
  return SizedBox(
    height: height,
    child: Stack(clipBehavior: Clip.none, children: [for (final i in order) card(i)]),
  );
}

String takeLabel(Gf g) => 'Take ${g.name} from ${g.clan.the}';

Widget handScreen(BuildContext context, List<Gf> gifts, {int lit = -1, int? picked}) {
  final ink = InkColors.of(context);
  final g = picked ?? lit;
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context, hint: picked == null ? 'Three clans came' : 'Taken'),
      const SizedBox(height: 10),
      SizedBox(
        height: 44,
        child: Text(
            picked != null
                ? '${gifts[picked].name} is yours. ${gifts[picked].clan.short} +6.'
                : (lit >= 0
                    ? '${gifts[lit].clan.name}: “${gifts[lit].clan.greeting}”'
                    : 'Touch a card to read its clan. One gift each: take one.'),
            style: _body(context, color: picked != null ? _apGold : null)),
      ),
      const SizedBox(height: 4),
      handOf(gifts, lit: lit, picked: picked),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: g >= 0 ? () {} : null,
          child: Text(picked != null ? 'Continue' : (lit >= 0 ? takeLabel(gifts[lit]) : 'Pick a card'),
              textAlign: TextAlign.center)),
    ],
  );
}

// ================================================================== the list ===
class LRow extends StatelessWidget {
  const LRow(this.g, {super.key, this.state = 0, this.open = false});
  final Gf g;
  final int state; // 0 idle, 1 touched, 2 picked, 3 dim
  final bool open;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final picked = state == 2;
    final touched = state == 1;
    final c = g.clan;
    final frame = picked ? _apCore : (touched || open ? c.color : ink.seam);
    final body = Container(
      margin: EdgeInsets.only(left: touched ? 6 : 0),
      decoration: ShapeDecoration(
        color: picked ? Color.lerp(_apNavy, _apCore, 0.12) : _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(color: frame, width: picked || open ? 2.5 : 1.5), step: 2, steps: 2),
        shadows: [
          if (touched || picked) BoxShadow(color: frame.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_tintCl(c, 0.55), _tintCl(c, 0.12)])),
            alignment: Alignment.center,
            child: bannerFor(c, h: open ? 128 : 84),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GiftPlate(g, size: 40),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _name(context, size: 16)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Tag(g.label, picked ? _apCore : c.color, fill: true),
                        const SizedBox(width: 4),
                        if (g.tags.isNotEmpty) g.tags.last,
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(g.raises != null ? 'raises ${g.raises}' : g.effect,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sys(context, size: 11, color: _apGold)),
                const SizedBox(height: 4),
                Text('${c.short.toUpperCase()}  ·  “${c.greeting}”',
                    maxLines: open ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 11)),
                if (open) ...[
                  const SizedBox(height: 8),
                  Container(height: 1, color: c.color.withValues(alpha: 0.5)),
                  const SizedBox(height: 6),
                  Text('NOW', style: _sys(context, size: 9, color: ink.ash)),
                  Text(g.before ?? '', style: _sys(context, size: 11, color: _apCream)),
                  const SizedBox(height: 4),
                  Text('AFTER', style: _sys(context, size: 9, color: ink.ash)),
                  Text(g.after ?? '', style: _sys(context, size: 11, color: _apCore)),
                  const SizedBox(height: 6),
                  Text('Takes ${c.the} up by 6. Its rivals hold it against you.',
                      style: _body(context, size: 11, color: _apGold)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
    return Opacity(opacity: state == 3 ? 0.3 : 1, child: body);
  }
}

Widget listScreen(BuildContext context, List<Gf> gifts, {int touched = -1, int open = -1, int? picked}) {
  final sel = picked ?? open;
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context, hint: picked == null ? 'Three clans came' : 'Taken'),
      const SizedBox(height: 12),
      for (var i = 0; i < gifts.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LRow(gifts[i],
              open: sel == i,
              state: picked != null
                  ? (picked == i ? 2 : 3)
                  : (touched == i ? 1 : 0)),
        ),
      const SizedBox(height: 6),
      FilledButton(
          onPressed: sel >= 0 ? () {} : null,
          child: Text(picked != null
              ? 'Continue'
              : (sel >= 0 ? takeLabel(gifts[sel]) : 'Pick a row'),
              textAlign: TextAlign.center)),
    ],
  );
}

// ============================================================ the mixed offer ===
/// The recommendation: one screen, one pick. What is NEW is a card in the hand (a
/// skill, an object, a title...); what RAISES something the hero already has is a
/// row under the hand (an ascension, a perk rank). Cards 1-3, rows 0-2.
Widget mixedScreen(BuildContext context, List<Gf> cards, List<Gf> rows,
    {int lit = -1, int open = -1, int? picked}) {
  final all = [...cards, ...rows];
  final sel = picked ?? (lit >= 0 ? lit : (open >= 0 ? cards.length + open : -1));
  final cardLit = (picked != null ? (picked < cards.length ? picked : -1) : lit);
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context, hint: picked == null ? 'Three clans came' : 'Taken'),
      const SizedBox(height: 8),
      SizedBox(
        height: 36,
        child: Text(
            sel >= 0 && picked == null
                ? '${all[sel].clan.name}: “${all[sel].clan.greeting}”'
                : (picked != null
                    ? '${all[picked].name} is yours.'
                    : 'New things are cards. What raises one of yours is a row.'),
            maxLines: 2,
            style: _body(context, size: 12)),
      ),
      const SizedBox(height: 16),
      handOf(cards,
          lit: cardLit < 0 && picked == null ? lit : cardLit,
          picked: picked != null && picked < cards.length ? picked : null,
          height: cards.length == 1 && lit < 0 && picked == null ? 250 : 300),
      const SizedBox(height: 4),
      Text('RAISES WHAT YOU HAVE', style: _sys(context, size: 10, color: InkColors.of(context).ash)),
      const SizedBox(height: 4),
      for (var i = 0; i < rows.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: LRow(rows[i],
              open: picked == null && open == i,
              state: picked != null
                  ? (picked == cards.length + i ? 2 : 3)
                  : (open == i ? 1 : 0)),
        ),
      const SizedBox(height: 4),
      FilledButton(
          onPressed: sel >= 0 ? () {} : null,
          child: Text(picked != null ? 'Continue' : (sel >= 0 ? takeLabel(all[sel]) : 'Pick one'),
              textAlign: TextAlign.center)),
    ],
  );
}

// ================================================================== the test ===
void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('hand and list', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    _skills = jsonDecode(File('assets/gamedata/skills.json').readAsStringSync())
        as Map<String, dynamic>;
    _factions = jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
        as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final scheme = AppPalette.stitchedInk.schemeFor(Brightness.dark);

    Future<void> shot(String name, Widget Function(BuildContext) build,
        {double h = 780}) async {
      tester.view.physicalSize = Size(360, h);
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Builder(builder: (c) => Phone(title: 'Level up', child: build(c))),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    final sk3 = skillOffer();
    final lv3 = levelOffer();
    // the hand
    await shot('hand-offer', (c) => handScreen(c, sk3));
    await shot('hand-touched', (c) => handScreen(c, sk3, lit: 1));
    await shot('hand-picked', (c) => handScreen(c, sk3, picked: 1));
    final hf = <({int lit, int? picked})>[
      (lit: -1, picked: null),
      (lit: 0, picked: null),
      (lit: 1, picked: null),
      (lit: 2, picked: null),
      (lit: 1, picked: null),
      (lit: -1, picked: 1),
      (lit: -1, picked: 1),
    ];
    for (final (i, f) in hf.indexed) {
      await shot('hf$i', (c) => handScreen(c, sk3, lit: f.lit, picked: f.picked));
    }
    // the list
    await shot('list-offer', (c) => listScreen(c, lv3));
    await shot('list-opened', (c) => listScreen(c, lv3, open: 0));
    await shot('list-picked', (c) => listScreen(c, lv3, picked: 0));
    final lf = <({int touched, int open, int? picked})>[
      (touched: -1, open: -1, picked: null),
      (touched: 1, open: -1, picked: null),
      (touched: -1, open: 1, picked: null),
      (touched: 0, open: 1, picked: null),
      (touched: -1, open: 0, picked: null),
      (touched: -1, open: 0, picked: 0),
      (touched: -1, open: 0, picked: 0),
    ];
    for (final (i, f) in lf.indexed) {
      await shot('lf$i', (c) => listScreen(c, lv3, touched: f.touched, open: f.open, picked: f.picked));
    }
    // the mixed offer: 2 skills + 1 level, then 1 skill + 2 levels, and a non-skill gift
    final two = [Gf.skill(_c('dominion'), 'fireball'), Gf.skill(_c('crows'), 'mage_frost_nova')];
    final oneRow = [Gf.ascension(_c('penitents'), 'mage_mending_tide', 'mending_touch')];
    await shot('mixed-2cards-1row', (c) => mixedScreen(c, two, oneRow, lit: 0));
    await shot('mixed-2cards-1row-opened', (c) => mixedScreen(c, two, oneRow, open: 0), h: 860);
    await shot('mixed-2cards-1row-picked', (c) => mixedScreen(c, two, oneRow, picked: 2));
    final one = [Gf.skill(_c('dominion'), 'fireball')];
    final twoRows = [
      Gf.ascension(_c('penitents'), 'mage_mending_tide', 'mending_touch'),
      Gf.rank(Cl.wayfarer()),
    ];
    await shot('mixed-1card-2rows', (c) => mixedScreen(c, one, twoRows, lit: 0));
    await shot('mixed-1card-2rows-opened', (c) => mixedScreen(c, one, twoRows, open: 1), h: 880);
    final objects = [Gf.skill(_c('dominion'), 'fireball'), Gf.object(_c('compact')), Gf.skill(_c('crows'), 'mage_frost_nova')];
    await shot('non-skill-gift-in-hand', (c) => handScreen(c, objects, lit: 1));
    // the base card, the three cards of the hand at full size (for reference)
    await shot('cards-full-size', (c) => Container(
          color: Theme.of(c).colorScheme.surface,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final g in sk3) Padding(padding: const EdgeInsets.all(8), child: ClanCard2(g)),
          ]),
        ));
  });
}
