// The spoils of a won floor (v1.861): the main game's spoils sheet
// (LootSheet), no gold, beside the Tower's ladder. What the floor's chest
// gave (gear worn when it beats the hero's, potions into the bag) is only
// shown here: the engine has already put it where it goes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_hero.dart' show TowerData, towerHeroOf;
import '../../data/tower/tower_levelup_loot.dart' show towerNudgeOn;
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
import '../../theme/motion.dart';
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

/// The confirm sheet of a table's choice (v2.10.28): the card picked, large
/// over the floor, with Change (back to the cards) and Confirm; the choice
/// only counts at Confirm. On the loot table it is the floor's spoils sheet
/// (its title and the floor's coins). A table of the Level Up and loot rules
/// shows the styled card; an older table shows the card's words.
class TowerPickConfirm extends ConsumerWidget {
  const TowerPickConfirm({
    super.key,
    required this.run,
    required this.data,
    required this.reward,
    required this.loot,
    required this.styled,
    required this.coinsGained,
    required this.onConfirm,
    required this.onChange,
  });

  final TowerRun run;
  final TowerData data;
  final TowerReward reward;

  /// The loot table (its spoils title and coins), or another table.
  final bool loot;

  /// Draw the styled card (rules 2's tables), or only the words.
  final bool styled;
  final int coinsGained;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = towerCardText(ref, reward);
    // The gamble card is final once taken: the sheet says so.
    final gamble = reward.kind == TowerRewardKind.gamble;
    // The stat a skill raises, as on the table's card.
    final String? nudge = styled
        ? towerNudgeOn(towerHeroOf(run, data), reward, data, rules: run.rules)
        : null;
    // The card is a reveal: it grows in over the floor (reduce motion: it is
    // simply there).
    final reduced = MediaQuery.of(context).disableAnimations;
    const width = 216.0;
    Widget reveal(Widget child) => reduced
        ? child
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.86, end: 1),
            duration: Motion.slow,
            curve: Curves.easeOutBack,
            builder: (context, v, c) => Opacity(
                opacity: ((v - 0.86) / 0.14).clamp(0.0, 1.0),
                child: Transform.scale(scale: v, child: c)),
            child: child);
    return ListView(
      key: const Key('tower_pick_confirm'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // The bookmarks hang over the top right: the words keep clear of them.
        Padding(
          padding: const EdgeInsets.only(right: 150),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                gamble
                    ? tr(ref, 'tower_gamble_confirm_title')
                    : loot
                        ? tr(ref, 'tower_spoils_loot_title')
                            .replaceAll('{n}', '${run.floor}')
                        : tr(ref, 'tower_confirm_title'),
                style: theme.textTheme.headlineSmall),
            Text(
                tr(
                    ref,
                    gamble
                        ? 'tower_gamble_confirm_hint'
                        : 'tower_confirm_hint'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 16),
        if (styled)
          Center(
            child: reveal(Container(
              width: width,
              height: width * towerStyledCardHeight / towerStyledCardWidth,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                    color: inkBlack.withValues(alpha: 0.55), blurRadius: 36),
              ]),
              child: FittedBox(
                  child:
                      towerStyledCardFor(ref, run, data, reward, nudge: nudge)),
            )),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: inkBlack.withValues(alpha: 0.72),
                border: Border.all(color: inkSlate),
                borderRadius: BorderRadius.circular(8)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.kind.toUpperCase(), style: theme.textTheme.labelMedium),
              Text(t.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
              if (t.text.isNotEmpty)
                Text(t.text, style: theme.textTheme.bodyMedium),
            ]),
          ),
        if (loot && coinsGained > 0) ...[
          const SizedBox(height: 14),
          // The floor's coins on a soft ink scrim over the floor.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
                color: inkBlack.withValues(alpha: 0.72),
                border: Border.all(color: inkSlate),
                borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const TowerCoinDisc(size: IconSize.s32),
              const SizedBox(width: 10),
              Text(
                  tr(
                          ref,
                          coinsGained == 1
                              ? 'tower_coins_gained_one'
                              : 'tower_coins_gained')
                      .replaceAll('{n}', '$coinsGained'),
                  style: theme.textTheme.bodyMedium),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('tower_change'),
              onPressed: onChange,
              child:
                  Text(tr(ref, gamble ? 'tower_gamble_look' : 'tower_change')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              key: const Key('tower_confirm'),
              onPressed: onConfirm,
              child:
                  Text(tr(ref, gamble ? 'tower_gamble_take' : 'tower_confirm')),
            ),
          ),
        ]),
      ],
    );
  }
}
