// PICTURES (UX_SHOTS=<folder>): MOCKS of the Tower's bookmark views over the
// real floor screen at 412: three tabs hanging at the top right (Stats,
// Equipment, Dice), each in two versions. The hero is the run's own (towerHeroOf)
// with a few pieces of gear, nudges and dice added by hand for the picture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/skills/die_slot_ring.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/ability_radar.dart';
import 'package:narrative_data_app/widgets/die_tile.dart';
import 'package:narrative_data_app/widgets/item_stats.dart';
import 'package:narrative_data_app/widgets/level_up_art.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

enum _View { stats, gear, dice }

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
const _names = {
  'strength': 'Strength',
  'dexterity': 'Dexterity',
  'constitution': 'Constitution',
  'intelligence': 'Intelligence',
  'wisdom': 'Wisdom',
  'perception': 'Perception',
  'luck': 'Luck',
  'charisma': 'Charisma',
};

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.2,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

Map<String, int> _abilities(SimCharacter h) => {
      'strength': h.strength,
      'dexterity': h.dexterity,
      'constitution': h.constitution,
      'intelligence': h.intelligence,
      'wisdom': h.wisdom,
      'perception': h.perception,
      'luck': h.luck,
      'charisma': h.charisma,
    };

/// A bookmark tab: cloth hanging from the header, the open one longer.
class _Tab extends StatelessWidget {
  const _Tab(this.icon, this.label, this.open);
  final IconData icon;
  final String label;
  final bool open;
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: open ? 78 : 56,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: open ? inkRed : inkBlack,
          border: Border(
            left: BorderSide(color: open ? inkPaper : inkGold, width: 2),
            right: BorderSide(color: open ? inkPaper : inkGold, width: 2),
            bottom: BorderSide(color: open ? inkPaper : inkGold, width: 2),
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
          boxShadow: [
            BoxShadow(
                color: inkBlack.withValues(alpha: 0.7),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.only(top: 6),
        child: Column(children: [
          Icon(icon, size: 22, color: inkPaper),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: _p(8, inkPaper, w: FontWeight.w700)
                  .copyWith(letterSpacing: 0.4)),
        ]),
      );
}

Widget _tabs(_View? open) => Row(mainAxisSize: MainAxisSize.min, children: [
      _Tab(Icons.radar, 'Stats', open == _View.stats),
      _Tab(Icons.shield_outlined, 'Gear', open == _View.gear),
      _Tab(Icons.casino_outlined, 'Dice', open == _View.dice),
    ]);

/// The panel an open tab drops over the floor.
Widget _panel(String title, Widget child) => Container(
      decoration: BoxDecoration(
          color: inkBlack.withValues(alpha: 0.94),
          border: Border.all(color: inkSlate),
          borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: _d(20, inkPaper)),
          const Spacer(),
          const Icon(Icons.close, size: 18, color: inkGrey),
        ]),
        const SizedBox(height: 8),
        Expanded(child: child),
      ]),
    );

Widget _chip(String t, {Color color = inkPaper, Widget? lead}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, const SizedBox(width: 4)],
        Text(t, style: _p(11, color, w: FontWeight.w700)),
      ]),
    );

Widget _pips(int n, int cap) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < cap; i++)
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
              color: i < n ? inkGold : Colors.transparent,
              border: Border.all(color: i < n ? inkGold : inkGrey, width: 1),
              borderRadius: BorderRadius.circular(2)),
        ),
    ]);

Widget _header(SimCharacter h, int nudges) =>
    Wrap(spacing: 6, runSpacing: 6, children: [
      _chip('HP ${h.currentHealth} / ${h.maxHealth}',
          color: inkRed,
          lead: const Icon(Icons.favorite, size: 12, color: inkRed)),
      _chip('Level ${h.level}'),
      _chip('Armour ${h.baseArmor + 4}'),
      _chip('Damage ${h.baseDamage + 3}'),
    ]);

