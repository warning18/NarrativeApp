// PROPOSAL (pictures only, no PR): the Tower's cards in the latest ink design,
// three directions, each a pick of three cards at 360 and 320 wide, their
// states, a French long name at x1.3 text, and the reroll / banish control.
//   A  ink paper cards in the kit's seeded variations (tint, tilt, torn edge,
//      pin), the rarity a spot of colour
//   B  tall tarot-like cards: a painted vignette from the ink plates, a red
//      seal for the rarity
//   C  a black card, a paper title band, a big icon
// Existing art only. UX_SHOTS=<folder>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_seed.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_worn.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

enum _R { common, rare, epic }

const _rarityColour = {
  _R.common: inkGrey,
  _R.rare: Color(0xFF6FA3D0),
  _R.epic: Color(0xFFE0B04A),
};
const _rarityWord = {
  'en': ['COMMON', 'RARE', 'EPIC'],
  'fr': ['COMMUNE', 'RARE', 'ÉPIQUE']
};

class _C {
  const _C(
      this.kind, this.name, this.text, this.rarity, this.icon, this.vignette,
      {this.isNew = false, this.price});
  final String kind, name, text, icon, vignette;
  final _R rarity;
  final bool isNew;
  final int? price;
}

const _skill = _C(
    'SKILL',
    'Steady Aim',
    'Take the extra second to make it count.',
    _R.rare,
    'assets/icons/skills/steady_aim.png',
    'assets/visuals/tower/tower_ward5.png');
const _die = _C(
    'DIE',
    'Chorus Die',
    'A d12: every face sings with the others.',
    _R.common,
    'assets/visuals/dice/die_d12_bone_44.png',
    'assets/visuals/tower/tower_shop.png');
const _spell = _C(
    'SPELL',
    'Rally the Line',
    'The party closes ranks: every member recovers health.',
    _R.epic,
    'assets/icons/skills/rallying_cry.png',
    'assets/visuals/tower/tower_parley.png',
    isNew: true);
const _frLong = _C(
    'SERMENT',
    'Résonance de l’Ordre des Sentinelles Vigilantes',
    'Chaque face de Garde protège aussi un allié proche, jusqu’à la fin de l’étage.',
    _R.rare,
    'assets/icons/skills/brace.png',
    'assets/visuals/tower/tower_bargain.png',
    isNew: true);

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.2, color: c);

Widget _icon(_C c, double s) => Image.asset(c.icon,
    width: s,
    height: s,
    filterQuality: FilterQuality.none,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(width: s, height: s));

Widget _grey(bool disabled, Widget w) => disabled
    ? ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.7, 0,
        ]),
        child: w)
    : w;

Widget _price(int p, {bool fr = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      color: inkRed,
      child: Text(fr ? '$p marques · trop cher' : '$p marks · can’t afford',
          style: _prose(10, inkPaper).copyWith(fontWeight: FontWeight.w700)),
    );

Widget _newTag(bool fr) =>
    InkTag(fr ? 'NOUVEAU · synergie' : 'NEW · synergy', red: true);

Widget _spot(_R r, {double s = 12}) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _rarityColour[r],
        border: Border.all(color: inkBlack, width: 1.5)));

// ---- A: ink paper, seeded -------------------------------------------------

class _CardA extends StatelessWidget {
  const _CardA(this.c,
      {this.selected = false,
      this.hover = false,
      this.disabled = false,
      this.fr = false});
  final _C c;
  final bool selected, hover, disabled, fr;

  @override
  Widget build(BuildContext context) {
    final seed = InkSeed.of(c.name);
    final body = Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
          color: seed.paper,
          border: selected ? Border.all(color: inkRed, width: 2.5) : null),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 46,
            height: 46,
            color: inkDeep,
            alignment: Alignment.center,
            child: _icon(c, 36)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(c.kind,
                  style: _prose(9.5, inkSlate).copyWith(
                      letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_rarityWord[fr ? 'fr' : 'en']![c.rarity.index],
                  style: _prose(9, inkOnPaper)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 5),
              _spot(c.rarity),
            ]),
            const SizedBox(height: 2),
            Text(c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _display(17, inkOnPaper)),
            const SizedBox(height: 3),
            Text(c.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _prose(11.5, inkOnPaper)),
            if (c.isNew || c.price != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(spacing: 6, runSpacing: 3, children: [
                  if (c.isNew) _newTag(fr),
                  if (c.price != null) _price(c.price!, fr: fr),
                ]),
              ),
          ]),
        ),
      ]),
    );
    final card = InkWeatherSafe(seed: seed, child: body);
    return Transform.translate(
      offset: Offset(0, hover ? -4 : 0),
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          if (hover)
            const BoxShadow(
                color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 6)),
        ]),
        child: _grey(disabled, card),
      ),
    );
  }
}

