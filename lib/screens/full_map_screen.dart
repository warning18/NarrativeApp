import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show ChartPalette;
import '../data/story_repository.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/story_providers.dart';
import '../providers/travel_history_provider.dart';
import '../theme/stitched_ink.dart';
import '../widgets/calques_sheet.dart';
import '../widgets/camp_travel.dart' show travelToPlace;
import '../widgets/chart_map_painter.dart' show ChartFog;
import '../widgets/journey_world_map.dart';
import 'travel_map_screen.dart' show closeMapRoute;

/// Each landmark where a shop opens in [story].
Set<String> shopPlacesOf(StoryData story) => {
      for (final node in story.nodes.values)
        if (node.choices.any((c) => (c.unlockShopId ?? '').isNotEmpty))
          if (landmarkOfScene(node.id) case final landmark?) landmark.id,
    };

/// Each landmark's kind of place, from the settlements the story puts
/// there (a town's hub, a camp).
Map<String, String> placeKindsOf(StoryData story) {
  final kinds = <String, String>{};
  for (final node in story.nodes.values) {
    final settlement = node.settlement;
    final landmark = settlement == null ? null : landmarkOfScene(node.id);
    if (landmark != null) kinds[landmark.id] = settlement!.kind;
  }
  return kinds;
}

/// The full-screen map (board 8): the Journey's own chart, whole, on its
/// own page. A tap on a place opens a sheet: where the party stands, or the
/// offer to travel there. [focusId] opens it on that place with its sheet
/// up (the camp's "On the map").
class FullMapScreen extends ConsumerStatefulWidget {
  const FullMapScreen({super.key, this.focusId});

  final String? focusId;

  @override
  ConsumerState<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends ConsumerState<FullMapScreen> {
  StoryData? _inputsOf;
  Set<String> _shops = const {};
  Set<String> _camps = const {};

  @override
  void initState() {
    super.initState();
    final id = widget.focusId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final landmark = landmarkById(id);
        if (mounted && landmark != null) _placeSheet(landmark);
      });
    }
  }

  Future<void> _placeSheet(Landmark landmark) async {
    final language = ref.read(appLanguageProvider);
    final history = ref.read(travelHistoryProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final name = landmark.name(language);
    final nodeId = history.travelTargets[landmark.id];
    final here = history.currentId == landmark.id;
    final busy =
        ref.read(combatActiveProvider) || ref.read(expeditionActiveProvider);
    final go = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          key: const Key('map_place_sheet'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(landmark.blurb(language),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              if (here)
                Text(tr(ref, 'map_here'),
                    key: const Key('map_here'),
                    style:
                        theme.textTheme.labelLarge?.copyWith(color: ink.gold))
              else if (nodeId == null)
                Text(tr(ref, 'map_no_road'),
                    key: const Key('map_no_road'),
                    style:
                        theme.textTheme.labelMedium?.copyWith(color: ink.ash))
              else if (busy)
                Text(tr(ref, 'map_busy'),
                    key: const Key('map_busy'),
                    style:
                        theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('map_cancel'),
                    onPressed: () => Navigator.of(sheet).pop(false),
                    child: Text(tr(ref,
                        here || nodeId == null ? 'close_button' : 'cancel')),
                  ),
                  if (!here && nodeId != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('travel_go'),
                      onPressed:
                          busy ? null : () => Navigator.of(sheet).pop(true),
                      child: Text(tr(ref, 'map_travel_here')),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (go != true || nodeId == null || !mounted) return;
    final place = ref.read(storyDataProvider).value?.nodeFor(nodeId);
    if (place == null) return;
    // The map's own route, kept: a notice may be showing over it by the
    // time the walk is done, so what is closed is this page, not the top.
    final nav = Navigator.of(context);
    final mapRoute = ModalRoute.of(context);
    await travelToPlace(context, ref, place);
    closeMapRoute(nav, mapRoute);
  }

  @override
  Widget build(BuildContext context) {
    final story = ref.watch(storyDataProvider).value;
    final play = ref.watch(storyPlayProvider);
    final look = ref.watch(mapLookProvider);
    final palette = ChartPalette.of(look);
    final editing = ref.watch(appModeProvider) == AppMode.edit;
    if (story != null && !identical(story, _inputsOf)) {
      _inputsOf = story;
      _shops = shopPlacesOf(story);
      _camps = {
        for (final e in placeKindsOf(story).entries)
          if (e.value == 'camp') e.key,
      };
    }
    final standing = play.isInExcursion
        ? currentLandmark(play.currentNodeId, play.history)
        : currentLandmark(play.currentNodeId, play.history) ??
            landmarkOfScene(play.currentNodeId);
    final discovered =
        discoveredLandmarkIds([...play.history, play.currentNodeId]);
    final worldDiscovered = editing
        ? {for (final l in worldMapLandmarks) l.id}
        : {...discovered, if (standing != null) standing.id};
    Landmark? nextPlace;
    if (standing != null) {
      final index = worldMapLandmarks.indexOf(standing);
      for (var i = index + 1; i < worldMapLandmarks.length; i++) {
        if (!worldDiscovered.contains(worldMapLandmarks[i].id)) {
          nextPlace = worldMapLandmarks[i];
          break;
        }
      }
    }
    final focusId = widget.focusId;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'map_full_title'))),
      body: SafeArea(
        child: JourneyWorldMap(
          key: const ValueKey('full_world_map'),
          level: JourneyMapLevel.world,
          palette: palette,
          here: standing,
          discovered: worldDiscovered,
          legs: roadLegs(
              journeyOf(play.history, play.currentNodeId), worldDiscovered),
          ahead: nextPlace,
          shopPlaces: _shops,
          campPlaces: _camps,
          chapterColor: (n) => switch (look) {
            MapLook.night => mapChapter(n).dark,
            MapLook.parchment => mapChapter(n).light,
            MapLook.shroud => const Color(0xFFA3A3AA),
          },
          onLayers: () => showCalquesSheet(context, ref),
          onSelect: _placeSheet,
          focus: focusId == null ? null : landmarkById(focusId),
          fog: editing ? ChartFog.none : ChartFog.uncharted,
        ),
      ),
    );
  }
}