// ------------------------------------------------------------------ stats
Widget _statsA(SimCharacter h, Map<String, int> nudge) {
  final total = nudge.values.fold<int>(0, (a, b) => a + b);
  return _panel(
      'Stats',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(h, total),
        const SizedBox(height: 4),
        Expanded(
          child: Center(
            child: LevelUpStatsArea(
                before: _abilities(h),
                after: null,
                label: (k) => _abbr[k]!,
                dark: true),
          ),
        ),
        Text('Level Up nudges: +$total of +10 this climb',
            style: _p(12, inkPaper, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 6, children: [
          for (final k in abilityRadarOrder)
            if ((nudge[k] ?? 0) > 0)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_abbr[k]!, style: _p(11, inkGrey)),
                const SizedBox(width: 4),
                _pips(nudge[k]!, 4),
              ]),
        ]),
      ]));
}

Widget _statsB(SimCharacter h, Map<String, int> nudge) {
  final total = nudge.values.fold<int>(0, (a, b) => a + b);
  final now = _abilities(h);
  return _panel(
      'Stats',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(h, total),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.15,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final k in abilityRadarOrder)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(color: inkSlate),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    LevelUpSymbol(k, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_names[k]!, style: _p(11, inkGrey)),
                            Row(children: [
                              Text('${now[k]}', style: _d(22, inkPaper)),
                              if ((nudge[k] ?? 0) > 0)
                                Text('  +${nudge[k]}',
                                    style: _p(12, inkGold, w: FontWeight.w800)),
                            ]),
                            _pips(nudge[k] ?? 0, 4),
                          ]),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Level Up nudges: +$total of +10 this climb',
            style: _p(12, inkPaper, w: FontWeight.w700)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: total / 10,
              minHeight: 6,
              color: inkGold,
              backgroundColor: inkSlate.withValues(alpha: 0.5)),
        ),
      ]));
}

// ------------------------------------------------------------------- gear
const _slots = [
  ('Head', 'Head'),
  ('Weapon', 'Weapon'),
  ('Top', 'Body'),
  ('Bottom', 'Legs'),
  ('Foot', 'Feet'),
  ('Banner', 'Banner'),
];

Widget _gearA(SimCharacter h, Map<String, dynamic> items) {
  Widget tile(String slot, String label) {
    final id = h.equippedBySlot[slot];
    final item = id == null ? null : items[id] as Map<String, dynamic>?;
    return SizedBox(
      width: 92,
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: inkDark,
              border: Border.all(
                  color: id == null ? inkSlate : inkPaper,
                  width: id == null ? 1 : 1.5),
              borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: id == null
              ? Text('empty', style: _p(10, inkGrey))
              : ItemPixelIcon(id, item?['itemType']?.toString(), size: 44),
        ),
        const SizedBox(height: 3),
        Text(label.toUpperCase(),
            style: _p(9, inkGrey, w: FontWeight.w700)
                .copyWith(letterSpacing: 0.6)),
        Text(item?['itemName']?.toString() ?? '',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: _p(10.5, inkPaper)),
      ]),
    );
  }

  final weapon = items[h.equippedBySlot['Weapon']] as Map<String, dynamic>?;
  return _panel(
      'Equipment',
      Column(children: [
        SizedBox(
          height: 500,
          child: Stack(alignment: Alignment.center, children: [
            Image.asset('assets/visuals/levelup/hero_warrior.png',
                height: 300,
                filterQuality: FilterQuality.none,
                isAntiAlias: false),
            Positioned(top: 0, child: tile('Head', 'Head')),
            Positioned(left: 0, top: 110, child: tile('Weapon', 'Weapon')),
            Positioned(right: 0, top: 110, child: tile('Banner', 'Banner')),
            Positioned(left: 0, top: 235, child: tile('Top', 'Body')),
            Positioned(right: 0, top: 235, child: tile('Bottom', 'Legs')),
            Positioned(bottom: 0, child: tile('Foot', 'Feet')),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(color: inkSlate),
              borderRadius: BorderRadius.circular(8)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(weapon?['itemName']?.toString() ?? '',
                style: _d(15, inkPaper)),
            const SizedBox(height: 4),
            ItemStatChips(
                item: weapon,
                language: AppLanguage.en,
                compact: true,
                deltaVsEmpty: false),
          ]),
        ),
      ]));
}

