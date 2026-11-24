// PICTURES ONLY (UX_SHOTS=<folder>): Tower briefs 6 (coins: reroll, banish, the
// merchant), 7 (heat 1-3) and 8 (daily climb, best-run record) in the ink and
// tarot look, at 360 and 320, English and French, plus 320 FR at 1.3x text.
// Rules and numbers are Core's (docs/simulation/tower-briefs-6-7-8-spec.md,
// claude/core-tower-spec678); the words are Narrative's
// (docs/narrative/drafts/tower-offers-and-briefs.md). What is a guess of the
// look is marked "guess" on the sheets.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

typedef _T = (String, String); // EN, FR

const _coin = Color(0xFFD9B44A);

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.25, color: c);
TextStyle _sys(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.system, fontSize: s, height: 1.1, color: c);

class _L {
  const _L(this.fr);
  final bool fr;
  String t(_T v) => fr ? v.$2 : v.$1;
  String n(_T v, Map<String, Object> m) {
    var s = t(v);
    m.forEach((k, x) => s = s.replaceAll('{$k}', '$x'));
    return s;
  }
}

// Narrative's strings (claude/narrative-drafts).
const _wallet = ('Coins to spend: {n}', 'Pièces à dépenser : {n}');
const _gained = ('+{n} coins', '+{n} pièces');
const _lost = ('Coins left: {n} (lost)', 'Pièces restantes : {n} (perdues)');
const _reroll = ('Reroll · {n}', 'Retirer · {n}');
const _banish = ('Banish', 'Bannir');
const _banishConfirm = (
  'Banish this card for good? It will not return this climb.',
  'Bannir cette carte ? Elle ne reviendra pas durant cette ascension.'
);
const _boon = ('A boon', 'Une faveur');
const _boonText = (
  'A skill, a die or a spell, your pick of three.',
  'Une compétence, un dé ou un sort, au choix parmi trois.'
);
const _salveLine = (
  'A salve, still warm from the candle. Coins only; the Tower takes no silver.',
  'Un onguent encore tiède de la chandelle. Des pièces seulement ; la Tour ne prend pas l’argent.'
);
const _potionLine = (
  'Potions, three to a tray. Take two and the third is for the next climber.',
  'Des potions, trois par plateau. Prenez-en deux, la troisième est pour le prochain grimpeur.'
);
const _boonLine = (
  'Something stronger, if the purse allows. Choose with care: he will not take it back.',
  'Quelque chose de plus fort, si la bourse le permet. Choisissez bien : il ne le reprendra pas.'
);
const _sworn = (
  'You wear their colours; the price is halved, and he does not look up.',
  'Vous portez leurs couleurs : le prix est divisé par deux, et il ne lève pas les yeux.'
);
const _heatNames = [
  ('The plain climb', 'L’ascension simple'),
  ('Embers', 'Braises'),
  ('Flame', 'Flamme'),
  ('Pyre', 'Bûcher'),
];
const _heatLines = [
  ('Today’s climb.', 'L’ascension d’aujourd’hui.'),
  (
    'Foes hit a little harder; marks come a little faster.',
    'Les adversaires frappent un peu plus fort ; les marques tombent un peu plus vite.'
  ),
  (
    'Foes hit harder; marks come faster still.',
    'Les adversaires frappent plus fort ; les marques tombent encore plus vite.'
  ),
  (
    'Foes hit hardest; marks pay in full.',
    'Les adversaires frappent au plus fort ; les marques paient plein tarif.'
  ),
];
const _heatLocked = (
  'Win the top at {heat} to open',
  'Gagnez au sommet (niveau {heat}) pour ouvrir'
);
const _heatMarks = ('Marks +{n}%', 'Marques +{n} %');
const _heatOpened = ('{heat} is open', 'Niveau ouvert : {heat}');
const _dailyButton = ('Daily climb', 'Ascension du jour');
const _dailyEntry = (
  'Today’s climb: the same stairs for everyone.',
  'L’ascension du jour : les mêmes escaliers pour tout le monde.'
);
const _dailyDone = (
  'Today’s climb is done. The stairs reset at dawn.',
  'L’ascension du jour est faite. Les escaliers se rebâtissent à l’aube.'
);
const _dailyOne = (
  'One attempt a day. Leaving counts.',
  'Une tentative par jour. Partir compte.'
);
const _dailyHero =
    ('Today: {race} {profession}', 'Aujourd’hui : {race} {profession}');
