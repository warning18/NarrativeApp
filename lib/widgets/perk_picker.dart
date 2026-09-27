import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/perks.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// The level-up perk choice (see perks.dart): the three perks on offer,
/// one tap to take one, then the next offer while picks remain. Nothing
/// when there's no pick to make.
class PerkPicker extends ConsumerStatefulWidget {
  const PerkPicker({super.key});

  @override
  ConsumerState<PerkPicker> createState() => _PerkPickerState();
}

class _PerkPickerState extends ConsumerState<PerkPicker> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(playerSessionProvider.notifier).ensurePerkOffer();
    });
  }

  Future<void> _choose(String perkName) async {
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.choosePerk(perkName);
    await notifier.ensurePerkOffer();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    if (session.pendingPerkPicks <= 0 || session.perkOffer.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${tr(ref, 'perk_choose_title')} · '
          '${tr(ref, 'perk_pending').replaceAll('{n}', '${session.pendingPerkPicks}')}',
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        for (final name in session.perkOffer)
          if (perkFromName(name) case final perk?)
            Card(
              key: Key('perk_offer_$name'),
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _busy ? null : () => _choose(name),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(ref, perkNameKey(perk)),
                                style: theme.textTheme.titleSmall),
                            Text(tr(ref, perkDescKey(perk)),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (perkInfo[perk]!.maxRank > 1)
                        Text(
                          tr(ref, 'perk_rank')
                              .replaceAll('{n}',
                                  '${(session.perkRanks[name] ?? 0) + 1}')
                              .replaceAll(
                                  '{max}', '${perkInfo[perk]!.maxRank}'),
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// The perks taken so far, with their ranks.
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
