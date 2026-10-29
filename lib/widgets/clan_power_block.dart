// A clan's strength and its land (Wave 12, over Core's clan_power.dart): how
// powerful it is now (a bar across its four tiers, with the tier named), the
// places it holds (a count and the names), and, when it has made the
// character its nemesis, a red mark. For the clan's card (clan_peek.dart)
// and the Throne room's captions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart';
import '../data/factions.dart' show Faction;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'clan_rank_plate.dart';

/// The nemesis' red (the mark on its card, its standard and its places).
const Color nemesisRed = Color(0xFFD1453B);

/// The tier's name key (power_tier_minor ... power_tier_ascendant).
/// The colour a place held by [holder] is washed with on the map: the
/// clan's own, red when it is the party's [nemesis]; none for no holder.
Color? holderTint(
    String holder, Map<String, Faction> factions, String? nemesis) {
  if (holder.isEmpty) return null;
  if (holder == nemesis) return nemesisRed;
  final faction = factions[holder];
  return faction == null ? null : Color(faction.color | 0xFF000000);
}

String powerTierKey(PowerTier tier) => 'power_tier_${tier.name}';

/// The most places named in the list before "+N more".
const int powerBlockMaxPlaces = 6;

class ClanPowerBlock extends ConsumerWidget {
  const ClanPowerBlock(
      {super.key, required this.factionId, required this.color});

  final String factionId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(playerSessionProvider.select((s) => s.politics));
    final geography = ref.watch(geographyProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final nemesis = politics.nemesis == factionId;
    final powered = hasPower(factionId, data);
    if (!powered && !nemesis) return const SizedBox.shrink();

    final power = powerOf(politics, factionId, data);
    final tier = powerTierFor(power);
    final held = [
      for (final id in placesOf(factionId, geography, politics))
        if (geography.places[id] case final place?)
          lang == AppLanguage.fr && place.nameFr.isNotEmpty
              ? place.nameFr
              : place.name,
    ];
    final shown = held.take(powerBlockMaxPlaces).toList();
    final more = held.length - shown.length;
    final accent = nemesis ? nemesisRed : color;

    String holds() => switch (held.length) {
          0 => trFor(lang, 'holds_places_none'),
          1 => trFor(lang, 'holds_places_one'),
          final n => trFor(lang, 'holds_places_n').replaceAll('{n}', '$n'),
        };

    return Column(
      key: Key('clan_power_$factionId'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nemesis)
          Container(
            key: Key('clan_nemesis_$factionId'),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: nemesisRed.withValues(alpha: 0.14),
              border: Border.all(color: nemesisRed.withValues(alpha: 0.8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    size: 15, color: nemesisRed),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(trFor(lang, 'clan_nemesis_tag'),
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: nemesisRed, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        if (powered) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Row(
              children: [
                Text(trFor(lang, 'power_label').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontFamily: InkFonts.system,
                        letterSpacing: 1)),
                const Spacer(),
                Text(trFor(lang, powerTierKey(tier)),
                    key: Key('clan_power_tier_$factionId'),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: accent)),
                const SizedBox(width: 6),
                Text('$power',
                    key: Key('clan_power_value_$factionId'),
                    style:
                        theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
              ],
            ),
          ),
          _PowerBar(power: power, color: accent),
          ClanRankLine(clanId: factionId),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(holds(),
              key: Key('clan_holds_count_$factionId'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        if (shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              key: Key('clan_holds_list_$factionId'),
              spacing: 5,
              runSpacing: 4,
              children: [
                for (final name in shown)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.6)),
                      color: accent.withValues(alpha: 0.12),
                    ),
                    child: Text(name, style: theme.textTheme.labelSmall),
                  ),
                if (more > 0)
                  Text(trFor(lang, 'holds_more').replaceAll('{n}', '$more'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The power bar: 0 to [maxPower], ticks where the tiers begin (25, 50, 75).
class _PowerBar extends StatelessWidget {
  const _PowerBar({required this.power, required this.color});

  final int power;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      return SizedBox(
        key: const Key('power_bar'),
        height: 12,
        child: Stack(
          children: [
            Positioned.fill(
              top: 3,
              bottom: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: ink.seam.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 3,
              bottom: 3,
              width: width * power.clamp(0, maxPower) / maxPower,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: color,
                ),
              ),
            ),
            for (final tick in const [
              risingPower,
              dominantPower,
              ascendantPower
            ])
              Positioned(
                left: width * tick / maxPower - 1,
                top: 0,
                bottom: 0,
                width: 2,
                child: ColoredBox(color: ink.voidColor.withValues(alpha: 0.7)),
              ),
          ],
        ),
      );
    });
  }
}
