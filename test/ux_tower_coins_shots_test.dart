// PICTURES ONLY (UX_SHOTS=<folder>): Tower coins and the marks shop in the ink
// (Core's docs/proposals/tower-coins.md on claude/core-tower-designs): the coin
// chip and buttons, the stall with its boon at 15, the marks screen as three
// tabs (Unlocks / Perks / Looks), the two perk slots on the door and the end
// tally. 360 and 412, English and French. The wording of perks is Core's names
// with my one-line placeholders for Narrative ("guess"); perk icons are Art's
// to draw (a neutral square stands in).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

const _nb = ' ';
const _coin = Color(0xFFD9B44A);
const _mark = Color(0xFFC9C6BE);

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.25, color: c);
Widget _coinDot(double s) => Container(
    width: s,
    height: s,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _coin,
        border: Border.all(color: inkBlack, width: 1.2)),
    child: Container(
        width: s * 0.45,
        height: s * 0.45,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8C6D1E), width: 1.2))));

Widget _markDot(double s) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
        color: _mark,
        border: Border.all(color: inkBlack, width: 1.2),
        borderRadius: BorderRadius.circular(2)));

class _L {
  const _L(this.fr);
  final bool fr;
  String t(String en, String frs) => fr ? frs : en;
}

// (en name, fr name, en effect, fr effect, price)
const _perks = [
  (
    'Purse',
    'Bourse',
    'Start the climb with 5 coins.',
    'Commencez l’ascension avec 5 pièces.',
    30
  ),
  (
    'Deep pockets',
    'Grandes poches',
    'The bag holds 6 potions, not 5.',
    'Le sac contient 6 potions, pas 5.',
    30
  ),
  (
    'Early word',
    'Parole donnée',
    'The late oath comes from floor 12, not 15.',
    'Le serment tardif vient dès l’étage 12, pas 15.',
    35
  ),
  (
    'Old friend',
    'Vieil ami',
    '+2 standing with one clan of your pool at the start.',
    '+2 d’estime auprès d’un clan de votre cercle au départ.',
    40
  ),
  (
    'Second wind',
    'Second souffle',
    '15%$_nb' 'max health back after a warden or boss.',
    '15$_nb% de santé max rendus après un gardien ou un boss.',
    40
  ),
  (
    'Keen eye',
    'Œil vif',
    'The floor-5 boon is one rarity step up.',
    'La faveur de l’étage 5 monte d’un cran de rareté.',
    45
  ),
  (
    'Free hand',
    'Main libre',
    'The first reroll of each climb is free.',
    'Le premier retirage de chaque ascension est gratuit.',
    45
  ),
  (
    'Fourth card',
    'Quatrième carte',
    'The first two boon tables show a fourth card.',
    'Les deux premières tables de faveurs montrent une quatrième carte.',
    60
  ),
];

Widget _title(String a, [String? b]) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a, style: _display(18, inkPaper)),
        if (b != null) Text(b, style: _prose(11.5, inkGrey)),
      ]),
    );

Widget _guess(String s) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('guess: $s', style: _prose(10.5, const Color(0xFFE0A860))));

Widget _chip(Widget leading, String text, Color line) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: inkBlack, border: Border.all(color: line, width: 1.2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        leading,
        const SizedBox(width: 4),
        Text(text, style: _prose(12, inkPaper)),
      ]),
    );

Widget _tabs(_L l, int on) => Row(children: [
      for (final (i, label) in [
        l.t('Unlocks', 'Déblocages'),
        l.t('Perks', 'Atouts'),
        l.t('Looks', 'Parures'),
      ].indexed)
        Expanded(
          child: Container(
            height: 34,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: i == on ? inkPaper : inkBlack,
                border: Border.all(color: i == on ? inkPaper : inkSlate)),
            child: Text(label,
                style: _display(14, i == on ? inkOnPaper : inkPaper)),
          ),
        ),
    ]);