/// The kit's seeded wear without the weather: tint is the seed's, a torn
/// edge, marks and a pin; the tilt is kept to the small end for a wide card.
class InkWeatherSafe extends StatelessWidget {
  const InkWeatherSafe({super.key, required this.seed, required this.child});
  final InkSeed seed;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      InkWorn(seed: seed, tear: true, tilt: true, child: child);
}

// ---- B: tall tarot ---------------------------------------------------------

class _CardB extends StatelessWidget {
  const _CardB(this.c, this.w,
      {this.selected = false,
      this.hover = false,
      this.disabled = false,
      this.fr = false});
  final _C c;
  final double w;
  final bool selected, hover, disabled, fr;

  @override
  Widget build(BuildContext context) {
    // The card grows with the text setting; the name and the words scale down
    // to the room they have.
    final ts = MediaQuery.textScalerOf(context).scale(10) / 10;
    final h = w * 1.62 * (1 + (ts - 1) * 1.5);
    final card = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: selected ? inkRed : inkPaper, width: selected ? 3 : 1.5)),
      child: Column(children: [
        Expanded(
          flex: 10,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(c.vignette,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const ColoredBox(color: inkDark)),
            DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                  inkBlack.withValues(alpha: 0.25),
                  inkBlack.withValues(alpha: 0.7),
                ]))),
            Positioned(
                left: 5,
                top: 5,
                child: Container(
                    padding: const EdgeInsets.all(3),
                    color: inkBlack.withValues(alpha: 0.85),
                    child: _icon(c, w * 0.24))),
            Positioned(
                right: 5,
                top: 5,
                child: Text(c.kind,
                    style: _prose(8, inkPaper).copyWith(
                        letterSpacing: 0.6, fontWeight: FontWeight.w700))),
            // The red seal: its dots count the rarity.
            Positioned(
              left: 5,
              bottom: 5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inkRed,
                    border: Border.all(color: inkPaper, width: 1.5)),
                alignment: Alignment.center,
                child: Text('•' * (c.rarity.index + 1),
                    style: _prose(10, inkPaper)
                        .copyWith(height: 1, fontWeight: FontWeight.w900)),
              ),
            ),
            if (c.isNew)
              Positioned(
                right: 4,
                bottom: 6,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: inkRed,
                    child: Text(fr ? 'NOUV.' : 'NEW',
                        style: _prose(8.5, inkPaper)
                            .copyWith(fontWeight: FontWeight.w800))),
              ),
          ]),
        ),
        Container(
          color: inkPaper,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: w - 12,
              child: Text(c.name,
                  textAlign: TextAlign.center,
                  style: _display(w > 100 ? 13.5 : 12.5, inkOnPaper)),
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w - 12,
                child: Text(c.text,
                    textAlign: TextAlign.center, style: _prose(9.5, inkPaper)),
              ),
            ),
          ),
        ),
        if (c.price != null)
          SizedBox(
              width: double.infinity,
              child: FittedBox(
                  fit: BoxFit.scaleDown, child: _price(c.price!, fr: fr))),
      ]),
    );
    return Transform.translate(
      offset: Offset(0, hover || selected ? -6 : 0),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(boxShadow: [
          if (hover || selected)
            const BoxShadow(
                color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 6)),
        ]),
        child: _grey(disabled, card),
      ),
    );
  }
}

// ---- C: black card, paper band, big icon -----------------------------------

class _CardC extends StatelessWidget {
  const _CardC(this.c,
      {this.selected = false,
      this.hover = false,
      this.disabled = false,
      this.fr = false});
  final _C c;
  final bool selected, hover, disabled, fr;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: selected ? inkRed : inkPaper.withValues(alpha: 0.7),
              width: selected ? 2.5 : 1)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: _rarityColour[c.rarity]),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: inkPaper,
                    padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
                    child: Row(children: [
                      Expanded(
                          child: Text(c.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _display(15.5, inkOnPaper))),
                      const SizedBox(width: 6),
                      Text(c.kind,
                          style: _prose(9, inkSlate).copyWith(
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                color: inkDark,
                                border: Border.all(
                                    color: _rarityColour[c.rarity]!, width: 2)),
                            alignment: Alignment.center,
                            child: _icon(c, 48),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: _prose(11.5, inkPaper)),
                                  if (c.isNew || c.price != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                          spacing: 6,
                                          runSpacing: 3,
                                          children: [
                                            if (c.isNew) _newTag(fr),
                                            if (c.price != null)
                                              _price(c.price!, fr: fr),
                                          ]),
                                    ),
                                ]),
                          ),
                        ]),
                  ),
                ]),
          ),
        ]),
      ),
    );
    return Transform.translate(
      offset: Offset(0, hover ? -4 : 0),
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          if (hover)
            const BoxShadow(
                color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 6)),
        ]),
        child: _grey(disabled, card),
      ),
    );
  }
}

