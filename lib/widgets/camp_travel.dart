import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/chapter_loop.dart';
import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../screens/story_player_screen.dart'
    show rollRoadEncounter, takeStoryChoice;
import 'immersive_notice.dart';
import 'ship_widgets.dart';

// The way between the camp and the places of the open chapters (see
// chapter_loop.dart). The camp is the party's base: the story stands there
// between trips. A place on the same shore as the Rusty Eel is a walk, with
// whatever the road holds (a detour, a raid); one with a landing of its own
// is a voyage, with its sea events and raiders. The same roads lead from
// one place to another, and back to the camp.

/// The port a trip to [settlement] ends at: its landing, or null for the
/// camp's own shore.
String? destinationPortIdFor(
        Settlement? settlement, Map<String, dynamic> ports) =>
    landingPortIdFor(settlement, ports);

/// Whether a trip to [destinationPortId] (null: the camp's shore) is a
/// walk from where the Eel is moored now.
bool isWalkFrom(
  String? destinationPortId, {
  required Map<String, dynamic> ports,
  required String savedPortId,
}) {
  final here = currentPortIdFor(ports, savedPortId);
  final there = destinationPortId ?? homePortId(ports);
  return there == null || here == there;
}

/// How far [destinationPortId] (null: the camp's shore) is from where the
/// Eel is moored, as the player reads it: "a day's walk", or "3 days at
/// sea".
String routeLabelTo(
  WidgetRef ref,
  String? destinationPortId, {
  required Map<String, dynamic> ports,
  required String savedPortId,
}) {
  if (isWalkFrom(destinationPortId, ports: ports, savedPortId: savedPortId)) {
    return tr(ref, 'camp_route_walk');
  }
  final here = currentPortIdFor(ports, savedPortId);
  final there = destinationPortId ?? homePortId(ports);
  // Home is as far as the port the Eel leaves (see VoyageScreen).
  final measured = there == homePortId(ports) ? here : there;
  final port = measured == null ? null : ports[measured];
  final days = port is Map<String, dynamic> ? portVoyageLength(port) : 1;
  return tr(ref, 'camp_route_sail').replaceAll('{n}', '$days');
}

/// How far [settlement] is from the camp, as the player reads it.
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

/// Moves the party to [destinationPortId] (null: the camp's shore): a
/// voyage when the Eel must sail, a walk otherwise. True once it is there.
/// A walk says so with [walkNotice]; a voyage plays out on its own screen.
Future<bool> moveParty(
  BuildContext context,
  WidgetRef ref, {
  required String? destinationPortId,
  String? walkNotice,
}) async {
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final session = ref.read(playerSessionProvider);
  final there = destinationPortId ?? homePortId(ports);
  if (there == null) return true;
  if (isWalkFrom(destinationPortId,
      ports: ports, savedPortId: session.currentPortId)) {
    if (walkNotice != null && context.mounted) {
      showImmersiveNotice(context, icon: Icons.hiking, message: walkNotice);
    }
    return true;
  }
  if (!context.mounted) return false;
  return sailTo(context, ref,
      toPortId: there, toPort: ports[there] as Map<String, dynamic>);
}

/// Travels to [targetNodeId] ([destinationPortId] its port, null for the
/// camp's shore): the voyage or the walk, then the story moves there. A
/// walk may meet something on the road first (a detour or a raid, see
/// [rollRoadEncounter]), which the story plays before arriving. [origin] is
/// the road's name on a detour's card.
Future<void> travelTo(
  BuildContext context,
  WidgetRef ref, {
  required String targetNodeId,
  required String? destinationPortId,
  required String walkNotice,
  required String origin,
}) async {
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final walk = isWalkFrom(destinationPortId,
      ports: ports, savedPortId: ref.read(playerSessionProvider).currentPortId);
  final play = ref.read(storyPlayProvider.notifier);
  if (walk) {
    final chain = await rollRoadEncounter(ref,
        chapter: ref.read(reachedChapterProvider),
        fromNodeId: ref.read(storyPlayProvider).currentNodeId);
    if (!context.mounted) return;
    if (chain != null && chain.isNotEmpty) {
      play.startExcursion(chain, targetNodeId, origin: origin);
      return;
    }
    showImmersiveNotice(context, icon: Icons.hiking, message: walkNotice);
    play.choose(targetNodeId);
    return;
  }
  final arrived =
      await moveParty(context, ref, destinationPortId: destinationPortId);
  if (!arrived) return;
  play.choose(targetNodeId);
}

/// Travels to [place]: its arrival scene the first time, the place itself
/// after.
Future<void> travelToPlace(
    BuildContext context, WidgetRef ref, StoryNode place) async {
  final settlement = place.settlement;
  if (settlement == null) return;
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
  final name = settlement.nameFor(fr);
  await travelTo(
    context,
    ref,
    targetNodeId:
        arrivalNodeFor(place, ref.read(storyPlayProvider).visitedNodeIds),
    destinationPortId: destinationPortIdFor(settlement, ports),
    walkNotice: tr(ref, 'travel_walked_to').replaceAll('{place}', name),
    origin: tr(ref, 'travel_road_to').replaceAll('{place}', name),
  );
}

