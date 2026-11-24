// PROPOSAL (pictures only, no PR): clans in the Tower, in the tarot style, at
// 360 and 320, English and French (UX_SHOTS=<folder>):
//   a  a clan offer (three clans, each a card with its gift; Accept / Refuse for a mark)
//   b  the standing with a clan rising during the run: where it shows (the
//      card, the hero sheet, a toast; the rail is shown as the option not
//      chosen)
//   c  the moment the oath unlocks, and the oath card itself
// Clan names, mottoes, colours and oath names are the game's (factions.json);
// the numbers and strings are Core's (docs/simulation/tower-clan-offers.md,
// built on claude/core-tower-clans-build): +2 for the clan, +1 allies, −1
// rivals, standing 0..6, the oath at 6; the three skill names are samples.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

// Core's strings (claude/core-tower-clans-build, lib/l10n/app_strings.dart),
// copied here because that branch is not on main yet.
const _core = <String, (String, String)>{
  'tower_kind_gift': ('Gift · {clan}', 'Don · {clan}'),
  'tower_standing_line': ('Standing {n}/{max}', 'Estime {n}/{max}'),
  'tower_standing_step': ('Standing {from} to {to}', 'Estime : {from} à {to}'),
  'tower_not_now': ('Not now (+1 mark)', 'Pas maintenant (+1 marque)'),
  'tower_one_oath': ('One oath a climb.', 'Un seul serment par ascension.'),
  'tower_offer_frame_title': (
    'The clans come to you',
    'Les clans viennent à vous'
  ),
  'tower_oath_title': (
    '{clan} offer you their oath',
    '{clan} vous offrent leur serment'
  ),
  'tower_swear': ('Swear', 'Jurer'),
  'tower_kind_oath': ('Oath', 'Serment'),
  'tower_standing_toast_dominion': (
    'The Dominion thinks more of you.',
    'Le Dominion vous estime davantage.'
  ),
  'tower_unlock_banner_dominion': (
    'A door opens: the Dominion thinks you worthy of its oath.',
    'Une porte s’ouvre\u00a0: le Dominion vous juge digne de son serment.'
  ),
  'tower_oath_line_dominion': (
    'The Dominion keeps the lamps lit and the books closed. Swear, and you are written in both.',
    'Le Dominion garde les lampes allumées et les livres fermés. Prêtez serment, et vous figurerez dans les deux.'
  ),
  'tower_standing_toast_mire': (
    'The Mire Courts think more of you.',
    'Les Cours du Marais vous estiment davantage.'
  ),
  'tower_unlock_banner_mire': (
    'A door opens: the Mire Courts think you worthy of their oath.',
    'Une porte s’ouvre\u00a0: les Cours du Marais vous jugent dignes de leur serment.'
  ),
  'tower_oath_line_mire': (
    'The Courts of the Mire forgive nothing and forget nothing. Swear, and they will remember you kindly.',
    'Les Cours du Marais ne pardonnent rien et n’oublient rien. Prêtez serment, et elles se souviendront de vous avec bonté.'
  ),
  'tower_standing_toast_penitents': (
    'The Penitents think more of you.',
    'Les Pénitents vous estiment davantage.'
  ),
  'tower_unlock_banner_penitents': (
    'A door opens: the Penitents think you worthy of their oath.',
    'Une porte s’ouvre\u00a0: les Pénitents vous jugent dignes de leur serment.'
  ),
  'tower_oath_line_penitents': (
    'The Penitents climb on their knees. Swear, and they will make room on the stair.',
    'Les Pénitents montent à genoux. Prêtez serment, et ils vous feront de la place dans l’escalier.'
  ),
};

String _t(AppLanguage l, String k) =>
    l == AppLanguage.fr ? _core[k]!.$2 : _core[k]!.$1;

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.25, color: c);
TextStyle _sys(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.system, fontSize: s, height: 1.1, color: c);

class _Clan {
  const _Clan(this.id, this.en, this.fr, this.mottoEn, this.mottoFr,
      this.colour, this.oathEn, this.oathFr);
  final String id, en, fr, mottoEn, mottoFr, oathEn, oathFr;
  final Color colour;
  String short(bool fr_) => fr_ ? fr : en;
  String motto(bool fr_) => fr_ ? mottoFr : mottoEn;
  String oath(bool fr_) => fr_ ? oathFr : oathEn;
}

