// PICTURES ONLY (UX_SHOTS=<folder>): the user's older asks, drawn together:
// a plain frame, black-and-paper wax seals and "more frame manga forms to add
// diversity". One clan gift card (Focus Mind, uncommon, standing 4/6) in six
// frame shapes: rounded (today), plain hard-edged, cut corners, slanted,
// split (a diagonal gutter) and a burst edge; each at rest; and the seal in
// red wax (today) and in black and paper. English 412 wide, French 360.
import 'dart:io';
import 'dart:math' as math;
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

import 'support/fonts.dart';

const _w = 190.0, _h = 300.0;
const _clan = Color(0xFF3FB06A);

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c, {bool italic = false}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.2,
    color: c,
    fontStyle: italic ? FontStyle.italic : null);

/// A black-and-paper wax seal: an ink disc, a paper ring, paper pips.
class _InkSeal extends StatelessWidget {
  const _InkSeal({this.pips = 2, this.size = 24});

  final int pips;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inkBlack,
            border: Border.all(color: inkOnPaper, width: 2)),
        alignment: Alignment.center,
        child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              for (var i = 0; i < pips; i++)
                Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: inkPaper)),
            ]),
      );
}

/// The outline of a frame shape, by name, in a w x h box.
Path _shape(String kind, Size s) {
  final w = s.width, h = s.height;
  switch (kind) {
    case 'cut': // chamfered corners, top-right and bottom-left cut deeper
      return Path()
        ..moveTo(10, 0)
        ..lineTo(w - 34, 0)
        ..lineTo(w, 34)
        ..lineTo(w, h - 10)
        ..lineTo(w - 10, h)
        ..lineTo(34, h)
        ..lineTo(0, h - 34)
        ..lineTo(0, 10)
        ..close();
    case 'slant': // a parallelogram leaning like the Tower's slanted panels
      return Path()
        ..moveTo(16, 0)
        ..lineTo(w, 6)
        ..lineTo(w - 16, h)
        ..lineTo(0, h - 6)
        ..close();
    case 'split': // a diagonal gutter: the top panel's lower edge cuts across
      return Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h - 44)
        ..lineTo(0, h)
        ..close();
    case 'burst': // a jagged lower edge, like an action panel
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h - 18);
      const n = 9;
      for (var i = 0; i < n; i++) {
        final x0 = w - w * i / n;
        final x1 = w - w * (i + 1) / n;
        p
          ..lineTo((x0 + x1) / 2, h)
          ..lineTo(x1, h - 18);
      }
      return p..close();
    default: // plain
      return Path()..addRect(Offset.zero & s);
  }
}

class _Clip extends CustomClipper<Path> {
  _Clip(this.kind);
  final String kind;
  @override
  Path getClip(Size size) => _shape(kind, size);
  @override
  bool shouldReclip(_Clip old) => old.kind != kind;
}

class _Outline extends CustomPainter {
  _Outline(this.kind, this.width);
  final String kind;
  final double width;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      _shape(kind, size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = width
        ..color = inkBlack);
  @override
  bool shouldRepaint(_Outline old) => old.kind != kind;
}

class _T {
  const _T(
      this.name, this.kind, this.clan, this.ripple, this.quote, this.standing);
  final String name, kind, clan, ripple, quote, standing;
}

const _en = _T(
    'Focus Mind',
    'Gift · Uncommon',
    'Mire',
    'Mire +2 · Dominion −1 · Compact +1',
    'What the fen takes, the fen returns.',
    'Standing 4/6');
const _fr = _T(
    'Esprit concentré',
    'Don · Peu commun',
    'Marais',
    'Marais +2 · Dominion −1 · Compact +1',
    'Ce que le marais prend, le marais le rend.',
    'Rang 4/6');

Widget _content(_T t, {required bool inkSeal, double bottom = 14}) => Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, bottom),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 84,
            height: 84,
            color: inkBlack,
            alignment: Alignment.center,
            child: Image.asset(SkillIcons.pathFor('focus_mind'),
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none),
          ),
          Align(
              alignment: Alignment.topRight,
              child: inkSeal
                  ? const _InkSeal()
                  : const TowerSeal(rarity: 1, size: 24)),
        ]),
        const SizedBox(height: 8),
        Text(t.name.toUpperCase(), style: _display(16, inkOnPaper)),
        const SizedBox(height: 4),
        Container(width: 40, height: 3, color: _clan),
        const SizedBox(height: 6),
        Text(t.kind, style: _prose(11, inkOnPaper)),
        Text('${t.clan} · ${t.standing}',
            style:
                _prose(12, inkOnPaper).copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(t.ripple,
            textAlign: TextAlign.center,
            style: _prose(10.5, inkOnPaper.withValues(alpha: 0.75))),
        const Spacer(),
        Text('“${t.quote}”',
            textAlign: TextAlign.center,
            style: _prose(10.5, inkOnPaper, italic: true)),
      ]),
    );

Widget _card(String kind, _T t, {bool inkSeal = false}) {
  const size = Size(_w, _h);
  if (kind == 'round') {
    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
          color: inkPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: inkBlack, width: 2)),
      child: _content(t, inkSeal: inkSeal),
    );
  }
  final stroke = kind == 'plain' ? 2.0 : 3.0;
  return SizedBox(
    width: _w,
    height: _h,
    child: Stack(children: [
      ClipPath(
        clipper: _Clip(kind),
        child: Container(
            width: size.width,
            height: size.height,
            color: inkPaper,
            child: _content(t,
                inkSeal: inkSeal,
                bottom: kind == 'split'
                    ? 50
                    : kind == 'burst'
                        ? 26
                        : 14)),
      ),
      Positioned.fill(
          child: IgnorePointer(
              child: CustomPaint(painter: _Outline(kind, stroke)))),
    ]),
  );
}

Widget _sheet(_T t, double w) {
  const kinds = [
    ('round', 'Rounded · today'),
    ('plain', 'Plain'),
    ('cut', 'Cut corners'),
    ('slant', 'Slanted'),
    ('split', 'Split panel'),
    ('burst', 'Burst edge'),
  ];
  Widget cell(String k, String label, {bool ink = false}) => Column(children: [
        Text(label, style: _display(14, inkPaper)),
        const SizedBox(height: 8),
        _card(k, t, inkSeal: ink),
      ]);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Frame shapes (red wax seal)', style: _display(18, inkPaper)),
    const SizedBox(height: 10),
    Wrap(spacing: 16, runSpacing: 20, children: [
      for (final (k, l) in kinds) cell(k, l),
    ]),
    const SizedBox(height: 24),
    Text('Seals: red wax (today) · black and paper',
        style: _display(18, inkPaper)),
    const SizedBox(height: 10),
    Wrap(spacing: 16, runSpacing: 20, children: [
      cell('round', 'Red wax'),
      cell('round', 'Black and paper', ink: true),
      cell('cut', 'Cut + black and paper', ink: true),
    ]),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('card frames and seals', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final (name, lang, w) in [('en', _en, 412.0), ('fr', _fr, 412.0)]) {
      final key = GlobalKey();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(w, 2400);
      await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: inkDeep,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: Container(
                  width: w,
                  color: inkDeep,
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  child: _sheet(lang, w)),
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
        File('$shots/frames-$name-412.png')
            .writeAsBytesSync(b!.buffer.asUint8List());
      });
      await t.pumpWidget(const SizedBox());
    }
  });
}
