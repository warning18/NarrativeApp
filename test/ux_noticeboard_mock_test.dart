// A mock of the notice board, improved (UX, for the user to approve before
// anything is built). Today: a plain assignment icon on the district map, a
// sheet with one row ("Bounty board"), and a page of three grey cards with a
// bar and a tonal Claim. Proposed: the pin is a small board with a count of
// what waits; it opens straight on the board: a wooden board with the
// contracts as pinned notes (a stamp for the kind, the goal in the book's
// type, the progress as pips, the pay as chips, a wax seal to claim that
// glows when the note is met, DONE stamped over a claimed one), and a line
// for when a new board goes up.
// UX_SHOTS=<folder> takes docs/ux-shots/noticeboard-mock.png.
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
    ('Spectral', ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
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

class _Note {
  const _Note(this.icon, this.goal, this.progress, this.required, this.gold,
      this.essence,
      {this.tilt = 0});
  final IconData icon;
  final String goal;
  final int progress;
  final int required;
  final int gold;
  final int essence;
  final double tilt;
}

const _notes = [
  _Note(Icons.pets, 'Put down 3 × Harbor Rat', 2, 3, 60, 4, tilt: -0.012),
  _Note(Icons.groups, 'Win 2 fights against a pack', 2, 2, 90, 6, tilt: 0.01),
  _Note(Icons.shield_moon, 'Win 2 fights with nobody down and no potion drunk',
      0, 2, 120, 8,
      tilt: -0.008),
];

/// Today's page: three plain cards.
Widget _today(BuildContext context) {
  final theme = Theme.of(context);
  return Scaffold(
    appBar: AppBar(title: const Text('Bounty board')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      for (final n in _notes)
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Icon(n.icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.goal, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: n.progress / n.required,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${n.progress}/${n.required}',
                          style: theme.textTheme.labelSmall),
                    ]),
                    const SizedBox(height: 4),
                    Text('+${n.gold} Gold · +${n.essence} Essence',
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                  onPressed: n.progress >= n.required ? () {} : null,
                  child: const Text('Claim')),
            ]),
          ),
        ),
      Text(
          'Fights anywhere count. A new board goes up once these are claimed '
          'or the chapter turns.',
          style: theme.textTheme.bodySmall),
    ]),
  );
}

const _paper = Color(0xFFE9DCC1);
const _ink = Color(0xFF2B2420);
const _wood = Color(0xFF4A3526);

Widget _pip(bool on) => Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? const Color(0xFF8C3A2B) : Colors.transparent,
        border: Border.all(color: const Color(0xFF8C3A2B), width: 1.6),
      ),
    );

Widget _noteCard(_Note n) {
  final met = n.progress >= n.required;
  return Transform.rotate(
    angle: n.tilt,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF8C3A2B), width: 2),
                  ),
                  child: Icon(n.icon, size: 20, color: const Color(0xFF8C3A2B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(n.goal,
                      style: const TextStyle(
                          fontFamily: 'Spectral',
                          fontSize: 17,
                          height: 1.3,
                          color: _ink,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (var i = 0; i < n.required; i++) _pip(i < n.progress),
                const SizedBox(width: 6),
                Text(met ? 'Done' : '${n.progress} of ${n.required}',
                    style: const TextStyle(
                        fontFamily: 'PixelifySans',
                        fontSize: 13,
                        color: Color(0xFF6B5A48))),
                const Spacer(),
                _chip(Icons.paid_outlined, '${n.gold}'),
                const SizedBox(width: 6),
                _chip(Icons.auto_awesome, '${n.essence}'),
                // Room for the seal.
                const SizedBox(width: 52),
              ]),
            ],
          ),
        ),
        // The pin at the top.
        const Positioned(
          top: -6,
          left: 0,
          right: 0,
          child: Center(
            child: Icon(Icons.push_pin, size: 22, color: Color(0xFF8C3A2B)),
          ),
        ),
        // The wax seal: a Claim, glowing when the note is met.
        Positioned(
          right: 10,
          bottom: -14,
          child: Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? const Color(0xFFB0392B) : const Color(0xFF8A7F73),
              boxShadow: [
                if (met)
                  const BoxShadow(
                      color: Color(0xAAF2C14E),
                      blurRadius: 14,
                      spreadRadius: 1),
                const BoxShadow(
                    color: Colors.black45, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
            child: Text('Claim',
                style: TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 12,
                    color: met ? const Color(0xFFFFE9B0) : Colors.white70)),
          ),
        ),
      ]),
    ),
  );
}