List<_Clan> _clans() {
  final j = jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
      as Map<String, dynamic>;
  _Clan of(String id) {
    final v = j[id] as Map<String, dynamic>;
    final sworn = v['sworn'] as Map<String, dynamic>;
    return _Clan(
        id,
        '${v['short']}',
        '${v['short_fr']}',
        '${v['motto']}',
        '${v['motto_fr']}',
        Color(int.parse('FF${'${v['color']}'.substring(1)}', radix: 16)),
        '${sworn['name']}',
        '${sworn['name_fr']}');
  }

  // The start pool: three clans that are rivals of each other.
  return [of('dominion'), of('mire'), of('penitents')];
}

class _Gift {
  const _Gift(
      this.en, this.fr, this.textEn, this.textFr, this.rarity, this.delta);
  final String en, fr, textEn, textFr;
  final int rarity, delta;
}

const _gifts = [
  _Gift(
      'Open Door',
      'Porte ouverte',
      'Your first fight each floor opens with a free reroll.',
      'Votre premier combat de chaque étage s’ouvre sur une relance gratuite.',
      2,
      2),
  _Gift('Iron Stance', 'Posture de fer', 'Defend faces heal 3.',
      'Les faces de Défense soignent 3.', 3, 2),
  _Gift(
      'Fen Lantern',
      'Lanterne du marais',
      'Poison on you wears off a round sooner.',
      'Le poison sur vous cesse une manche plus tôt.',
      1,
      2),
];

Widget _title(String a, String b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a, style: _display(22, inkPaper)),
        Text(b, style: _prose(13, inkGrey)),
      ]),
    );

Widget _standingChip(_Clan c, int delta, bool fr) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: inkBlack, border: Border.all(color: c.colour, width: 1.2)),
      child: Text('+$delta ${c.short(fr)}', style: _sys(9, inkPaper)),
    );

// ---- a: the clan offer ------------------------------------------------------

Widget _offer(double w, bool fr, {int held = 0, bool rows = false}) {
  final clans = _clans();
  final inner = w - 24;
  final cardW = (inner - 16) / 3;
  Widget card(int i) {
    final c = clans[i], g = _gifts[i];
    final flag = ClanFlag(factionId: c.id, height: 22);
    if (rows) {
      return TowerRowCard(
        kind: fr ? 'Don' : 'Gift',
        name: fr ? g.fr : g.en,
        text: fr ? g.textFr : g.textEn,
        icon: flag,
        rarity: g.rarity,
        held: i == held,
        dim: i != held,
        footer: _standingChip(c, g.delta, fr),
      );
    }
    return TowerTarotCard(
      width: cardW,
      kind: fr ? 'Don' : 'Gift',
      name: fr ? g.fr : g.en,
      text: fr ? g.textFr : g.textEn,
      vignette: 'assets/visuals/cards/clans/backdrop_${c.id}.png',
      icon: flag,
      rarity: g.rarity,
      held: i == held,
      dim: i != held,
      footer: _standingChip(c, g.delta, fr),
    );
  }

  final c = clans[held], g = _gifts[held];
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title(_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_offer_frame_title'),
        fr ? 'Étage 5 vaincu · 3 offres' : 'Floor 5 cleared · 3 offers'),
    if (rows)
      for (var i = 0; i < 3; i++)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: card(i))
    else
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          card(i),
        ],
      ]),
    const SizedBox(height: 12),
    // The card in hand: the clan's words and what the gift moves.
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 4,
          height: 44,
          margin: const EdgeInsets.only(right: 8),
          color: c.colour),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fr ? '${g.fr} · ${c.fr}' : '${g.en} · ${c.en}',
              style: _display(15, inkPaper)),
          Text(fr ? '« ${c.motto(fr)} »' : '“${c.motto(fr)}”',
              style: _prose(12, inkGrey)),
          const SizedBox(height: 2),
          // Core's line under the card: what the gift moves, then where it stands.
          Text(
              '${[
                for (final x in clans)
                  '${x.short(fr)} ${x.id == c.id ? '+${g.delta}' : '−1'}'
              ].join(' · ')}\n${_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_standing_line').replaceAll('{n}', '0').replaceAll('{max}', '6')}',
              style:
                  _prose(11.5, inkPaper).copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    ]),
    const SizedBox(height: 12),
    Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: [
      InkButton(
          label: _t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_not_now'),
          height: 38,
          onPressed: () {}),
      InkButton(
          label: fr ? 'Accepter' : 'Accept',
          primary: true,
          height: 38,
          onPressed: () {}),
    ]),
  ]);
}

