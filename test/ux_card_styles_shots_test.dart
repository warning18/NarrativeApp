// PICTURES (UX_SHOTS=<folder>): MOCK sheet of one card style per type, so the
// types tell apart at a glance and not by colour alone (stock tone, border,
// corner shape, a mark). Real vignettes where they exist, drawn stand-ins
// (marked "new art") where they do not. Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart'
    show InkFonts, buildAppTheme, stitchedInkScheme;

import 'support/fonts.dart';

const _gold = Color(0xFFC9A24B);
const _violet = Color(0xFF1B1533);
const _iron = Color(0xFF454E53);
const _tan = Color(0xFFB9A27A);
const _clan = Color(0xFF3F7F6B);

enum _Shape { square, chamfer, swallow, notch }

class _Spec {
  const _Spec(this.label, this.kind, this.name, this.text,
      {this.vignette,
      this.icon = Icons.help_outline,
      this.stock = inkBlack,
      this.ink = inkPaper,
      this.edge = inkPaper,
      this.edgeWidth = 1.5,
      this.dashed = false,
      this.twin = false,
      this.rivets = false,
      this.shape = _Shape.square,
      this.band = inkPaper,
      this.bandInk = inkOnPaper,
      this.stripe,
      this.stamp,
      this.coin = false,
      this.back = false,
      this.needsArt = false});
  final String label, kind, name, text;
  final String? vignette;
  final IconData icon;
  final Color stock, ink, edge, band, bandInk;
  final double edgeWidth;
  final bool dashed, twin, rivets, coin, back, needsArt;
  final _Shape shape;
  final Color? stripe;
  final String? stamp;
}

const _v = 'assets/visuals/tower_cards/';
const List<_Spec> _specs = [
  _Spec('Skill', 'Skill', 'Ember Lash', 'Hit one foe for 6 fire.',
      vignette: '${_v}skill_fire.png',
      icon: Icons.local_fire_department,
      stock: inkPaper,
      ink: inkOnPaper,
      edge: inkBlack,
      band: inkBlack,
      bandInk: inkPaper),
  _Spec('Die', 'Die', 'Ash Die', 'A d6 with two faces of 4.',
      vignette: '${_v}die.png', icon: Icons.casino),
  _Spec('Skill upgrade', 'Upgrade', 'Ember Lash II', 'Rank 2: 9 fire.',
      vignette: '${_v}skill_fire.png',
      icon: Icons.local_fire_department,
      stock: inkPaper,
      ink: inkOnPaper,
      edge: _gold,
      edgeWidth: 4,
      band: _gold,
      bandInk: inkBlack,
      stamp: '+1'),
  _Spec('Spell', 'Spell', 'Radiant Judgment', 'Strike all foes with light.',
      vignette: '${_v}spell_damage.png',
      icon: Icons.auto_awesome,
      stock: _violet,
      edge: inkPaper,
      twin: true,
      shape: _Shape.chamfer,
      band: inkPaper),
  _Spec('Clan gift', 'Clan gift', 'Shadow Step', 'The clan lends its stride.',
      vignette: '${_v}skill_void.png',
      icon: Icons.groups,
      stock: inkDark,
      shape: _Shape.swallow,
      stripe: _clan,
      band: inkDark,
      bandInk: inkPaper),
  _Spec('Equipment', 'Equipment', 'Iron Bracers', '+2 armour while worn.',
      icon: Icons.shield,
      stock: _iron,
      edge: inkBlack,
      edgeWidth: 4,
      rivets: true,
      band: inkBlack,
      bandInk: inkPaper,
      needsArt: true),
  _Spec('Item', 'Item', 'Bone Salve', 'Heal 30% of your health.',
      icon: Icons.local_pharmacy,
      stock: _tan,
      ink: inkOnPaper,
      edge: inkOnPaper,
      dashed: true,
      shape: _Shape.notch,
      band: inkOnPaper,
      bandInk: inkPaper,
      needsArt: true),
  _Spec('Money', 'Coins', '40 coins', 'Spend them at the next stall.',
      icon: Icons.monetization_on,
      stock: inkBlack,
      edge: _gold,
      edgeWidth: 3,
      dashed: true,
      coin: true,
      band: _gold,
      bandInk: inkBlack,
      needsArt: true),
  _Spec('Clan oath', 'Oath', 'Oath of Ash', 'Swear to the clan: ward +1.',
      vignette: '${_v}skill_light.png',
      icon: Icons.flag,
      stock: inkDeep,
      edge: inkRed,
      edgeWidth: 2,
      shape: _Shape.swallow,
      stripe: inkRed,
      band: inkDeep,
      bandInk: inkPaper),
  _Spec('Gamble (face down)', 'Gamble', '', '',
      icon: Icons.question_mark,
      stock: inkDeep,
      edge: inkPaper,
      twin: true,
      back: true,
      needsArt: true),
];

