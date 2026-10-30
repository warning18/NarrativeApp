// A clan's die in the dice bag (clan-dice-gifts.md, section 5): the clan's
// flag, "<Clan>'s gift", and how the die's Resonance stands -- lit, or
// asleep with its reason. Nothing for a die that is no clan's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/clan_dice.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import 'pixel_banner.dart';

/// The line of resonance text for [state] ([clan]: the clan's name), or ''
/// for no clan die.
String resonanceLineFor(Resonance state, String clan, AppLanguage language) {
  String t(String key) => trFor(language, key);
  return switch (state) {
    Resonance.lit => t('clan_die_resonance_lit')
        .replaceAll('{n}', '$resonanceBonus')
        .replaceAll('{max}', '$resonanceMaxFace'),
    Resonance.notMainClan =>
      t('clan_die_resonance_main').replaceAll('{clan}', clan),
    Resonance.standingLow =>
      t('clan_die_resonance_standing').replaceAll('{clan}', clan),
    Resonance.none => '',
  };
}

class ClanDieGift extends ConsumerWidget {
  const ClanDieGift({super.key, required this.dieId, this.die});

  final String dieId;

  /// The die's dice.json record; read from the game data when null.
  final Map<String, dynamic>? die;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final die = this.die ??
        ref.watch(gameDbProvider(diceSchema)).value?[dieId]
            as Map<String, dynamic>?;
    final clanId = clanOfDie(die);
    if (clanId.isEmpty) return const SizedBox.shrink();
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final language = ref.watch(appLanguageProvider);
    final faction = data.faction(clanId);
    final clan = faction?.nameFor(language) ?? clanId;
    final state = resonanceOf(die, politics: politics, data: data);
    final theme = Theme.of(context);
    final color = faction == null
        ? theme.colorScheme.primary
        : Color(faction.color | 0xFF000000);
    final lit = state == Resonance.lit;
    return Padding(
      key: Key('clan_die_gift_$dieId'),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClanFlag(factionId: clanId, height: 26, found: lit),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trFor(language, 'clan_die_gift_title')
                      .replaceAll('{clan}', clan),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                Text(
                  resonanceLineFor(state, clan, language),
                  key: Key('clan_die_resonance_${state.name}'),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: lit ? null : theme.colorScheme.onSurfaceVariant,
                      fontStyle: lit ? null : FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
