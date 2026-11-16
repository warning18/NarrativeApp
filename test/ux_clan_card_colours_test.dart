// Colours that follow the clan (UX_SHOTS=<folder>): today's v1.975 card (with
// the effect line back) and three ways to let each card's colours come from its
// clan while the rarity frames stay as Art made them:
//   1 body tint   2 clan backdrop   3 accents only   (+ a mix of 1 and 3)
// All six clans and the Wayfarer, real data (factions.json, skills.json, the
// clans' banners). Mock only: nothing here is used by the app.
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

/// One real gift: a skill of skills.json offered by a clan of factions.json (or
/// the Wayfarer's perk rank).
class Gift {
  Gift(this.clanId, this.skillId)
      : rec = _skills[skillId] as Map<String, dynamic>,
        clan = _factions[clanId] as Map<String, dynamic>?;
  Gift.wayfarer()
      : clanId = 'wayfarer',
        skillId = 'keen_eye',
        rec = const {'rarity': 'common'},
        clan = null;
  final String clanId, skillId;
  final Map<String, dynamic> rec;
  final Map<String, dynamic>? clan;

  bool get isWayfarer => clan == null;
  String get name => isWayfarer ? 'Keen Eye' : skillDisplayName(skillId);
  String get element => rec['element']?.toString() ?? 'None';
  String get rarity => rec['rarity']?.toString() ?? 'common';
  CardTier get tier => _tierOf(rarity);
  String get kind => isWayfarer ? 'Perk' : 'Skill';
  Color get color => isWayfarer
      ? const Color(0xFF8D6E63)
      : Color(int.parse((clan!['color'] as String).substring(1), radix: 16) |
          0xFF000000);
  String get clanName => isWayfarer ? 'The Wayfarer' : clan!['name'] as String;
  String get clanShort => isWayfarer ? 'Wayfarer' : clan!['short'] as String;
  String get greeting => isWayfarer
      ? 'No banner, no price. Take what helps.'
      : (clan!['greetings'] as List).first as String;
  String? get banner => isWayfarer ? null : clanBannerId(clanId);