/// Goes back to the camp from wherever the party is: a walk, or a voyage
/// home. The story stands at the camp again.
Future<void> returnToCamp(BuildContext context, WidgetRef ref) async {
  final campId = ref.read(currentCampNodeIdProvider);
  if (campId == null) return;
  await travelTo(
    context,
    ref,
    targetNodeId: campId,
    destinationPortId: null,
    walkNotice: tr(ref, 'camp_walked_back'),
    origin: tr(ref, 'travel_road_to_camp'),
  );
}

/// Sets out from the camp on its chapter's main quest ([choice]): the trip
/// to where it starts first (its `travelPlaceId`), then the choice itself,
/// as the story would take it (its expedition, its fight, its scene).
Future<void> setOutOnMainQuest(
    BuildContext context, WidgetRef ref, StoryChoice choice) async {
  if (choice.travels) {
    final story = ref.read(storyDataProvider).value;
    final place = story?.nodeFor(choice.travelPlaceId!);
    final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
    final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
    final arrived = await moveParty(
      context,
      ref,
      destinationPortId: destinationPortIdFor(place?.settlement, ports),
      walkNotice: place?.settlement == null
          ? null
          : tr(ref, 'travel_walked_to')
              .replaceAll('{place}', place!.settlement!.nameFor(fr)),
    );
    if (!arrived || !context.mounted) return;
  }
  await takeStoryChoice(context, ref, choice);
}

/// "Back to the camp", in a place once the camp stands: how far it is, and
/// the way back.
class CampReturnButton extends ConsumerWidget {
  const CampReturnButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final savedPortId =
        ref.watch(playerSessionProvider.select((s) => s.currentPortId));
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
        '${routeLabelTo(ref, null, ports: ports, savedPortId: savedPortId)}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The places the party can travel on to from [fromNodeId] (every known
/// place but that one), each with how far it is and its "Go".
class TravelOnList extends ConsumerWidget {
  const TravelOnList({super.key, required this.fromNodeId});

  final String fromNodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref
        .watch(knownPlacesProvider)
        .where((p) => p.id != fromNodeId)
        .toList();
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final place in places) PlaceCard(place: place)],
    );
  }
}

/// A place the party knows: its kind, its name, one line about it, how
/// much of it is done, how far it is from where the Eel is, and "Go".
class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place});

  final StoryNode place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final settlement = place.settlement!;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final session = ref.watch(playerSessionProvider);
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    final progress = placeProgress(place, session.flags);
    final route = routeLabelTo(ref, destinationPortIdFor(settlement, ports),
        ports: ports, savedPortId: session.currentPortId);
    final theme = Theme.of(context);
    final blurb = settlement.blurbFor(fr);
    return Card(
      child: ListTile(
        key: Key('place_${place.id}'),
        leading: Icon(placeIconFor(settlement)),
        title: Text(settlement.nameFor(fr)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blurb != null) Text(blurb, maxLines: 2),
            Text(
              [
                tr(ref, 'place_kind_${settlement.kind}'),
                route,
                if (progress.total > 0)
                  tr(ref, 'place_progress')
                      .replaceAll('{done}', '${progress.done}')
                      .replaceAll('{total}', '${progress.total}'),
              ].join(' · '),
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        isThreeLine: blurb != null,
        trailing: FilledButton.tonal(
          key: Key('go_${place.id}'),
          onPressed: busy ? null : () => travelToPlace(context, ref, place),
          child: Text(tr(ref, 'place_go_button')),
        ),
      ),
    );
  }
}

IconData placeIconFor(Settlement settlement) {
  switch (settlement.kind) {
    case 'camp':
      return Icons.local_fire_department_outlined;
    case 'village':
      return Icons.cottage_outlined;
    case 'site':
      return Icons.place_outlined;
    default:
      return Icons.location_city_outlined;
  }
}

/// The Camp tab while the party is away from the camp: where it is, the
/// way back from a place, and the Rusty Eel as she stands.
class CampAwayView extends ConsumerWidget {
  const CampAwayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final play = ref.watch(storyPlayProvider);
    final node =
        ref.watch(storyDataProvider).value?.nodeFor(play.currentNodeId);
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final savedPortId =
        ref.watch(playerSessionProvider.select((s) => s.currentPortId));
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final place =
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
          place == null
              ? tr(ref, 'camp_away_body')
              : tr(ref, 'camp_away_town_body')
                  .replaceAll('{place}', place.nameFor(fr))
                  .replaceAll(
                      '{route}',
                      routeLabelTo(ref, null,
                          ports: ports, savedPortId: savedPortId)),
          style: theme.textTheme.bodyMedium,
        ),
        if (place != null) ...[
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