Widget _chip(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x22000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF6B5A48)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontFamily: 'PixelifySans', fontSize: 13, color: _ink)),
      ]),
    );

/// The proposed board.
Widget _board(BuildContext context) {
  final theme = Theme.of(context);
  final ink = InkColors.dark;
  return Scaffold(
    backgroundColor: _wood,
    appBar: AppBar(
      backgroundColor: const Color(0xFF3A2A1E),
      title: const Text('Notice board'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(
            child: Text('Chapter 2 · 1 to claim',
                style: theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
          ),
        ),
      ],
    ),
    body:
        ListView(padding: const EdgeInsets.only(top: 6, bottom: 24), children: [
      for (final n in _notes) ...[
        _noteCard(n),
        const SizedBox(height: 12),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Text(
          'Fights anywhere count. When these are claimed, or the chapter '
          'turns, new notices go up.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      ),
    ]),
  );
}

/// A district's corner of the map, with the service pin as it is today and
/// as proposed.
Widget _pin(bool proposed) {
  return SizedBox(
    width: 150,
    height: 110,
    child: Stack(children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2B2822),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF554F44)),
          ),
        ),
      ),
      // Two blocks of the district.
      Positioned(
          left: 14,
          top: 18,
          child:
              Container(width: 52, height: 34, color: const Color(0xFF45403A))),
      Positioned(
          right: 14,
          bottom: 18,
          child:
              Container(width: 60, height: 30, color: const Color(0xFF3F3A34))),
      Positioned(
        left: 62,
        top: 30,
        child: proposed
            ? Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 34,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _wood,
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: const Color(0xFF8A6A4A), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  child: Stack(children: [
                    Positioned(
                        left: 4,
                        top: 4,
                        child: Container(width: 12, height: 9, color: _paper)),
                    Positioned(
                        right: 4,
                        top: 6,
                        child: Container(width: 12, height: 9, color: _paper)),
                    Positioned(
                        left: 10,
                        bottom: 3,
                        child: Container(width: 13, height: 8, color: _paper)),
                  ]),
                ),
                // What waits: a count, red when one can be claimed.
                Positioned(
                  right: -9,
                  top: -9,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFB0392B)),
                    child: const Text('1',
                        style: TextStyle(
                            fontFamily: 'PixelifySans',
                            fontSize: 12,
                            color: Colors.white)),
                  ),
                ),
              ])
            : Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFE9E2D2)),
                child: const Icon(Icons.assignment_outlined,
                    size: 17, color: Color(0xFF2B2420)),
              ),
      ),
    ]),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a picture of the notice board (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1700, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final theme = buildAppTheme(const ColorScheme.dark());
    Widget phone(String title, WidgetBuilder page) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 14,
                      color: Color(0xFFE2B890))),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Theme(
                    data: theme,
                    child: MediaQuery(
                      data: const MediaQueryData(size: Size(390, 700)),
                      child: Builder(builder: page),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0C0B0F),
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF0C0B0F),
            child: Row(children: [
              // The pins, today and proposed, above their pages.
              Expanded(
                child: Column(children: [
                  const SizedBox(height: 8),
                  const Text('The pin on the district map',
                      style: TextStyle(
                          fontFamily: 'Spectral',
                          fontSize: 14,
                          color: Color(0xFFE2B890))),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(children: [
                      _pin(false),
                      const SizedBox(height: 4),
                      const Text('today',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                    ]),
                    const SizedBox(width: 18),
                    Column(children: [
                      _pin(true),
                      const SizedBox(height: 4),
                      const Text('a board, with what waits',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  Expanded(
                      child: Builder(
                          builder: (context) => phoneBody(
                              context,
                              theme,
                              _today,
                              'Today: a sheet with one row, then this page'))),
                ]),
              ),
              phone('Proposed: the pin opens straight on the board', _board),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/noticeboard-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

Widget phoneBody(BuildContext context, ThemeData theme, WidgetBuilder page,
        String title) =>
    Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 14,
                color: Color(0xFFE2B890))),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Theme(
              data: theme,
              child: MediaQuery(
                data: const MediaQueryData(size: Size(390, 700)),
                child: Builder(builder: page),
              ),
            ),
          ),
        ),
      ]),
    );
