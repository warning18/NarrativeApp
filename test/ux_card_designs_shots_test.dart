// PICTURES ONLY (UX_SHOTS=<folder>): three designs of ONE clan gift card
// (the Mire's Focus Mind, uncommon, standing 4/6), each at rest and lifted.
// Ink and paper, the clan colour as one small spot, little detail.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart'
    show TowerSeal;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/skill_icons.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

const _clan = Color(0xFF3F8F5A);
const _w = 210.0, _h = 346.0;

class _T {
  const _T(this.name, this.kind, this.clan, this.line, this.standing);
  final String name, kind, clan, line, standing;
}

const _en = _T('Focus Mind', 'Gift · Uncommon', 'Mire',
    'What the fen takes, the fen returns.', 'Standing 4/6');
const _fr = _T('Esprit concentré', 'Don · Peu commun', 'Marais',
    'Ce que le marais prend, le marais le rend.', 'Rang 4/6');

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c, {bool italic = false}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.2,
    color: c,
    fontStyle: italic ? FontStyle.italic : null);

Widget _icon(double size) => Image.asset(SkillIcons.pathFor('focus_mind'),
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none);

Widget _frame(Widget card, bool lit) => Transform.translate(
    offset: Offset(0, lit ? -18 : 0),
    child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(
                color: lit ? inkPaper : Colors.transparent, width: 2)),
        child: card));

// A: the tarot plate. Paper, a black silhouette, the name below, the seal.
Widget _a(_T t) => SizedBox(
      width: _w,
      height: _h,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: inkPaper, border: Border.all(color: inkBlack, width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration:
                BoxDecoration(border: Border.all(color: inkBlack, width: 1)),
            child: Stack(children: [
              Align(
                  alignment: const Alignment(0, -0.3),
                  child: Container(
                      width: 124,
                      height: 124,
                      color: inkBlack,
                      alignment: Alignment.center,
                      child: _icon(96))),
              const Positioned(right: 8, top: 8, child: TowerSeal(rarity: 1)),
              Positioned(
                left: 8,
                right: 8,
                bottom: 14,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: _display(17, inkOnPaper)),
                  const SizedBox(height: 4),
                  Text('${t.clan} · ${t.standing}',
                      style: _prose(11, inkOnPaper.withValues(alpha: 0.7))),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );

// B: the banner card. Black, the banner tall at the left, a paper strip, a
// thin clan line.
Widget _b(_T t) => SizedBox(
      width: _w,
      height: _h,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: inkBlack,
            border:
                Border.all(color: inkPaper.withValues(alpha: 0.6), width: 2)),
        child: Stack(children: [
          Positioned(
              left: 14,
              top: 0,
              child: SizedBox(
                  width: 64,
                  height: 128,
                  child: PixelBanner(id: clanBannerId('mire')!, scale: 1))),
          Positioned(left: 100, top: 22, child: _icon(76)),
          Positioned(
            left: 0,
            right: 0,
            top: 170,
            child: Container(
              color: inkPaper,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Text(t.name, style: _display(19, inkOnPaper)),
            ),
          ),
          Positioned(
              left: 0,
              right: 0,
              top: 170 + 38,
              child: Container(height: 3, color: _clan)),
          Positioned(
            left: 14,
            right: 14,
            top: 226,
            child: Text(t.standing, style: _prose(14, inkPaper)),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text('“${t.line}”',
                style: _prose(12.5, inkPaper.withValues(alpha: 0.75),
                    italic: true)),
          ),
        ]),
      ),
    );

// C: the type card. Paper, the name large, one rule, a round clan stamp, the
// standing as a tally.
Widget _c(_T t) => SizedBox(
      width: _w,
      height: _h,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: inkPaper, border: Border.all(color: inkBlack, width: 3)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.kind.toUpperCase(),
                style: _prose(10.5, inkOnPaper.withValues(alpha: 0.65))
                    .copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 14),
            Text(t.name, style: _display(36, inkOnPaper).copyWith(height: 1.0)),
            const SizedBox(height: 14),
            Container(height: 2, width: 64, color: inkBlack),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: _clan),
                child:
                    Text(t.clan.substring(0, 1), style: _display(16, inkPaper)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                        width: 6,
                        height: i < 4 ? 20 : 12,
                        margin: const EdgeInsets.only(right: 5),
                        color: i < 4
                            ? inkBlack
                            : inkBlack.withValues(alpha: 0.25)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );

Widget _sheet(_T t) {
  Widget col(String label, Widget Function(_T) card) => Column(children: [
        Text(label, style: _display(15, inkPaper)),
        const SizedBox(height: 14),
        _frame(card(t), false),
        const SizedBox(height: 34),
        _frame(card(t), true),
        const SizedBox(height: 22),
      ]);
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    col('A · plate', _a),
    const SizedBox(width: 22),
    col('B · banner', _b),
    const SizedBox(width: 22),
    col('C · type', _c),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('three card designs', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final (name, lang) in [('en', _en), ('fr', _fr)]) {
      final key = GlobalKey();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(780, 880);
      await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: inkDeep,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: Container(
                  color: inkDeep,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: _sheet(lang)),
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
        final r =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await r.toImage(pixelRatio: 2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/designs-$name.png')
            .writeAsBytesSync(b!.buffer.asUint8List());
      });
      await t.pumpWidget(const SizedBox());
    }
  });
}
