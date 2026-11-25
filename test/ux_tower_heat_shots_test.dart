// PICTURES ONLY (UX_SHOTS=<folder>): Tower Heat in the ink, five named levels
// with a curse each (Core's docs/proposals/tower-heat.md on
// claude/core-tower-designs): the door's picker (six steps), the curse list,
// the header chip, the end screen's badge and the Ash trim at heat 5. 360 and
// 412, English and French. Names are Core's; the curse lines are my own
// placeholders until Narrative words them ("guess").
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

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.25, color: c);
TextStyle _sys(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.system, fontSize: s, height: 1.1, color: c);

const _nb = ' ';
// The flame's colour by level: amber to deep orange, then ash. Not red: red is
// the warning.
const _flame = [
  Color(0xFF9AA3A7),
  Color(0xFFE8B23C),
  Color(0xFFE8892A),
  Color(0xFFE86A1E),
  Color(0xFFD9531E),
  Color(0xFFC9C6BE),
];
const _names = [
  ('The plain climb', 'L’ascension simple'),
  ('Embers', 'Braises'),
  ('Smoke', 'Fumée'),
  ('Flame', 'Flamme'),
  ('Pyre', 'Bûcher'),
  ('Ash', 'Cendre'),
];
const _curses = [
  ('Today’s climb.', 'L’ascension d’aujourd’hui.'),
  (
    'Foes are 5% stronger on every floor.',
    'Les adversaires sont plus forts de 5$_nb% à chaque étage.'
  ),
  (
    'Wardens and bosses carry one affix more.',
    'Gardiens et boss portent une affixe de plus.'
  ),
  (
    'You recover 8% after a floor, not 15%. More Elites above floor 10.',
    'Vous récupérez 8$_nb% après un étage, pas 15$_nb%. Plus d’Élites après l’étage 10.'
  ),
  (
    'No boons on floors 13 and 23. The late oath waits for floor 18.',
    'Pas de faveurs aux étages 13 et 23. Le serment tardif attend l’étage 18.'
  ),
  (
    'Foes ×1.10 above floor 10. A gift costs each rival clan 2, not 1.',
    'Adversaires ×1,10 après l’étage 10. Un don coûte 2 à chaque clan rival, pas 1.'
  ),
];
const _marks = ['', '1.25', '1.5', '1.75', '2', '2.25'];

class _L {
  const _L(this.fr);
  final bool fr;
  String name(int i) => fr ? _names[i].$2 : _names[i].$1;
  String curse(int i) => fr ? _curses[i].$2 : _curses[i].$1;
  String marks(int i) {
    final m = fr ? _marks[i].replaceAll('.', ',') : _marks[i];
    return fr ? 'Marques ×$m' : 'Marks ×$m';
  }

  String locked(int i) => fr
      ? 'Gagnez au sommet (${name(i - 1)}) pour ouvrir'
      : 'Win the top at ${name(i - 1)} to open';
}

Widget _flames(int n, {double size = 14}) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < n; i++)
        Icon(Icons.local_fire_department, size: size, color: _flame[n]),
    ]);

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

Widget _row(_L l, int i, {required bool open, bool selected = false}) {
  final locked = !open;
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
        color: inkBlack,
        border: Border.all(
            color: selected ? _flame[i] : (locked ? inkSlate : inkPaper),
            width: selected ? 2.5 : 1.2)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 78,
          child: i == 0
              ? Text('0', style: _sys(14, locked ? inkGrey : inkPaper))
              : locked
                  ? const Icon(Icons.lock_outline, size: 16, color: inkGrey)
                  : _flames(i, size: 14)),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.name(i), style: _display(15, locked ? inkGrey : inkPaper)),
          Text(locked ? l.locked(i) : l.curse(i),
              style: _prose(11.5, locked ? inkGrey : const Color(0xFFC8CDD0))),
          if (i > 0)
            Text(l.marks(i),
                style: _prose(11, locked ? inkSlate : const Color(0xFFD9B44A))
                    .copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    ]),
  );
}

Widget _picker(_L l, {required int open, required int selected}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i <= 5; i++)
        _row(l, i, open: i <= open, selected: i == selected),
    ]);

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

Widget _header(_L l, int heat) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.fr ? 'LES ESCALIERS BAS' : 'THE LOWER STAIRS',
          style: _sys(10, inkGrey).copyWith(letterSpacing: 1.4)),
      Text(l.fr ? 'Étage 7 sur 30' : 'Floor 7 of 30',
          style: _display(26, inkPaper)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 4, children: [
        _chip(_flames(1, size: 13), '$heat', _flame[heat]),
        _chip(Icon(Icons.local_fire_department, size: 13, color: _flame[heat]),
            l.name(heat), _flame[heat]),
      ]),
    ]);

Widget _curseList(_L l, int heat) => Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
          color: inkBlack, border: Border.all(color: inkPaper, width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.fr ? 'En vigueur dans cette ascension' : 'In force this climb',
            style: _display(16, inkPaper)),
        const SizedBox(height: 8),
        for (var i = 1; i <= heat; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 78, child: _flames(i, size: 13)),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(l.name(i), style: _display(14, inkPaper)),
                        if (i == heat) ...[
                          const SizedBox(width: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              color: _flame[i],
                              child: Text(l.fr ? 'nouveau' : 'new',
                                  style: _prose(10, inkBlack)
                                      .copyWith(fontWeight: FontWeight.w700))),
                        ],
                      ]),
                      Text(l.curse(i),
                          style: _prose(11.5, const Color(0xFFC8CDD0))),
                    ]),
              ),
            ]),
          ),
        Align(
            alignment: Alignment.centerRight,
            child: InkButton(
                label: l.fr ? 'Fermer' : 'Close',
                height: 34,
                onPressed: () {})),
      ]),
    );

