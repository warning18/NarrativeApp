// The clan's offer at a level-up, three directions (UX_SHOTS=<folder>, UX_DIR=a|b|c):
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


// ------------------------------------------------------------ the states ---
enum CardState { idle, hover, picked, dim }

Widget kindTag(Gift g, Color frame, {bool fill = true}) =>
    Tag(_kindLabel(g.kind), frame, fill: fill);

Widget giftLines(BuildContext context, Gift g, {double size = 10.5}) {
  final s = g.skill;
  return Column(mainAxisSize: MainAxisSize.min, children: [
    Text(s.effect().isEmpty ? s.desc : s.effect(),
        textAlign: TextAlign.center,
        style: _sys(context, size: size + 0.5, color: _apCream)),
    const SizedBox(height: 2),
    Text(g.kind == Kind.ascension ? 'Raises ${g.raises!.name}' : s.desc,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: _body(context, size: size)),
  ]);
}

Widget tagRow(Sk s) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (s.element != 'None') Tag(s.element, _element(s.element), dot: true),
        const SizedBox(width: 4),
        Tag(_cap(s.rarity), _rarity(s.rarity)),
      ]),
    );

// =============================================================== DIRECTION A
// Three portrait cards: the clan's banner hangs over the card, the gift is its seal.

class ACard extends StatelessWidget {
  const ACard(this.g, {super.key, this.state = CardState.idle});
  final Gift g;
  final CardState state;

  @override
  Widget build(BuildContext context) {
    final picked = state == CardState.picked;
    final hover = state == CardState.hover;
    final frame = picked ? _apCore : g.clan.color;
    final s = g.skill;
    Widget card = Container(
      width: 106,
      height: 330,
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(color: frame, width: picked ? 3 : 2),
            step: 3,
            steps: 3),
        shadows: [
          if (hover || picked)
            BoxShadow(color: frame.withValues(alpha: 0.55), blurRadius: 14),
        ],
      ),
      child: Column(children: [
        Container(
          height: 128,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_tint(g.clan, 0.55), _tint(g.clan, 0.12)])),
          alignment: Alignment.center,
          child: bannerOf(g.clan, h: 116),
        ),
        Transform.translate(
            offset: const Offset(0, -18), child: Plate(s, size: 44)),
        Transform.translate(
          offset: const Offset(0, -14),
          child: Column(children: [
            Text(s.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: _name(context, size: 13)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            child: Column(children: [
              kindTag(g, frame),
              const SizedBox(height: 4),
              Expanded(child: giftLines(context, g, size: 10)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Column(children: [
            tagRow(s),
            const SizedBox(height: 4),
            Text(g.clan.short.toUpperCase(),
                style: _sys(context, size: 10, color: g.clan.color)),
          ]),
        ),
      ]),
    );
    card = Transform.translate(offset: Offset(0, hover ? -8 : 0), child: card);
    return Opacity(opacity: state == CardState.dim ? 0.35 : 1, child: card);
  }
}

Widget aOffer(BuildContext context, {int? hover, int? picked}) {
  final o = _offer();
  return ListView(padding: const EdgeInsets.all(14), children: [
    pickerHeader(context, hint: picked == null ? 'Three clans came' : 'Taken'),
    const SizedBox(height: 18),
    SizedBox(
      height: 352,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              ACard(o[i],
                  state: picked != null
                      ? (picked == i ? CardState.picked : CardState.dim)
                      : hover == i
                          ? CardState.hover
                          : CardState.idle),
          ]),
    ),
    const SizedBox(height: 10),
    Text(
        picked == null
            ? (hover == null
                ? 'One gift each. Take one: its clan thinks better of you, its rivals worse.'
                : '${o[hover].clan.name}: “${o[hover].clan.greeting}”')
            : '${o[picked].skill.name} is yours. ${o[picked].clan.short} +6.',
        style: _body(context)),
    const SizedBox(height: 12),
    FilledButton(
        onPressed: picked == null ? null : () {},
        child: Text(picked == null ? 'Pick a card' : 'Continue')),
  ]);
}

// =============================================================== DIRECTION B
// Three stacked rows: the banner, the gift, the words; one opens.

