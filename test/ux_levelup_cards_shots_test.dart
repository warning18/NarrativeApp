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
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart'
    show ClanHandFan;
import 'package:narrative_data_app/widgets/level_up_art.dart';

import 'support/fonts.dart';
import 'support/ux_card_styles.dart';

const _clanHue = Color(0xFF3F7F6B);

const _clan = UxCardSpec(
    'Clan gift', 'Clan gift', 'Shadow Step', 'Strike first.',
    vignette: '${uxV}skill_void.png',
    icon: Icons.groups,
    stock: inkDark,
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

Widget _red(String label, {bool on = true}) => FilledButton(
    style: FilledButton.styleFrom(
        backgroundColor: inkRed,
        foregroundColor: inkPaper,
        disabledBackgroundColor: inkRed.withValues(alpha: 0.35)),
    onPressed: on ? () {} : null,
    child: Text(label));

/// Today's offer screen: the Tower floor behind, the ribbon (Level Up) or a
/// title, the real fanned hand (the middle card in front, none in hand until
/// one is touched), the held card's words under it (with [detailRight] beside
/// them), Take in red, then [below].
class _Offer extends StatelessWidget {
  const _Offer({
    required this.title,
    required this.hint,
    required this.cards,
    required this.held,
    required this.detail,
    this.below = const [],
    this.detailRight,
    this.notNow,
    this.ribbon = false,
  });
  final String title, hint;
  final List<UxCardSpec> cards;
  final int held;
  final List<String> detail;
  final List<Widget> below;
  final Widget? detailRight;
  final String? notNow;
  final bool ribbon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final words = held >= 0
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(detail[0], style: t.titleSmall),
            for (final l in detail.skip(1)) Text(l, style: t.bodyMedium),
          ])
        : Text('Tap a card, or swipe it up to take it.', style: t.bodySmall);
    return TowerBackdrop(
      floor: 4,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 10, 16, 24),
        children: [
          if (ribbon)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: SizedBox(
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                    child: Image.asset('assets/visuals/levelup/ribbon.png',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                        isAntiAlias: false),
                  ),
                  Text(title, style: _d(24, Colors.white)),
                ]),
              ),
            )
          else
            Text(title, style: t.headlineSmall),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(hint,
                style: t.bodyMedium?.copyWith(color: t.bodySmall?.color)),
          ),
          const SizedBox(height: 12),
          ClanHandFan(
            cards: [for (final c in cards) UxCard(c, 122, heightK: 1.65)],
            keys: [for (var i = 0; i < cards.length; i++) Key('c$i')],
            lit: held,
            front: 1,
            onTap: null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: detailRight == null
                ? words
                : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: words),
                    const SizedBox(width: 6),
                    detailRight!,
                  ]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _red('Take', on: held >= 0),
            ),
          ),
          if (notNow != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(notNow!,
                    style:
                        t.titleSmall?.copyWith(color: const Color(0xFFC9A24B))),
              ),
            ),
          ...below,
        ],
      ),
    );
  }
}

/// A compact radar on the floor under a soft ink scrim (no hard panel):
/// the 8 symbols and values round a small shape, the nudge ghosted.
Widget _radar(String? stat, String label, {double side = 230}) {
  final after = stat == null ? null : {..._before, stat: _before[stat]! + 1};
  return Container(
    width: side,
    decoration: BoxDecoration(
        gradient: RadialGradient(colors: [
      inkBlack.withValues(alpha: 0.82),
      inkBlack.withValues(alpha: 0.55),
      inkBlack.withValues(alpha: 0),
    ], stops: const [
      0.0,
      0.6,
      1.0
    ])),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      LevelUpStatsArea(
          before: _before,
          after: after,
          label: (k) => _abbr[k]!,
          dark: true,
          compact: true),
      if (stat != null)
        Text(label, style: _p(12, inkPaper, w: FontWeight.w700)),
    ]),
  );
}

class _Spoils extends StatelessWidget {
  const _Spoils();
  @override
  Widget build(BuildContext context) => TowerBackdrop(
        floor: 4,
        child: Padding(
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
                const UxCard(_gear, 96, heightK: 1.75),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Iron Bracers', style: _d(16, inkOnPaper)),
                        Text('Worn: armour 3 → 5', style: _p(13, inkOnPaper)),
                        const SizedBox(height: 10),
                        Text('Left on the table', style: _p(11, inkSlate)),
                        Text('Potion bundle · 2 coins',
                            style: _p(12, inkSlate)),
                      ]),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: _red('Continue')),
            ]),
          ),
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
                child: SizedBox(width: w, height: h, child: body)))),
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
      const lvl = [_clan, _skill, _spell];
      const lvl2 = [_clan, _rank, _die];
      Future<void> shot(String name, double h, Widget body) async {
        await _show(tester, key, w, h, body);
        await _shot(tester, key, '$shots/$name-$n.png');
      }

      const hint = 'Choose one card. A skill also raises a stat by 1.';
      const skillWords = [
        'Ember Lash',
        'Hit one foe for 6 fire. Raises Intelligence by 1.'
      ];
      const clanWords = [
        'Shadow Step',
        'Strike first in the next fight. Raises Dexterity by 1.',
        'Mire +2 · Dominion -1 · Compact +1 · Penitents -1',
      ];
      // Variant A: the radar beside the held card's words.
      await shot(
          'levelup-A-start',
          700,
          _Offer(
              ribbon: true,
              title: 'Level 4',
              hint: hint,
              cards: lvl,
              held: -1,
              detail: const [],
              detailRight: _radar(null, '', side: 150)));
      await shot(
          'levelup-A-skill',
          700,
          _Offer(
              ribbon: true,
              title: 'Level 4',
              hint: hint,
              cards: lvl,
              held: 1,
              detail: skillWords,
              detailRight: _radar('intelligence', '+1 INT', side: 150)));
      await shot(
          'levelup-A-clan',
          700,
          _Offer(
              ribbon: true,
              title: 'Level 4',
              hint: hint,
              cards: lvl,
              held: 0,
              detail: clanWords,
              detailRight: _radar('dexterity', '+1 DEX', side: 150)));
      // Variant B: the radar under the words, centred, larger.
      await shot(
          'levelup-B-skill',
          860,
          _Offer(
              ribbon: true,
              title: 'Level 4',
              hint: hint,
              cards: lvl,
              held: 1,
              detail: skillWords,
              below: [
                Center(child: _radar('intelligence', 'Ember Lash: +1 INT'))
              ]));
      await shot(
          'levelup-B-rankup-die',
          860,
          _Offer(
              ribbon: true,
              title: 'Level 4',
              hint: hint,
              cards: lvl2,
              held: 1,
              detail: const [
                'Ember Lash II',
                'Rank 2: 9 fire. Raises Intelligence by 1.'
              ],
              below: [
                Center(child: _radar('intelligence', 'Ember Lash II: +1 INT'))
              ]));
      const loot = [_gear, _bundle, _purse];
      await shot(
          'loot-start',
          640,
          const _Offer(
              title: 'Floor 7 cleared',
              hint: 'Choose one reward',
              cards: loot,
              held: -1,
              detail: [],
              notNow: 'Not now (+1 mark)'));
      await shot(
          'loot-held',
          640,
          const _Offer(
              title: 'Floor 7 cleared',
              hint: 'Choose one reward',
              cards: loot,
              held: 0,
              detail: [
                'Iron Bracers',
                '+2 armour while worn. Worn if it beats yours.'
              ],
              notNow: 'Not now (+1 mark)'));
      await shot('spoils-sheet', 350, const _Spoils());
    }
  });
}