Widget _perkRow(_L l, int i,
    {required bool owned, int? slot, required int marks}) {
  final p = _perks[i];
  final afford = marks >= p.$5;
  final worn = slot != null;
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    decoration: BoxDecoration(
        color: inkBlack,
        border: Border.all(
            color: worn ? _mark : (owned || afford ? inkPaper : inkSlate),
            width: worn ? 2 : 1.2)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          color: inkDark,
          child: Text(p.$1[0],
              style: _display(18, owned || afford ? inkPaper : inkSlate))),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t(p.$1, p.$2),
              style: _display(14, owned || afford ? inkPaper : inkGrey)),
          Text(l.t(p.$3, p.$4),
              style: _prose(
                  11.5, owned || afford ? const Color(0xFFC8CDD0) : inkGrey)),
        ]),
      ),
      const SizedBox(width: 6),
      if (owned)
        _chip(
            const SizedBox.shrink(),
            worn
                ? l.t('Worn ${slot + 1}', 'Porté ${slot + 1}')
                : l.t('Owned', 'Acquis'),
            worn ? _mark : inkSlate)
      else
        _chip(_markDot(11), '${p.$5}', afford ? _mark : inkSlate),
    ]),
  );
}

Widget _marksScreen(_L l, int tab) {
  const marks = 214;
  return Container(
    padding: const EdgeInsets.all(10),
    color: inkDeep,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _markDot(16),
        const SizedBox(width: 6),
        Text(l.t('$marks Ash Marks', '$marks marques de cendre'),
            style: _prose(15, inkPaper).copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      _tabs(l, tab),
      const SizedBox(height: 10),
      if (tab == 0)
        Text(
            l.t('Every unlock is owned: the tree is full. Marks now buy perks and looks.',
                'Tous les déblocages sont acquis : l’arbre est plein. Les marques achètent désormais atouts et parures.'),
            style: _prose(12, inkGrey))
      else if (tab == 1) ...[
        Text(
            l.t('Two perks are worn on a climb, chosen on the door.',
                'Deux atouts sont portés par ascension, choisis à la porte.'),
            style: _prose(11.5, inkGrey)),
        const SizedBox(height: 6),
        _perkRow(l, 0, owned: true, slot: 0, marks: marks),
        _perkRow(l, 2, owned: true, slot: 1, marks: marks),
        _perkRow(l, 1, owned: true, marks: marks),
        _perkRow(l, 3, owned: false, marks: marks),
        _perkRow(l, 6, owned: false, marks: marks),
        _perkRow(l, 7, owned: false, marks: marks),
        Text(
            l.t(
                'Next perk: Fourth card, 60 marks (needs 12 more less than… )'
                    .replaceAll(' (needs 12 more less than… )', ''),
                'Prochain atout : Quatrième carte, 60 marques'),
            style: _prose(11, inkGrey)),
      ] else ...[
        for (final (i, n) in [
          (0, l.t('Moth trim', 'Bordure de mites')),
          (1, l.t('Stitch trim', 'Bordure cousue')),
          (2, l.t('Brass trim', 'Bordure de laiton')),
          (3, l.t('Bone trim', 'Bordure d’os')),
          (4, l.t('Lamp trim', 'Bordure de lampe')),
        ])
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: inkBlack,
                border: Border.all(
                    color: [
                      inkPaper,
                      inkPaper,
                      inkSlate,
                      inkSlate,
                      inkSlate
                    ][i],
                    width: i < 2 ? 2 : 1.2)),
            child: Row(children: [
              Container(width: 54, height: 22, color: inkDark),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      Text(n, style: _display(14, i < 2 ? inkPaper : inkGrey))),
              _chip(
                  i < 2 ? const SizedBox.shrink() : _markDot(11),
                  i < 2
                      ? (i == 0
                          ? l.t('Worn', 'Portée')
                          : l.t('Owned', 'Acquise'))
                      : '10',
                  i < 2 ? _mark : inkSlate),
            ]),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: inkBlack,
              border: Border.all(color: const Color(0xFFC9C6BE), width: 2)),
          child: Row(children: [
            Container(width: 54, height: 22, color: const Color(0xFFC9C6BE)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    l.t('Ash trim: earned at Ash, never sold',
                        'Bordure de cendre : gagnée à Cendre, jamais vendue'),
                    style: _display(13, const Color(0xFFC9C6BE)))),
          ]),
        ),
      ],
    ]),
  );
}

