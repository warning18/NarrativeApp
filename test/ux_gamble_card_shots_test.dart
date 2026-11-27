// PICTURES (UX_SHOTS=<folder>): MOCKS of the GAMBLE card: one of the three is
// dealt face down; a good Perception shows a hint; the pick reveals it with a
// flip; no Change afterwards. The back and the '?' seal are the back of our own card
// here until Art's files arrive. Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

const _teal = Color(0xFF3E8E85);

/// The back of our own Tower card: same frame and corner, the card's own
/// dark stock and the ink hatching of its band, one paper '?' in the middle.
class _Back extends StatelessWidget {
  const _Back({this.band, this.peek = false});
  final Color? band;
  final bool peek;
  @override
  Widget build(BuildContext context) => Container(
        width: 122,
        height: 201,
        decoration: BoxDecoration(
            color: inkBlack,
            border: Border.all(color: inkPaper, width: 1.5),
            borderRadius: BorderRadius.circular(10)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Stack(fit: StackFit.expand, children: [
            Padding(
              padding: const EdgeInsets.all(7),
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: inkDark,
                      border: Border.all(color: inkGrey, width: 1))),
            ),
            if (band != null)
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 9, color: band)),
            if (peek)
              const Positioned(top: 0, left: 0, right: 0, child: _FacePeek()),
            Center(child: Text('?', style: _d(44, inkPaper))),
          ]),
        ),
      );
}

/// The top slice of the real face showing through (a hint of the family).
class _FacePeek extends StatelessWidget {
  const _FacePeek();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ClipRect(
          child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 52 / 201,
              child: _face()),
        ),
      );
}

Widget _face({String name = 'Court Die', String text = 'd6 · 1 2 2 3 4 5'}) =>
    SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.die,
        kind: 'Die',
        name: name,
        text: text,
        vignette: 'assets/visuals/none.png',
        badge: const Icon(Icons.casino, size: 16, color: inkBlack),
      ),
    );

Widget _skill() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.skill,
        kind: 'Skill',
        name: 'Parry',
        text: 'Block the next blow.',
        nudge: '+1 DEX',
        vignette: 'assets/visuals/none.png',
        badge: Icon(Icons.shield, size: 16, color: inkBlack),
      ),
    );

Widget _gear() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.gear,
        kind: 'Gear',
        name: 'Ash Cloak',
        text: '+2 armour.',
        vignette: 'assets/visuals/none.png',
        badge: Icon(Icons.checkroom, size: 16, color: inkBlack),
      ),
    );

Widget _fit(Widget c, double w) =>
    SizedBox(width: w, height: w * 201 / 122, child: FittedBox(child: c));

Widget _row(List<Widget> cards, double w, {List<String>? caps}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++)
          Column(children: [
            _fit(cards[i], w),
            if (caps != null) ...[
              const SizedBox(height: 4),
              Text(caps[i], style: _p(10.5, inkGrey)),
            ],
          ]),
      ],
    );

Widget _head(String t, String sub) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: _d(17, inkPaper)),
      Text(sub, style: _p(11.5, inkGrey)),
      const SizedBox(height: 8),
    ]);

Widget _flip(double scaleX, bool showFace) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(scaleX, 1, 1),
      child: showFace ? _face() : const _Back(),
    );

class _Sheet extends StatelessWidget {
  const _Sheet(this.width);
  final double width;
  @override
  Widget build(BuildContext context) {
    const cw0 = 0.0;
    final cw = (width - 64) / 3 + cw0;
    final fw = (width - 80) / 4;
    return TowerBackdrop(
      floor: 6,
      child: Container(
        color: inkBlack.withValues(alpha: 0.82),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _head('1 · Three cards, one face down',
              'Gamble: you see what you pick only after.'),
          _row([_skill(), const _Back(), _gear()], cw,
              caps: ['Parry', 'Face down', 'Ash Cloak']),
          const SizedBox(height: 10),
          _head('2 · Good Perception: a hint',
              'Colour of its family, or a slice of its face.'),
          _row([const _Back(band: _teal), const _Back(peek: true)], cw,
              caps: ['Family colour', 'Part of the face']),
          const SizedBox(height: 10),
          _head('3 · The pick turns it over',
              'A flip, 400 ms (Motion token), then the face.'),
          _row(
              [
                _flip(1, false),
                _flip(.55, false),
                _flip(.55, true),
                _flip(1, true)
              ],
              fw,
              caps: ['0', '130 ms', '270 ms', '400 ms']),
          const SizedBox(height: 10),
          _head('4 · No turning back',
              'No Change after a face-down pick: the sheet says so.'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: inkBlack,
                border: Border.all(color: inkRed, width: 1.5),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _fit(const _Back(), 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No turning back', style: _d(18, inkPaper)),
                      Text('Take it unseen. You cannot change your mind.',
                          style: _p(12, inkGrey)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: inkRed,
                            child: Text('Take it', style: _p(13, inkPaper))),
                        const SizedBox(width: 12),
                        Text('Look again', style: _p(13, inkGold)),
                      ]),
                    ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('gamble at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
              home: Scaffold(body: _Sheet(width))),
        ),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/gamble-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
