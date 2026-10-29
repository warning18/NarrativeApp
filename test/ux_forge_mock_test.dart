// A mock of the Forge, for the user to approve before anything is built (UX;
// Core's rule is docs/proposals/forge-roll.md on claude/core-forge-roll: the
// forge rolls its own d20, modifiers add with their sources, the total reads
// as Flawed / Sound / Fine / Masterwork). Two pictures:
//   forge-sheet-mock.png   the sheet today and reworked
//   forge-moment-mock.png  the forging, in four beats
// The die is the game's own D20Roll; everything else is drawn here.
// UX_SHOTS=<folder> takes both.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/d20_roll.dart';
import 'support/fonts.dart';

const _bg = Color(0xFF17151B);
const _card = Color(0xFF211E27);
const _good = Color(0xFF3E9B57);
const _bad = Color(0xFFD9625C);
const _gold = Color(0xFFE2B890);
const _ash = Color(0xFF9A93A6);
const _ember = Color(0xFFFF9B3D);

/// A tier of the forge's roll and what it does to a piece.
class _Tier {
  const _Tier(this.name, this.range, this.delta, this.colour);
  final String name;
  final String range;
  final int delta;
  final Color colour;
}

const _tiers = [
  _Tier('Flawed', '1–4', -1, _bad),
  _Tier('Sound', '5–14', 0, _ash),
  _Tier('Fine', '15–19', 1, Color(0xFF6CC3A0)),
  _Tier('Masterwork', '20+', 2, Color(0xFFF2C14E)),
];

TextStyle _t(double size, {Color? c, bool bold = false, bool italic = false}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        height: 1.25,
        color: c ?? const Color(0xFFEDE6DC),
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal);

TextStyle _px(double size, {Color? c}) => TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: size,
    color: c ?? const Color(0xFFEDE6DC));

Widget _chip(String text, Color c, {IconData? icon, bool fill = false}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: fill ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.7)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4)
        ],
        Text(text, style: _t(12.5, c: c, bold: true)),
      ]),
    );

Widget _phone(String title, Widget body, {double w = 360, double h = 760}) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: _t(14, c: _gold)),
      ),
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF111015),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3642)),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    ]);

Widget _grab() => Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
            color: _ash.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2)),
      ),
    );

Widget _goldBadge(int n) => Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.monetization_on_outlined, size: 16, color: _gold),
      const SizedBox(width: 4),
      Text('$n', style: _px(14, c: _gold)),
    ]);

Widget _pieceIcon() => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: const Color(0xFF2D2A35),
          borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.hiking, color: _gold, size: 24),
    );

// ---------------------------------------------------------------- the sheet

/// Today's sheet: the hint, one card per piece, "Needs: Iron ore 5/3 · 60 gold".
Widget _sheetToday() =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _grab(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(children: [
          Expanded(child: Text('Forge', style: _t(17))),
          _goldBadge(112),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
            'Iron ore comes off Inquisition soldiers, the dock overseer, wisps, the iron golem and the dead of the catacombs.',
            style: _t(12, c: _ash)),
      ),
      for (final (n, ore) in const [
        ('Iron-Shod Boots', 5),
        ('Iron-Shod Greaves', 1)
      ])
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _pieceIcon(),
              const SizedBox(width: 12),
              Expanded(child: Text(n, style: _t(14, bold: true))),
              FilledButton(
                  onPressed: ore >= 3 ? () {} : null,
                  child: const Text('Forge')),
            ]),
            const SizedBox(height: 6),
            Wrap(
                spacing: 6,
                children: [_chip('Armor +2', _good), _chip('Speed −1', _bad)]),
            const SizedBox(height: 4),
            Text('Needs: Iron ore $ore/3 · 60 gold', style: _t(12, c: _ash)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Forging shows a notice: “Forged: Iron-Shod Boots”.',
            style: _t(12, c: _bad, italic: true)),
      ),
    ]);