class BRow extends StatelessWidget {
  const BRow(this.g,
      {super.key, this.state = CardState.idle, this.open = false});
  final Gift g;
  final CardState state;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final picked = state == CardState.picked;
    final hover = state == CardState.hover;
    final frame = picked ? _apCore : (hover || open ? g.clan.color : ink.seam);
    final s = g.skill;
    final body = Container(
      margin: EdgeInsets.only(left: hover ? 6 : 0),
      decoration: ShapeDecoration(
        color: picked ? Color.lerp(_apNavy, _apCore, 0.12) : _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(color: frame, width: picked || open ? 2.5 : 1.5),
            step: 2,
            steps: 2),
        shadows: [
          if (hover || picked)
            BoxShadow(color: frame.withValues(alpha: 0.4), blurRadius: 10),
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
                    colors: [_tint(g.clan, 0.55), _tint(g.clan, 0.12)])),
            alignment: Alignment.center,
            child: bannerOf(g.clan, h: open ? 120 : 84),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Plate(s, size: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _name(context, size: 16)),
                              const SizedBox(height: 3),
                              Row(children: [
                                kindTag(g, picked ? _apCore : g.clan.color),
                                const SizedBox(width: 4),
                                Tag(_cap(s.rarity), _rarity(s.rarity)),
                              ]),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        '${s.effect()}${g.kind == Kind.ascension ? '  ·  raises ${g.raises!.name}' : ''}',
                        style: _sys(context, size: 11, color: _apCream)),
                    const SizedBox(height: 4),
                    Text('${g.clan.short.toUpperCase()}  ·  “${g.clan.greeting}”',
                        maxLines: open ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: _body(context, size: 11)),
                    if (open) ...[
                      const SizedBox(height: 6),
                      Text(
                          'Takes ${g.clan.name} up by 6. Its rivals will hold it against you.',
                          style: _body(context, size: 11, color: _apGold)),
                    ],
                  ]),
            ),
          ),
        ]),
      ),
    );
    return Opacity(opacity: state == CardState.dim ? 0.3 : 1, child: body);
  }
}

Widget bOffer(BuildContext context, {int? hover, int? picked, int open = -1}) {
  final o = _offer();
  final sel = picked ?? open;
  return ListView(padding: const EdgeInsets.all(14), children: [
    pickerHeader(context, hint: picked == null ? 'Three clans came' : 'Taken'),
    const SizedBox(height: 12),
    for (var i = 0; i < 3; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: BRow(o[i],
            open: sel == i,
            state: picked != null
                ? (picked == i ? CardState.picked : CardState.dim)
                : hover == i
                    ? CardState.hover
                    : CardState.idle),
      ),
    const SizedBox(height: 6),
    FilledButton(
        onPressed: sel < 0 ? null : () {},
        child: Text(picked != null
            ? 'Continue'
            : sel < 0
                ? 'Pick a card'
                : 'Take ${o[sel].skill.name}')),
  ]);
}

// =============================================================== DIRECTION C
// One big card at a time, the next one peeking: swipe to compare the clans.

Widget cBig(BuildContext context, Gift g,
    {required double w, required double h, CardState state = CardState.idle}) {
  final s = g.skill;
  final picked = state == CardState.picked;
  final frame = picked ? _apCore : g.clan.color;
  return Transform.translate(
    offset: Offset(0, state == CardState.hover ? -6 : 0),
    child: Opacity(
      opacity: state == CardState.dim ? 0.2 : 1,
      child: Container(
        width: w,
        height: h,
        decoration: ShapeDecoration(
          color: _apNight,
          shape: PixelChipBorder(
              side: BorderSide(color: frame, width: picked ? 3.5 : 2.5),
              step: 4,
              steps: 3),
          shadows: [
            if (state == CardState.hover || picked)
              BoxShadow(color: frame.withValues(alpha: 0.5), blurRadius: 16),
          ],
        ),
        child: Column(children: [
          Container(
            height: 176,
            margin: const EdgeInsets.all(6),
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_tint(g.clan, 0.6), _tint(g.clan, 0.12)])),
            child: Stack(alignment: Alignment.center, children: [
              Positioned(left: 22, top: 0, child: bannerOf(g.clan, h: 168)),
              Positioned(right: 22, bottom: 22, child: SkillPixelIcon(s.id, size: 96)),
              Positioned(right: 6, top: 6, child: kindTag(g, frame)),
            ]),
          ),
          Container(
            width: double.infinity,
            color: g.clan.color,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(s.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 18,
                    color: _apOutline)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(children: [
                Text(s.effect(),
                    textAlign: TextAlign.center,
                    style: _sys(context, size: 12, color: _apCream)),
                if (g.kind == Kind.ascension)
                  Text('Raises ${g.raises!.name}',
                      style: _sys(context, size: 11, color: _apGold)),
                const SizedBox(height: 4),
                Text('“${g.clan.greeting}”',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 12).copyWith(
                        fontStyle: FontStyle.italic)),
                const Spacer(),
                tagRow(s),
                const SizedBox(height: 4),
                Text('${g.clan.name.toUpperCase()}  +6',
                    style: _sys(context, size: 10, color: g.clan.color)),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

Widget cOffer(BuildContext context,
    {int focus = 0, int? picked, bool pressing = false}) {
  final o = _offer();
  final ink = InkColors.of(context);
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context,
          hint: picked == null ? 'Swipe · three clans' : 'Taken'),
      const SizedBox(height: 14),
      SizedBox(
        height: 392,
        child: Stack(alignment: Alignment.center, children: [
          for (final i in [for (var k = 0; k < 3; k++) k].where((k) => k != focus))
            Positioned(
              left: i < focus ? -150 : null,
              right: i > focus ? -150 : null,
              child: Transform.scale(
                scale: 0.88,
                child: cBig(context, o[i],
                    w: 230,
                    h: 360,
                    state: picked != null ? CardState.dim : CardState.idle),
              ),
            ),
          cBig(context, o[focus],
              w: 250,
              h: 380,
              state: picked == focus
                  ? CardState.picked
                  : pressing
                      ? CardState.hover
                      : CardState.idle),
        ]),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: i == focus ? 16 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: i == focus ? o[i].clan.color : ink.seam,
          ),
      ]),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: () {},
          child: Text(picked != null
              ? 'Continue'
              : 'Take ${o[focus].skill.name} from the ${o[focus].clan.short}')),
    ],
  );
}