Widget _gearB(SimCharacter h, Map<String, dynamic> items) => _panel(
    'Equipment',
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, children: [
        _chip('Armour ${h.baseArmor + 4}'),
        _chip('Damage ${h.baseDamage + 3}'),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (slot, label) in _slots)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    border: Border.all(color: inkSlate),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(children: [
                          Text(label.toUpperCase(),
                              style: _p(8, inkGrey, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          if (h.equippedBySlot[slot] != null)
                            ItemPixelIcon(
                                h.equippedBySlot[slot],
                                (items[h.equippedBySlot[slot]]
                                        as Map?)?['itemType']
                                    ?.toString(),
                                size: 36)
                          else
                            const Icon(Icons.remove, color: inkSlate, size: 28),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: h.equippedBySlot[slot] == null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text('Nothing worn',
                                    style: _p(12, inkGrey)
                                        .copyWith(fontStyle: FontStyle.italic)))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                            '${(items[h.equippedBySlot[slot]] as Map)['itemName']}',
                                            style: _d(14, inkPaper)),
                                      ),
                                      Text(
                                          '${(items[h.equippedBySlot[slot]] as Map)['rarity']}',
                                          style: _p(10, inkGrey)),
                                    ]),
                                    const SizedBox(height: 3),
                                    ItemStatChips(
                                        item: items[h.equippedBySlot[slot]]
                                            as Map<String, dynamic>,
                                        language: AppLanguage.en,
                                        compact: true,
                                        maxChips: 3),
                                  ]),
                      ),
                    ]),
              ),
          ],
        ),
      ),
      Text('Gear from the floors is worn when it is at least as good.',
          style: _p(11, inkGrey).copyWith(fontStyle: FontStyle.italic)),
    ]));

// ------------------------------------------------------------------- dice
const _faceAbbr = {
  'Attack': 'ATK',
  'Defend': 'DEF',
  'Skill': 'SKL',
  'Heal': 'HEAL',
  'Mana': 'MANA',
};

Widget _faceDisc(Map<String, dynamic> f, double side) => Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: inkDark,
          border: Border.all(
              color: f['type'] == 'Skill' ? inkGold : inkPaper, width: 1.5)),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        f['type'] == 'Skill'
            ? Icon(Icons.auto_awesome, size: side * 0.34, color: inkGold)
            : Text('${f['value']}', style: _d(side * 0.36, inkPaper)),
        Text(_faceAbbr['${f['type']}'] ?? '',
            style: _p(side * 0.17, inkGrey, w: FontWeight.w700)),
      ]),
    );

const _bagIds = [
  ('starter_die', 'Start'),
  ('iron_die', 'Bought'),
  ('flame_die', 'Level Up: gift'),
  ('frost_die', 'Level Up: gift'),
  ('vigil_die', 'Level Up: gift'),
];

Widget _diceA(SimCharacter h) {
  const sel = 'flame_die';
  final faces = h.ownedDice[sel]!;
  return _panel(
      'Dice',
      Column(children: [
        // The rail: the climb's dice, the die in play ringed in red.
        SizedBox(
          height: 78,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final (id, _) in _bagIds)
              Container(
                width: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: inkDark,
                    border: Border.all(
                        color: id == sel ? inkRed : inkSlate,
                        width: id == sel ? 2.5 : 1),
                    borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: DieTile(
                    dieId: id,
                    faces: h.ownedDice[id]!.length,
                    size: 52,
                    glowing: id == sel),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DieSlotRing(
            count: faces.length,
            slot: (i, side, compact) => _faceDisc(faces[i], side),
            center: DieTile(dieId: sel, faces: faces.length, size: 96),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(color: inkSlate),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Text('Flame die', style: _d(15, inkPaper)),
            const Spacer(),
            _chip('In play', color: inkRed),
          ]),
        ),
      ]));
}

