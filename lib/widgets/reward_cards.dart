// The reward card's kinds (reward_card.dart): each builds the card's data
// from what the moment knows. Quest complete, an item found, a clan's gift.
import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/item_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';
import 'item_lore.dart';
import 'item_stats.dart';
import 'reward_card.dart';

/// The accent of a quest's chapter (the card's header colour); chapter art
/// takes this over when it exists.
Color rewardChapterColour(int chapter) {
  const palette = <Color>[
    Color(0xFFE07A2F), // 1 ember
    Color(0xFF4FA3A5), // 2 salt
    Color(0xFFC95F4A), // 3 ash
    Color(0xFF6E9E5B), // 4 fen
    Color(0xFF7FB4D8), // 5 frost
    Color(0xFF5A8FD0), // 6 tide
    Color(0xFFB5894B), // 7 lantern
    Color(0xFFA77BCA), // 8 throne
  ];
  return palette[(chapter.clamp(1, palette.length)) - 1];
}

/// An item's own picture on a reward tile, a mark for its absence.
Widget rewardItemIcon(String itemId, Color accent) => PixelIcon(
      ItemIcons.pathFor(itemId),
      size: 36,
      fallback: Icon(Icons.inventory_2_outlined, size: 28, color: accent),
    );

/// One row for an item: its name, its rarity as a tag and its stats under
/// it, "NEW" at the right.
RewardLine rewardItemLine(
  BuildContext context, {
  required String itemId,
  required Map<String, dynamic>? item,
  required AppLanguage lang,
}) {
  final scheme = Theme.of(context).colorScheme;
  final rarity = item?['rarity']?.toString() ?? '';
  final colour = itemRarityColor(scheme, rarity);
  final stats = [
    for (final line in gearStatLines(item, null, lang))
      '${line.label} ${line.value > 0 ? '+' : ''}${line.value}',
  ];
  final rare = rarity == 'Rare' || rarity == 'Relic';
  return RewardLine(
    key: Key('reward_item_$itemId'),
    icon: rewardItemIcon(itemId, colour),
    accent: colour,
    title: item?['itemName']?.toString() ?? itemId,
    tag: itemRarityLabelFor(lang, rarity),
    tagColor: colour,
    sub: stats.isEmpty
        ? (item?['description']?.toString() ?? '')
        : stats.join(' · '),
    value: trFor(lang, 'reward_new'),
    glow: rare,
  );
}

/// Quest complete: the gold, the experience with its bar, what else was
/// won, and the notes (a die paid in gold, the clans' and the party's
/// answers).
RewardCardData questRewardCard(
  BuildContext context, {
  required AppLanguage lang,
  required InkColors ink,
  required String questName,
  required int chapter,
  required int gold,
  required int xp,
  required int xpBefore,
  required int xpAfter,
  required int xpNeeded,
  required int level,
  required bool leveledUp,
  List<RewardLine> found = const [],
  List<RewardNote> notes = const [],
}) {
  final accent = rewardChapterColour(chapter);
  final xpSub = leveledUp
      ? trFor(lang, 'reward_xp_levelup').replaceAll('{n}', '$level')
      : trFor(lang, 'reward_xp_sub')
          .replaceAll('{before}', '$xpBefore')
          .replaceAll('{after}', '$xpAfter')
          .replaceAll('{need}', '$xpNeeded')
          .replaceAll('{n}', '$level');
  return RewardCardData(
    kind: '${trFor(lang, 'reward_kind_quest')} · '
        '${trFor(lang, 'reward_chapter').replaceAll('{n}', '$chapter')}',
    title: questName,
    accent: accent,
    button: trFor(lang, 'reward_continue'),
    lines: [
      if (gold > 0)
        RewardLine(
          key: const Key('reward_gold'),
          icon: Icon(Icons.paid, size: 30, color: ink.gold),
          accent: ink.gold,
          title: trFor(lang, 'reward_gold'),
          sub: trFor(lang, 'reward_gold_sub'),
          value: '+$gold',
        ),
      if (xp > 0)
        RewardLine(
          key: const Key('reward_xp'),
          icon: Icon(Icons.star, size: 30, color: ink.tide),
          accent: ink.tide,
          title: trFor(lang, 'reward_xp'),
          bar: leveledUp ? 1 : (xpNeeded <= 0 ? 0 : xpAfter / xpNeeded),
          sub: xpSub,
          value: '+$xp',
        ),
      ...found,
    ],
    notes: notes,
  );
}

/// An item (or a few) found: one row each.
RewardCardData itemFoundCard({
  required AppLanguage lang,
  required String title,
  required Color accent,
  required List<RewardLine> lines,
}) =>
    RewardCardData(
      kind: trFor(lang, 'reward_kind_item'),
      title: title,
      accent: accent,
      button: trFor(lang, 'reward_continue'),
      lines: lines,
    );

/// A clan's gift taken: the gift's row, and what it did to the standings.
RewardCardData clanGiftCard({
  required AppLanguage lang,
  required String clanName,
  required Color clanColour,
  required RewardLine gift,
  required List<String> standing,
}) =>
    RewardCardData(
      kind: trFor(lang, 'reward_kind_clan_gift'),
      title: clanName,
      accent: clanColour,
      button: trFor(lang, 'reward_continue'),
      lines: [gift],
      notes: [
        if (standing.isNotEmpty)
          RewardNote(
              '${trFor(lang, 'reward_standing')}: ${standing.join(' · ')}'),
      ],
    );
