// The base card of the clan's offer (UX_SHOTS=<folder>): one upright card template for
// three clans, the sheet at 1x and 2x, and the three held as a hand at the level-up.
// Previously: three directions (a|b|c):
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


// ------------------------------------------------------------ the card ---
const double kCardW = 210, kCardH = 346;

Widget tagRow(Sk s) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (s.element != 'None') Tag(s.element, _element(s.element), dot: true),
        const SizedBox(width: 4),
        Tag(_cap(s.rarity), _rarity(s.rarity)),
      ]),
    );

/// The base card: one template for every clan and every gift. The clan gives the
/// colour and the banner; the gift gives the icon, the name, the kind tag, the
/// effect and the tags. [lit] = the card in hand that is touched.
class ClanCard extends StatelessWidget {
  const ClanCard(this.g, {super.key, this.lit = false});
  final Gift g;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final c = g.clan;
    final s = g.skill;
    return Container(
      width: kCardW,
      height: kCardH,
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(
        color: _apNavy,
        shape: PixelChipBorder(
            side: BorderSide(color: lit ? _apCore : c.color, width: 3),
            step: 4,
            steps: 3),
        shadows: [
          BoxShadow(
              color: (lit ? _apCore : c.color).withValues(alpha: lit ? 0.55 : 0.25),
              blurRadius: lit ? 16 : 8),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(color: c.color.withValues(alpha: 0.35))),
        child: Column(children: [
          // The art: the clan's banner hangs at the left, the gift stands at the
          // right, the kind of gift in the corner.
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_tint(c, 0.6), _tint(c, 0.14)])),
            child: Stack(children: [
              Positioned(left: 16, top: 6, child: bannerOf(c, h: 138)),
              Positioned(
                  right: 14,
                  bottom: 14,
                  child: Plate(s, size: 86)),
              Positioned(right: 6, top: 6, child: kindTag(g, c.color)),
            ]),
          ),
          Container(
            height: 32,
            width: double.infinity,
            color: c.color,
            alignment: Alignment.center,
            child: Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 19,
                    height: 1,
                    color: _apOutline)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(children: [
                Text(s.effect(),
                    textAlign: TextAlign.center,
                    style: _sys(context, size: 12.5, color: _apCream)),
                if (g.kind == Kind.ascension)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Raises ${g.raises!.name}',
                        textAlign: TextAlign.center,
                        style: _sys(context, size: 11, color: _apGold)),
                  ),
                const SizedBox(height: 4),
                Text(s.desc,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 12)),
                const SizedBox(height: 6),
                tagRow(s),
                const Spacer(),
                Container(height: 1, color: c.color.withValues(alpha: 0.5)),
                const SizedBox(height: 6),
                Text('“${c.greeting}”',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _body(context, size: 11.5)
                        .copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Text(c.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sys(context,
                            size: 9.5,
                            color: Color.lerp(c.color, _apCream, 0.45))),
                  ),
                  Text('+6',
                      style: _sys(context, size: 11, color: _apCore)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget kindTag(Gift g, Color frame) =>
    Tag(_kindLabel(g.kind), frame, fill: true);

/// The three cards side by side, at full size, on the page's colour.
Widget sheet(BuildContext context) {
  final o = _offer();
  return Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.all(18),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 18),
        ClanCard(o[i]),
      ],
    ]),
  );
}

/// The three held as a hand at the level-up: they overlap in a fan, the one that
/// is touched rises out of the hand and comes in front.
Widget hand(BuildContext context, {int lit = 1}) {
  final o = _offer();
  const s = 0.66; // the hand's cards: a little smaller than the touched one
  const sl = 0.84; // the touched card
  Widget card(int i) {
    final touched = i == lit;
    final k = touched ? sl : s;
    final angle = (i - 1) * 0.11 * (touched ? 0.25 : 1);
    return Positioned(
      left: ([0.0, 96.5, 193.0][i] - (touched ? 18.5 : 0)).clamp(0.0, 332 - kCardW * sl),
      bottom: touched ? 24 : 0,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: kCardW * k,
          height: kCardH * k,
          child: FittedBox(child: ClanCard(o[i], lit: touched)),
        ),
      ),
    );
  }

  final order = [for (var i = 0; i < 3; i++) if (i != lit) i, lit];
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    children: [
      pickerHeader(context, hint: 'Three clans came'),
      const SizedBox(height: 10),
      Text(
          '${o[lit].clan.name}: “${o[lit].clan.greeting}”',
          style: _body(context)),
      const SizedBox(height: 14),
      SizedBox(
        height: 330,
        child: Stack(clipBehavior: Clip.none, children: [
          for (final i in order) card(i),
        ]),
      ),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: () {},
          child: Text('Take ${o[lit].skill.name}')),
    ],
  );
}

// ------------------------------------------------------------------ test ---
void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the base card', skip: shots == null, (tester) async {
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

    Future<void> shot(String name, Widget Function(BuildContext) build,
        {required Size size, double ratio = 2, bool phone = false}) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(scheme),
          home: Builder(
              builder: (c) => phone
                  ? Phone(title: 'Level up', child: build(c))
                  : Scaffold(
                      body: Align(
                          alignment: Alignment.topLeft, child: build(c)))),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
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

    const sheetSize = Size(3 * kCardW + 2 * 18 + 36, kCardH + 36);
    await shot('base-cards-1x', sheet, size: sheetSize, ratio: 1);
    await shot('base-cards-2x', sheet, size: sheetSize, ratio: 2);
    await shot('hand', hand, size: const Size(360, 780), phone: true);
    await shot('hand-left', (c) => hand(c, lit: 0),
        size: const Size(360, 780), phone: true);
    await shot('hand-right', (c) => hand(c, lit: 2),
        size: const Size(360, 780), phone: true);
  });
}