const _dailyChip = ('Daily', 'Du jour');
const _recordNew = ('New record', 'Nouveau record');
const _recordNone = ('No climb recorded yet.', 'Aucune ascension enregistrée.');
const _recordBest = ('Highest floor', 'Étage le plus haut');
const _recordDaily = ('Best daily climb', 'Meilleure ascension du jour');

// ---- small pieces ----------------------------------------------------------

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

Widget _flames(int n, {double size = 14, Color? color}) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < n; i++)
        Icon(Icons.local_fire_department,
            size: size, color: color ?? const Color(0xFFE08A3C)),
    ]);

Widget _chip(Widget leading, String text, {Color line = inkPaper}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: inkBlack, border: Border.all(color: line, width: 1.2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        leading,
        const SizedBox(width: 4),
        Text(text, style: _prose(12, inkPaper)),
      ]),
    );

Widget _panelTitle(String a, [String? b]) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a, style: _display(18, inkPaper)),
        if (b != null) Text(b, style: _prose(11.5, inkGrey)),
      ]),
    );

Widget _guess(String s) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('guess: $s', style: _prose(10.5, const Color(0xFFE0A860))));

// The floor header: title, then what the run carries in chips.
Widget _header(_L l, {bool coins = true, int heat = 0, bool daily = false}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.fr ? 'LES ESCALIERS BAS' : 'THE LOWER STAIRS',
          style: _sys(10, inkGrey).copyWith(letterSpacing: 1.4)),
      Text(l.fr ? 'Étage 7 sur 30' : 'Floor 7 of 30',
          style: _display(26, inkPaper)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 4, children: [
        if (coins) _chip(_coinDot(13), '12', line: _coin),
        if (heat > 0)
          _chip(_flames(1, size: 13), '$heat', line: const Color(0xFFE08A3C)),
        if (daily)
          _chip(const Icon(Icons.today, size: 13, color: inkPaper),
              l.t(_dailyChip)),
      ]),
    ]);

// ---- brief 6 ---------------------------------------------------------------

Widget _spoils(_L l) => Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.fr ? 'Butin' : 'Spoils', style: _display(16, inkPaper)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.shield_outlined, size: 18, color: inkGrey),
          const SizedBox(width: 6),
          Text(l.fr ? 'Cotte de mailles' : 'Chain Shirt',
              style: _prose(13, inkPaper)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          _coinDot(16),
          const SizedBox(width: 6),
          Text(l.n(_gained, {'n': 2}),
              style: _prose(13, _coin).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          InkTag(l.fr ? 'Élite +1' : 'Elite +1'),
        ]),
      ]),
    );

