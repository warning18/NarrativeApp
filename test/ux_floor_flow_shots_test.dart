// PICTURES (UX_SHOTS=<folder>): three versions of how a floor works when it
// holds a choice (a shortcut, a parley, a bargain) or a test (a setback, a
// rival): A a modal on arrival, B the choice built into the Fight button, C a
// landing > choice > climb strip. The d20 rolls when the player climbs, not on
// arrival. Mocks over the real floor pieces; not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_bands.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';

import 'support/fonts.dart';

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

const _floor = 14;

/// The floor behind: header, the foe's band, the hero's band; [below] is what
/// each version puts under them (the choice, the Fight button).
Widget _floorScreen({required Widget below, Widget? top, Widget? modal}) =>
    TowerBackdrop(
      floor: _floor,
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (top != null) ...[top, const SizedBox(height: 10)],
            Text('THE MIDDLE HALLS',
                style: _p(11, inkGrey, w: FontWeight.w700)),
            Text('Floor $_floor of 30', style: _d(26, inkPaper)),
            const SizedBox(height: 8),
            InkFoeBand(
              plate: towerBackdropAsset(towerBandOf(_floor)),
              foes: const [InkBandFoe('slum_thug', 'Slum Thug')],
            ),
            const SizedBox(height: 10),
            InkHeroBand(
              plate: towerBackdropAsset(towerBandOf(_floor)),
              sprite: heroSpriteFor('human', 'warrior'),
              health: 0.83,
              healthText: '29 / 35',
              healthKey: const Key('hp'),
              title: 'Your health',
            ),
            const SizedBox(height: 12),
            Expanded(child: below),
          ]),
        ),
        if (modal != null) ...[
          Positioned.fill(
              child: ColoredBox(color: inkBlack.withValues(alpha: 0.78))),
          Positioned.fill(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
                  child: Center(
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: inkBlack.withValues(alpha: 0.97),
                              border: Border.all(color: inkPaper, width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          child: modal)))),
        ],
      ]),
    );

enum _K { win, lose, plain }

/// One line of outcome: "Win: ..." green, "Lose: ..." red, a plain one grey.
Widget _line(_K k, String text) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 38,
            child: Text(
                switch (k) {
                  _K.win => 'Win',
                  _K.lose => 'Lose',
                  _K.plain => ''
                },
                style: _p(11.5, k == _K.win ? inkMore : inkLess,
                    w: FontWeight.w800))),
        Expanded(child: Text(text, style: _p(12, inkPaper))),
      ]),
    );

/// An option: its title, one outcome line per result, and its button.
Widget _option(String title, List<Widget> lines,
        {String? button,
        bool primary = false,
        bool selected = false,
        Widget? lead}) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: inkBlack.withValues(alpha: 0.92),
          border: Border.all(
              color: selected ? inkRed : inkPaper, width: selected ? 2.5 : 1.5),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (lead != null) ...[lead, const SizedBox(width: 8)],
          Expanded(child: Text(title, style: _d(16, inkPaper))),
          if (selected) const Icon(Icons.check_circle, color: inkRed, size: 22),
        ]),
        const SizedBox(height: 4),
        ...lines,
        if (button != null) ...[
          const SizedBox(height: 10),
          _wide(InkButton(
              label: button, onPressed: () {}, primary: primary, height: 44)),
        ],
      ]),
    );

IconData get _stair => Icons.stairs;

Widget _stairLines() => Column(children: [
      _line(_K.win, 'Floors 14 and 15 are skipped, you land on floor 16.'),
      _line(_K.lose, 'The climb ends here.'),
      _line(_K.plain, 'An Elite stands in the fight’s place.'),
    ]);

Widget _doorLines() => Column(children: [
      _line(_K.plain, 'Fight the floor as usual. No risk, no skip.'),
    ]);

Widget _testLines() => Column(children: [
      _line(_K.win, 'You catch yourself and take a potion.'),
      _line(_K.lose, 'Your foot slips: fall to floor 13.'),
    ]);

Widget _wide(Widget b) => Row(children: [Expanded(child: b)]);