// ---- b: standing rising -----------------------------------------------------

Widget _bar(_Clan c, int standing, int max, int oathAt) => Row(children: [
      for (var i = 1; i <= max; i++) ...[
        Container(
          width: 15,
          height: 9,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: i <= standing ? c.colour : inkDark,
            border: Border.all(
                color: i == oathAt ? inkPaper : inkSlate,
                width: i == oathAt ? 1.6 : 1),
          ),
        ),
      ],
    ]);

Widget _standing(double w, bool fr) {
  final clans = _clans();
  final c = clans[0];
  Widget panel(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: _prose(9.5, inkGrey)
                  .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          child,
        ]),
      );
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(fr ? 'L’estime d’un clan monte' : 'Standing with a clan rises'),
    const SizedBox(height: 16),
    panel(
        fr
            ? '1 · Quand les cartes se ferment : un bandeau'
            : '1 · When the cards close: a toast',
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          color: inkBlack,
          child: Row(children: [
            ClanFlag(factionId: c.id, height: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  '${_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_standing_toast_dominion')} '
                  '${_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_standing_step').replaceAll('{from}', '3').replaceAll('{to}', '5')}\n'
                  '${clans[1].short(fr)} ${_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_standing_step').replaceAll('{from}', '2').replaceAll('{to}', '1')} · '
                  '${clans[2].short(fr)} ${_t(fr ? AppLanguage.fr : AppLanguage.en, 'tower_standing_step').replaceAll('{from}', '1').replaceAll('{to}', '0')}',
                  style: _prose(12.5, inkPaper)),
            ),
            Text('+2', style: _sys(14, c.colour)),
          ]),
        )),
    panel(
        fr
            ? '2 · Sur la carte (quand le clan offre) : sa barre'
            : '2 · On the card (when the clan offers): its bar',
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          color: inkBlack,
          child: Row(children: [
            ClanFlag(factionId: c.id, height: 22),
            const SizedBox(width: 10),
            _bar(c, 3, 6, 6),
            const SizedBox(width: 8),
            Text('3/6', style: _sys(11, inkPaper)),
          ]),
        )),
    panel(
        fr
            ? '3 · Sur la fiche du héros : tous les clans'
            : '3 · On the hero sheet: all clans',
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          color: inkBlack,
          child: Column(children: [
            for (final (i, cl) in clans.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  ClanFlag(factionId: cl.id, height: 20),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: w > 340 ? 68 : 64,
                      child: Text(cl.short(fr),
                          style: _prose(11.5, inkPaper),
                          overflow: TextOverflow.ellipsis)),
                  _bar(cl, [3, 2, 1][i], 6, 6),
                  const SizedBox(width: 6),
                  if (i == 0)
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        color: inkRed,
                        child: Text('+2', style: _sys(9.5, inkPaper)))
                  else
                    Text('${[3, 2, 1][i]}/6', style: _sys(10, inkGrey)),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                    width: 12,
                    height: 8,
                    decoration: BoxDecoration(
                        border: Border.all(color: inkPaper, width: 1.6))),
                const SizedBox(width: 6),
                Text(
                    fr
                        ? 'Le serment s’offre ici.'
                        : 'The oath is offered here.',
                    style: _prose(10.5, inkGrey)),
              ]),
            ),
          ]),
        )),
    panel(
        fr ? 'Pas retenu : sur le rail' : 'Not chosen: on the rail',
        Opacity(
          opacity: 0.6,
          child: Row(children: [
            Container(
                width: 34,
                padding: const EdgeInsets.all(4),
                color: inkBlack,
                child: Column(children: [
                  for (final n in ['6', '5', '4'])
                    Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        height: 14,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: n == '5' ? inkRed : inkSlate)),
                        child: Text(n, style: _sys(8, inkPaper))),
                ])),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
                    fr
                        ? 'Un point de la couleur du clan près du palier : trop de bruit sur une rampe de 40 px.'
                        : 'A dot in the clan’s colour by the notch: too much noise on a 40 px rail.',
                    style: _prose(10.5, inkGrey))),
          ]),
        )),
  ]);
}

