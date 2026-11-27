// The Tower's bookmarks (v2.10.31, the user's pick: version A of each): three
// tabs hang from the top right of the floor screen, in the clan bookmarks'
// kit (ink cloth, a gold hem, a glyph and a small-caps label); the open one is
// red and longer, and its view drops over the floor. Read-only: Stats (the
// hero's abilities on the big radar, the Level Up nudges against their caps,
// HP and level), Gear (the hero with a tile for each slot) and Dice (the
// climb's dice like the Journey's, a ring of faces round the die).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart' show skillDisplayName;
import '../../data/sim_combat.dart';
import '../../data/tower/tower_session.dart' show towerSessionOf;
import '../../models/ally_state.dart'
    show equipmentBonusFor, equipmentScalingBonusFor;
import '../../data/tower/tower_hero.dart' show TowerData, towerHeroOf;
import '../../data/tower/tower_levelup_loot.dart'
    show towerNudgeClimbCapOf, towerNudgeStatCapOf;
import '../../data/tower/tower_run.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/ability_radar.dart'
    show abilityAbbrevKey, abilityRadarOrder;
import '../../widgets/die_tile.dart';
import '../../widgets/fight_sprites.dart' show heroWalkName;
import '../../widgets/item_stats.dart';
import '../../widgets/level_up_art.dart'
    show LevelUpStatsArea, LevelUpSymbol, levelUpHeroAsset;
import '../skills/die_slot_ring.dart';
import 'ink/ink_palette.dart';
import 'tower_offer_view.dart' show towerDieName;
import 'tower_providers.dart' show towerProvider;

enum TowerBookmark { stats, gear, dice }

TextStyle _prose(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.2,
    color: c,
    fontWeight: w);
TextStyle _display(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

/// The three tabs. [open] is the one whose view is showing, or null.
class TowerBookmarkTabs extends ConsumerWidget {
  const TowerBookmarkTabs({super.key, required this.open, required this.onTap});

  final TowerBookmark? open;
  final void Function(TowerBookmark) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget tab(TowerBookmark b, String glyph, String key) {
      final isOpen = open == b;
      final edge = isOpen ? inkPaper : inkGold;
      return GestureDetector(
        key: Key('tower_bookmark_${b.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(b),
        child: Container(
          width: 44,
          height: isOpen ? 78 : 56,
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: isOpen ? inkRed : inkBlack,
            border: Border(
              left: BorderSide(color: edge, width: 2),
              right: BorderSide(color: edge, width: 2),
              bottom: BorderSide(color: edge, width: 2),
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(6)),
            boxShadow: [
              BoxShadow(
                  color: inkBlack.withValues(alpha: 0.7),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(children: [
            Image.asset(glyph,
                width: IconSize.s32,
                height: IconSize.s32,
                filterQuality: FilterQuality.none),
            const SizedBox(height: 2),
            Text(tr(ref, key).toUpperCase(),
                maxLines: 1,
                style: _prose(8, inkPaper, w: FontWeight.w700)
                    .copyWith(letterSpacing: 0.4)),
          ]),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        tab(TowerBookmark.stats, 'assets/visuals/ink/bm_stats.png',
            'tower_bm_stats'),
        tab(TowerBookmark.gear, 'assets/visuals/ink/bm_gear.png',
            'tower_bm_gear'),
        tab(TowerBookmark.dice, 'assets/visuals/ink/bm_dice.png',
            'tower_bm_dice'),
      ]),
    );
  }
}

/// The panel of an open bookmark, over the floor.
class TowerBookmarkPanel extends ConsumerWidget {
  const TowerBookmarkPanel({
    super.key,
    required this.run,
    required this.data,
    required this.which,
    required this.onClose,
  });

  final TowerRun run;
  final TowerData data;
  final TowerBookmark which;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = towerHeroOf(run, data);
    final title = switch (which) {
      TowerBookmark.stats => 'tower_bm_title_stats',
      TowerBookmark.gear => 'tower_bm_title_gear',
      TowerBookmark.dice => 'tower_bm_title_dice',
    };
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: Key('tower_bookmark_panel_${which.name}'),
        decoration: BoxDecoration(
            color: inkBlack,
            border: Border.all(color: inkSlate),
            borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tr(ref, title), style: _display(20, inkPaper)),
            const Spacer(),
            IconButton(
              key: const Key('tower_bookmark_close'),
              icon: const Icon(Icons.close, size: IconSize.s16, color: inkGrey),
              onPressed: onClose,
            ),
          ]),
          Expanded(
            child: switch (which) {
              TowerBookmark.stats =>
                _StatsView(run: run, data: data, hero: hero),
              TowerBookmark.gear => _GearView(run: run, data: data, hero: hero),
              TowerBookmark.dice => _DiceView(data: data, hero: hero),
            },
          ),
        ]),
      ),
    );
  }
}

Widget _chip(String t, {Color color = inkPaper, Widget? lead, Key? key}) =>
    Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, const SizedBox(width: 4)],
        Text(t, style: _prose(11, color, w: FontWeight.w700)),
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
              border: Border.all(color: i < n ? inkGold : inkGrey),
              borderRadius: BorderRadius.circular(2)),
        ),
    ]);