Widget _table(_L l, double w, {bool poor = false, bool confirm = false}) {
  final cardW = (w - 24 - 16) / 3;
  Widget banish(Widget card, {bool show = true}) =>
      Stack(clipBehavior: Clip.none, children: [
        card,
        if (show)
          Positioned(
            right: 6,
            bottom: 14,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: inkBlack,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: poor ? inkSlate : inkPaper, width: 1.4)),
              child: Icon(Icons.close,
                  size: 14, color: poor ? inkSlate : inkPaper),
            ),
          ),
      ]);
  Widget tag4(bool shown) => shown
      ? Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('${l.t(_banish)} · 4',
              style: _prose(10.5, poor ? inkSlate : inkGrey)))
      : const SizedBox(height: 15);
  Widget card(String kind, String name, String text, String art, int rarity,
          {bool held = false}) =>
      Column(children: [
        banish(TowerTarotCard(
          width: cardW,
          kind: kind,
          name: name,
          text: text,
          vignette: 'assets/visuals/tower_cards/$art.png',
          icon: const SizedBox(width: 22, height: 22),
          rarity: rarity,
          held: held,
          dim: !held,
        )),
        tag4(true),
      ]);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      card(
          l.fr ? 'Compétence' : 'Skill',
          l.fr ? 'Visée assurée' : 'Steady Aim',
          l.fr ? 'Une seconde de plus.' : 'Take the extra second.',
          'skill_none',
          2),
      const SizedBox(width: 8),
      card(l.fr ? 'Dé' : 'Die', l.fr ? 'Dé du chœur' : 'Chorus Die', 'd12',
          'die', 0,
          held: true),
      const SizedBox(width: 8),
      card(
          l.fr ? 'Sort' : 'Spell',
          l.fr ? 'Serrez les rangs' : 'Rally the Line',
          l.fr ? 'Le groupe resserre les rangs.' : 'The party closes ranks.',
          'spell_heal',
          1),
    ]),
    const SizedBox(height: 8),
    if (confirm)
      Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
            color: inkBlack, border: Border.all(color: inkPaper, width: 1.2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t(_banishConfirm), style: _prose(13, inkPaper)),
          const SizedBox(height: 10),
          Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                InkButton(
                    label: l.fr ? 'Garder' : 'Keep',
                    height: 36,
                    onPressed: () {}),
                InkButton(
                    label: '${l.t(_banish)} · 4',
                    primary: true,
                    height: 36,
                    onPressed: () {}),
              ]),
        ]),
      )
    else
      Row(children: [
        Expanded(
            child: Wrap(spacing: 10, runSpacing: 8, children: [
          InkButton(
              label: l.n(_reroll, {'n': 3}),
              height: 38,
              onPressed: poor ? null : () {}),
          if (poor)
            Text(l.fr ? 'Pas assez de pièces.' : 'Not enough coins.',
                style: _prose(11.5, inkGrey)),
        ])),
        InkButton(
            label: l.fr ? 'Prendre' : 'Take',
            primary: true,
            height: 38,
            onPressed: () {}),
      ]),
    if (!confirm)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
            l.fr
                ? 'Retirer coûte 3, puis 5, puis 7… · Bannir : 4, cinq par ascension.'
                : 'Reroll costs 3, then 5, then 7… · Banish: 4, at most 5 a climb.',
            style: _prose(10.5, inkGrey)),
      ),
  ]);
}

Widget _stall(_L l, {bool sworn = false}) {
  Widget line(String name, String body, int price) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: _display(15, inkOnPaper)),
              Text(body, style: _prose(11.5, const Color(0xFF3A3F48))),
            ]),
          ),
          const SizedBox(width: 8),
          InkButton(
              label: '${sworn ? (price / 2).ceil() : price}',
              onPaper: true,
              height: 32,
              onPressed: () {}),
        ]),
      );
  return InkPaperPanel(
    title: l.fr ? 'Le marchand' : 'The merchant',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _coinDot(16),
        const SizedBox(width: 6),
        Text(l.n(_wallet, {'n': 16}),
            style:
                _prose(13, inkOnPaper).copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 8),
      line(l.fr ? 'Onguent' : 'Salve', l.t(_salveLine), 4),
      line(l.fr ? 'Potions' : 'Potions', l.t(_potionLine), 5),
      line(l.t(_boon), '${l.t(_boonText)} ${l.t(_boonLine)}', 10),
      if (sworn)
        Text(l.t(_sworn),
            style: _prose(11, const Color(0xFF3A3F48))
                .copyWith(fontStyle: FontStyle.italic)),
    ]),
  );
}

