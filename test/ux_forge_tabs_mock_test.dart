// The Forge sheet, reworked again (UX mock): the user found it had too many
// infos and wants tabs to switch between the kinds of piece. So: a tab for
// each equipment slot the forge makes (Head, Body, Legs, Feet: items.json
// equipSlot Head / Top / Bottom / Foot, from craftedAt), one short line for
// the d20 with its modifiers and odds behind a tap, and a compact card for
// each piece: its name, its numbers, what it needs with a tick or a cross,
// one button. The forging moment is the approved one (forge-moment-mock).
// The pieces are the real four of items.json at the Hammersmith's forge.
// UX_SHOTS=<folder> takes docs/ux-shots/forge-tabs-mock.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File('assets/fonts/$f').readAsBytesSync())
              .buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

const _bg = Color(0xFF111015);
const _card = Color(0xFF211E27);
const _good = Color(0xFF3E9B57);
const _bad = Color(0xFFD9625C);
const _gold = Color(0xFFE2B890);
const _ash = Color(0xFF9A93A6);
const _line = Color(0xFF3A3642);

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

class _Piece {
  const _Piece(this.name, this.slot, this.armor, this.ore, this.gold);
  final String name;
  final String slot;
  final int armor;
  final int ore;
  final int gold;
}

const _pieces = [
  _Piece('Iron Cap', 'Head', 1, 2, 45),
  _Piece('Iron Scale Coat', 'Body', 2, 5, 110),
  _Piece('Iron Greaves', 'Legs', 1, 4, 75),
  _Piece('Iron-Shod Boots', 'Feet', 1, 3, 60),
];

const _slotIcons = {
  'Head': Icons.sports_motorsports_outlined,
  'Body': Icons.checkroom_outlined,
  'Legs': Icons.airline_seat_legroom_normal,
  'Feet': Icons.hiking,
};

Widget _chip(String text, Color c, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.65)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 3)
        ],
        Text(text, style: _t(12, c: c, bold: true)),
      ]),
    );

Widget _phone(String title, Widget body) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: _t(13.5, c: _gold)),
        ),
        Container(
          width: 360,
          height: 560,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: body,
        ),
      ],
    );

/// The tabs: one for each kind of piece the forge makes, a dot where
/// something can be forged now, the count of pieces.
Widget _tabs(String selected, Map<String, bool> ready) => SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final slot in const ['Head', 'Body', 'Legs', 'Feet'])
            Padding(
              padding: const EdgeInsets.only(right: 5, top: 6, bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: slot == selected
                      ? const Color(0xFFB794F6).withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color:
                          slot == selected ? const Color(0xFFB794F6) : _line),
                ),
                child: Row(children: [
                  Icon(_slotIcons[slot],
                      size: 16, color: slot == selected ? Colors.white : _ash),
                  const SizedBox(width: 5),
                  Text(slot,
                      style: _t(13, c: slot == selected ? Colors.white : _ash)),
                  if (ready[slot] == true) ...[
                    const SizedBox(width: 4),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _good)),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );

Widget _need(String label, int have, int need) {
  final ok = have >= need;
  return _chip('$label  have $have · need $need', ok ? _good : _bad,
      icon: ok ? Icons.check : Icons.close);
}

Widget _pieceCard(_Piece p, {required int ore, required int gold}) {
  final can = ore >= p.ore && gold >= p.gold;
  return Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: can ? _gold.withValues(alpha: 0.5) : _line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFF2D2A35),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(_slotIcons[p.slot], color: _gold, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(p.name, style: _t(14.5, bold: true))),
        _chip('Armor +${p.armor}', _good),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 5, children: [
        _need('Iron ore', ore, p.ore),
        _need('Gold', gold, p.gold),
      ]),
      const SizedBox(height: 9),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: can ? () {} : null,
          icon: Icon(can ? Icons.hardware : Icons.lock_outline, size: 17),
          label: Text(can ? 'Forge' : 'Short of ${p.ore - ore} iron ore'),
        ),
      ),
    ]),
  );
}

