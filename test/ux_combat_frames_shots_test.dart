// PICTURES ONLY (UX_SHOTS=<folder>): the card frame shapes on the fight
// screen, 412 wide (the user "didn't see the new Manga frame shapes in combat
// mode"). One mock fight, the same hand every time: two foes with their
// intents, the player's hand (skills, a spell, the ultimate) and the cards in
// play; in six shapes (rounded today, plain, cut corners, slanted, split
// panel, burst edge) and a 7th panel that gives each kind its own shape
// (skills rounded, spells cut, the ultimate burst, foe intents slanted).
// A mock: real icons and the Tower's ink, not the fight screen's code.
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

import 'support/fonts.dart';

const _w = 412.0;

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c, {bool bold = false, bool italic = false}) =>
    TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: s,
        height: 1.2,
        color: c,
        fontWeight: bold ? FontWeight.w700 : null,
        fontStyle: italic ? FontStyle.italic : null);

Path _shape(String kind, Size s) {
  final w = s.width, h = s.height;
  final c = (h * 0.16).clamp(8.0, 20.0);
  switch (kind) {
    case 'round':
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Offset.zero & s, const Radius.circular(12)));
    case 'cut':
      return Path()
        ..moveTo(6, 0)
        ..lineTo(w - c * 1.6, 0)
        ..lineTo(w, c * 1.6)
        ..lineTo(w, h - 6)
        ..lineTo(w - 6, h)
        ..lineTo(c * 1.6, h)
        ..lineTo(0, h - c * 1.6)
        ..lineTo(0, 6)
        ..close();
    case 'slant':
      return Path()
        ..moveTo(c * 0.8, 0)
        ..lineTo(w, 3)
        ..lineTo(w - c * 0.8, h)
        ..lineTo(0, h - 3)
        ..close();
    case 'split':
      return Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h - c * 1.5)
        ..lineTo(0, h)
        ..close();
    case 'burst':
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h - 8);
      final n = (w / 12).round().clamp(4, 14);
      for (var i = 0; i < n; i++) {
        final x0 = w - w * i / n;
        final x1 = w - w * (i + 1) / n;
        p
          ..lineTo((x0 + x1) / 2, h)
          ..lineTo(x1, h - 8);
      }
      return p..close();
    default:
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
  _Outline(this.kind, this.color);
  final String kind;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      _shape(kind, size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = 2.5
        ..color = color);
  @override
  bool shouldRepaint(_Outline old) => old.kind != kind || old.color != color;
}

/// [child] in the frame [kind]: stock fill, an ink outline.
Widget _framed(String kind, double w, double h, Widget child,
    {Color fill = inkPaper, Color line = inkBlack, bool lift = false}) {
  return Transform.translate(
    offset: Offset(0, lift ? -10 : 0),
    child: SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        ClipPath(
          clipper: _Clip(kind),
          child: Container(width: w, height: h, color: fill, child: child),
        ),
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(painter: _Outline(kind, line)))),
      ]),
    ),
  );
}

Widget _icon(String path, double size) => Image.asset(path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none);

class _Card {
  const _Card(this.kind, this.id, this.name, this.cost, this.text);
  final String kind; // skill | spell | ultimate
  final String id, name, text;
  final int cost;
}

const _hand = [
  _Card('skill', 'power_strike', 'Power Strike', 2, 'Hit for 14.'),
  _Card('skill', 'bulwark_stance', 'Bulwark', 1, 'Block 10.'),
  _Card('spell', 'fireball', 'Fireball', 3, 'Burn all foes.'),
  _Card('ultimate', 'void_blast', 'Void Blast', 5, 'Hit for 40.'),
];

Widget _cardBody(_Card c, double w, double h,
    {required bool inPlay, String frame = 'round'}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
        8, 10, 8, frame == 'split' ? 22 : (frame == 'burst' ? 14 : 8)),
    child: Column(children: [
      Stack(alignment: Alignment.center, children: [
        Container(
            width: 52,
            height: 52,
            color: inkBlack,
            alignment: Alignment.center,
            child: _icon('assets/icons/skills/${c.id}.png', 40)),
        Align(
            alignment: Alignment.topRight,
            child: c.kind == 'ultimate'
                ? const TowerSeal(rarity: 3, size: 16)
                : const SizedBox.shrink()),
      ]),
      const SizedBox(height: 4),
      Text(c.name.toUpperCase(),
          maxLines: 1, style: _display(11.5, inkOnPaper)),
      Text('${c.cost} · ${c.text}',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: _prose(10, inkOnPaper.withValues(alpha: 0.8))),
    ]),
  );
}

