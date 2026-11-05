import 'package:flutter/material.dart';

import '../data/loot_changes.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'loot_sheet.dart';

/// The sheet's "what the spoils change" lines for what the engine says each
/// reward changes ([lootChanges], data/loot_changes.dart): one line per thing
/// that changes, in the order it first changes, a value several rewards move
/// shown from where the first leaves it to where the last does (two antidotes:
/// x1 to x3). [items] is items.json (names and pictures of the bag's items),
/// [spellName] the name of a spell by its id. A reward with nothing to count
/// (gear, a spellbook already known) adds no line.
List<LootSheetLine> lootSheetLines(
  List<LootRewardChanges> rewards, {
  required AppLanguage language,
  required InkColors ink,
  Map<String, dynamic> items = const {},
  String Function(String spellId)? spellName,
}) {
  final merged = <String, LootChange>{};
  final order = <String>[];
  for (final reward in rewards) {
    // The Knucklebone says its rolls a round: its copy in the bag is not a
    // second line.
    final rolls =
        reward.changes.any((c) => c.kind == LootChangeKind.rollsPerRound);
    for (final c in reward.changes) {
      if (c.kind == LootChangeKind.nothing) continue;
      if (rolls && c.kind == LootChangeKind.bagItem) continue;
      final key = '${c.kind.name}:${c.subjectId ?? ''}';
      final before = merged[key];
      if (before == null) {
        order.add(key);
        merged[key] = c;
      } else {
        merged[key] = LootChange(
            kind: c.kind,
            subjectId: c.subjectId,
            before: before.before,
            after: c.after);
      }
    }
  }
  String t(String key) => trFor(language, key);
  return [
    for (final key in order)
      _line(merged[key]!, language, ink, items, spellName, t),
  ];
}

LootSheetLine _line(
  LootChange c,
  AppLanguage language,
  InkColors ink,
  Map<String, dynamic> items,
  String Function(String)? spellName,
  String Function(String) t,
) {
  String times(int n) => '×$n';
  switch (c.kind) {
    case LootChangeKind.gold:
      return LootSheetLine(
        label: t('loot_line_gold'),
        before: '${c.before}',
        after: '${c.after}',
        icon: Icon(Icons.monetization_on, size: 28, color: ink.gold),
        tone: ink.gold,
      );
    case LootChangeKind.potions:
      return LootSheetLine(
        label: t('loot_line_potions'),
        before: times(c.before),
        after: times(c.after),
        icon: Icon(Icons.science, size: 26, color: ink.heal),
        tone: ink.heal,
      );
    case LootChangeKind.antidotes:
      return LootSheetLine(
        label: t('loot_line_antidotes'),
        before: times(c.before),
        after: times(c.after),
        icon: const ItemPixelIcon('antidote', 'Potion', size: 28),
        tone: ink.heal,
      );
    case LootChangeKind.bagItem:
      final id = c.subjectId ?? '';
      final item = items[id] as Map<String, dynamic>?;
      return LootSheetLine(
        label: item?['itemName']?.toString() ?? id,
        before: times(c.before),
        after: times(c.after),
        icon: ItemPixelIcon(id, item?['itemType']?.toString(), size: 28),
      );
    case LootChangeKind.rollsPerRound:
      return LootSheetLine(
        label: t('loot_line_rolls'),
        before: '${c.before}',
        after: '${c.after}',
        icon: const ItemPixelIcon('charm_fourth_roll', 'Charm', size: 28),
      );
    case LootChangeKind.health:
      return LootSheetLine(
        label: t('loot_line_health'),
        before: '${c.before}',
        after: '${c.after}',
        icon: Icon(Icons.favorite, size: 26, color: ink.blood),
        tone: ink.heal,
      );
    case LootChangeKind.spell:
      final id = c.subjectId ?? '';
      return LootSheetLine(
        label: '${t('loot_line_spell')} · ${spellName?.call(id) ?? id}',
        before: '—',
        after: t('loot_line_spell_learnt'),
        icon: Icon(Icons.auto_awesome, size: 26, color: ink.voidColor),
        tone: ink.voidColor,
      );
    case LootChangeKind.statPoints:
      return LootSheetLine(
        label: t('loot_line_stat_points'),
        before: '${c.before}',
        after: '${c.after}',
        icon: Icon(Icons.trending_up, size: 26, color: ink.gold),
      );
    case LootChangeKind.offers:
      return LootSheetLine(
        label: t('loot_line_offers'),
        before: '${c.before}',
        after: '${c.after}',
        icon: Icon(Icons.handshake, size: 26, color: ink.gold),
      );
    case LootChangeKind.nothing:
      throw StateError('a "nothing" line has no row');
  }
}