/// The reworked sheet.
Widget _sheetNew() {
  Widget need(String label, int have, int need, {IconData? icon}) {
    final ok = have >= need;
    return Row(children: [
      Icon(ok ? Icons.check_circle : Icons.cancel,
          size: 16, color: ok ? _good : _bad),
      const SizedBox(width: 6),
      Expanded(child: Text(label, style: _t(13))),
      Text('you carry ', style: _t(12, c: _ash)),
      Text('$have', style: _t(13, c: ok ? _good : _bad, bold: true)),
      Text('  ·  needs ', style: _t(12, c: _ash)),
      Text('$need', style: _t(13, bold: true)),
    ]);
  }

  Widget odds() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.casino_outlined, size: 16, color: _gold),
          const SizedBox(width: 6),
          Text('Your roll: d20 + 3', style: _t(13, bold: true)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 4, children: [
          _chip('Dwarf hero +2', _good),
          _chip('Friends of the Pact +1', _good),
        ]),
        const SizedBox(height: 8),
        // The odds of each tier with those modifiers: 5 / 50 / 25 / 20.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            for (final (t, pct) in [
              (_tiers[0], 5),
              (_tiers[1], 50),
              (_tiers[2], 25),
              (_tiers[3], 20)
            ])
              Expanded(
                flex: pct,
                child: Container(
                  height: 8,
                  color: t.colour,
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          for (final (t, pct) in [
            (_tiers[0], 5),
            (_tiers[1], 50),
            (_tiers[2], 25),
            (_tiers[3], 20)
          ])
            Expanded(
              child: Text('${t.name} $pct%', style: _t(10, c: t.colour)),
            ),
        ]),
      ]);

  Widget piece(String name, int ore, {required bool can}) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: can
                    ? _gold.withValues(alpha: 0.5)
                    : const Color(0xFF33303B))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _pieceIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _t(14.5, bold: true)),
                    Text('Uncommon · boots', style: _t(11.5, c: _ash)),
                  ]),
            ),
          ]),
          const SizedBox(height: 8),
          // The piece's numbers by tier: the result is read before the roll.
          Row(children: [
            Text('Armor', style: _t(12, c: _ash)),
            const SizedBox(width: 8),
            for (final t in _tiers) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: t.colour.withValues(alpha: t.delta == 0 ? 0.22 : 0.10),
                  border: Border.all(color: t.colour.withValues(alpha: 0.7)),
                ),
                child: Text('${2 + t.delta}', style: _px(13, c: t.colour)),
              ),
            ],
            const SizedBox(width: 4),
            Text('Speed −1', style: _t(12, c: _bad)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 52),
            child: Text('flawed · sound · fine · masterwork',
                style: _t(10.5, c: _ash)),
          ),
          const SizedBox(height: 8),
          need('Iron ore', ore, 3),
          const SizedBox(height: 3),
          need('Gold', 112, 60),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: can ? () {} : null,
              icon: Icon(can ? Icons.hardware : Icons.lock_outline, size: 18),
              label:
                  Text(can ? 'Forge it: roll the d20' : 'Short of 2 iron ore'),
            ),
          ),
        ]),
      );

  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _grab(),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(children: [
        Expanded(child: Text('Forge', style: _t(17))),
        _goldBadge(112),
      ]),
    ),
    // The keeper speaks for the place.
    Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: _ember, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.face_6, size: 28, color: _gold),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dagny Ironhand', style: _t(11.5, c: _gold, bold: true)),
            Text(
                '“Too heavy for the Weaponsmith, so it came to me. Lift it before you pay for it.”',
                style: _t(12.5, italic: true)),
          ]),
        ),
      ]),
    ),
    // Where the ore drops, as one line with the ore's own icon, not a paragraph.
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.terrain, size: 15, color: _ash),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
              'Iron ore drops from Inquisition soldiers, the dock overseer, wisps, the iron golem and the catacombs’ dead.',
              style: _t(11.5, c: _ash)),
        ),
      ]),
    ),
    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: odds()),
    piece('Iron-Shod Boots', 5, can: true),
    piece('Iron-Shod Greaves', 1, can: false),
  ]);
}

// -------------------------------------------------------------- the moment

