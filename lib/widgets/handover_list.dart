// The towns that changed hands, as a short list (wave 17, item 3): in the
// layers sheet under the calques, for the player who missed the toast. Each
// row is the town, the old ruler's flag and name, an arrow, the new ruler's.
// Nothing at all when nothing has changed hands since the player last looked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/geography_provider.dart';
import '../theme/stitched_ink.dart';
import 'pixel_banner.dart';
import 'town_handover.dart';

class HandoverList extends ConsumerWidget {
  const HandoverList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes = ref.watch(recentHandoversProvider);
    if (changes.isEmpty) return const SizedBox.shrink();
    final language = ref.watch(appLanguageProvider);
    final factions = ref.watch(factionsProvider);
    final geography = ref.watch(geographyProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    String town(String id) =>
        geography.places[id]?.nameFor(language == AppLanguage.fr) ?? id;
    String clan(String id) => id.isEmpty
        ? trFor(language, 'town_handover_no_one')
        : factions[id]?.shortFor(language) ?? id;
    Widget side(String id) => Row(mainAxisSize: MainAxisSize.min, children: [
          if (id.isNotEmpty) ...[
            ClanFlag(factionId: id, height: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
              child: Text(clan(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium)),
        ]);
    return Padding(
      key: const Key('handover_list'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trFor(language, 'town_handover_title').toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.4, color: ink.gold)),
          const SizedBox(height: 4),
          for (final h in changes)
            Padding(
              key: Key('handover_${h.townId}'),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(town(h.townId), style: theme.textTheme.bodyMedium),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    side(h.fromClan),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child:
                          Icon(Icons.arrow_forward, size: 14, color: ink.ash),
                    ),
                    side(h.toClan),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
