// PICTURES (UX_SHOTS=<folder>): the GAMBLE card's BACK, three versions built from
// the tarot deck's own pieces. Before: MOCKS of the GAMBLE card: one of the three is
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

Widget _skill() => const SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: TowerCardStyle.skill,
        kind: 'Skill',
        name: 'Parry',
        text: 'Block the next blow.',
        nudge: '+1 DEX',
        vignette: 'assets/visuals/tower_cards/skill_fire.png',
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
        vignette: 'assets/visuals/tower_cards/loot_equipment.png',
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

Widget _backCard(TowerCardStyle style, String vignette, IconData icon,
        {bool darkBadge = false}) =>
    SizedBox(
      width: 122,
      height: 201,
      child: TowerStyledCard(
        style: style,
        kind: 'Face down',
        name: '? ? ?',
        text: 'Dealt unseen.',
        vignette: vignette,
        darkBadge: darkBadge,
        badge: Icon(icon, size: 16, color: darkBadge ? inkPaper : inkBlack),
      ),
    );

const _dir = 'assets/visuals/tower_cards';

/// A: the watching eye (the Void skill's vignette) on the paper card.
Widget _backA() =>
    _backCard(TowerCardStyle.skill, '$_dir/skill_void.png', Icons.help_outline);

/// B: the pair of dice (the die vignette) on the black card: a gamble.
Widget _backB() =>
    _backCard(TowerCardStyle.die, '$_dir/die.png', Icons.help_outline,
        darkBadge: true);

/// C: the red wax seal alone on plain paper, the same frame.
Widget _backC() => Container(
      width: 122,
      height: 201,
      decoration: BoxDecoration(
          color: inkPaper,
          border: Border.all(color: inkBlack, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(fit: StackFit.expand, children: [
          Padding(
            padding: const EdgeInsets.all(7),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border.all(color: inkBlack, width: 1))),
          ),
          for (final a in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight
          ])
            Align(
              alignment: a,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: inkRed, shape: BoxShape.circle)),
              ),
            ),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(alignment: Alignment.center, children: [
                Image.asset('$_dir/seal_blank.png',
                    width: 80,
                    height: 80,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.fill),
                Text('?', style: _d(34, inkPaper)),
              ]),
            ),
          ),
        ]),
      ),
    );

class _Sheet extends StatelessWidget {
  const _Sheet(this.width);
  final double width;
  @override
  Widget build(BuildContext context) {
    final cw = (width - 64) / 3;
    return TowerBackdrop(
      floor: 6,
      child: Container(
        color: inkBlack.withValues(alpha: 0.82),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (t, sub, back) in [
              (
                'A · The watching eye',
                'The Void skill\'s eye on paper.',
                _backA()
              ),
              (
                'B · The dice',
                'The die card\'s pair of dice, black card.',
                _backB()
              ),
              (
                'C · The wax seal',
                'The rarity seal alone, four red pips.',
                _backC()
              ),
            ]) ...[
              _head(t, sub),
              _row([_skill(), back, _gear()], cw),
              const SizedBox(height: 10),
            ],
            Text(
                'Same frame, shape and size as every card. Needs no new art; a custom '
                'Ashen Tower stair-spiral would need one new tarot-style generation.',
                style: _p(11, inkGrey)),
          ]),
        ),
      ),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('gamble backs at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 820);
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
        File('$shots/gamble-backs-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
