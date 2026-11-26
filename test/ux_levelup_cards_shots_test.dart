// PICTURES (UX_SHOTS=<folder>): MOCKS of the Tower's new Level Up (three
// cards on the painted screen, the radar ghosting the +1 nudge), the floor
// loot table (equipment, item, money) and the spoils sheet that shows what
// was taken. Real: the stage (plate, ribbon, hero), the radar, Art's
// vignettes. Mock: the cards (test/support/ux_card_styles.dart).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart'
    show InkFonts, buildAppTheme, stitchedInkScheme;
import 'package:narrative_data_app/widgets/level_up_art.dart';

import 'support/fonts.dart';
import 'support/ux_card_styles.dart';

const _clanHue = Color(0xFF3F7F6B);

const _clan = UxCardSpec(
    'Clan gift', 'Clan gift', 'Shadow Step', 'Strike first in the next fight.',
    vignette: '${uxV}skill_void.png',
    icon: Icons.groups,
    stock: inkDark,
    shape: UxShape.swallow,
    stripe: _clanHue,
    band: inkDark,
    bandInk: inkPaper,
    note: 'Standing +2 · allies +1 · rivals −1',
    nudge: '+1 DEX');
const _skill = UxCardSpec(
    'Skill', 'Skill', 'Ember Lash', 'Hit one foe for 6 fire.',
    vignette: '${uxV}skill_fire.png',
    icon: Icons.local_fire_department,
    stock: inkPaper,
    ink: inkOnPaper,
    edge: inkBlack,
    band: inkBlack,
    bandInk: inkPaper,
    nudge: '+1 INT');
const _rank = UxCardSpec(
    'Rank-up', 'Rank-up', 'Ember Lash II', 'Rank 2: 9 fire.',
    vignette: '${uxV}skill_fire.png',
    icon: Icons.local_fire_department,
    stock: inkPaper,
    ink: inkOnPaper,
    edge: Color(0xFFC9A24B),
    edgeWidth: 4,
    band: Color(0xFFC9A24B),
    bandInk: inkBlack,
    stamp: '+1',
    nudge: '+1 INT');
const _spell = UxCardSpec(
    'Spell', 'Spell', 'Radiant Judgment', 'Strike all foes with light.',
    vignette: '${uxV}spell_damage.png',
    icon: Icons.auto_awesome,
    stock: Color(0xFF1B1533),
    edge: inkPaper,
    twin: true,
    shape: UxShape.chamfer,
    band: inkPaper,
    nudge: '+1 WIS');
const _die = UxCardSpec('Die', 'Die', 'Ash Die', 'A d6 with two faces of 4.',
    vignette: '${uxV}die.png', icon: Icons.casino, nudge: '+1 STR');
const _gear = UxCardSpec(
    'Equipment', 'Equipment', 'Iron Bracers', '+2 armour while worn.',
    vignette: '${uxV}loot_equipment.png',
    icon: Icons.shield,
    stock: Color(0xFF454E53),
    edge: inkBlack,
    edgeWidth: 4,
    rivets: true,
    band: inkBlack,
    bandInk: inkPaper);
const _bundle = UxCardSpec(
    'Item', 'Bundle', 'Potion bundle', 'Three potions into the bag.',
    vignette: '${uxV}loot_item.png',
    icon: Icons.local_pharmacy,
    stock: Color(0xFFB9A27A),
    ink: inkOnPaper,
    edge: inkOnPaper,
    dashed: true,
    shape: UxShape.notch,
    band: inkOnPaper,
    bandInk: inkPaper);
const _purse = UxCardSpec(
    'Money', 'Purse', '2 coins', 'Spend them at the next stall.',
    vignette: '${uxV}loot_money.png',
    icon: Icons.monetization_on,
    edge: Color(0xFFC9A24B),
    edgeWidth: 3,
    dashed: true,
    coin: true,
    band: Color(0xFFC9A24B),
    bandInk: inkBlack);

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.2,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

const _abbr = {
  'strength': 'STR',
  'dexterity': 'DEX',
  'constitution': 'CON',
  'intelligence': 'INT',
  'wisdom': 'WIS',
  'perception': 'PER',
  'luck': 'LUCK',
  'charisma': 'CHA',
};
const _before = {
  'strength': 8,
  'dexterity': 7,
  'constitution': 9,
  'intelligence': 5,
  'wisdom': 6,
  'perception': 4,
  'luck': 3,
  'charisma': 4,
};