/// An anvil, a hammer and sparks; [swing] 0 raised, 1 struck; [burst] 0..1
/// sparks, [colour] theirs.
class _Anvil extends CustomPainter {
  _Anvil({required this.swing, required this.burst, required this.colour});
  final double swing;
  final double burst;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final base = size.height;
    final iron = Paint()..color = const Color(0xFF4A4655);
    final dark = Paint()..color = const Color(0xFF2E2B36);
    // The anvil: face, waist, foot.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.22, base - 54, w * 0.56, 18),
            const Radius.circular(3)),
        iron);
    canvas.drawRect(Rect.fromLTWH(w * 0.36, base - 38, w * 0.28, 20), dark);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, base - 20, w * 0.44, 12),
            const Radius.circular(3)),
        iron);
    // The piece glowing on it.
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, base - 62, w * 0.24, 9),
            const Radius.circular(4)),
        Paint()..color = Color.lerp(_ember, colour, burst * 0.6)!);
    // The hammer, pivoting round the hand.
    canvas.save();
    canvas.translate(w * 0.80, base - 90);
    canvas.rotate(-1.15 + swing * 1.0);
    canvas.drawRect(const Rect.fromLTWH(-72, -3, 72, 6),
        Paint()..color = const Color(0xFF8A6A48));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-92, -13, 26, 26), const Radius.circular(3)),
        iron);
    canvas.restore();
    // Sparks.
    final rng = math.Random(7);
    final p = Paint()
      ..color = colour
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    final centre = Offset(w * 0.5, base - 64);
    final n = (10 + burst * 26).round();
    for (var i = 0; i < n; i++) {
      final a = -math.pi + rng.nextDouble() * math.pi;
      final r0 = 8 + rng.nextDouble() * 10;
      final r1 = r0 + 10 + burst * (24 + rng.nextDouble() * 50);
      canvas.drawLine(centre + Offset(math.cos(a), math.sin(a)) * r0,
          centre + Offset(math.cos(a), math.sin(a)) * r1, p);
    }
  }

  @override
  bool shouldRepaint(_Anvil old) => false;
}

Widget _anvil({double swing = 0, double burst = 0.2, Color colour = _ember}) =>
    SizedBox(
      height: 150,
      child: CustomPaint(
          painter: _Anvil(swing: swing, burst: burst, colour: colour),
          size: const Size(double.infinity, 150)),
    );

Widget _beat(String n, String caption, List<Widget> body) => Container(
      width: 300,
      height: 560,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111015),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3642)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$n  $caption', style: _t(12.5, c: _gold)),
        const SizedBox(height: 10),
        ...body,
      ]),
    );

Widget _modifierRow(String label, String value, {required bool landed}) =>
    Opacity(
      opacity: landed ? 1 : 0.28,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: _t(13))),
          Text(value, style: _px(14, c: _good)),
        ]),
      ),
    );

Widget _tierStrip(int total) => Column(children: [
      Row(children: [
        for (final t in _tiers)
          Expanded(
            flex: t.name == 'Flawed'
                ? 4
                : t.name == 'Sound'
                    ? 10
                    : t.name == 'Fine'
                        ? 5
                        : 3,
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: t.colour,
            ),
          ),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        for (final t in _tiers)
          Expanded(
            flex: t.name == 'Flawed'
                ? 4
                : t.name == 'Sound'
                    ? 10
                    : t.name == 'Fine'
                        ? 5
                        : 3,
            child: Text(t.range,
                textAlign: TextAlign.center, style: _t(10, c: t.colour)),
          ),
      ]),
    ]);