// ---- c: the oath unlocks, and the oath card ----------------------------------

Widget _oath(double w, bool fr) {
  final c = _clans()[0];
  final inner = w - 24;
  final lang = fr ? AppLanguage.fr : AppLanguage.en;
  final cardW = (inner - 16) / 3;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // The moment: a banner unfurls over the top of the cleared floor.
    Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border(left: BorderSide(color: c.colour, width: 6))),
      child: Row(children: [
        ClanFlag(factionId: c.id, height: 38),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t(lang, 'tower_unlock_banner_${c.id}'),
                style: _display(14, inkPaper)),
            Text(
                _t(lang, 'tower_standing_line')
                    .replaceAll('{n}', '6')
                    .replaceAll('{max}', '6'),
                style: _prose(11.5, inkGrey)),
          ]),
        ),
      ]),
    ),
    const SizedBox(height: 16),
    _title(fr ? 'Étage 5 vaincu' : 'Floor 5 cleared',
        fr ? 'Choisissez une récompense' : 'Choose one reward'),
    // The oath is a fourth card, apart from the three of the floor (core's
    // plan): wide, on top, in hand.
    TowerRowCard(
      kind: _t(lang, 'tower_kind_oath'),
      name: c.oath(fr),
      text:
          '${_t(lang, 'tower_oath_line_${c.id}')} ${_t(lang, 'tower_one_oath')}',
      icon: ClanFlag(factionId: c.id, height: 28),
      rarity: 4,
      held: true,
    ),
    const SizedBox(height: 10),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      TowerTarotCard(
        width: cardW,
        kind: fr ? 'Compétence' : 'Skill',
        name: fr ? 'Visée assurée' : 'Steady Aim',
        text: fr ? 'Prenez une seconde de plus.' : 'Take the extra second.',
        vignette: 'assets/visuals/tower_cards/skill_none.png',
        icon: const SizedBox(width: 22, height: 22),
        rarity: 2,
        dim: true,
      ),
      const SizedBox(width: 8),
      TowerTarotCard(
        width: cardW,
        kind: fr ? 'Dé' : 'Die',
        name: fr ? 'Dé du chœur' : 'Chorus Die',
        text: 'd12',
        vignette: 'assets/visuals/tower_cards/die.png',
        icon: const SizedBox(width: 22, height: 22),
        dim: true,
      ),
      const SizedBox(width: 8),
      TowerTarotCard(
        width: cardW,
        kind: fr ? 'Sort' : 'Spell',
        name: fr ? 'Serrez les rangs' : 'Rally the Line',
        text: fr ? 'Le groupe resserre les rangs.' : 'The party closes ranks.',
        vignette: 'assets/visuals/tower_cards/spell_heal.png',
        icon: const SizedBox(width: 22, height: 22),
        dim: true,
      ),
    ]),
    const SizedBox(height: 12),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 4,
          height: 54,
          margin: const EdgeInsets.only(right: 8),
          color: c.colour),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              _t(lang, 'tower_oath_title')
                  .replaceAll('{clan}', fr ? 'Les ${c.fr}' : 'The ${c.en}'),
              style: _display(15, inkPaper)),
          Text(
              fr
                  ? 'Leur estime et leur dé : Le Ciseleur de sel.'
                  : 'Their standing and their die: the Salt Chisel.',
              style: _prose(12, inkPaper)),
          Text(_t(lang, 'tower_one_oath'), style: _prose(11, inkGrey)),
        ]),
      ),
    ]),
    const SizedBox(height: 12),
    Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: [
      InkButton(label: _t(lang, 'tower_not_now'), height: 38, onPressed: () {}),
      InkButton(
          label: _t(lang, 'tower_swear'),
          primary: true,
          height: 38,
          onPressed: () {}),
    ]),
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

  testWidgets('clans in the Tower, in tarot', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [360.0, 320.0]) {
      final n = w.toInt();
      for (final fr in [false, true]) {
        final l = fr ? 'fr' : 'en';
        await sheet(t, 'a-offer-$n-$l', w, _offer(w, fr));
        await sheet(t, 'b-standing-$n-$l', w, _standing(w, fr));
        await sheet(t, 'c-oath-$n-$l', w, _oath(w, fr));
      }
    }
    await sheet(
        t, 'a-offer-rows-320-fr-1.3x', 320, _offer(320, true, rows: true),
        scale: 1.3);
  });
}