// ---- the pick, the control, the sheets -------------------------------------

Widget _control(bool fr) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InkButton(
              label: fr ? 'Relancer (2)' : 'Reroll (2)',
              height: 36,
              onPressed: () {}),
          const SizedBox(width: 10),
          InkButton(
              label: fr ? 'Bannir' : 'Banish', height: 36, onPressed: () {}),
        ]),
        const SizedBox(height: 6),
        Text(
            fr
                ? 'Deux relances restent à l’étage.'
                : 'Two rerolls left this floor.',
            style: _prose(10.5, inkGrey)),
      ]),
    );

Widget _takeRow(bool fr) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
          alignment: Alignment.centerRight,
          child: InkButton(
              label: fr ? 'Prendre' : 'Take',
              primary: true,
              height: 38,
              onPressed: () {})),
    );

Widget _rowCard(String dir, _C c, double w,
    {bool selected = false,
    bool hover = false,
    bool disabled = false,
    bool fr = false}) {
  switch (dir) {
    case 'A':
      return _CardA(c,
          selected: selected, hover: hover, disabled: disabled, fr: fr);
    case 'C':
      return _CardC(c,
          selected: selected, hover: hover, disabled: disabled, fr: fr);
    default:
      return _CardB(c, w,
          selected: selected, hover: hover, disabled: disabled, fr: fr);
  }
}

const _titles = {
  'A': 'A · Ink paper',
  'B': 'B · Tarot',
  'C': 'C · Black and paper'
};

Widget _pick(String dir, double w, {bool fr = false, List<_C>? cards}) {
  final cs = cards ?? [_skill, _die, _spell];
  final inner = w - 24;
  final tall = dir == 'B';
  final cardW = (inner - 16) / 3;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(_titles[dir]!),
    const SizedBox(height: 14),
    if (tall)
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _rowCard('B', cs[i], cardW, selected: i == 1, fr: fr),
        ],
      ])
    else
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _rowCard(dir, cs[i], inner, selected: i == 1, fr: fr),
        ),
    _takeRow(fr),
    _control(fr),
  ]);
}

Widget _states(String dir, double w, {bool fr = false}) {
  final inner = w - 24;
  final cardW = (inner - 16) / 3;
  final list = <(String, _C, bool, bool, bool)>[
    ('common', _die, false, false, false),
    ('rare', _skill, false, false, false),
    ('epic', _spell, false, false, false),
    ('selected', _skill, true, false, false),
    ('hovered', _die, false, true, false),
    (
      'disabled · can’t afford',
      const _C(
          'SKILL',
          'Iron Guard',
          'Defend faces block one more.',
          _R.rare,
          'assets/icons/skills/brace.png',
          'assets/visuals/tower/tower_ward5.png',
          price: 30),
      false,
      false,
      true
    ),
    ('new synergy', _spell, false, false, false),
  ];
  Widget cap(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 3, top: 8),
      child: Text(s.toUpperCase(),
          style: _prose(9, inkGrey).copyWith(letterSpacing: 1)));
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab('${_titles[dir]} · states'),
    if (dir == 'B')
      Wrap(spacing: 8, runSpacing: 12, children: [
        for (final e in list)
          SizedBox(
            width: cardW,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              cap(e.$1.split(' ').first),
              SizedBox(
                  height: cardW * 1.62 + 8,
                  child: _rowCard('B', e.$2, cardW,
                      selected: e.$3, hover: e.$4, disabled: e.$5, fr: fr)),
            ]),
          ),
      ])
    else
      for (final e in list) ...[
        cap(e.$1),
        _rowCard(dir, e.$2, inner,
            selected: e.$3, hover: e.$4, disabled: e.$5, fr: fr),
      ],
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> sheet(WidgetTester t, String name, double w, Widget body,
      {double scale = 1.0}) async {
    final key = GlobalKey();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(w, 1500);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: MediaQuery(
        data: MediaQueryData(
            size: Size(w, 1500), textScaler: TextScaler.linear(scale)),
        child: Material(
          color: inkDeep,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: Container(
                width: w,
                color: inkDeep,
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [body]),
              ),
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull, reason: name);
    await t.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
  }

  testWidgets('the Tower cards, three directions', skip: shots == null,
      (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [360.0, 320.0]) {
      final n = w.toInt();
      for (final dir in ['A', 'B', 'C']) {
        await sheet(t, '$dir-pick-$n', w, _pick(dir, w));
        await sheet(t, '$dir-states-$n', w, _states(dir, w));
        await sheet(t, '$dir-french-1.3x-$n', w,
            _pick(dir, w, fr: true, cards: [_frLong, _die, _spell]),
            scale: 1.3);
      }
    }
  });
}