Widget _end6(_L l) => Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.fr ? 'Vous êtes tombé à l’étage 12' : 'You fell on floor 12',
            style: _display(20, inkPaper)),
        const SizedBox(height: 6),
        Text(l.fr ? '34 marques de cendre' : '34 Ash Marks',
            style: _sys(15, inkPaper)),
        const SizedBox(height: 2),
        Text(l.n(_lost, {'n': 9}), style: _prose(10.5, inkGrey)),
      ]),
    );

Widget _brief6(double w, bool fr) {
  final l = _L(fr);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(fr ? 'Brief 6 · pièces' : 'Brief 6 · coins'),
    _panelTitle(
        fr ? '1 · L’en-tête de l’étage' : '1 · The floor header',
        fr
            ? 'Une pastille de pièces à côté de la santé et du sac'
            : 'A coin chip beside health and the bag'),
    _header(l),
    _guess(fr
        ? 'pastille or, en pièces de la run seulement'
        : 'the chip in gold, in-run coins only'),
    _panelTitle(fr ? '2 · Le butin' : '2 · The spoils',
        fr ? 'Une ligne avec le coffre' : 'One line with the chest'),
    _spoils(l),
    _panelTitle(
        fr ? '3 · Retirer et bannir' : '3 · Reroll and banish',
        fr
            ? 'Prix affichés ; × sur chaque carte de faveur'
            : 'Prices shown; a × on each boon card'),
    _table(l, w),
    _panelTitle(fr ? '3b · Trop pauvre' : '3b · Too poor', ''),
    _table(l, w, poor: true),
    _panelTitle(fr ? '3c · Bannir : confirmer' : '3c · Banish: confirm', ''),
    _table(l, w, confirm: true),
    _panelTitle(
        fr ? '4 · Le marchand' : '4 · The merchant',
        fr
            ? 'Tout en pièces ; troisième ligne : une faveur à 10'
            : 'Everything in coins; a third line: a boon at 10'),
    _stall(l),
    const SizedBox(height: 14),
    _stall(l, sworn: true),
    _panelTitle(fr ? '5 · La fin' : '5 · The end',
        fr ? 'Les pièces ne sont pas des marques' : 'Coins are not marks'),
    _end6(l),
  ]);
}

// ---- brief 7 ---------------------------------------------------------------

Widget _heatRow(_L l, int i, {required bool open, bool selected = false}) {
  final locked = !open;
  final text = locked ? inkGrey : inkPaper;
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
        color: inkBlack,
        border: Border.all(
            color: selected ? inkRed : (locked ? inkSlate : inkPaper),
            width: selected ? 2 : 1.2)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 52,
          child: i == 0
              ? Text('0', style: _sys(14, text))
              : locked
                  ? const Icon(Icons.lock_outline, size: 16, color: inkGrey)
                  : _flames(i, size: 15)),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t(_heatNames[i]), style: _display(15, text)),
          Text(
              locked
                  ? l.n(_heatLocked, {'heat': l.t(_heatNames[i - 1])})
                  : l.t(_heatLines[i]),
              style: _prose(11.5, locked ? inkGrey : const Color(0xFFC8CDD0))),
          if (i > 0)
            Text(l.n(_heatMarks, {'n': 25 * i}),
                style: _prose(11, locked ? inkSlate : _coin)
                    .copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    ]),
  );
}

Widget _heatPicker(_L l, {required int open, required int selected}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < 4; i++)
        _heatRow(l, i, open: i <= open, selected: i == selected),
    ]);

