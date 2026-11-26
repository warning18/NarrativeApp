// The spoils of a won floor (v1.861): the main game's spoils sheet
// (LootSheet), no gold, beside the Tower's ladder. What the floor's chest
// gave (gear worn when it beats the hero's, potions into the bag) is only
// shown here: the engine has already put it where it goes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_hero.dart' show TowerData;
import '../../data/tower/tower_rewards.dart' show TowerReward;
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/item_stats.dart';
import '../../widgets/loot_sheet.dart';
import '../../theme/icon_sizes.dart';
import 'ink/ink_palette.dart';
import 'tower_coin_view.dart';
import 'tower_offer_view.dart' show towerCardText, towerStyledCardFor;
import 'tower_styled_card.dart';

class TowerSpoilsView extends ConsumerWidget {
  const TowerSpoilsView(
      {super.key,
      required this.run,
      required this.onTake,
      this.coinsGained = 0});

  /// The coins the floor paid (towerCoinsFor), a line when above 0.
  final int coinsGained;

  final TowerRun run;

  /// The Take button: on to the floor's boon or oath, or the next floor.
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final ink = InkColors.of(context);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final drop = run.spoils[run.floor] ?? const <String>[];
    final potions =
        drop.fold<int>(0, (n, id) => n + (towerSpoilsPotions[id] ?? 0));
    final antidotes = drop.where((id) => id == towerSpoilsAntidote).length;
    final rewards = <LootReward>[
      for (var i = 0; i < drop.length; i++)
        _reward(i, drop[i], items[drop[i]] as Map<String, dynamic>?, lang),
    ];
    return LootSheet(
      language: lang,
      title: tr(ref, 'tower_spoils_title').replaceAll('{n}', '${run.floor}'),
      chestAsset: 'assets/icons/chests/wooden_open.png',
      tierLabel: tr(ref, 'tower_floor_${run.floor}'),
      showHandle: false,
      // The chest at 96 px (72 on a narrow phone, so a French title fits).
      chestSize: MediaQuery.sizeOf(context).width >= 360 ? 96 : 72,
      changes: [
        if (coinsGained > 0)
          LootSheetLine(
            label:
                tr(ref, 'tower_coins_gained').replaceAll('{n}', '$coinsGained'),
            before: '${run.coins - coinsGained}',
            after: '${run.coins}',
            icon: const TowerCoinDisc(size: IconSize.s32),
            tone: inkPaper,
          ),
        if (potions > 0)
          LootSheetLine(
            label: tr(ref, 'loot_line_potions'),
            before: '×${run.potions - potions}',
            after: '×${run.potions}',
            icon: Icon(Icons.science, size: IconSize.s32, color: ink.heal),
            tone: ink.heal,
          ),
        if (antidotes > 0)
          LootSheetLine(
            label: tr(ref, 'loot_line_antidotes'),
            before: '×${run.antidotes - antidotes}',
            after: '×${run.antidotes}',
            icon: const ItemPixelIcon('antidote', 'Potion', size: IconSize.s32),
            tone: ink.heal,
          ),
      ],
      rewards: rewards,
      useNow: const {},
      onUseNow: (_, __) {},
      onTake: onTake,
      footer: drop.isEmpty
          ? Text(tr(ref, 'tower_spoils_none'),
              key: const Key('tower_spoils_none'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
          : null,
    );
  }

  LootReward _reward(
      int i, String id, Map<String, dynamic>? item, AppLanguage lang) {
    final type = item?['itemType']?.toString() ?? '';
    final note = consumableNote(id, item, lang);
    final worn = note == null
        ? '${item?['description'] ?? ''}\n${trFor(lang, 'tower_spoils_worn')}'
            .trim()
        : '$note\n${trFor(lang, 'tower_spoils_bag')}';
    return LootReward(
      id: '$i',
      name: item?['itemName']?.toString() ?? id,
      text: worn,
      icon: ItemPixelIcon(id, type, size: IconSize.s32),
    );
  }
}

/// The spoils of rules 2 (the loot table's summary, v2.10.26): the card taken
/// from the table, in its style, with what it is and the coins the floor paid,
/// closed by Continue. Shown once the table is answered; no chest.
class TowerLootSummary extends ConsumerWidget {
  const TowerLootSummary({
    super.key,
    required this.run,
    required this.data,
    required this.floor,
    required this.taken,
    required this.coinsGained,
    required this.onContinue,
  });

  final TowerRun run;
  final TowerData data;
  final int floor;

  /// The loot card taken; null when the table was left.
  final TowerReward? taken;
  final int coinsGained;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final card = taken;
    final t = card == null ? null : towerCardText(ref, card);
    const width = 96.0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          key: const Key('tower_loot_summary'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: inkPaper, border: Border.all(color: inkDeep, width: 3)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(ref, 'tower_spoils_loot_title').replaceAll('{n}', '$floor'),
                style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: InkFonts.display, color: inkOnPaper)),
            Text(
                tr(
                    ref,
                    card == null
                        ? 'tower_spoils_loot_none'
                        : 'tower_spoils_loot_took'),
                style: theme.textTheme.bodySmall?.copyWith(color: inkSlate)),
            const SizedBox(height: 12),
            if (card != null && t != null)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: width,
                  height: width * towerStyledCardHeight / towerStyledCardWidth,
                  child: FittedBox(
                      child: towerStyledCardFor(ref, run, data, card)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: InkFonts.display,
                                color: inkOnPaper)),
                        if (t.text.isNotEmpty)
                          Text(t.text,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: inkOnPaper)),
                      ]),
                ),
              ]),
            if (coinsGained > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  const TowerCoinDisc(size: IconSize.s32),
                  const SizedBox(width: 10),
                  Text(
                      tr(ref, 'tower_coins_gained')
                          .replaceAll('{n}', '$coinsGained'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: inkOnPaper)),
                ]),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('tower_loot_continue'),
                onPressed: onContinue,
                child: Text(tr(ref, 'tower_spoils_continue')),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