TextStyle _d(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _p(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.prose, fontSize: s, height: 1.2, color: c);

class _ShapeClipper extends CustomClipper<Path> {
  const _ShapeClipper(this.shape);
  final _Shape shape;
  @override
  Path getClip(Size s) {
    const c = 12.0;
    final w = s.width, h = s.height;
    return switch (shape) {
      _Shape.square => (Path()..addRect(Offset.zero & s)),
      _Shape.chamfer => Path()
        ..moveTo(c, 0)
        ..lineTo(w - c, 0)
        ..lineTo(w, c)
        ..lineTo(w, h - c)
        ..lineTo(w - c, h)
        ..lineTo(c, h)
        ..lineTo(0, h - c)
        ..lineTo(0, c)
        ..close(),
      _Shape.swallow => Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(w / 2, h - 16)
        ..lineTo(0, h)
        ..close(),
      _Shape.notch => Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.5 - 8)
        ..arcToPoint(Offset(w, h * 0.5 + 8),
            radius: const Radius.circular(8), clockwise: false)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..lineTo(0, h * 0.5 + 8)
        ..arcToPoint(Offset(0, h * 0.5 - 8),
            radius: const Radius.circular(8), clockwise: false)
        ..close(),
    };
  }

  @override
  bool shouldReclip(_ShapeClipper old) => old.shape != shape;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.spec);
  final _Spec spec;
  @override
  void paint(Canvas canvas, Size s) {
    final path = _ShapeClipper(spec.shape).getClip(s);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = spec.edge
      ..strokeWidth = spec.edgeWidth * 2; // half is clipped
    canvas.save();
    canvas.clipPath(path);
    if (spec.dashed) {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + 5), p);
          d += 8;
        }
      }
    } else {
      canvas.drawPath(path, p);
    }
    if (spec.twin) {
      final q = Paint()
        ..style = PaintingStyle.stroke
        ..color = spec.edge.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      canvas.drawRect(Rect.fromLTWH(5, 5, s.width - 10, s.height - 10), q);
    }
    if (spec.rivets) {
      final r = Paint()..color = inkBlack;
      final hi = Paint()..color = inkGrey;
      for (final o in [
        const Offset(7, 7),
        Offset(s.width - 7, 7),
        Offset(7, s.height - 7),
        Offset(s.width - 7, s.height - 7)
      ]) {
        canvas.drawCircle(o, 3, r);
        canvas.drawCircle(o.translate(-0.7, -0.7), 1.2, hi);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) => false;
}

class _BackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = inkPaper.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (double x = -s.height; x < s.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x + s.height, s.height), p);
      canvas.drawLine(Offset(x + s.height, 0), Offset(x, s.height), p);
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) => false;
}

class _Card extends StatelessWidget {
  const _Card(this.spec, this.width);
  final _Spec spec;
  final double width;