/// The d20 line: short; the modifiers and the odds are behind a tap.
Widget _rollLine({required bool open}) {
  Widget odds() => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip('Dwarf hero +2', _good),
            _chip('Friends of the Pact +1', _good),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const Row(children: [
              Expanded(
                  flex: 5,
                  child: SizedBox(
                      height: 8, child: ColoredBox(color: Color(0xFFD9625C)))),
              Expanded(
                  flex: 50,
                  child: SizedBox(
                      height: 8, child: ColoredBox(color: Color(0xFF9A93A6)))),
              Expanded(
                  flex: 25,
                  child: SizedBox(
                      height: 8, child: ColoredBox(color: Color(0xFF6CC3A0)))),
              Expanded(
                  flex: 20,
                  child: SizedBox(
                      height: 8, child: ColoredBox(color: Color(0xFFF2C14E)))),
            ]),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: Text('Flawed 5%',
                    style: _t(10, c: const Color(0xFFD9625C)))),
            Expanded(child: Text('Sound 50%', style: _t(10, c: _ash))),
            Expanded(
                child: Text('Fine 25%',
                    style: _t(10, c: const Color(0xFF6CC3A0)))),
            Expanded(
                child: Text('Masterwork 20%',
                    style: _t(10, c: const Color(0xFFF2C14E)))),
          ]),
          const SizedBox(height: 6),
          Text(
              'A flawed piece is −1 armor and loses nothing; Fine +1; Masterwork +2.',
              style: _t(11, c: _ash, italic: true)),
        ]),
      );
  return Container(
    margin: const EdgeInsets.fromLTRB(14, 2, 14, 10),
    padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1820),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.casino_outlined, size: 16, color: _gold),
        const SizedBox(width: 7),
        Text('Roll', style: _t(13, c: _ash)),
        const SizedBox(width: 6),
        Text('d20 + 3', style: _px(15)),
        const Spacer(),
        Text(open ? 'hide' : 'odds', style: _t(12, c: _ash)),
        Icon(open ? Icons.expand_less : Icons.expand_more,
            size: 20, color: _ash),
      ]),
      if (open) odds(),
    ]),
  );
}

Widget _header({required bool noteOpen}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
                color: _ash.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 14, 2),
          child: Row(children: [
            Text('Forge', style: _t(17)),
            const SizedBox(width: 8),
            // Where the ore drops: behind an (i), not a paragraph.
            Icon(Icons.info_outline, size: 18, color: noteOpen ? _gold : _ash),
            const Spacer(),
            const Icon(Icons.monetization_on_outlined, size: 16, color: _gold),
            const SizedBox(width: 4),
            Text('112', style: _px(14, c: _gold)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text(
              '“Too heavy for the Weaponsmith, so it came to me.”  Dagny',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(12, c: _ash, italic: true)),
        ),
        if (noteOpen)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                'Iron ore drops from Inquisition soldiers, the dock overseer, wisps, the iron golem and the catacombs’ dead.',
                style: _t(11.5, c: _ash)),
          ),
      ],
    );

Widget _sheet({
  required String tab,
  required bool rollOpen,
  bool noteOpen = false,
  required int ore,
}) {
  final slotPieces = [
    for (final p in _pieces)
      if (p.slot == tab) p
  ];
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _header(noteOpen: noteOpen),
    _tabs(tab, {
      for (final p in _pieces) p.slot: ore >= p.ore,
    }),
    _rollLine(open: rollOpen),
    for (final p in slotPieces) _pieceCard(p, ore: ore, gold: 112),
  ]);
}

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('The Forge: tabs by kind of piece, less on each card',
            style: _t(18)),
        const SizedBox(height: 4),
        Text(
            'One short d20 line (modifiers and odds behind a tap), the ore hint behind the (i), '
            'one compact card for each piece: name, numbers, what it needs with a tick or a cross, one button. '
            'The forging moment is the approved one.',
            style: _t(11.5, c: _ash)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _phone('Feet · the d20 line closed',
              _sheet(tab: 'Feet', rollOpen: false, ore: 5)),
          const SizedBox(width: 22),
          _phone('Legs · odds opened, the piece short of ore',
              _sheet(tab: 'Legs', rollOpen: true, ore: 3)),
          const SizedBox(width: 22),
          _phone('Head · the (i) opened',
              _sheet(tab: 'Head', rollOpen: false, noteOpen: true, ore: 5)),
        ]),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('a tab for each slot the forge makes, with the real pieces', () {
    expect({for (final p in _pieces) p.slot}, {'Head', 'Body', 'Legs', 'Feet'});
    expect(_pieces.length, 4);
  });

  testWidgets('a picture of the forge tabs (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1240, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: const Color(0xFF17151B),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(color: const Color(0xFF17151B), child: _board()),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/forge-tabs-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