Widget _pill(String t, {Color c = inkGold}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(color: c, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: Text(t, style: _p(11, c, w: FontWeight.w800)),
    );

Widget _d20(String shown) => Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: inkBlack,
          border: Border.all(color: inkPaper, width: 2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(shown, style: _d(20, inkPaper)),
    );

// ---------------------------------------------------------------- Version A
// A modal on arrival: it cannot be dismissed without choosing; a forced test
// has one button. The d20 rolls on Climb.

Widget _a1() => _floorScreen(
      below: const SizedBox.shrink(),
      modal: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('A stair in the wall', style: _d(22, inkPaper)),
        Text('Choose your way: you cannot go on without.',
            style: _p(12, inkGrey)),
        const SizedBox(height: 10),
        _option('Take the stair', [_stairLines()],
            button: 'Take the stair',
            primary: true,
            lead: Icon(_stair, color: inkPaper)),
        const SizedBox(height: 10),
        _option('Take the door', [_doorLines()],
            button: 'Take the door',
            lead: const Icon(Icons.door_front_door_outlined, color: inkPaper)),
      ]),
    );

Widget _a2() => _floorScreen(
      below: const SizedBox.shrink(),
      modal: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Setback: a test of Dexterity', style: _d(20, inkPaper)),
        Text('A tread gives way under your foot. Catch yourself.',
            style: _p(12, inkGrey)),
        const SizedBox(height: 4),
        Text('Forced: this one you cannot refuse.',
            style: _p(11.5, inkLess, w: FontWeight.w700)),
        const SizedBox(height: 10),
        _option(
            'Face it',
            [
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                      'd20 +2 against 12 (65% to pass), rolled when you climb.',
                      style: _p(12, inkGrey))),
              _testLines(),
            ],
            button: 'Face it',
            primary: true,
            lead: const Icon(Icons.casino_outlined, color: inkPaper)),
      ]),
    );

Widget _a3() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: inkBlack.withValues(alpha: 0.9),
            border: Border.all(color: inkSlate),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.stairs, color: inkPaper, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('The stair: an Elite fights in this place',
                    style: _p(12.5, inkPaper))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.casino_outlined, color: inkPaper, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Dexterity test, d20 +2 against 12, when you climb',
                    style: _p(12.5, inkPaper))),
          ]),
        ]),
      ),
      const Spacer(),
      _wide(InkButton(
          label: 'Climb', onPressed: () {}, primary: true, height: 50)),
    ]));

Widget _a4() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: inkBlack.withValues(alpha: 0.92),
            border: Border.all(color: inkMore, width: 2),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          _d20('14'),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('14 + 2 = 16 against 12', style: _d(15, inkPaper)),
                Text('You catch yourself and take a potion.',
                    style: _p(12, inkMore, w: FontWeight.w700)),
              ])),
        ]),
      ),
      const Spacer(),
      _wide(InkButton(
          label: 'Fight', onPressed: () {}, primary: true, height: 50)),
    ]));

// ---------------------------------------------------------------- Version B
// The choice is built into the Fight button: the panel under the foes holds the
// ways, the button names what you commit to.

Widget _b1() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('CHOOSE YOUR WAY', style: _p(11, inkGrey, w: FontWeight.w800)),
      const SizedBox(height: 6),
      _option('Take the stair', [_stairLines()],
          lead: Icon(_stair, color: inkPaper)),
      const SizedBox(height: 8),
      _option('Take the door', [_doorLines()],
          lead: const Icon(Icons.door_front_door_outlined, color: inkPaper)),
      const Spacer(),
      _wide(
          const InkButton(label: 'Choose a way', onPressed: null, height: 50)),
    ]));

Widget _b2() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('CHOOSE YOUR WAY', style: _p(11, inkGrey, w: FontWeight.w800)),
      const SizedBox(height: 6),
      _option('Take the stair', [_stairLines()],
          selected: true, lead: Icon(_stair, color: inkPaper)),
      const SizedBox(height: 8),
      Opacity(
          opacity: 0.55,
          child: _option('Take the door', [_doorLines()],
              lead:
                  const Icon(Icons.door_front_door_outlined, color: inkPaper))),
      const Spacer(),
      _wide(InkButton(
          label: 'Climb the stair',
          onPressed: () {},
          primary: true,
          height: 50)),
    ]));

Widget _b3() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('SETBACK', style: _p(11, inkGrey, w: FontWeight.w800)),
        const SizedBox(width: 8),
        _pill('forced', c: inkLess),
      ]),
      const SizedBox(height: 6),
      _option(
          'A test of Dexterity',
          [
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    'A tread gives way under your foot. d20 +2 against 12, rolled when you climb.',
                    style: _p(12, inkGrey))),
            _testLines(),
          ],
          lead: const Icon(Icons.casino_outlined, color: inkPaper)),
      const Spacer(),
      _wide(InkButton(
          label: 'Climb and roll',
          onPressed: () {},
          primary: true,
          height: 50)),
    ]));

