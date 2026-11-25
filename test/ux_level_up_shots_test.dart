// PICTURES (UX_SHOTS=<folder>): three proposals for the Tower's Level Up screen
// at 412 wide and one at 360, drawn from the real numbers of the user's
// screenshot (Level 4: STR 1, DEX 10, CON -2, INT 3, WIS -1, PER 1, LUCK 2,
// CHA 0; base damage 8, armour 0, health 32). Mock widgets in the Ink palette,
// not the app's screen: A a cleaned-up layout, B cards with before and after,
// C a bar per stat instead of the radar.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';

import 'support/fonts.dart';

const _prose = 'Spectral';
const _display = 'IMFellEnglishSC';
const _system = 'PixelifySans';
const _lining = [FontFeature.liningFigures()];

typedef _Stat = ({String abbr, String name, int value, IconData icon});

const _stats = <_Stat>[
  (abbr: 'STR', name: 'Strength', value: 1, icon: Icons.fitness_center),
  (abbr: 'DEX', name: 'Dexterity', value: 10, icon: Icons.directions_run),
  (abbr: 'CON', name: 'Constitution', value: -2, icon: Icons.favorite),
  (abbr: 'INT', name: 'Intelligence', value: 3, icon: Icons.auto_stories),
  (abbr: 'WIS', name: 'Wisdom', value: -1, icon: Icons.visibility),
  (abbr: 'PER', name: 'Perception', value: 1, icon: Icons.center_focus_strong),
  (abbr: 'LUCK', name: 'Luck', value: 2, icon: Icons.casino),
  (abbr: 'CHA', name: 'Charisma', value: 0, icon: Icons.record_voice_over),
];

/// The three offers: stat index, the lines under it (what it does for this hero),
/// and the before to after of the numbers it moves.
typedef _Offer = ({
  int stat,
  List<String> effects,
  List<(String, String, String)> moves
});

const _offers = <_Offer>[
  (stat: 3, effects: ['story checks'], moves: []),
  (
    stat: 1,
    effects: ['+1 damage', '+2% dodge'],
    moves: [('Damage', '8', '9'), ('Dodge', '25%', '27%')]
  ),
  (stat: 0, effects: ['story checks'], moves: []),
];

TextStyle _t(double size,
        {Color color = inkPaper, String family = _prose, FontWeight? weight}) =>
    TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 1.15,
        color: color,
        fontWeight: weight,
        fontFeatures: _lining);

Widget _appBar() => Container(
      height: 56,
      color: inkBlack,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        const Icon(Icons.arrow_back, color: inkGrey),
        const SizedBox(width: 22),
        Text('Level Up', style: _t(24, family: _display)),
        const Spacer(),
        const Icon(Icons.info_outline, color: inkPaper),
      ]),
    );

Widget _levelPanel({bool compact = false}) => Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
          color: inkDeep,
          border: Border.all(color: inkSlate),
          borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Level 4', style: _t(26, family: _display)),
          const Spacer(),
          Text('XP 0 / 400', style: _t(13, color: inkGrey)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
                value: 0.0,
                minHeight: 8,
                color: inkPaper,
                backgroundColor: inkSlate)),
      ]),
    );

Widget _button() => Container(
      height: 48,
      alignment: Alignment.center,
      color: inkRed,
      child: Text('Take this pick', style: _t(16, family: _system)),
    );

/// A card of the row.
Widget _card(int i, int selected, {bool before = false, double width = 120}) {
  final o = _offers[i];
  final s = _stats[o.stat];
  final sel = i == selected;
  return Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
    decoration: BoxDecoration(
      color: sel ? const Color(0xFF2A2A30) : inkDeep,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: sel ? inkPaper : inkSlate, width: sel ? 2 : 1),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: sel ? inkRed : inkGrey, width: 1.5),
            color: inkBlack),
        child: Icon(s.icon, size: 26, color: sel ? inkRed : inkPaper),
      ),
      const SizedBox(height: 6),
      Text('+1',
          style:
              _t(22, color: sel ? inkRed : inkPaper, weight: FontWeight.w700)),
      Text(s.abbr, style: _t(15, family: _system)),
      Text(s.name, style: _t(11, color: inkGrey)),
      if (before) ...[
        const SizedBox(height: 4),
        Text('${s.value} → ${s.value + 1}', style: _t(15, color: inkPaper)),
      ],
      const SizedBox(height: 4),
      for (final e in o.effects)
        Text(e,
            textAlign: TextAlign.center,
            style: _t(11, color: e == 'story checks' ? inkGrey : inkPaper)),
      if (sel)
        const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 18, color: inkPaper)),
    ]),
  );
}

Widget _cards(int selected, double w, {bool before = false}) {
  final cw = (w - 32 - 16) / 3;
  return Row(children: [
    for (var i = 0; i < 3; i++) ...[
      if (i > 0) const SizedBox(width: 8),
      SizedBox(
          width: cw,
          child: Opacity(
              opacity: i == selected ? 1 : 0.9,
              child: _card(i, selected, before: before, width: cw))),
    ],
  ]);
}

/// The radar: -2 sits at the first ring, 10 at the rim, so a negative stays a
/// readable dent, the shape filled; the pick ghosted in dashed.
class _RadarPainter extends CustomPainter {
  _RadarPainter(this.pickStat);

  final int? pickStat;

  double _r(double v, double rim) =>
      rim * (0.18 + 0.82 * ((v + 2) / 12).clamp(0.0, 1.0));

