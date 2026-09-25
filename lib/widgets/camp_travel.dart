import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'immersive_notice.dart';
import 'ship_widgets.dart';

// The way between the camp and the towns the story reaches: a town on the
// camp's own shore is a walk, one with a landing of its own is a voyage on
// the Rusty Eel. From a town the party can go back to the camp (its
// expeditions, works, Harbor and companions) while the story waits there,
// and sets out for the town again from the camp.

/// How far [settlement] is from the camp, as the player reads it: "a day's
/// walk", or "3 days at sea".
String campRouteLabel(
  WidgetRef ref,
  Settlement settlement,
  Map<String, dynamic> ports,
) {
  final landing = landingPortIdFor(settlement, ports);
  if (landing == null) return tr(ref, 'camp_route_walk');
  return tr(ref, 'camp_route_sail').replaceAll(
      '{n}', '${portVoyageLength(ports[landing] as Map<String, dynamic>)}');
}

/// Goes back to the camp from the town the story stands in: a walk, or a
/// voyage from the town's landing to the cove (its sea events play out,
/// see VoyageScreen). The story waits in the town; the Camp tab opens.
Future<void> returnToCamp(BuildContext context, WidgetRef ref) async {
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final play = ref.read(storyPlayProvider);
  final node = ref.read(storyDataProvider).value?.nodeFor(play.currentNodeId);
  final session = ref.read(playerSessionProvider);
  if (node == null ||
      !canReturnToCampFrom(node,
          inExcursion: play.isInExcursion, flags: session.flags)) {
    return;
  }
  final homeId = homePortId(ports);
  final homePort =
      homeId == null ? null : ports[homeId] as Map<String, dynamic>?;
  if (homeId == null || homePort == null) return;
  // Going back swaps the page this was called from for the camp: nothing
  // past this point reads [ref].
  final notifier = ref.read(playerSessionProvider.notifier);
  final walkedNotice = tr(ref, 'camp_walked_back');
  final landing = landingPortIdFor(node.settlement, ports);
  if (landing != null) {
    // The Eel waits at the town's landing; the way home is a voyage.
    if (currentPortIdFor(ports, session.currentPortId) != landing) {
      await notifier.arriveAtPort(landing);
    }
    if (!context.mounted) return;
    final arrived =
        await sailTo(context, ref, toPortId: homeId, toPort: homePort);
    if (!arrived) return;
  } else {
    await notifier.arriveAtPort(homeId);
    if (context.mounted) {
      showImmersiveNotice(context, icon: Icons.hiking, message: walkedNotice);
    }
  }
  await notifier.beginCampVisit(node.id);
}

/// Takes the party from the camp back to the town where the story waits:
/// a walk, or a voyage to the town's landing. True once it is there; the
/// Story tab opens on the town again.
Future<bool> travelToWaitingTown(BuildContext context, WidgetRef ref) async {
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final session = ref.read(playerSessionProvider);
  final node =
      ref.read(storyDataProvider).value?.nodeFor(session.campVisitFromNodeId);
  final notifier = ref.read(playerSessionProvider.notifier);
  if (node == null) {
    await notifier.endCampVisit();
    return true;
  }
  final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
  final walkedNotice = tr(ref, 'camp_walked_out')
      .replaceAll('{place}', node.settlement?.nameFor(fr) ?? '');
  final landing = landingPortIdFor(node.settlement, ports);
  if (landing != null) {
    final arrived = await sailTo(context, ref,
        toPortId: landing, toPort: ports[landing] as Map<String, dynamic>);
    if (!arrived) return false;
  } else if (context.mounted) {
    showImmersiveNotice(context, icon: Icons.hiking, message: walkedNotice);
  }
  await notifier.endCampVisit();
  return true;
}

/// "Back to the camp", in a town once the camp stands: how far it is, and
/// the way back.
class CampReturnButton extends ConsumerWidget {
  const CampReturnButton({super.key, required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    return FilledButton.tonalIcon(
      key: const Key('town_back_to_camp'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        alignment: Alignment.centerLeft,
      ),
      onPressed: busy ? null : () => returnToCamp(context, ref),
      icon: const Icon(Icons.local_fire_department_outlined, size: 18),
      label: Text(
        '${tr(ref, 'camp_return_button')} · '
        '${campRouteLabel(ref, settlement, ports)}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The Camp tab while the party is away from the camp: where it is, the
/// way back from a town, and the Rusty Eel as she stands.
class CampAwayView extends ConsumerWidget {
  const CampAwayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final play = ref.watch(storyPlayProvider);
    final node =
        ref.watch(storyDataProvider).value?.nodeFor(play.currentNodeId);
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final town =
        canReturnToCampFrom(node, inExcursion: play.isInExcursion, flags: flags)
            ? node!.settlement
            : null;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tr(ref, 'camp_away_title'),
                  style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          town == null
              ? tr(ref, 'camp_away_body')
              : tr(ref, 'camp_away_town_body')
                  .replaceAll('{place}', town.nameFor(fr))
                  .replaceAll('{route}', campRouteLabel(ref, town, ports)),
          style: theme.textTheme.bodyMedium,
        ),
        if (town != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('camp_return'),
            onPressed: ref.watch(combatActiveProvider) ||
                    ref.watch(expeditionActiveProvider)
                ? null
                : () => returnToCamp(context, ref),
            icon: const Icon(Icons.local_fire_department_outlined),
            label: Text(tr(ref, 'camp_return_button')),
          ),
        ],
        const SizedBox(height: 16),
        const ShipStatusCard(),
      ],
    );
  }
}
