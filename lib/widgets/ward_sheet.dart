// "Ward the road" (wave 16, road_wards.dart): the Warding Cairn's Banish
// kept for the trail instead of a card. A sheet to pick the hunting clan
// (when more than one hunts) and how long to ward it, 3, 6 or 9 roads for 1,
// 2 or 3 charges; the ones the charges cannot pay for stand dim. Opened from
// the Banish power (roll_power_row.dart); the line it sets is Narrative's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/road_wards.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import 'pixel_banner.dart';
import 'sheet_kit.dart';

/// Opens the sheet over [context]; the charges to spend are read from the
/// session.
Future<void> showWardSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const WardSheet(),
    );

class WardSheet extends ConsumerStatefulWidget {
  const WardSheet({super.key});

  @override
  ConsumerState<WardSheet> createState() => _WardSheetState();
}

class _WardSheetState extends ConsumerState<WardSheet> {
  String? _clan;

  Future<void> _ward(String clanId, int roads) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final data = ref.read(clanDataProvider);
    final language = ref.read(appLanguageProvider);
    final nemesis = ref.read(politicsProvider).nemesis;
    final ok = await ref
        .read(playerSessionProvider.notifier)
        .wardRoad(clanId, roads, data);
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
    messenger?.showSnackBar(SnackBar(
        key: const Key('ward_set_toast'),
        content:
            Text(wardSetLine(clanId, language, data: data, nemesis: nemesis))));
  }

  @override
  Widget build(BuildContext context) {
    final targets = ref.watch(wardTargetsProvider);
    final charges = ref.watch(campRollsProvider).banish ?? 0;
    final data = ref.watch(clanDataProvider);
    final language = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final clan = targets.contains(_clan)
        ? _clan
        : (targets.isEmpty ? null : targets.first);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              icon: Icons.shield_outlined,
              title: tr(ref, 'ward_choice'),
              titleKey: const Key('ward_sheet_title'),
              caption: tr(ref, 'ward_choice_hint'),
              padding: const EdgeInsets.only(bottom: 8),
            ),
            if (clan == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(tr(ref, 'ward_no_target'),
                    key: const Key('ward_no_target')),
              )
            else ...[
              if (targets.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final id in targets)
                        ChoiceChip(
                          key: Key('ward_clan_$id'),
                          selected: id == clan,
                          avatar: ClanFlag(factionId: id, height: 18),
                          label:
                              Text(data.faction(id)?.shortFor(language) ?? id),
                          onSelected: (_) => setState(() => _clan = id),
                        ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    ClanFlag(factionId: clan, height: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          data.faction(clan)?.shortFor(language) ?? clan,
                          style: theme.textTheme.titleSmall),
                    ),
                  ]),
                ),
              for (final option in wardOptions(charges))
                SheetRow(
                  key: Key('ward_option_${option.roads}'),
                  leading: const Icon(Icons.shield_outlined),
                  title: wardLine('ward_length', language,
                      roads: option.roads, cost: option.cost),
                  enabled: option.affordable,
                  onTap: option.affordable
                      ? () => _ward(clan, option.roads)
                      : null,
                ),
            ],
            const SizedBox(height: 6),
            OutlinedButton(
              key: const Key('ward_close'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(ref, 'close_button')),
            ),
          ],
        ),
      ),
    );
  }
}
