// The clan power sign (option A, "Ranking with arrows"): a small dark plate
// with the clan's rank among the clans with power and an arrow for how it
// moved since the last chapter ("#2 ▲"). Neutral gold and blue-grey, never
// the standing's green and red. Reads Core's clanPowerRankingProvider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';

const Color _plateInk = Color(0xFF141217);
const Color _plateGold = Color(0xFFF2C14E);
const Color _plateDown = Color(0xFF8FA3B8);

/// [clanId]'s [ClanPowerRank] now, or null for a faction with no power.
final clanRankProvider = Provider.family<ClanPowerRank?, String>((ref, clanId) {
  for (final r in ref.watch(clanPowerRankingProvider)) {
    if (r.clanId == clanId) return r;
  }
  return null;
});

/// The arrow for [change] places climbed: up, down, or a dash when steady.
String rankArrow(int change) => change > 0
    ? '▲'
    : change < 0
        ? '▼'
        : '–';

Color _arrowColor(int change) => change > 0
    ? _plateGold
    : change < 0
        ? _plateDown
        : const Color(0xFFB8B2A6);

String _arrowKey(int change) => change > 0
    ? 'rank_arrow_up'
    : change < 0
        ? 'rank_arrow_down'
        : 'rank_arrow_steady';

/// The plate: "#2 ▲". Nothing for a clan with no power.
class ClanRankPlate extends ConsumerWidget {
  const ClanRankPlate({super.key, required this.clanId, this.size = 11});

  final String clanId;

  /// The text size; the plate grows with it.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(clanRankProvider(clanId));
    if (r == null) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    final change = r.rankChange;
    final label = trFor(lang, 'rank_plate_label')
        .replaceAll('{rank}', '${r.rank}')
        .replaceAll('{arrow}', trFor(lang, _arrowKey(change)));
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        key: Key('clan_rank_plate_$clanId'),
        padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: 1),
        decoration: BoxDecoration(
          color: _plateInk,
          borderRadius: BorderRadius.circular(size * 0.4),
          border: Border.all(color: _plateGold.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#${r.rank}',
                style: TextStyle(
                    color: _plateGold,
                    fontSize: size,
                    height: 1.2,
                    fontWeight: FontWeight.w800)),
            SizedBox(width: size * 0.25),
            Text(rankArrow(change),
                key: Key('clan_rank_arrow_$clanId'),
                style: TextStyle(
                    color: _arrowColor(change), fontSize: size * 0.85)),
          ],
        ),
      ),
    );
  }
}

/// The Clans page's line: "#2 ▲ Rank 2 of 10 in power · +3 power since the last chapter".
class ClanRankLine extends ConsumerWidget {
  const ClanRankLine({super.key, required this.clanId});

  final String clanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(clanRankProvider(clanId));
    if (r == null) return const SizedBox.shrink();
    final total = ref.watch(clanPowerRankingProvider).length;
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final d = r.powerChange;
    final delta = '${d > 0 ? '+' : '−'}${d.abs()}';
    final move = d == 0
        ? ''
        : ' · ${trFor(lang, 'rank_power_change').replaceAll('{delta}', delta)}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        key: Key('clan_rank_line_$clanId'),
        children: [
          ClanRankPlate(clanId: clanId, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                trFor(lang, 'rank_of_total')
                        .replaceAll('{rank}', '${r.rank}')
                        .replaceAll('{total}', '$total') +
                    move,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
