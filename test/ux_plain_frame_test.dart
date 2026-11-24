// PICTURE ONLY (UX_SHOTS=<folder>): the tarot card with a plain, hard-edged
// frame (no ornate corners) and a hard offset shadow, beside Art's ornate one,
// held in neutral ink and paper and in two clan colours (Art's hues). 360 and
// 320, English and French.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.25, color: c);

/// The card with a plain frame: a flat 2 px line, hard corners, and a hard
/// shadow that steps out to the lower right when it is held.
class _PlainCard extends StatelessWidget {
  const _PlainCard(
      {required this.width,
      required this.kind,
      required this.name,
      required this.text,
      required this.vignette,
      required this.rarity,
      this.held = false,
      this.accent = inkPaper});

  final double width;
  final String kind, name, text, vignette;
  final int rarity;
  final bool held;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final line = held ? accent : inkPaper.withValues(alpha: 0.5);
    final plate = held ? accent : inkPaper;
    final card = Container(
      width: width,
      height: width * 1.75,
      decoration: BoxDecoration(
        color: inkBlack,
        border: Border.all(color: line, width: held ? 3 : 2),
        boxShadow: held
            ? [BoxShadow(color: accent, offset: const Offset(5, 5))]
            : const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3))],
      ),
      child: Column(children: [
        Expanded(
          flex: 9,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(vignette,
                fit: BoxFit.cover, filterQuality: FilterQuality.none),
            Positioned(
              right: 5,
              top: 5,
              child: Text(kind.toUpperCase(),
                  style: _prose(8, inkPaper).copyWith(
                      letterSpacing: 0.6, fontWeight: FontWeight.w700)),
            ),
            Positioned(left: 5, bottom: 5, child: TowerSeal(rarity: rarity)),
          ]),
        ),
        Container(
          color: plate,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
          child: Text(name,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: _display(
                  12, plate.computeLuminance() > 0.35 ? inkOnPaper : inkPaper)),
        ),
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
            child: Text(text,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _prose(9.5, inkPaper)),
          ),
        ),
      ]),
    );
    return held
        ? Transform.translate(offset: const Offset(0, -4), child: card)
        : card;
  }
}

Widget _row(
    String label, double w, bool fr, Widget Function(int i, double cw) card) {
  final cw = (w - 24 - 16 - 6) / 3;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(label, style: _display(15, inkPaper))),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        card(i, cw),
      ],
    ]),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the plain card frame', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final w in [360.0, 320.0]) {
      for (final fr in [false, true]) {
        final kinds =
            fr ? ['Compétence', 'Dé', 'Sort'] : ['Skill', 'Die', 'Spell'];
        final names = fr
            ? ['Visée assurée', 'Dé du chœur', 'Serrez les rangs']
            : ['Steady Aim', 'Chorus Die', 'Rally the Line'];
        final texts = fr
            ? [
                'Une seconde de plus pour que ça compte.',
                'd12',
                'Le groupe resserre les rangs.'
              ]
            : [
                'Take the extra second to make it count.',
                'd12',
                'The party closes ranks.'
              ];
        const art = ['skill_none', 'die', 'spell_heal'];
        Widget plain(int i, double cw, {Color accent = inkPaper}) => _PlainCard(
            width: cw,
            kind: kinds[i],
            name: names[i],
            text: texts[i],
            vignette: 'assets/visuals/tower_cards/${art[i]}.png',
            rarity: [2, 0, 1][i],
            held: i == 1,
            accent: accent);
        final key = GlobalKey();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(w, 1500);
        await t.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: InkFonts.prose),
          home: Material(
            color: inkDeep,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: w,
                  color: inkDeep,
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fr ? 'Le cadre des cartes' : 'The card frame',
                            style: _display(22, inkPaper)),
                        _row(
                            fr
                                ? 'Aujourd’hui : coins ornés (Art)'
                                : 'Today: ornate corners (Art)',
                            w,
                            fr,
                            (i, cw) => TowerTarotCard(
                                  width: cw,
                                  kind: kinds[i],
                                  name: names[i],
                                  text: texts[i],
                                  vignette:
                                      'assets/visuals/tower_cards/${art[i]}.png',
                                  icon: const SizedBox(width: 22, height: 22),
                                  rarity: [2, 0, 1][i],
                                  held: i == 1,
                                  dim: i != 1,
                                )),
                        _row(
                            fr
                                ? 'Plat, arêtes vives, ombre dure : sans chef de clan (encre et papier)'
                                : 'Plain, hard edges, hard shadow: no leader (ink and paper)',
                            w,
                            fr,
                            (i, cw) => plain(i, cw)),
                        _row(
                            fr ? 'Dominion en tête' : 'Dominion leads',
                            w,
                            fr,
                            (i, cw) =>
                                plain(i, cw, accent: const Color(0xFF2F6FE0))),
                        _row(
                            fr ? 'Corneilles en tête' : 'Crows lead',
                            w,
                            fr,
                            (i, cw) =>
                                plain(i, cw, accent: const Color(0xFFE0479E))),
                        _row(
                            fr
                                ? 'Veille en tête (jaune : le nom passe à l’encre)'
                                : 'Vigil leads (yellow: the name plate keeps ink)',
                            w,
                            fr,
                            (i, cw) =>
                                plain(i, cw, accent: const Color(0xFFE8C21A))),
                      ]),
                ),
              ),
            ),
          ),
        ));
        for (var i = 0; i < 6; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/plain-frame-${w.toInt()}-${fr ? 'fr' : 'en'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        await t.pumpWidget(const SizedBox());
      }
    }
  });
}