Map<String, int> _abilitiesOf(SimCharacter h) => {
      'strength': h.strength,
      'dexterity': h.dexterity,
      'constitution': h.constitution,
      'intelligence': h.intelligence,
      'wisdom': h.wisdom,
      'perception': h.perception,
      'luck': h.luck,
      'charisma': h.charisma,
    };

// ------------------------------------------------------------------ stats
/// What the hero strikes and blocks with, as the fight works it out: the base
/// plus the worn gear's, plus what the gear's scaling gives for the stats.
({int armour, int damage}) _fightStats(TowerRun run, TowerData data) {
  final s = towerSessionOf(run, data);
  final scaling = equipmentScalingBonusFor(s.equippedItemIds, data.items,
      strength: s.strength,
      dexterity: s.dexterity,
      constitution: s.constitution,
      intelligence: s.intelligence);
  return (
    armour: s.baseArmor +
        equipmentBonusFor(s.equippedItemIds, data.items, 'armor') +
        scaling.armorBonus,
    damage: s.baseDamage +
        equipmentBonusFor(s.equippedItemIds, data.items, 'attackDamage') +
        scaling.damageBonus,
  );
}

class _StatsView extends ConsumerWidget {
  const _StatsView({required this.run, required this.data, required this.hero});

  final TowerRun run;
  final TowerData data;
  final SimCharacter hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The nudges only count on rules 2 (rules 1 keeps its stat picks there).
    final nudge = run.rules >= 2 ? hero.pickedPoints : const <String, int>{};
    final total = nudge.values.fold<int>(0, (a, b) => a + b);
    final stats = _fightStats(run, data);
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(
              tr(ref, 'tower_bm_hp')
                  .replaceAll('{a}', '${hero.currentHealth}')
                  .replaceAll('{b}', '${hero.maxHealth}'),
              color: inkRed,
              lead: const Icon(Icons.favorite,
                  size: IconSize.s16, color: inkRed)),
          _chip(tr(ref, 'tower_bm_level').replaceAll('{n}', '${hero.level}')),
          _chip(tr(ref, 'tower_bm_armour').replaceAll('{n}', '${stats.armour}'),
              key: const Key('tower_bm_armour'),
              lead: const Icon(Icons.shield_outlined,
                  size: IconSize.s16, color: inkPaper)),
          _chip(tr(ref, 'tower_bm_damage').replaceAll('{n}', '${stats.damage}'),
              key: const Key('tower_bm_damage'),
              lead:
                  const Icon(Icons.bolt, size: IconSize.s16, color: inkPaper)),
        ]),
        const SizedBox(height: 4),
        Center(
          child: LevelUpStatsArea(
              before: _abilitiesOf(hero),
              after: null,
              label: (k) => tr(ref, abilityAbbrevKey(k)),
              dark: true),
        ),
        if (run.rules >= 2) ...[
          Text(
              tr(ref, 'tower_bm_nudges')
                  .replaceAll('{n}', '$total')
                  .replaceAll('{cap}', '${towerNudgeClimbCapOf(run.rules)}'),
              key: const Key('tower_bm_nudges'),
              style: _prose(12, inkPaper, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 6, children: [
            for (final k in abilityRadarOrder)
              if ((nudge[k] ?? 0) > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  LevelUpSymbol(k, size: 16),
                  const SizedBox(width: 4),
                  _pips(nudge[k]!, towerNudgeStatCapOf(run.rules)),
                ]),
          ]),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------- gear
const _slots = ['Head', 'Weapon', 'Banner', 'Top', 'Bottom', 'Foot'];

class _GearView extends ConsumerStatefulWidget {
  const _GearView({required this.run, required this.data, required this.hero});

  final TowerRun run;
  final TowerData data;
  final SimCharacter hero;

  @override
  ConsumerState<_GearView> createState() => _GearViewState();
}

class _GearViewState extends ConsumerState<_GearView> {
  String? _slot;

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    Map<String, dynamic>? row(String? id) =>
        id == null ? null : (items[id] as Map?)?.cast<String, dynamic>();
    final selected = _slot ??
        _slots.firstWhere((s) => hero.equippedBySlot[s] != null,
            orElse: () => 'Weapon');
    Widget tile(String slot) {
      final id = hero.equippedBySlot[slot];
      final item = row(id);
      final isSel = slot == selected;
      return GestureDetector(
        key: Key('tower_gear_$slot'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _slot = slot),
        child: SizedBox(
          width: 92,
          child: Column(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: inkDark,
                  border: Border.all(
                      color:
                          isSel ? inkRed : (id == null ? inkSlate : inkPaper),
                      width: isSel ? 2.5 : 1.5),
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: id == null
                  ? Text(tr(ref, 'tower_bm_empty'), style: _prose(10, inkGrey))
                  : ItemPixelIcon(id, item?['itemType']?.toString(),
                      size: IconSize.s48),
            ),
            const SizedBox(height: 3),
            Text(tr(ref, 'forge_slot_$slot').toUpperCase(),
                style: _prose(9, inkGrey, w: FontWeight.w700)
                    .copyWith(letterSpacing: 0.6)),
            Text(item?['itemName']?.toString() ?? '',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: _prose(10.5, inkPaper)),
          ]),
        ),
      );
    }

    final walk = heroWalkName(hero.raceId, hero.professionId);
    final chosen = row(hero.equippedBySlot[selected]);
    return ListView(
      padding: const EdgeInsets.only(right: 8),
      children: [
        SizedBox(
          height: 500,
          child: Stack(alignment: Alignment.center, children: [
            Image.asset(levelUpHeroAsset(walk),
                height: 300,
                filterQuality: FilterQuality.none,
                isAntiAlias: false),
            Positioned(top: 0, child: tile('Head')),
            Positioned(left: 0, top: 110, child: tile('Weapon')),
            Positioned(right: 0, top: 110, child: tile('Banner')),
            Positioned(left: 0, top: 235, child: tile('Top')),
            Positioned(right: 0, top: 235, child: tile('Bottom')),
            Positioned(bottom: 0, child: tile('Foot')),
          ]),
        ),
        if (chosen != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(color: inkSlate),
                borderRadius: BorderRadius.circular(8)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${chosen['itemName']}', style: _display(15, inkPaper)),
              const SizedBox(height: 4),
              ItemStatChips(
                  item: chosen,
                  language: ref.watch(appLanguageProvider),
                  compact: true,
                  deltaVsEmpty: false),
            ]),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------- dice
class _DiceView extends ConsumerStatefulWidget {
  const _DiceView({required this.data, required this.hero});

  final TowerData data;
  final SimCharacter hero;

  @override
  ConsumerState<_DiceView> createState() => _DiceViewState();
}

class _DiceViewState extends ConsumerState<_DiceView> {
  String? _die;
  int? _face;

  static const _abbr = {
    'Attack': 'ATK',
    'Defend': 'DEF',
    'Skill': 'SKL',
    'Heal': 'HEAL',
    'Mana': 'MANA',
  };

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final ids = hero.ownedDice.keys.toList();
    final inPlay = hero.diceId;
    final id = ids.contains(_die)
        ? _die!
        : (ids.contains(inPlay) ? inPlay : ids.first);
    final faces = hero.ownedDice[id] ?? const <Map<String, dynamic>>[];
    final lang = ref.watch(appLanguageProvider);
    Widget disc(int i, double side) {
      final f = faces[i];
      final skill = f['type'] == 'Skill';
      final sel = _face == i;
      return GestureDetector(
        key: Key('tower_die_face_$i'),
        onTap: () => setState(() => _face = i),
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: inkDark,
              border: Border.all(
                  color: sel ? inkRed : (skill ? inkGold : inkPaper),
                  width: sel ? 2.5 : 1.5)),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            skill
                ? Icon(Icons.auto_awesome, size: side * 0.34, color: inkGold)
                : Text('${f['value']}', style: _display(side * 0.36, inkPaper)),
            Text(_abbr['${f['type']}'] ?? '',
                style: _prose(side * 0.17, inkGrey, w: FontWeight.w700)),
          ]),
        ),
      );
    }

    final face = _face != null && _face! < faces.length ? faces[_face!] : null;
    final assigned = _face == null ? null : hero.diceSkillAssignments['$_face'];
    return Column(children: [
      SizedBox(
        height: 78,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final d in ids)
            GestureDetector(
              key: Key('tower_die_$d'),
              onTap: () => setState(() {
                _die = d;
                _face = null;
              }),
              child: Container(
                width: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: inkDark,
                    border: Border.all(
                        color: d == id ? inkRed : inkSlate,
                        width: d == id ? 2.5 : 1),
                    borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: DieTile(
                    dieId: d,
                    faces: hero.ownedDice[d]!.length,
                    size: 52,
                    glowing: d == inPlay),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: DieSlotRing(
          count: faces.length,
          slot: (i, side, compact) => disc(i, side),
          center: DieTile(dieId: id, faces: faces.length, size: 96),
        ),
      ),
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            border: Border.all(color: inkSlate),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(towerDieName(ref, id), style: _display(15, inkPaper)),
              if (face != null)
                Text(
                    [
                      '${face['faceName'] ?? face['type']}',
                      if (face['type'] != 'Skill') '${face['value']}',
                      if (assigned != null)
                        skillDisplayName(assigned, language: lang),
                    ].join(' · '),
                    style: _prose(12, inkGrey)),
            ]),
          ),
          if (id == inPlay)
            _chip(tr(ref, 'tower_bm_in_play'), color: inkRed)
          else
            FilledButton(
              key: const Key('tower_die_play'),
              style: FilledButton.styleFrom(
                  backgroundColor: inkRed,
                  foregroundColor: inkPaper,
                  visualDensity: VisualDensity.compact),
              onPressed: () => ref
                  .read(towerProvider.notifier)
                  .chooseDie(id, data: widget.data),
              child: Text(tr(ref, 'tower_bm_play')),
            ),
        ]),
      ),
    ]);
  }
}
