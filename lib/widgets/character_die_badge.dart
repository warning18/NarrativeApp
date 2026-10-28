// The die in hand on the Character tab's portrait (v1.605, the user's pick of
// the two placements drawn in docs/proposals/character-dice-button.md): a round
// badge on the portrait's lower right corner in the die's own look, ringed in
// the page's colour so it lies on the square, with the number of the other
// dice in the bag as a pill on its lower left. One tap opens the dice screen on
// that die. Hidden while the dice are not yet open (the inventory feature) and
// for a character with no die.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/feature_unlocks_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../data/feature_unlocks.dart' show GameFeature, GameFeatureInfo;
import '../screens/dice_loadout_screen.dart';
import '../theme/stitched_ink.dart';
import 'inventory_parts.dart' show InventoryDieTile;

class CharacterDieBadge extends ConsumerWidget {
  const CharacterDieBadge({super.key});

  /// How far the badge reaches beyond the portrait's edge.
  static const double overhang = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    if (!isFeatureUnlocked(ref, GameFeature.inventory.id)) {
      return const SizedBox.shrink();
    }
    final dieId =
        ref.watch(playerSessionProvider.select((s) => s.equippedDiceId));
    final owned =
        ref.watch(playerSessionProvider.select((s) => s.ownedDiceIds));
    final dice = ref.watch(localizedDbProvider(diceSchema)).value;
    final die = dieId == null ? null : dice?[dieId] as Map<String, dynamic>?;
    if (dieId == null || die == null) return const SizedBox.shrink();
    final faces = (die['numberOfFaces'] as num?)?.toInt() ??
        (die['faces'] as List?)?.length ??
        6;
    final more =
        owned.where((id) => id != dieId && dice!.containsKey(id)).length;
    return Tooltip(
      message: tr(ref, 'tile_dice'),
      child: GestureDetector(
        key: const Key('character_die_badge'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DiceLoadoutScreen(initialDieId: dieId))),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.scaffoldBackgroundColor,
              ),
              child: InventoryDieTile(
                  dieId: dieId, faces: faces, size: 28, lit: true),
            ),
            if (more > 0)
              Positioned(
                left: -10,
                bottom: -4,
                child: Container(
                  key: const Key('character_die_badge_more'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: ink.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+$more',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.scaffoldBackgroundColor,
                          fontWeight: FontWeight.w700,
                          height: 1.1)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