Widget _door(_L l) => Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.t('Perks for this climb', 'Atouts de cette ascension'),
            style: _display(16, inkPaper)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _slot(l, 0, filled: l.t('Purse', 'Bourse'))),
          const SizedBox(width: 8),
          Expanded(child: _slot(l, 1)),
        ]),
        const SizedBox(height: 6),
        Text(
            l.t('Heat: Flame (3) · marks ×1.75',
                'Chaleur : Flamme (3) · marques ×1,75'),
            style: _prose(12, inkGrey)),
      ]),
    );

Widget _slot(_L l, int i, {String? filled}) => Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
          color: inkDeep,
          border: Border.all(
              color: filled == null ? inkSlate : _mark,
              width: filled == null ? 1.2 : 2)),
      child: Text(
          filled ?? l.t('Slot ${i + 1}: choose', 'Case ${i + 1} : choisir'),
          style: filled == null ? _prose(12, inkGrey) : _display(14, inkPaper)),
    );

Widget _tally(_L l) {
  Widget line(String a, String b, {bool bold = false, Color? c}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Expanded(
              child: Text(a,
                  style: _prose(12.5, c ?? inkGrey)
                      .copyWith(fontWeight: bold ? FontWeight.w700 : null))),
          Text(b,
              style: _prose(12.5, c ?? inkPaper)
                  .copyWith(fontWeight: bold ? FontWeight.w700 : null)),
        ]),
      );
  return Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    color: inkBlack,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('You fell on floor 23', 'Vous êtes tombé à l’étage 23'),
          style: _display(20, inkPaper)),
      const SizedBox(height: 8),
      line(l.t('Floors', 'Étages'), '23'),
      line(l.t('Wardens', 'Gardiens'), '4'),
      line(l.t('Bosses', 'Boss'), '2'),
      line(l.t('Refusals', 'Refus'), '3'),
      line(l.t('Heat: Flame ×1.75', 'Chaleur : Flamme ×1,75'), '+31'),
      line(l.t('First win at this heat', 'Première victoire à ce niveau'),
          '+20'),
      Container(
          height: 1,
          color: inkSlate,
          margin: const EdgeInsets.symmetric(vertical: 4)),
      line(l.t('Ash Marks banked', 'Marques de cendre gagnées'), '88',
          bold: true),
      const SizedBox(height: 6),
      Row(children: [
        _coinDot(14),
        const SizedBox(width: 6),
        Text(l.t('Coins left: 9 (lost)', 'Pièces restantes : 9 (perdues)'),
            style: _prose(11, inkGrey)),
      ]),
      const SizedBox(height: 6),
      Text(
          l.t('Next perk: Fourth card, 12 more marks',
              'Prochain atout : Quatrième carte, 12 marques de plus'),
          style: _prose(12, _mark).copyWith(fontWeight: FontWeight.w700)),
    ]),
  );
}