Widget _foe(String kind, String id, String name, int hp, String intent,
    {double w = 192}) {
  return _framed(
    kind,
    w,
    74,
    Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            color: inkBlack,
            alignment: Alignment.center,
            child: _icon('assets/icons/enemies/$id.png', 40)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(name.toUpperCase(),
                        maxLines: 1, style: _display(12, inkOnPaper))),
                const SizedBox(height: 3),
                Container(
                    height: 6,
                    width: 100 * hp / 100,
                    color: const Color(0xFFA53030)),
                const SizedBox(height: 3),
                Text(intent,
                    maxLines: 1, style: _prose(10.5, inkOnPaper, bold: true)),
              ]),
        ),
      ]),
    ),
  );
}

Widget _panel(String title, String foeKind, String skillKind, String spellKind,
    String ultKind) {
  String frameOf(_Card c) => switch (c.kind) {
        'skill' => skillKind,
        'spell' => spellKind,
        _ => ultKind,
      };
  const cw = 92.0, ch = 124.0;
  return Container(
    width: _w,
    color: inkDeep,
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: _display(15, inkPaper)),
      const SizedBox(height: 8),
      Text('Round 2 · Their intents', style: _prose(11, inkGrey)),
      const SizedBox(height: 4),
      Row(children: [
        _foe(foeKind, 'bone_warden', 'Bone Warden', 80, 'Strikes for 18'),
        const SizedBox(width: 8),
        _foe(foeKind, 'catacomb_ghoul', 'Catacomb Ghoul', 55, 'Drains 6'),
      ]),
      const SizedBox(height: 10),
      Text('In play', style: _prose(11, inkGrey)),
      const SizedBox(height: 4),
      Row(children: [
        for (final c in [_hand[0], _hand[2]]) ...[
          _framed(frameOf(c), cw, ch,
              _cardBody(c, cw, ch, inPlay: true, frame: frameOf(c)),
              fill: inkPaper, line: inkPaper),
          const SizedBox(width: 8),
        ],
      ]),
      const SizedBox(height: 10),
      Text('Your hand', style: _prose(11, inkGrey)),
      const SizedBox(height: 14),
      Row(children: [
        for (var i = 0; i < _hand.length; i++) ...[
          _framed(
              frameOf(_hand[i]),
              cw,
              ch,
              _cardBody(_hand[i], cw, ch,
                  inPlay: false, frame: frameOf(_hand[i])),
              lift: i == 1),
          if (i < _hand.length - 1) const SizedBox(width: 6),
        ],
      ]),
      const SizedBox(height: 10),
      Container(
          width: _w - 20,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFA53030),
              borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          child: Text('Roll Dice', style: _prose(15, inkPaper, bold: true))),
    ]),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('combat frames', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    const kinds = [
      ('round', 'Rounded · today'),
      ('plain', 'Plain'),
      ('cut', 'Cut corners'),
      ('slant', 'Slanted'),
      ('split', 'Split panel'),
      ('burst', 'Burst edge'),
    ];
    final key = GlobalKey();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(_w * 4 + 5 * 10, 1320);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: const Color(0xFF05060A),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF05060A),
              padding: const EdgeInsets.all(10),
              child: Wrap(spacing: 10, runSpacing: 10, children: [
                for (final (k, l) in kinds) _panel(l, k, k, k, k),
                _panel(
                    'Per kind: skills rounded · spells cut · ultimate burst · '
                        'intents slanted',
                    'slant',
                    'round',
                    'cut',
                    'burst'),
              ]),
            ),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await r.toImage(pixelRatio: 1.25);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/combat-frames-412.png')
          .writeAsBytesSync(b!.buffer.asUint8List());
    });
  });
}