Widget _end(_L l) => Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: inkBlack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.fr ? 'Le sommet est à vous' : 'The top is yours',
            style: _display(20, inkPaper)),
        const SizedBox(height: 6),
        Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.fr ? '104 marques de cendre' : '104 Ash Marks',
                  style: _prose(15, inkPaper)
                      .copyWith(fontWeight: FontWeight.w700)),
              _chip(
                  _flames(1, size: 12),
                  l.fr ? 'Flamme · marques ×1,75' : 'Flame · marks ×1.75',
                  _flame[3]),
            ]),
        const SizedBox(height: 8),
        Row(children: [
          _flames(4, size: 15),
          const SizedBox(width: 6),
          Text(l.fr ? 'Niveau ouvert : Bûcher' : 'Pyre is open',
              style:
                  _prose(13, _flame[4]).copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(l.fr ? 'Votre meilleure ascension' : 'Your best climb',
            style: _sys(9.5, inkGrey).copyWith(letterSpacing: 1.2)),
        Row(children: [
          Text(l.fr ? 'Sommet' : 'The top', style: _display(18, inkPaper)),
          const SizedBox(width: 8),
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.local_fire_department,
                  size: 16, color: i <= 3 ? _flame[3] : inkSlate),
            ),
        ]),
      ]),
    );

Widget _trim(_L l, {required bool ash}) => Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(
              color: ash ? _flame[5] : inkPaper, width: ash ? 3 : 1.2),
          boxShadow: ash
              ? const [BoxShadow(color: Color(0x55C9C6BE), blurRadius: 12)]
              : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.fort, size: 20, color: ash ? _flame[5] : inkPaper),
          const SizedBox(width: 8),
          Text(l.fr ? 'La Tour de Cendre' : 'The Ashen Tower',
              style: _display(20, ash ? _flame[5] : inkPaper)),
        ]),
        Text(
            l.fr
                ? 'Trente étages. Une seule voie.'
                : 'Thirty floors. One way up.',
            style: _prose(12, inkGrey)),
        if (ash)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l.fr ? 'Cendre vaincue' : 'Ash conquered',
                style: _sys(10, _flame[5]).copyWith(letterSpacing: 1.2)),
          ),
      ]),
    );

Widget _sheet(double w, bool fr) {
  final l = _L(fr);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkTab(fr ? 'Chaleur · cinq niveaux' : 'Heat · five levels'),
    _title(
        fr ? '1 · À la porte de la Tour' : '1 · On the Tower door',
        fr
            ? 'Six pas ; les verrouillés sont ternes. Caché tant que Braises est fermé.'
            : 'Six steps; the locked ones dimmed. Hidden until Embers opens.'),
    Text(
        fr
            ? 'Braises vient de s’ouvrir (le plus haut ouvert est choisi) :'
            : 'Embers has just opened (the highest open is picked):',
        style: _prose(10.5, inkGrey)),
    const SizedBox(height: 4),
    _picker(l, open: 1, selected: 1),
    const SizedBox(height: 8),
    Text(fr ? 'Tout est ouvert, Flamme choisi :' : 'All open, Flame picked:',
        style: _prose(10.5, inkGrey)),
    const SizedBox(height: 4),
    _picker(l, open: 5, selected: 3),
    _guess(fr
        ? 'une rangée par niveau ; la flamme prend la couleur du niveau (ambre à cendre), jamais le rouge'
        : 'one row a level; the flame takes the level\'s colour (amber to ash), never red'),
    _title(
        fr ? '2 · La liste des malédictions' : '2 · The curse list',
        fr
            ? 'Ouverte depuis la pastille ; le dernier niveau marqué « nouveau »'
            : 'Opened from the chip; the newest marked'),
    _curseList(l, 3),
    const SizedBox(height: 14),
    _curseList(l, 5),
    _guess(fr
        ? 'les lignes de malédiction sont de moi, à reformuler par Narrative'
        : 'the curse lines are mine, for Narrative to reword'),
    _title(
        fr ? '3 · La pastille dans l’étage' : '3 · The chip on the floor',
        fr
            ? 'Niveau et nom, pendant toute la run'
            : 'The level and its name, for the whole run'),
    _header(l, 3),
    _title(
        fr ? '4 · La fin' : '4 · The end',
        fr
            ? 'Marques ×1,75, le niveau ouvert, le badge au record'
            : 'Marks ×1.75, the level opened, the badge on the record'),
    _end(l),
    _title(
        fr
            ? '5 · Cendre vaincue : la bordure de la Tour'
            : '5 · Ash conquered: the Tower\'s trim',
        fr ? 'Sans, puis avec' : 'Without, then with'),
    _trim(l, ash: false),
    const SizedBox(height: 12),
    _trim(l, ash: true),
    _guess(fr
        ? 'il n’y a pas encore de bannière de la Tour : je dessine le bandeau de la porte'
        : 'there is no Tower banner yet: I draw the door\'s title block'),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('Tower heat', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [412.0, 360.0]) {
      for (final fr in [false, true]) {
        final key = GlobalKey();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(w, 3600);
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
          File('$shots/heat-${w.toInt()}-${fr ? 'fr' : 'en'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        await t.pumpWidget(const SizedBox());
      }
    }
  });
}