Widget _stall(_L l) => InkPaperPanel(
      title: l.t('The merchant', 'Le marchand'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _coinDot(16),
          const SizedBox(width: 6),
          Text(l.t('Coins to spend: 16', 'Pièces à dépenser : 16'),
              style:
                  _prose(13, inkOnPaper).copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        for (final (a, b, _, p) in [
          (l.t('Salve', 'Onguent'), l.t('Heals 40%.', 'Rend 40$_nb%.'), '', 4),
          (
            l.t('Potions', 'Potions'),
            l.t('Two for the bag.', 'Deux pour le sac.'),
            '',
            5
          ),
          (
            l.t('A boon', 'Une faveur'),
            l.t('A skill, a die or a spell, your pick of three.',
                'Une compétence, un dé ou un sort, au choix parmi trois.'),
            '',
            15
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a, style: _display(15, inkOnPaper)),
                      Text(b, style: _prose(11.5, const Color(0xFF3A3F48))),
                    ]),
              ),
              const SizedBox(width: 8),
              InkButton(
                  label: '$p',
                  onPaper: true,
                  height: 32,
                  onPressed: p > 16 ? null : () {}),
            ]),
          ),
      ]),
    );

Widget _sheet(double w, bool fr) {
  final l = _L(fr);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(l.t('Coins and the marks shop', 'Pièces et boutique de marques')),
    _title(
        l.t('1 · The chip and the buttons', '1 · La pastille et les boutons'),
        l.t('The run\'s coins, beside the health',
            'Les pièces de la run, près de la santé')),
    Wrap(spacing: 6, runSpacing: 4, children: [
      _chip(_coinDot(13), '12', _coin),
    ]),
    const SizedBox(height: 10),
    Wrap(spacing: 10, runSpacing: 8, children: [
      InkButton(
          label: l.t('Reroll · 3', 'Retirer · 3'),
          height: 36,
          onPressed: () {}),
      InkButton(
          label: l.t('Banish · 4', 'Bannir · 4'), height: 36, onPressed: () {}),
    ]),
    Text(
        l.t('Reroll 3, then 5, then 7… · Banish 4, five a climb.',
            'Retirer : 3, puis 5, puis 7… · Bannir : 4, cinq par ascension.'),
        style: _prose(10.5, inkGrey)),
    _guess(l.t('the card table is in the earlier sheet (tower-briefs-678)',
        'la table de cartes est dans la planche précédente (tower-briefs-678)')),
    _title(
        l.t('2 · The stall, the boon at 15', '2 · L’étal, la faveur à 15'),
        l
            .t('Coins only; 15 is greyed while the purse holds 16? No: affordable.',
                'Pièces seulement')
            .replaceAll(
                '; 15 is greyed while the purse holds 16? No: affordable.',
                '')),
    _stall(l),
    _title(
        l.t('3 · The marks screen, three tabs',
            '3 · L’écran des marques, trois onglets'),
        l.t('Unlocks | Perks | Looks', 'Déblocages | Atouts | Parures')),
    _marksScreen(l, 1),
    const SizedBox(height: 14),
    _marksScreen(l, 2),
    const SizedBox(height: 14),
    _marksScreen(l, 0),
    _guess(l.t(
        'perk icons: a letter stands in until Art draws eight; the perk lines are mine, for Narrative',
        'icônes des atouts : une lettre en attendant les huit d’Art ; lignes de moi, pour Narrative')),
    _title(
        l.t('4 · The door: two perk slots',
            '4 · La porte : deux cases d’atouts'),
        l.t('Beside the Heat picker', 'À côté du choix de chaleur')),
    _door(l),
    _title(
        l.t('5 · The end tally', '5 · Le bilan de fin'),
        l.t('Floors, wardens, bosses, refusals, heat, bonus, banked, coins lost, next perk',
            'Étages, gardiens, boss, refus, chaleur, bonus, gagné, pièces perdues, prochain atout')),
    _tally(l),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('Tower coins and the marks shop', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [412.0, 360.0]) {
      for (final fr in [false, true]) {
        final key = GlobalKey();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(w, 5200);
        await t.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: InkFonts.prose),
          home: Material(
            color: inkDeep,
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: Container(
                    width: w,
                    color: inkDeep,
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                    child: _sheet(w, fr),
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
        expect(t.takeException(), isNull, reason: '$w $fr');
        await t.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/coins-${w.toInt()}-${fr ? 'fr' : 'en'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        await t.pumpWidget(const SizedBox());
      }
    }
  });
}
