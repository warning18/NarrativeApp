import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show ChartPalette;
import '../data/travel_history.dart' show TravelHistory;
import '../data/world_map.dart';
import '../data/world_roads.dart' show RoadKind;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/story_providers.dart';
import '../providers/travel_history_provider.dart';
import '../widgets/camp_travel.dart' show travelToPlace;
import '../widgets/travel_map_view.dart';

/// The map of where the party has been: the story world's chart with the
/// road taken in order, the places reached by name, the ones only heard of
/// as "?" (see TravelHistory), and a ring round each place the camp can
/// travel to. A tap on a ringed place offers the journey.
class TravelMapScreen extends ConsumerWidget {
  const TravelMapScreen({super.key});

  /// The places reached in the order the party reached them, one entry per
  /// visit (a place gone back to appears again).
  static List<String> visitOrder(TravelHistory history) => history.legs.isEmpty
      ? [for (final stop in history.stops) stop.landmarkId]
      : [history.legs.first.fromId, for (final leg in history.legs) leg.toId];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(travelHistoryProvider);
    final language = ref.watch(appLanguageProvider);
    final palette = ChartPalette.of(ref.watch(mapLookProvider));
    String nameOf(String id) => landmarkById(id)?.name(language) ?? id;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'travel_map_title'))),
      body: SafeArea(
        child: TravelMapView(
          key: const Key('travel_map'),
          geography: ref.watch(storyChartProvider),
          palette: palette,
          language: language,
          visited: visitOrder(history),
          known: history.heardOf,
          legs: [
            for (final leg in history.legs)
              TravelLeg(leg.fromId, leg.toId, sea: leg.kind == RoadKind.sea),
          ],
          travelTargets: history.travelTargets.keys.toSet(),
          here: history.currentId,
          nameOf: nameOf,
          onTapPlace: (id, state) => _tapped(context, ref, history, id, state),
        ),
      ),
    );
  }

  Future<void> _tapped(BuildContext context, WidgetRef ref,
      TravelHistory history, String id, TravelPlaceState state) async {
    final language = ref.read(appLanguageProvider);
    final landmark = landmarkById(id);
    final name = landmark?.name(language) ?? id;
    final nodeId = history.travelTargets[id];
    final theme = Theme.of(context);

    if (nodeId != null) {
      final go = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Padding(
            key: const Key('travel_offer'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(ref, 'travel_to_title').replaceAll('{place}', name),
                    style: theme.textTheme.titleMedium),
                if (landmark != null) ...[
                  const SizedBox(height: 6),
                  Text(landmark.blurb(language),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheet).pop(false),
                      child: Text(tr(ref, 'cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('travel_go'),
                      onPressed: ref.read(combatActiveProvider) ||
                              ref.read(expeditionActiveProvider)
                          ? null
                          : () => Navigator.of(sheet).pop(true),
                      child: Text(tr(ref, 'place_go_button')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (go != true || !context.mounted) return;
      final story = ref.read(storyDataProvider).value;
      final place = story?.nodeFor(nodeId);
      if (place == null) return;
      await travelToPlace(context, ref, place);
      // The journey has begun: back to the Journey, where it is played.
      if (context.mounted) Navigator.of(context).maybePop();
      return;
    }

    // A place that is not a way to travel: what it is, or that it is only
    // a name so far.
    final text = state == TravelPlaceState.known
        ? tr(ref, 'travel_heard_of').replaceAll('{place}', name)
        : landmark?.blurb(language) ?? name;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          key: const Key('travel_place_info'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state == TravelPlaceState.visited)
                Text(name, style: theme.textTheme.titleMedium),
              if (state == TravelPlaceState.visited) const SizedBox(height: 6),
              Text(text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