/// A card in hand: lifted a little, with a red outline.
Widget _hand(UxCardSpec s, double w, {bool held = false, double k = 1.95}) =>
    Transform.translate(
        offset: Offset(0, held ? -6 : 0),
        child: Container(
          decoration: BoxDecoration(
              boxShadow: held
                  ? const [
                      BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 10,
                          offset: Offset(0, 6))
                    ]
                  : null),
          foregroundDecoration: held
              ? BoxDecoration(border: Border.all(color: inkRed, width: 3))
              : null,
          child: UxCard(s, w, held: held, heightK: k),
        ));

Widget _row(List<UxCardSpec> cards, double width,
    {int held = -1, double k = 1.95}) {
  final w = (width - 32 - 16) / 3;
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, c) in cards.indexed) _hand(c, w, held: i == held, k: k),
      ],
    ),
  );
}

Widget _heading(String title, String hint) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _d(18, inkPaper)),
        const SizedBox(height: 2),
        Text(hint, style: _p(12, inkGrey)),
      ]),
    );

Widget _take(String label, {bool on = true}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: on ? () {} : null,
            child: Text(label)),
      ),
    );

class _LevelUp extends StatelessWidget {
  const _LevelUp(this.cards, this.width, this.nudgeStat);
  final List<UxCardSpec> cards;
  final double width;
  final String nudgeStat;

  @override
  Widget build(BuildContext context) {
    final after = {..._before, nudgeStat: _before[nudgeStat]! + 1};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const LevelUpStage(level: 4, heroName: 'warrior', levelLabel: 'Level'),
      _heading('Take one card',
          'Tap a card, or swipe it up to take it. A skill also raises a stat by 1.'),
      _row(cards, width, held: 1, k: 2.15),
      Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: inkPaper, border: Border.all(color: inkDeep, width: 3)),
        child: Column(children: [
          Row(children: [
            Text('XP 8 / 12', style: _p(12, inkSlate)),
            const Spacer(),
            Text('${cards[1].name}: +1 ${_abbr[nudgeStat]}',
                style: _p(12, inkRedDeep, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          LevelUpStatsArea(
              before: _before, after: after, label: (k) => _abbr[k]!),
        ]),
      ),
      _take('Take'),
    ]);
  }
}

class _Spoils extends StatelessWidget {
  const _Spoils(this.width);
  final double width;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: inkPaper, border: Border.all(color: inkDeep, width: 3)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Floor 7: spoils', style: _d(20, inkOnPaper)),
            Text('You took one card from the loot table.',
                style: _p(12, inkSlate)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              UxCard(_gear, 96, heightK: 1.75),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iron Bracers', style: _d(16, inkOnPaper)),
                      Text('Worn: armour 3 → 5', style: _p(13, inkOnPaper)),
                      const SizedBox(height: 10),
                      Text('Left on the table', style: _p(11, inkSlate)),
                      Text('Potion bundle · 2 coins', style: _p(12, inkSlate)),
                      const SizedBox(height: 10),
                      Text('Coins 12 → 12 · Potions ×1 → ×1',
                          style: _p(11, inkSlate)),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: () {},
                  child: const Text('Take')),
            ),
          ]),
        ),
      );
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _show(
    WidgetTester tester, GlobalKey key, double w, double h, Widget body) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
    home: RepaintBoundary(
        key: key,
        child: ColoredBox(
            color: inkBlack,
            child: Material(
                color: inkBlack,
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: body)))),
  )));
  for (var i = 0; i < 10; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('level up cards, loot, spoils', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    for (final w in [412.0, 360.0]) {
      final n = w.toInt();
      await _show(tester, key, w, w > 400 ? 1330 : 1250,
          _LevelUp(const [_clan, _skill, _spell], w, 'intelligence'));
      await _shot(tester, key, '$shots/levelup-cards-$n.png');
      await _show(tester, key, w, w > 400 ? 1330 : 1250,
          _LevelUp(const [_clan, _rank, _die], w, 'intelligence'));
      await _shot(tester, key, '$shots/levelup-cards-rankup-die-$n.png');
      await _show(
          tester,
          key,
          w,
          420,
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _heading(
                'Loot: take one', 'Tap a card, or swipe it up to take it.'),
            _row(const [_gear, _bundle, _purse], w, held: 0),
            _take('Take'),
          ]));
      await _shot(tester, key, '$shots/loot-table-$n.png');
      await _show(tester, key, w, 335, _Spoils(w));
      await _shot(tester, key, '$shots/spoils-sheet-$n.png');
    }
  });
}