Widget _brief7(double w, bool fr) {
  final l = _L(fr);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(fr ? 'Brief 7 · niveaux de chaleur' : 'Brief 7 · heat'),
    _panelTitle(
        fr ? '1 · À l’écran de départ' : '1 · On the start screen',
        fr
            ? 'Sous la vocation, avant Grimper. Caché tant que le niveau 1 est fermé.'
            : 'Under the calling, before Climb. Hidden until heat 1 opens.'),
    Text(fr ? 'Chaleur' : 'Heat',
        style: _sys(10, inkGrey).copyWith(letterSpacing: 1.4)),
    const SizedBox(height: 4),
    Text(
        fr
            ? 'Le niveau 1 vient de s’ouvrir (le plus haut ouvert est choisi) :'
            : 'Heat 1 has just opened (the highest open is picked):',
        style: _prose(10.5, inkGrey)),
    const SizedBox(height: 4),
    _heatPicker(l, open: 1, selected: 1),
    const SizedBox(height: 8),
    Text(
        fr
            ? 'Les trois ouverts, un niveau plus bas choisi :'
            : 'All three open, a lower one picked:',
        style: _prose(10.5, inkGrey)),
    const SizedBox(height: 4),
    _heatPicker(l, open: 3, selected: 2),
    _guess(fr
        ? 'une rangée par niveau (320 px : pas de grille)'
        : 'one row a heat (no grid at 320 px)'),
    _panelTitle(
        fr ? '2 · Dans l’étage' : '2 · On the floor',
        fr
            ? 'Une pastille flamme + le niveau, pendant toute la run ; rien au niveau 0'
            : 'A flame chip with its number for the whole run; none at heat 0'),
    _header(l, coins: false, heat: 2),
    _panelTitle(fr ? '3 · La fin' : '3 · The end', ''),
    Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fr ? 'Le sommet est à vous' : 'The top is yours',
            style: _display(20, inkPaper)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          Text(fr ? '74 marques de cendre' : '74 Ash Marks',
              style:
                  _prose(15, inkPaper).copyWith(fontWeight: FontWeight.w700)),
          _chip(_flames(2, size: 12),
              fr ? 'Niveau 2 · ×1,5 marques' : 'Heat 2 · ×1.5 marks',
              line: const Color(0xFFE08A3C)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _flames(3, size: 15),
          const SizedBox(width: 6),
          Text(l.n(_heatOpened, {'heat': l.t(_heatNames[3])}),
              style: _prose(13, const Color(0xFFE08A3C))
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
      ]),
    ),
    _guess(fr
        ? 'la flamme en orange, hors du rouge sémantique'
        : 'the flame in orange, outside the semantic red'),
  ]);
}

// ---- brief 8 ---------------------------------------------------------------

Widget _record(_L l, {bool none = false}) => InkPaperPanel(
      title: 'Records',
      child: none
          ? Text(l.t(_recordNone),
              style: _prose(13, const Color(0xFF3A3F48))
                  .copyWith(fontStyle: FontStyle.italic))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.t(_recordBest).toUpperCase(),
                  style: _sys(9.5, const Color(0xFF5A6068))
                      .copyWith(letterSpacing: 1.2)),
              Row(children: [
                Text(l.fr ? 'Étage 21' : 'Floor 21',
                    style: _display(22, inkOnPaper)),
                const SizedBox(width: 8),
                _flames(2, size: 15, color: const Color(0xFFB4601C)),
              ]),
              Text(
                  l.fr
                      ? 'Humain mage · Pénitents · 41 min · 22 nov.'
                      : 'Human mage · Penitents · 41 min · 22 Nov',
                  style: _prose(12, const Color(0xFF3A3F48))),
              const SizedBox(height: 10),
              Text(l.t(_recordDaily).toUpperCase(),
                  style: _sys(9.5, const Color(0xFF5A6068))
                      .copyWith(letterSpacing: 1.2)),
              Row(children: [
                Text(l.fr ? 'Étage 17' : 'Floor 17',
                    style: _display(18, inkOnPaper)),
                const SizedBox(width: 8),
                Text(l.fr ? '24 min · 19 nov.' : '24 min · 19 Nov',
                    style: _prose(12, const Color(0xFF3A3F48))),
              ]),
            ]),
    );