// ------------------------------------------------------------------ test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final dir = Platform.environment['UX_DIR'] ?? 'a';

  testWidgets('clan offer directions', skip: shots == null, (tester) async {
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

    Future<void> shot(String name, Widget Function(BuildContext) build) async {
      final scheme = AppPalette.stitchedInk.schemeFor(Brightness.dark);
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Builder(
              builder: (c) => Phone(title: 'Level up', child: build(c))),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      late List<int> bytes;
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$dir-$name.png').writeAsBytesSync(bytes);
    }

    switch (dir) {
      case 'a':
        await shot('1-offer', (c) => aOffer(c));
        await shot('2-touched', (c) => aOffer(c, hover: 0));
        await shot('3-picked', (c) => aOffer(c, picked: 0));
        final fr = <({int? hover, int? picked})>[
          (hover: null, picked: null),
          (hover: 0, picked: null),
          (hover: 1, picked: null),
          (hover: 2, picked: null),
          (hover: 0, picked: null),
          (hover: null, picked: 0),
          (hover: null, picked: 0),
        ];
        for (final (i, f) in fr.indexed) {
          await shot('f$i', (c) => aOffer(c, hover: f.hover, picked: f.picked));
        }
      case 'b':
        await shot('1-offer', (c) => bOffer(c));
        await shot('2-touched', (c) => bOffer(c, open: 0));
        await shot('3-picked', (c) => bOffer(c, picked: 0));
        final fr = <({int? hover, int? picked, int open})>[
          (hover: null, picked: null, open: -1),
          (hover: 2, picked: null, open: -1),
          (hover: null, picked: null, open: 2),
          (hover: 0, picked: null, open: 2),
          (hover: null, picked: null, open: 0),
          (hover: null, picked: 0, open: 0),
          (hover: null, picked: 0, open: 0),
        ];
        for (final (i, f) in fr.indexed) {
          await shot('f$i',
              (c) => bOffer(c, hover: f.hover, picked: f.picked, open: f.open));
        }
      case 'c':
        await shot('1-offer', (c) => cOffer(c));
        await shot('2-touched', (c) => cOffer(c, focus: 2, pressing: true));
        await shot('3-picked', (c) => cOffer(c, picked: 0));
        final fr = <({int focus, bool press, int? picked})>[
          (focus: 0, press: false, picked: null),
          (focus: 1, press: false, picked: null),
          (focus: 2, press: false, picked: null),
          (focus: 2, press: true, picked: null),
          (focus: 2, press: false, picked: 2),
          (focus: 2, press: false, picked: 2),
        ];
        for (final (i, f) in fr.indexed) {
          await shot('f$i',
              (c) => cOffer(c, focus: f.focus, pressing: f.press, picked: f.picked));
        }
    }
  });
}
