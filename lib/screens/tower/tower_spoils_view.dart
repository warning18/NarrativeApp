// The spoils of a won floor (v1.861): the main game's spoils sheet
// (LootSheet), no gold, beside the Tower's ladder. What the floor's chest
// gave (gear worn when it beats the hero's, potions into the bag) is only
// shown here: the engine has already put it where it goes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class TowerSpoilsView extends ConsumerWidget {
  const TowerSpoilsView({super.key, required this.run, required this.onTake});

  final TowerRun run;

  /// The Take button: on to the floor's boon or oath, or the next floor.
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final ink = InkColors.of(context);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final drop = run.spoils[run.floor] ?? const <String>[];
    final potions = drop.fold<int>(
      0,
      (n, id) => n + (towerSpoilsPotions[id] ?? 0),
    );
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
          ? Text(
              tr(ref, 'tower_spoils_none'),
              key: const Key('tower_spoils_none'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          : null,
    );
  }

  LootReward _reward(
    int i,
    String id,
    Map<String, dynamic>? item,
    AppLanguage lang,
  ) {
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