Widget _dailyPanel(_L l, {bool done = false}) => InkPaperPanel(
      title: l.t(_dailyButton),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.fr ? '24 novembre 2026' : '24 November 2026',
            style: _sys(11, const Color(0xFF5A6068))),
        const SizedBox(height: 4),
        Text(done ? l.t(_dailyDone) : l.t(_dailyEntry),
            style: _prose(13, inkOnPaper)),
        const SizedBox(height: 6),
        Text(
            l.n(_dailyHero, {
              'race': l.fr ? 'Elfe' : 'Elf',
              'profession': l.fr ? 'voleur' : 'rogue'
            }),
            style: _display(15, inkOnPaper)),
        if (done)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l.fr ? 'Étage 17 · 24 min' : 'Floor 17 · 24 min',
                style: _prose(12.5, inkOnPaper)
                    .copyWith(fontWeight: FontWeight.w700)),
          )
        else ...[
          Text(l.t(_dailyOne), style: _prose(11.5, const Color(0xFF3A3F48))),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: InkButton(
                  label: l.t(_dailyButton),
                  primary: true,
                  height: 36,
                  onPressed: () {})),
        ],
      ]),
    );

Widget _brief8(double w, bool fr) {
  final l = _L(fr);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(fr
        ? 'Brief 8 · ascension du jour, records'
        : 'Brief 8 · daily, records'),
    _panelTitle(
        fr ? '1 · L’écran de départ' : '1 · The start screen',
        fr
            ? 'Un panneau du jour à côté de Grimper ; la carte des records remplace « Meilleur étage »'
            : 'A daily panel beside Climb; the record card replaces “Best floor”'),
    _dailyPanel(l),
    const SizedBox(height: 18),
    _record(l),
    _panelTitle(
        fr
            ? '1b · Le jour joué, sans record'
            : '1b · Played, and no record yet',
        ''),
    _dailyPanel(l, done: true),
    const SizedBox(height: 18),
    _record(l, none: true),
    _guess(fr
        ? 'le héros du jour montré avant de choisir'
        : 'the day’s hero shown before choosing'),
    _panelTitle(
        fr ? '2 · Dans l’étage' : '2 · On the floor',
        fr
            ? 'Une pastille « Du jour » pendant l’ascension du jour'
            : 'A “Daily” chip during the daily'),
    _header(l, coins: true, daily: true),
    _panelTitle(
        fr ? '3 · La fin : nouveau record' : '3 · The end: new record', ''),
    Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(
                  fr ? 'Vous êtes tombé à l’étage 23' : 'You fell on floor 23',
                  style: _display(20, inkPaper))),
          Image.asset('assets/visuals/tower_cards/stamp_new.png', height: 34),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: inkRed,
              child: Text(l.t(_recordNew), style: _sys(11, inkPaper))),
          const SizedBox(width: 8),
          Text(fr ? 'Étage 21' : 'Floor 21',
              style: _prose(12, inkGrey)
                  .copyWith(decoration: TextDecoration.lineThrough)),
        ]),
      ]),
    ),
    _guess(fr
        ? 'le tampon « new » d’Art déjà dans le jeu'
        : 'Art’s “new” stamp, already in the game'),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> sheet(WidgetTester t, String name, double w, Widget body,
      {double scale = 1.0}) async {
    final key = GlobalKey();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(w, 3600);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: MediaQuery(
        data: MediaQueryData(
            size: Size(w, 3600), textScaler: TextScaler.linear(scale)),
        child: Material(
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
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [body]),
                ),
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

  testWidgets('Tower briefs 6, 7, 8', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final (n, builder) in [
      ('6-coins', _brief6),
      ('7-heat', _brief7),
      ('8-daily', _brief8),
    ]) {
      for (final w in [360.0, 320.0]) {
        for (final fr in [false, true]) {
          await sheet(
              t, '$n-${w.toInt()}-${fr ? 'fr' : 'en'}', w, builder(w, fr));
        }
      }
      await sheet(t, '$n-320-fr-1.3x', 320, builder(320, true), scale: 1.3);
    }
  });
}
