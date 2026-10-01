import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/perks.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// The perks taken so far, with their ranks (a rank is the Wayfarer's
/// gift in an offer since v1.194, see offers.dart).
class PerkList extends ConsumerWidget {
  const PerkList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranks = ref.watch(playerSessionProvider.select((s) => s.perkRanks));
    final theme = Theme.of(context);
    final owned = [
      for (final perk in Perk.values)
        if ((ranks[perk.name] ?? 0) > 0) perk,
    ];
    if (owned.isEmpty) {
      return Text(tr(ref, 'perks_none'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final perk in owned)
          ListTile(
            key: Key('perk_owned_${perk.name}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.stars, color: theme.colorScheme.primary),
            title: Text(tr(ref, perkNameKey(perk))),
            subtitle: Text(tr(ref, perkDescKey(perk))),
            trailing: perkInfo[perk]!.maxRank > 1
                ? Text(tr(ref, 'perk_rank')
                    .replaceAll('{n}', '${ranks[perk.name]}')
                    .replaceAll('{max}', '${perkInfo[perk]!.maxRank}'))
                : null,
          ),
      ],
    );
  }
}