Widget _diceB(SimCharacter h) => _panel(
    'Dice',
    GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.05,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (id, source) in _bagIds)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(
                    color: id == 'flame_die' ? inkRed : inkSlate,
                    width: id == 'flame_die' ? 2.5 : 1),
                borderRadius: BorderRadius.circular(8)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                DieTile(
                    dieId: id,
                    faces: h.ownedDice[id]!.length,
                    size: 48,
                    glowing: id == 'flame_die'),
                const Spacer(),
                _chip('d${h.ownedDice[id]!.length}'),
              ]),
              const Spacer(),
              Text(id.replaceAll('_die', '').toUpperCase(),
                  style: _p(12, inkPaper, w: FontWeight.w800)),
              Text(source, style: _p(10, inkGrey)),
              const SizedBox(height: 4),
              Wrap(spacing: 3, runSpacing: 3, children: [
                for (final f in h.ownedDice[id]!)
                  Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: f['type'] == 'Skill' ? inkGold : inkGrey),
                        borderRadius: BorderRadius.circular(3)),
                    child: f['type'] == 'Skill'
                        ? const Icon(Icons.auto_awesome,
                            size: 10, color: inkGold)
                        : Text('${f['value']}',
                            style: _p(9, inkPaper, w: FontWeight.w700)),
                  ),
              ]),
              if (id == 'flame_die')
                Text('In play', style: _p(10, inkRed, w: FontWeight.w800)),
            ]),
          ),
      ],
    ));

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

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data)
          .copyWith(floor: 2);

  final scenes = <String,
      (
    _View?,
    Widget Function(SimCharacter, Map<String, dynamic>, Map<String, int>)?
  )>{
    'tabs-closed': (null, null),
    'stats-A': (_View.stats, (h, i, n) => _statsA(h, n)),
    'stats-B': (_View.stats, (h, i, n) => _statsB(h, n)),
    'gear-A': (_View.gear, (h, i, n) => _gearA(h, i)),
    'gear-B': (_View.gear, (h, i, n) => _gearB(h, i)),
    'dice-A': (_View.dice, (h, i, n) => _diceA(h)),
    'dice-B': (_View.dice, (h, i, n) => _diceB(h)),
  };

  for (final e in scenes.entries) {
    testWidgets('tower views ${e.key}', skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'tower_run_v1': jsonEncode(start.toJson()),
        'tutorial_enabled': false,
      });
      usePhone(tester, const Size(412, 900));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.en);
      // The hero, dressed for the picture.
      final hero = towerHeroOf(start, data);
      final items = data.items.cast<String, dynamic>();
      hero.level = 8;
      hero.maxHealth = 52;
      hero.currentHealth = 41;
      hero.baseArmor = 3;
      hero.baseDamage = 3;
      hero.strength += 2;
      hero.intelligence += 3;
      hero.dexterity += 2;
      hero.equippedBySlot
        ..['Weapon'] = 'sword_001'
        ..['Top'] = 'cloak_frostward'
        ..['Bottom'] = 'greaves_iron'
        ..['Foot'] = 'boots_worn_leather';
      for (final id in ['iron_die', 'flame_die', 'frost_die', 'vigil_die']) {
        hero.ownedDice[id] = ((data.dice[id] as Map)['faces'] as List)
            .cast<Map<String, dynamic>>();
      }
      const nudge = {'intelligence': 3, 'dexterity': 2, 'strength': 1};
      final key = GlobalKey();
      final open = e.value.$1;
      final build = e.value.$2;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              key: UniqueKey(),
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(container
                  .read(appPaletteProvider)
                  .schemeFor(Brightness.light)),
              home: Stack(children: [
                const TowerFloorScreen(),
                Positioned(
                    top: 56,
                    right: 6,
                    child: Material(
                        type: MaterialType.transparency, child: _tabs(open))),
                if (build != null)
                  Positioned(
                    top: 56 + 82,
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Material(
                        type: MaterialType.transparency,
                        child: build(hero, items, nudge)),
                  ),
              ])),
        ),
      ));
      for (var i = 0; i < 24; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _shot(tester, key, '$shots/${e.key}-412.png');
    });
  }
}