Widget _beats() {
  const fine = Color(0xFF6CC3A0);
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _beat('1', 'The strike: the die is cast', [
      _anvil(swing: 0.1, burst: 0.1),
      const SizedBox(height: 4),
      SizedBox(
        height: 150,
        child: Stack(alignment: Alignment.center, children: [
          // The tumbling die: ghosts trail it.
          for (final (dx, o) in const [(-34.0, 0.18), (-17.0, 0.34)])
            Transform.translate(
              offset: Offset(dx, 6),
              child: Opacity(
                  opacity: o,
                  child: Transform.rotate(
                      angle: 0.5,
                      child:
                          const D20Roll(roll: 7, rolling: false, size: 110))),
            ),
          Transform.rotate(
              angle: 0.5,
              child: const D20Roll(roll: 7, rolling: false, size: 110)),
        ]),
      ),
      Center(
          child: Text('The forge rolls its own d20…',
              style: _t(13, c: _ash, italic: true))),
      const SizedBox(height: 14),
      _modifierRow('Dwarf hero', '+2', landed: false),
      _modifierRow('Friends of the Pact', '+1', landed: false),
    ]),
    const SizedBox(width: 12),
    _beat('2', 'It lands; the modifiers add up', [
      _anvil(swing: 1, burst: 0.55),
      const SizedBox(height: 4),
      const SizedBox(
          height: 150, child: D20Roll(roll: 13, rolling: false, size: 130)),
      const SizedBox(height: 10),
      _modifierRow('Die', '13', landed: true),
      _modifierRow('Dwarf hero', '+2', landed: true),
      _modifierRow('Friends of the Pact', '+1', landed: true),
      const Divider(color: Color(0xFF3A3642)),
      Row(children: [
        Expanded(child: Text('Total', style: _t(14, bold: true))),
        Text('16', style: _px(22, c: fine)),
      ]),
      const SizedBox(height: 10),
      _tierStrip(16),
    ]),
    const SizedBox(width: 12),
    _beat('3', 'The tier is read', [
      _anvil(swing: 1, burst: 1, colour: fine),
      const SizedBox(height: 6),
      Center(
        child: Text('FINE',
            style: _px(38, c: fine).copyWith(letterSpacing: 4, shadows: [
              Shadow(color: fine.withValues(alpha: 0.6), blurRadius: 18)
            ])),
      ),
      Center(
          child:
              Text('15–19 · +1 to the main number', style: _t(12.5, c: _ash))),
      const SizedBox(height: 12),
      _tierStrip(16),
      const SizedBox(height: 12),
      Text(
          'A flawed roll would have lost nothing: the piece is made, weaker, and can be sold.',
          style: _t(11.5, c: _ash, italic: true)),
      const SizedBox(height: 10),
      Text(
          'A camp roll house: one reroll, or +1 a day (once). The reroll replays this beat.',
          style: _t(11.5, c: _ash, italic: true)),
    ]),
    const SizedBox(width: 12),
    _beat('4', 'The piece: before and after', [
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fine.withValues(alpha: 0.8), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _pieceIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fine Iron-Shod Boots', style: _t(14.5, bold: true)),
                    Text('Uncommon · boots', style: _t(11.5, c: _ash)),
                  ]),
            ),
            _chip('Fine', fine, fill: true),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('Armor', style: _t(13)),
            const Spacer(),
            Text('2', style: _px(15, c: _ash)),
            const Icon(Icons.arrow_right_alt, size: 20, color: _ash),
            Text('3', style: _px(18, c: _good)),
            const SizedBox(width: 6),
            _chip('+1', _good),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('Speed', style: _t(13)),
            const Spacer(),
            Text('−1', style: _px(15, c: _bad)),
            const SizedBox(width: 6),
            Text('unchanged', style: _t(11.5, c: _ash)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('Sells for', style: _t(13)),
            const Spacer(),
            Text('45', style: _px(15, c: _ash)),
            const Icon(Icons.arrow_right_alt, size: 20, color: _ash),
            Text('56', style: _px(18, c: _good)),
            const SizedBox(width: 4),
            Text('+25%', style: _t(11.5, c: _good)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Text('Spent: 3 iron ore · 60 gold', style: _t(12, c: _ash)),
      const Spacer(),
      FilledButton(onPressed: () {}, child: const Text('Take it')),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: () {}, child: const Text('Forge another')),
    ]),
  ]);
}

Future<void> _shoot(
    WidgetTester tester, GlobalKey key, String path, double ratio) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadAppFonts);

  Future<void> show(
      WidgetTester tester, Widget child, Size size, GlobalKey key) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: _bg,
              child: Padding(padding: const EdgeInsets.all(18), child: child),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('the forge sheet, today and reworked (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    final key = GlobalKey();
    await show(
        tester,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _phone('Today', _sheetToday()),
          const SizedBox(width: 24),
          _phone('Reworked: the roll is on the sheet before it is taken',
              _sheetNew()),
        ]),
        const Size(840, 840),
        key);
    await _shoot(tester, key, '$dir/forge-sheet-mock.png', 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the forging, in four beats (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    final key = GlobalKey();
    await show(tester, _beats(), const Size(1360, 620), key);
    await _shoot(tester, key, '$dir/forge-moment-mock.png', 1.5);
    expect(tester.takeException(), isNull);
  });
}