  Widget _art() {
    if (spec.vignette != null) {
      return Image.asset(spec.vignette!,
          fit: BoxFit.cover, filterQuality: FilterQuality.none);
    }
    // A drawn stand-in: marked as needing new art.
    return Stack(fit: StackFit.expand, children: [
      ColoredBox(color: spec.stock == _tan ? const Color(0xFF7A6A4C) : inkDark),
      Center(
          child: spec.coin
              ? Container(
                  width: width * 0.42,
                  height: width * 0.42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                      border: Border.all(color: inkBlack, width: 3)),
                  child: Icon(Icons.currency_exchange,
                      size: width * 0.22, color: inkBlack))
              : Icon(spec.icon, size: width * 0.4, color: inkPaper)),
      Positioned(
          right: 3,
          bottom: 2,
          child: Text('NEW ART',
              style: _p(7, inkPaper.withValues(alpha: 0.8))
                  .copyWith(letterSpacing: 0.5))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final h = width * 1.75;
    final body = spec.back
        ? Stack(fit: StackFit.expand, children: [
            ColoredBox(color: spec.stock),
            CustomPaint(painter: _BackPainter()),
            Center(
                child: Container(
              width: width * 0.5,
              height: width * 0.5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: inkRed,
                  border: Border.all(color: inkPaper, width: 2)),
              alignment: Alignment.center,
              child: Text('?', style: _d(width * 0.3, inkPaper)),
            )),
          ])
        : Column(children: [
            if (spec.stripe != null) Container(height: 5, color: spec.stripe),
            Expanded(
                flex: 9,
                child: Stack(fit: StackFit.expand, children: [
                  _art(),
                  Positioned(
                    left: 5,
                    top: 5,
                    child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            color: inkPaper,
                            borderRadius:
                                BorderRadius.circular(spec.coin ? 11 : 2)),
                        child: Icon(spec.icon, size: 15, color: inkOnPaper)),
                  ),
                  if (spec.stamp != null)
                    Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: _gold,
                              border: Border.all(color: inkBlack, width: 1.5)),
                          child: Text(spec.stamp!, style: _d(13, inkBlack)),
                        )),
                ])),
            Container(
              color: spec.band,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Text(spec.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: _d(11.5, spec.bandInk)),
            ),
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                child: Column(children: [
                  Text(spec.kind.toUpperCase(),
                      style: _p(8, spec.ink.withValues(alpha: 0.75)).copyWith(
                          letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Expanded(
                      child: Text(spec.text,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                          style: _p(9.5, spec.ink))),
                ]),
              ),
            ),
          ]);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(fit: StackFit.expand, children: [
        ClipPath(
          clipper: _ShapeClipper(spec.shape),
          child: Padding(
              padding: EdgeInsets.all(spec.edgeWidth),
              child: ColoredBox(color: spec.stock, child: body)),
        ),
        // The stock fills under the edge too.
        IgnorePointer(child: CustomPaint(painter: _EdgePainter(spec))),
      ]),
    );
  }
}

Widget _labelled(_Spec s, double w) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      _Card(s, w),
      const SizedBox(height: 4),
      SizedBox(
        width: w,
        child: Text(s.label,
            textAlign: TextAlign.center, style: _p(10.5, inkPaper)),
      ),
    ]);

Future<void> _shot(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _show(
    WidgetTester tester, GlobalKey key, double w, double h, Widget body) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
    home: RepaintBoundary(
        key: key,
        child: ColoredBox(
            color: inkBlack,
            child: Material(
                color: inkBlack,
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: body)))),
  )));
  // Let the vignettes decode.
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('card styles', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    // The sheet: 3 columns at 412, every type labelled.
    await _show(
        tester,
        key,
        412,
        940,
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [for (final s in _specs) _labelled(s, 112)],
          ),
        ));
    await _shot(tester, key, '$shots/card-styles-sheet-412.png');
    // A 3-card choice at real size (offer width 412: cards ~124 wide).
    for (final (name, idx) in [
      ('row-spell-equipment-money', [3, 5, 7]),
      ('row-skill-die-upgrade', [0, 1, 2]),
      ('row-item-clan-gamble', [6, 4, 9]),
    ]) {
      await _show(
          tester,
          key,
          412,
          260,
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final i in idx) _Card(_specs[i], 122)],
            ),
          ));
      await _shot(tester, key, '$shots/card-styles-$name.png');
    }
  });
}
