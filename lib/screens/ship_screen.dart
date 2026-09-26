import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/camp_presence_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/ship_widgets.dart';
import 'port_screen.dart';

/// The Rusty Eel, when the party is not at the camp: sailed out from it
/// for another port's expeditions, or taken away from it by the story.
/// Her hull, the port she is moored at (its rest, shops and expeditions)
/// and the chart. Her refits are the camp Harbor's (see HarborScreen).
class ShipScreen extends ConsumerWidget {
  const ShipScreen({super.key, this.embedded = false});

  /// True as the in-game Camp tab: the page without its own app bar.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final presence = ref.watch(campPresenceProvider);
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final savedPortId =
        ref.watch(playerSessionProvider.select((s) => s.currentPortId));
    final mooredId =
        ports == null ? null : currentPortIdFor(ports, savedPortId);
    final moored =
        mooredId == null ? null : ports![mooredId] as Map<String, dynamic>?;
    final ashore = moored != null && !portIsHome(moored);
    // Sailed out from the camp, the way home comes first; opened from Edit
    // Mode, it is on the chart with the rest.
    final sailedOut = embedded && presence == CampPresence.sailedOut;
    final homeId = ports == null ? null : homePortId(ports);
    final homePort =
        homeId == null ? null : ports![homeId] as Map<String, dynamic>?;
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    final theme = Theme.of(context);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (embedded)
          const Align(alignment: Alignment.centerRight, child: GoldBadge()),
        if (embedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tr(
                  ref,
                  presence == CampPresence.sailedOut
                      ? 'ship_sailed_out_note'
                      : 'ship_away_note'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        if (sailedOut && homeId != null && homePort != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              key: const Key('ship_sail_home'),
              onPressed: busy
                  ? null
                  : () =>
                      sailTo(context, ref, toPortId: homeId, toPort: homePort),
              icon: const Icon(Icons.local_fire_department_outlined),
              label: Text(tr(ref, 'sail_home_title')),
            ),
          ),
        const ShipStatusCard(),
        if (ashore) ...[
          const SizedBox(height: 16),
          Text(
            tr(ref, 'ship_ashore_section')
                .replaceAll('{port}', portNameFor(moored, fr)),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          PortServices(portId: mooredId!),
        ],
        const Divider(height: 32),
        Text(tr(ref, 'ports_section'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        PortChart(homeOnChart: !embedded),
      ],
    );
    final triggered = TutorialTrigger(topic: TutorialTopic.town, child: body);
    if (embedded) return triggered;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'boat_title')),
        actions: const [GoldBadge()],
      ),
      body: triggered,
    );
  }
}