  @override
  void paint(Canvas c, Size size) {
    final centre = size.center(Offset.zero);
    final rim = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = inkSlate;
    for (final k in [0.25, 0.5, 0.75, 1.0]) {
      c.drawCircle(centre, rim * k, ring);
    }
    Offset at(int i, double v) {
      final a = -math.pi / 2 + i * 2 * math.pi / 8;
      return centre + Offset(math.cos(a), math.sin(a)) * _r(v, rim);
    }

    for (var i = 0; i < 8; i++) {
      c.drawLine(centre, at(i, 10), ring);
    }
    Path shape(int? plus) {
      final p = Path();
      for (var i = 0; i < 8; i++) {
        final v = _stats[i].value + (i == plus ? 1 : 0);
        final o = at(i, v.toDouble());
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    c.drawPath(shape(null), Paint()..color = inkPaper.withValues(alpha: 0.16));
    c.drawPath(
        shape(null),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = inkPaper);
    if (pickStat != null) {
      final path = shape(pickStat);
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9) {
          c.drawPath(
              m.extractPath(d, math.min(d + 5, m.length)),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = inkRed);
        }
      }
      c.drawCircle(at(pickStat!, _stats[pickStat!].value + 1.0), 4,
          Paint()..color = inkRed);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.pickStat != pickStat;
}

Widget _radar(double w, int? pick) {
  const side = 190.0;
  final box = Size(w - 32, side + 108);
  return SizedBox(
    width: box.width,
    height: box.height,
    child: Stack(children: [
      Positioned(
          left: (box.width - side) / 2,
          top: 35,
          width: side,
          height: side,
          child: CustomPaint(painter: _RadarPainter(pick))),
      for (var i = 0; i < 8; i++)
        () {
          final a = -math.pi / 2 + i * 2 * math.pi / 8;
          final c = Offset(box.width / 2 + math.cos(a) * (side / 2 + 36),
              35 + side / 2 + math.sin(a) * (side / 2 + 28));
          final s = _stats[i];
          final picked = i == pick;
          return Positioned(
              left: c.dx - 30,
              top: c.dy - 17,
              width: 60,
              child: Column(children: [
                Text(s.abbr, style: _t(11, family: _system, color: inkGrey)),
                Text(picked ? '${s.value} → ${s.value + 1}' : '${s.value}',
                    style: _t(15,
                        color: picked ? inkRed : inkPaper,
                        weight: FontWeight.w700)),
              ]));
        }(),
    ]),
  );
}

Widget _derived({int? pick}) => Row(children: [
      for (final (label, now, plus) in [
        ('Base damage', '8', pick == 1 ? '9' : null),
        ('Base armour', '0', null),
        ('Max health', '32', null),
      ])
        Expanded(
          child: Column(children: [
            Text(plus == null ? now : '$now → $plus',
                style: _t(20,
                    color: plus == null ? inkPaper : inkRed,
                    weight: FontWeight.w700)),
            Text(label, style: _t(12, color: inkGrey)),
          ]),
        ),
    ]);

Widget _bars(int? pick, double w) => Column(children: [
      for (var i = 0; i < 8; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(children: [
            SizedBox(
                width: 42,
                child: Text(_stats[i].abbr,
                    style: _t(12,
                        family: _system,
                        color: i == pick ? inkPaper : inkGrey))),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                double x(num v) =>
                    box.maxWidth * ((v + 2) / 12).clamp(0.0, 1.0);
                final v = _stats[i].value;
                return SizedBox(
                  height: 14,
                  child: Stack(children: [
                    Container(color: inkDeep),
                    Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: x(v),
                        child:
                            Container(color: i == pick ? inkPaper : inkGrey)),
                    if (i == pick)
                      Positioned(
                          left: x(v),
                          top: 0,
                          bottom: 0,
                          width: x(v + 1) - x(v),
                          child: Container(color: inkRed)),
                    Positioned(
                        left: x(0),
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(color: inkSlate)),
                  ]),
                );
              }),
            ),
            SizedBox(
                width: 62,
                child: Text(
                    i == pick
                        ? '${_stats[i].value} → ${_stats[i].value + 1}'
                        : '${_stats[i].value}',
                    textAlign: TextAlign.right,
                    style: _t(15,
                        color: i == pick ? inkRed : inkPaper,
                        weight: FontWeight.w700))),
          ]),
        ),
    ]);

Widget _screen(String variant, double w, int selected) {
  final pick = _offers[selected].stat;
  final body = <Widget>[
    _levelPanel(compact: variant == 'C'),
    const SizedBox(height: 16),
    Text('Pick a gain', style: _t(18, family: _display, color: inkPaper)),
    const SizedBox(height: 8),
    _cards(selected, w, before: variant == 'B'),
    const SizedBox(height: 12),
    if (variant == 'C') ...[
      _bars(pick, w),
      const SizedBox(height: 10),
    ] else
      Center(child: _radar(w, pick)),
    _button(),
    const SizedBox(height: 14),
    _derived(pick: variant == 'A' || variant == 'B' ? pick : null),
    if (variant == 'B' && _offers[selected].moves.isNotEmpty) ...[
      const SizedBox(height: 10),
      for (final (label, from, to) in _offers[selected].moves)
        Text('$label  $from → $to', style: _t(14, color: inkPaper)),
    ],
  ];
  return Container(
    color: inkBlack,
    width: w,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _appBar(),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
      ),
    ]),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  for (final (variant, w, selected) in [
    ('A', 412.0, 1),
    ('B', 412.0, 1),
    ('C', 412.0, 1),
    ('B', 360.0, 2),
    ('A', 360.0, 1),
  ]) {
    testWidgets('level up $variant at ${w.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(w, 960);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: inkBlack,
          child: RepaintBoundary(
              key: key,
              child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _screen(variant, w, selected))),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/level-up-$variant-${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