Widget _b4() => _floorScreen(
        below:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('SETBACK', style: _p(11, inkGrey, w: FontWeight.w800)),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: inkBlack.withValues(alpha: 0.92),
            border: Border.all(color: inkLess, width: 2),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          _d20('6'),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('6 + 2 = 8 against 12', style: _d(15, inkPaper)),
                Text('Your foot slips: fall to floor 13.',
                    style: _p(12, inkLess, w: FontWeight.w700)),
              ])),
        ]),
      ),
      const Spacer(),
      _wide(InkButton(
          label: 'Back to floor 13',
          onPressed: () {},
          primary: true,
          height: 50)),
    ]));

// ---------------------------------------------------------------- Version C
// A strip of three steps: Landing > Choice > Climb; each step one screen.

Widget _strip(int at) {
  Widget step(int n, String t) {
    final on = n == at;
    final done = n < at;
    return Expanded(
      child: Column(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: on ? inkRed : (done ? inkPaper : inkBlack),
              shape: BoxShape.circle,
              border: Border.all(color: on ? inkRed : inkPaper, width: 1.5)),
          child: done
              ? const Icon(Icons.check, size: 16, color: inkBlack)
              : Text('$n', style: _d(13, inkPaper)),
        ),
        const SizedBox(height: 2),
        Text(t,
            style: _p(10.5, on ? inkPaper : inkGrey,
                w: on ? FontWeight.w800 : null)),
      ]),
    );
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
        color: inkBlack.withValues(alpha: 0.85),
        border: Border.all(color: inkSlate),
        borderRadius: BorderRadius.circular(8)),
    child: Row(
        children: [step(1, 'Landing'), step(2, 'Choice'), step(3, 'Climb')]),
  );
}

Widget _c1() => _floorScreen(
    top: _strip(1),
    below: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Something waits on this floor: a stair in the wall.',
          style: _p(13, inkPaper)),
      const Spacer(),
      _wide(InkButton(
          label: 'See the choice',
          onPressed: () {},
          primary: true,
          height: 50)),
    ]));

Widget _c2() => _floorScreen(
    top: _strip(2),
    below: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _option('Take the stair', [_stairLines()],
          button: 'Take the stair',
          primary: true,
          lead: Icon(_stair, color: inkPaper)),
      const SizedBox(height: 8),
      _option('Take the door', [_doorLines()],
          button: 'Take the door',
          lead: const Icon(Icons.door_front_door_outlined, color: inkPaper)),
    ]));

Widget _c3() => _floorScreen(
    top: _strip(2),
    below: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text('SETBACK', style: _p(11, inkGrey, w: FontWeight.w800)),
        const SizedBox(width: 8),
        _pill('forced', c: inkLess),
      ]),
      const SizedBox(height: 6),
      _option(
          'A test of Dexterity',
          [
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    'A tread gives way under your foot. d20 +2 against 12.',
                    style: _p(12, inkGrey))),
            _testLines(),
          ],
          button: 'Face it',
          primary: true,
          lead: const Icon(Icons.casino_outlined, color: inkPaper)),
    ]));

Widget _c4() => _floorScreen(
    top: _strip(3),
    below: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('YOUR CLIMB', style: _p(11, inkGrey, w: FontWeight.w800)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: inkBlack.withValues(alpha: 0.92),
            border: Border.all(color: inkPaper, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.stairs, color: inkPaper, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('The stair', style: _d(15, inkPaper))),
            Text('change', style: _p(12, inkGold, w: FontWeight.w700)),
          ]),
          _stairLines(),
          const Divider(color: inkSlate, height: 18),
          Row(children: [
            const Icon(Icons.casino_outlined, color: inkPaper, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Dexterity test', style: _d(15, inkPaper))),
          ]),
          _testLines(),
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Rolled when you press Climb.',
                  style: _p(11.5, inkGrey))),
        ]),
      ),
      const Spacer(),
      _wide(InkButton(
          label: 'Climb', onPressed: () {}, primary: true, height: 50)),
    ]));

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final (name, frames) in [
    ('A', [_a1, _a2, _a3, _a4]),
    ('B', [_b1, _b2, _b3, _b4]),
    ('C', [_c1, _c2, _c3, _c4]),
  ]) {
    testWidgets('flow $name', skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412 * 4 + 24, 860);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
              home: Scaffold(
                  body: Row(children: [
                for (var i = 0; i < frames.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  SizedBox(width: 412, height: 860, child: frames[i]()),
                ],
              ]))),
        ),
      ));
      for (var i = 0; i < 24; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/flow-$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