  String get effect {
    if (isWayfarer) return '+5% chance of a critical hit';
    final s = applySkillTier(rec, 0);
    final dmg = (s['damageMod'] as num?)?.toInt() ?? 0;
    final mul = (s['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
    final heal = (s['healAmount'] as num?)?.toInt() ?? 0;
    final shield = (s['shieldAmount'] as num?)?.toInt() ?? 0;
    return [
      if (dmg > 0) '+$dmg damage',
      if (mul > 1.0) '×${mul.toStringAsFixed(1)}',
      if (heal > 0) 'heals $heal',
      if (shield > 0) 'shields $shield',
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
    child: g.banner == null
        ? AspectRatio(
            aspectRatio: 0.5, child: CustomPaint(painter: _Pennant(g.color)))
        : FittedBox(
            fit: BoxFit.contain, child: PixelBanner(id: g.banner!, scale: 1)));

class _Pennant extends CustomPainter {
  _Pennant(this.c);
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    cv.drawRect(Rect.fromLTWH(s.width * 0.2, 0, 3, s.height),
        Paint()..color = const Color(0xFFD7B594));
    cv.drawPath(
        Path()
          ..moveTo(s.width * 0.2 + 3, s.height * 0.08)
          ..lineTo(s.width * 0.95, s.height * 0.22)
          ..lineTo(s.width * 0.2 + 3, s.height * 0.36)
          ..close(),
        Paint()..color = c);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// The clan's sign alone: the banner cropped to its emblem.

Widget _icon(Gift g, double size) => g.isWayfarer
    ? Icon(Icons.star_outline, size: size * 0.8, color: Palette.apolloCream)
    : SkillPixelIcon(g.skillId, size: size);

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

// ------------------------------------------------------------ the card ---
enum Dir { today, tint, backdrop, accents, mix }

const _dirs = <(Dir, String, String)>[
  (Dir.today, 'today', 'v1.975 today (+ effect line)'),
  (Dir.tint, '1-tint', '1  Body tint'),
  (Dir.backdrop, '2-backdrop', '2  Clan backdrop'),
  (Dir.accents, '3-accents', '3  Accents only'),
  (Dir.mix, '4-mix', '1 + 3  Mix (soft tint, accents)'),
];

Color _deep(Color c, double t) => Color.lerp(_night, c, t)!;
Color _light(Color c) => Color.lerp(c, Palette.apolloCream, 0.45)!;
Color _inkOn(Color c) =>
    contrast(Palette.apolloOutline, c) >= contrast(Palette.apolloCream, c)
        ? Palette.apolloOutline
        : Palette.apolloCream;

/// The body's colour at the middle of the text zone, for the readability check.
Color bodyMid(Gift g, Dir d) => switch (d) {
      Dir.tint => Color.lerp(_deep(g.color, 0.34), _deep(g.color, 0.2), 0.7)!,
      Dir.mix => Color.lerp(_deep(g.color, 0.26), _deep(g.color, 0.16), 0.7)!,
      _ => _navy,
    };

Widget clanCard(Gift g, Dir d, {bool lit = false, bool touched = false}) {
  final c = g.color;
  final tint = d == Dir.tint || d == Dir.mix;
  final accents = d == Dir.accents || d == Dir.mix;
  final top = tint ? _deep(c, d == Dir.mix ? 0.26 : 0.34) : _navy;
  final bot = tint ? _deep(c, d == Dir.mix ? 0.16 : 0.2) : _navy;
  final standing = accents ? _light(c) : _core;
  final tags = [
    Tag(g.kind, accents ? _light(c) : const Color(0xFF819796)),
    if (g.element != 'None') Tag(g.element, _element(g.element)),
    if (!g.isWayfarer) Tag(_cap(g.rarity), _rarityColor(g.rarity)),
    if (g.isWayfarer) const Tag('Rank 1 of 3', _gold),
  ];
  return _shell(g, lit, body: top, [
    // The body: a tint that follows the clan, or the shared navy.
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
              colors: [top, bot]),
        ),
      ),
    ),
    // The art zone.
    if (d == Dir.backdrop) ...[
      Positioned(
        left: 1,
        top: 1,
        width: 208,
        height: 152,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(c, Palette.apolloCream, 0.15)!
                    .withValues(alpha: 0.8),
                _deep(c, 0.5),
              ],
            ),
          ),
        ),
      ),
      if (g.banner != null)
        Positioned(
          left: 1,
          top: 1,
          width: 208,
          height: 152,
          child: ClipRect(
            child: OverflowBox(
              minWidth: 192,
              maxWidth: 192,
              minHeight: 384,
              maxHeight: 384,
              alignment: const Alignment(0.35, -0.3),
              child: Opacity(
                  opacity: 0.2, child: PixelBanner(id: g.banner!, scale: 3)),
            ),
          ),
        ),
      Positioned(
          left: 1,
          top: 1,
          child: Opacity(opacity: 0.5, child: _backdrop(g.tier, 208, 152))),
    ] else ...[
      Positioned(left: 1, top: 1, child: _backdrop(g.tier, 208, 152)),
      Positioned(
        left: 1,
        top: 1,
        width: 208,
        height: 152,
        child: ColoredBox(color: c.withValues(alpha: tint ? 0.1 : 0.18)),
      ),
    ],
    Positioned(left: 18, top: 12, width: 64, height: 128, child: _flag(g, 128)),
    Positioned(
      right: 16,
      top: 36,
      width: 80,
      height: 80,
      child: Stack(alignment: Alignment.center, children: [
        _plate(g.tier, 80),
        _icon(g, 48),
      ]),
    ),
    if (accents)
      Positioned(
        left: 13,
        top: 13,
        right: 13,
        bottom: 13,
        child: DecoratedBox(
            decoration: BoxDecoration(
                border: Border.all(color: c.withValues(alpha: 0.65)))),
      ),
    Positioned(
      left: 12,
      right: 12,
      top: 152,
      height: 30,
      child: Container(
        color: c,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(g.name, style: _name(19, _inkOn(c))),
        ),
      ),
    ),
    Positioned(
      left: 18,
      right: 18,
      top: 188,
      bottom: 16,
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(children: [
            for (var i = 0; i < tags.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              tags[i],
            ],
          ]),
        ),
        const SizedBox(height: 5),
        Text(g.effect, textAlign: TextAlign.center, style: _sys(12, _gold)),
        const SizedBox(height: 2),
        Text('+6 ${g.clanShort}', style: _sys(12, standing)),
        const Spacer(),
        Container(
            height: accents ? 2 : 1,
            color: c.withValues(alpha: accents ? 0.9 : 0.55)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '“', style: TextStyle(color: accents ? _light(c) : null)),
            TextSpan(text: g.greeting),
            TextSpan(
                text: '”', style: TextStyle(color: accents ? _light(c) : null)),
          ]),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: _prose(11, Palette.apolloCream, italic: true),
        ),
        const SizedBox(height: 6),
        Text(g.clanName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _sys(9.5, _light(c))),
      ]),
    ),
  ]);
}

