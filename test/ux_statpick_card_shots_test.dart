// PICTURES (UX_SHOTS=<folder>): MOCKS of the STAT-PICK reward card (a rare
// card that puts +1 in a stat of your choice) in a family colour of its own
// (verdigris), and the stat choice after taking it. Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/ability_radar.dart'
    show abilityAbbrevKey;
import 'package:narrative_data_app/widgets/level_up_art.dart'
    show LevelUpStatsArea;

import 'support/fonts.dart';

const _verdigris = Color(0xFF2E6F68);
const _verdigrisDeep = Color(0xFF173B38);

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

const _stats = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];
const _before = {
  'strength': 6,
  'dexterity': 5,
  'constitution': 7,
  'intelligence': 4,
  'wisdom': 3,
  'perception': 5,
  'luck': 2,
  'charisma': 3,
};

/// The card in its own family: a verdigris stock, the paper frame, a radar
/// glyph where the picture goes (placeholder for Art's vignette).
class _StatCard extends StatelessWidget {
  const _StatCard();
  @override
  Widget build(BuildContext context) => Container(
        width: 122,
        height: 201,
        decoration: BoxDecoration(
            color: _verdigris,
            border: Border.all(color: inkPaper, width: 1.5),
            borderRadius: BorderRadius.circular(10)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Column(children: [
            Expanded(
              flex: 9,
              child: Stack(fit: StackFit.expand, children: [
                const ColoredBox(color: _verdigrisDeep),
                const Center(
                    child: Icon(Icons.radar, size: 48, color: inkPaper)),
                Positioned(
                  left: 5,
                  top: 5,
                  child: Container(
                      width: 22,
                      height: 22,
                      color: inkPaper,
                      alignment: Alignment.center,
                      child: Text('+1', style: _d(11, inkBlack))),
                ),
              ]),
            ),
            Container(
                color: inkBlack,
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: Text('Stat point',
                    textAlign: TextAlign.center, style: _d(11.5, inkPaper))),
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                child: Column(children: [
                  Text('RARE',
                      style: _p(8, inkPaper.withValues(alpha: 0.8),
                          w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Expanded(
                      child: Text('Put +1 in a stat of your choice.',
                          textAlign: TextAlign.center,
                          style: _p(9.5, inkPaper))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        border: Border.all(color: inkPaper, width: 1.2),
                        borderRadius: BorderRadius.circular(9)),
                    child: Text('+1 ?',
                        style: _p(9.5, inkPaper, w: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}

Widget _fit(Widget c, double w) =>
    SizedBox(width: w, height: w * 201 / 122, child: FittedBox(child: c));

Widget _other(TowerCardStyle style, String kind, String name, String text,
        String vignette, IconData icon) =>
    SizedBox(
        width: 122,
        height: 201,
        child: TowerStyledCard(
          style: style,
          kind: kind,
          name: name,
          text: text,
          vignette: vignette,
          badge: Icon(icon, size: 16, color: inkBlack),
        ));

class _Sheet extends ConsumerWidget {
  const _Sheet(this.width);
  final double width;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cw = (width - 64) / 3;
    const picked = 'dexterity';
    final after = {..._before, picked: _before[picked]! + 1};
    Widget head(String t, String sub) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: _d(17, inkPaper)),
          Text(sub, style: _p(11.5, inkGrey)),
          const SizedBox(height: 8),
        ]);
    return TowerBackdrop(
      floor: 6,
      child: Container(
        color: inkBlack.withValues(alpha: 0.84),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          head('1 · The card, among three',
              'A rare card of its own family: verdigris stock.'),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _fit(
                _other(
                    TowerCardStyle.skill,
                    'Skill',
                    'Parry',
                    'Block the next blow.',
                    'assets/visuals/tower_cards/skill_fire.png',
                    Icons.shield),
                cw),
            _fit(const _StatCard(), cw),
            _fit(
                _other(
                    TowerCardStyle.gear,
                    'Gear',
                    'Ash Cloak',
                    '+2 armour.',
                    'assets/visuals/tower_cards/loot_equipment.png',
                    Icons.checkroom),
                cw),
          ]),
          const SizedBox(height: 14),
          head('2 · After Confirm: choose the stat',
              'The ribbon, the big radar with the +1 ghosted, eight buttons.'),
          Container(
            width: double.infinity,
            height: 36,
            alignment: Alignment.center,
            color: inkRed,
            child: Text('CHOOSE A STAT', style: _d(15, inkPaper)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 340,
            child: LevelUpStatsArea(
                before: _before,
                after: after,
                label: (k) => tr(ref, abilityAbbrevKey(k)),
                dark: true),
          ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in _stats)
              Container(
                width: (width - 32 - 18) / 4,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: s == picked ? inkPaper : Colors.transparent,
                    border: Border.all(
                        color: s == picked ? inkPaper : inkGrey, width: 1.5),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${tr(ref, abilityAbbrevKey(s))} ${_before[s]}',
                    style: _p(13, s == picked ? inkBlack : inkPaper,
                        w: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  color: inkRed,
                  child: Text('Confirm  +1 DEX', style: _p(14, inkPaper))),
            ),
            const SizedBox(width: 12),
            Text('Change', style: _p(14, inkGold, w: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    testWidgets('statpick at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
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
        File('$shots/statpick-${width.toInt()}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
