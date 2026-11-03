// The in-place choices, refined (UX mock): the two designs the user kept, the
// scene panel and stage mode, drawn again at 412 and 320 px on four scenes of
// the story (the Stone Bridge, the family house, Vane's gate with four
// choices, the price of the crossing with long choices, in French), and how
// the two could live together. Nothing is built.
// UX_SHOTS=<folder> takes the pictures (docs/ux-shots/inplace-refined/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'ux_inplace_refined_parts.dart';
import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _note = TextStyle(
    fontFamily: 'Spectral',
    fontSize: 12.5,
    height: 1.3,
    color: Color(0xFFD9D1C6));

/// A phone with a title over it and a few notes under it.
Widget _frame(BuildContext context, String title, double w, Widget screen,
    List<String> notes) {
  return SizedBox(
    width: w,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: 13,
              color: Color(0xFFF2C14E))),
      const SizedBox(height: 6),
      Phone(w: w, child: screen),
      const SizedBox(height: 8),
      for (final n in notes)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('•  $n', style: _note),
        ),
    ]),
  );
}

Widget _board(
    BuildContext context, String title, String sub, List<Widget> phones) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 1500,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: boardInk)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 14,
                  height: 1.3,
                  color: Color(0xFFB9B0C2))),
        ]),
      ),
      const SizedBox(height: 18),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in phones) ...[p, const SizedBox(width: 26)],
      ]),
    ]),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  test('the four scenes are real nodes of the story', () {
    final story = File('assets/Cleaned_Narrative_DAG.json').readAsStringSync();
    for (final id in ['"260"', '"400"', '"2015_vane"', '"7002_price"']) {
      expect(story.contains(id), isTrue, reason: id);
    }
    expect(bridge.picks, hasLength(2));
    expect(house.picks, hasLength(3));
    expect(vane.picks, hasLength(4));
    expect(
        price.picks.map((p) => p.text.length).reduce((a, b) => a > b ? a : b),
        greaterThan(55));
  });

  testWidgets('the boards (UX_SHOTS)', (tester) async {
    if (shots == null || shots.isEmpty) return;
    await tester.runAsync(loadAppFonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1700, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Directory(shots).createSync(recursive: true);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark));

    Future<void> shoot(String file, Widget Function(BuildContext) build) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: Material(
              color: const Color(0xFF17151B),
              child: Builder(builder: build),
            ),
          ),
        ),
      ));
      await _settle(tester);
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1.25);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull, reason: file);
    }

    await shoot('panel-1.png', (c) {
      return _board(
          c,
          'Scene panel, refined: the Stone Bridge and the family house',
          'The map stays in view above the panel, lit and a third of the screen, with the road of the choice you have picked; the panel is a vignette, the question, the cards. A first tap picks (Go shows), a second does it, as everywhere.',
          [
            _frame(c, 'The Stone Bridge · 412', 412,
                panelScreen(c, bridge, 412, selected: 0), [
              'Two choices: the vignette stays (you, the toll keeper, what he said).',
              'Neither choice moves you before it is done, so the map strip only shows where you stand.',
            ]),
            _frame(c, 'The Stone Bridge · 320', 320,
                panelScreen(c, bridge, 320, selected: 0), [
              'The map strip drops to 118 px, the vignette to 1.6x sprites; nothing scrolls.',
            ]),
            _frame(c, 'Your family\'s house · 412', 412,
                panelScreen(c, house, 412, selected: 2), [
              'Picking "Run" lights its road on the map strip, to a pin named The Black Hold; the card says it too.',
              'Three choices still fit with the vignette.',
            ]),
            _frame(c, 'Your family\'s house · 320', 320,
                panelScreen(c, house, 320, selected: 2), [
              'At 320 px the vignette shrinks (1.6x sprites) and all three cards still fit; with a fourth it would fold to one line.',
            ]),
          ]);
    });
    await shoot('panel-2.png', (c) {
      return _board(
          c,
          'Scene panel, refined: four choices, and long choices in French',
          'With four choices or a text of more than a line the vignette folds to one line (who speaks, what was said) so the cards keep the room; a list that is still too long scrolls under a fade, never cut short.',
          [
            _frame(c, 'Vane\'s gate (4 choices) · 412', 412,
                panelScreen(c, vane, 412, selected: 2), [
              'The vignette is the speaker line, all four cards fit with their tags (checks and a move).',
              'A choice that moves you ("Push past him") shows its road on the strip.',
            ]),
            _frame(c, 'Vane\'s gate · 320', 320,
                panelScreen(c, vane, 320, selected: 1), [
              'Four cards of one or two lines fit at 320 px with room to spare; the fade at the foot only shows when the list is longer.',
            ]),
            _frame(c, 'The price of the crossing (FR) · 412', 412,
                panelScreen(c, price, 412, fr: true, selected: 3), [
              'No one is faced (the Sovereign is a voice): the speaker line shows the voice, not a face.',
              'Long French choices wrap to two or three lines with their tag; nothing is cut.',
            ]),
            _frame(c, 'The price of the crossing (FR) · 320', 320,
                panelScreen(c, price, 320, fr: true, selected: 3), [
              'At 320 px all four fit, the last on four lines. Five choices, or the same text with two more words, would scroll under the fade; the map strip could fold away then.',
            ]),
          ]);
    });
    await shoot('stage-1.png', (c) {
      return _board(
          c,
          'Stage mode, refined: the Stone Bridge and the family house',
          'The choices no longer float over the map and the sprites: the stage keeps the two figures and the other\'s line, and the choices are a tray of bubbles under it, hung on a thread from the hero. A choice that moves you shows a door at the stage\'s edge, lit when picked.',
          [
            _frame(c, 'The Stone Bridge · 412', 412,
                stageScreen(c, bridge, 412, selected: 1, balloon: true), [
              'After the tap: the picked bubble rises into a balloon over the hero, the others fade, and the thug would answer.',
              'The door at the right edge names where the fight leaves you (Your Family\'s House).',
            ]),
            _frame(c, 'The Stone Bridge · 320', 320,
                stageScreen(c, bridge, 320, selected: 1), [
              'Sprites drop to 2.2x and the stage to 236 px; the tray still holds both bubbles.',
            ]),
            _frame(c, 'Your family\'s house · 412', 412,
                stageScreen(c, house, 412, selected: 2, balloon: true), [
              'Aurel Vane has his own sprite; the face-off is the one scene that is a fight.',
              '"Run" is said aloud (the balloon) and lights the door at the right: the hero turns and leaves by it.',
            ]),
            _frame(c, 'Your family\'s house · 320', 320,
                stageScreen(c, house, 320, selected: 2), [
              'Three bubbles fit at 320 px.',
            ]),
          ]);
    });
    await shoot('stage-2.png', (c) {
      return _board(
          c,
          'Stage mode, refined: four choices, and long choices in French',
          'Four bubbles fit under the stage at both widths; a fifth, or a longer French line, would scroll the tray, and the stage could shrink while it does. A scene with no one to face (the Sovereign\'s voice) has only the hero and the voice\'s line.',
          [
            _frame(c, 'Vane\'s gate (4 choices) · 412', 412,
                stageScreen(c, vane, 412, selected: 2), [
              'Vane has a stand-in sprite (an Inquisition soldier) until he gets his own.',
              'The door says where "Push past him" goes.',
            ]),
            _frame(c, 'Vane\'s gate · 320', 320,
                stageScreen(c, vane, 320, selected: 2), [
              'Four bubbles fit at 320 px under the 236 px stage; a fifth would scroll the tray.',
            ]),
            _frame(c, 'The price of the crossing (FR) · 412', 412,
                stageScreen(c, price, 412, fr: true, selected: 3), [
              'No facing sprite: the stage is the hero alone and the voice in its box.',
              'Long bubbles wrap to two lines; all four fit with room left.',
            ]),
            _frame(c, 'The price of the crossing (FR) · 320', 320,
                stageScreen(c, price, 320, fr: true, selected: 3), [
              'The weakest case: a stage that is nearly empty (the hero and a boxed voice) over four long bubbles. A scene like this reads better as a panel.',
            ]),
          ]);
    });

    await shoot('coexist.png', (c) {
      Widget small(String title, String rule, Widget phone) => SizedBox(
            width: 412 * 0.72,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 13,
                      color: Color(0xFFF2C14E))),
              const SizedBox(height: 4),
              SizedBox(
                  height: 40,
                  child: Text(rule, style: _note.copyWith(fontSize: 12))),
              SizedBox(
                width: 412 * 0.72,
                height: 412 * 2.16 * 0.72,
                child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                    child: phone),
              ),
            ]),
          );
      return _board(
          c,
          'How the two live together: the panel talks, the stage faces',
          'One set of cards, one transition. The scene\'s kind picks the screen: a hub stays on the map with its rings; a scene with a fight against someone who has a sprite is the stage; every other scene (talk, decide, pay, checks, a voice) is the panel.',
          [
            small(
                'Panel: talk and decide',
                'Vane\'s gate: checks, a move, a refusal. Quiet, text, four cards.',
                Phone(w: 412, child: panelScreen(c, vane, 412, selected: 2))),
            small(
                'Stage: a face-off',
                'The family house: Aurel Vane is faced and one choice is a fight. The stage is what a fight is.',
                Phone(
                    w: 412,
                    child: stageScreen(c, house, 412,
                        selected: 0, balloon: true))),
            small(
                'Panel: no one is faced',
                'The price of the crossing: a voice, long choices. The panel carries them.',
                Phone(
                    w: 412,
                    child: panelScreen(c, price, 412, fr: true, selected: 1))),
          ]);
    });
  });
}