// --------------------------------------------------------- readability ---
double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// ------------------------------------------------------------- layouts ---
typedef CardBuilder = Widget Function(Gift g, {bool lit, bool touched});

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

  testWidgets('clan colours', skip: shots == null, (tester) async {
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
    // The six clans and the Wayfarer, each with a real gift (the frames vary).
    final gifts = [
      Gift('dominion', 'fireball'),
      Gift('crows', 'mage_frost_nova'),
      Gift('compact', 'warrior_iron_stance'),
      Gift('mire', 'ranger_multi_shot'),
      Gift('vigil', 'quick_heal'),
      Gift('penitents', 'cleric_second_dawn'),
      Gift.wayfarer(),
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

    Widget cardsOf(Dir d, List<Gift> list) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in list)
              Padding(padding: const EdgeInsets.all(10), child: clanCard(g, d)),
          ],
        );

    for (final (d, id, title) in _dirs) {
      for (final (suffix, ratio) in [('1x', 1.0), ('2x', 2.0)]) {
        await shot('cards-$id-$suffix', const Size(940, 740), (c) {
          return ColoredBox(
            color: Theme.of(c).colorScheme.surface,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              cardsOf(d, gifts.sublist(0, 4)),
              cardsOf(d, gifts.sublist(4)),
            ]),
          );
        }, ratio: ratio);
      }
      // One hand of three on the level-up screen: Dominion, Mire, Penitents.
      final three = [gifts[0], gifts[3], gifts[5]];
      await shot('hand-$id', const Size(360, 700), (c) {
        return handScreen(
            c,
            three,
            (g, {bool lit = false, bool touched = false}) =>
                clanCard(g, d, lit: lit),
            title);
      });
    }
    // All the directions, one row each.
    await shot('compare', const Size(1500, 1760), (c) {
      return ColoredBox(
        color: Theme.of(c).colorScheme.surface,
        child: Column(children: [
          for (final (d, _, title) in _dirs)
            Expanded(
              child: Row(children: [
                SizedBox(
                    width: 90,
                    child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(title,
                            style: _sys(11,
                                Theme.of(c).colorScheme.onSurfaceVariant)))),
                for (final g in gifts)
                  Expanded(
                      child: FittedBox(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: clanCard(g, d)))),
              ]),
            ),
        ]),
      );
    }, ratio: 1);

    // Readability: contrast ratios of every text on every tint (WCAG 4.5 body,
    // 3 for large text).
    final out =
        StringBuffer('direction,clan,words,effect,standing,clanname,band\n');
    for (final (d, id, _) in _dirs) {
      for (final g in gifts) {
        final body = bodyMid(g, d);
        final accents = d == Dir.accents || d == Dir.mix;
        final r = [
          contrast(Palette.apolloCream, body),
          contrast(_gold, body),
          contrast(accents ? _light(g.color) : _core, body),
          contrast(_light(g.color), body),
          contrast(_inkOn(g.color), g.color),
        ];
        out.writeln(
            '$id,${g.clanId},${r.map((v) => v.toStringAsFixed(1)).join(',')}');
      }
    }
    File('$shots/readability.csv').writeAsStringSync(out.toString());
  });
}
