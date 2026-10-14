import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show ChartPalette;
import '../data/heard_of.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart' show zonesSchema;
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart' show localizedDbProvider;
import '../providers/player_session_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/story_providers.dart';
import '../providers/travel_history_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/calques_sheet.dart';
import '../widgets/help_hint.dart' show TourInfoButton;
import '../widgets/camp_travel.dart' show travelToPlace;
import '../widgets/chart_map_painter.dart' show ChartFog;
import '../widgets/journey_world_map.dart';
import '../widgets/map_legend_sheet.dart';
import 'heard_of_travel.dart' show setOutToHeardOf;
import 'journal_screen.dart' show JournalScreen;

/// Closes the full map's [route] wherever it is in the stack (not whatever
/// is on top: a "walked to" notice can be over it). A route that is gone
/// already is left alone.
void closeMapRoute(NavigatorState nav, Route<dynamic>? route) {
  if (route == null || !route.isActive || !nav.mounted) return;
  nav.removeRoute(route);
}

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

enum _MapSheetChoice { travel, setOut, markGoal, clearGoal }

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

  /// The place the chart is turned to and marked: the one asked for, then
  /// the end of a journey picked from the list.
  Landmark? _focus;

  /// One chapter picked out on the chart (0: all), and the replay of the
  /// road walked (a new token starts it).
  int _chapterFilter = 0;
  int _replayToken = 0;
  List<Landmark>? _replayLegs;

  @override
  void initState() {
    super.initState();
    final id = widget.focusId;
    _focus = id == null ? null : landmarkById(id);
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
    // A place only heard of: the sheet offers to set out for it, or to mark
    // it as the goal, by Core's rule (heard_of.dart).
    final heard = history.visited.contains(landmark.id) || here
        ? null
        : ref.read(heardOfPlacesProvider)[landmark.id];
    final isGoal = ref.read(mapGoalProvider) == landmark.id;
    final zoneName = heard?.expeditionId == null
        ? null
        : (ref
                .read(localizedDbProvider(zonesSchema))
                .value?[heard!.expeditionId] as Map?)?['zoneName']
            ?.toString();
    // "First: {zone}": the expedition that opens the way to the one that
    // finds this place (it sets the flag the other waits on).
    String? firstZone;
    if (heard != null && heard.waitsOnFlags.isNotEmpty) {
      final zones =
          ref.read(localizedDbProvider(zonesSchema)).value ?? const {};
      for (final entry in zones.entries) {
        final record = entry.value;
        if (record is Map &&
            heard.waitsOnFlags.contains(record['rewardFlag']?.toString())) {
          firstZone = record['zoneName']?.toString();
          break;
        }
      }
    }
    Text note(String key, {Color? colour, String? text}) => Text(
        text ?? tr(ref, key),
        key: Key(key),
        style: theme.textTheme.labelMedium?.copyWith(color: colour ?? ink.ash));
    final reasonLine = heard == null || heard.setsOut
        ? null
        : switch (heard.reason!) {
            HeardOfReason.storyOnly => 'heard_reason_storyOnly',
            HeardOfReason.noCamp => 'heard_reason_noCamp',
            HeardOfReason.laterChapter => 'heard_reason_laterChapter',
            HeardOfReason.needsHarbour => 'heard_reason_needsHarbour',
            HeardOfReason.needsExpedition => 'heard_reason_needsExpedition',
          };
    final choice = await showModalBottomSheet<_MapSheetChoice>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
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
                note('map_here', colour: ink.gold)
              else if (heard != null) ...[
                if (heard.setsOut) ...[
                  if (heard.byExpedition)
                    note('map_set_out_expedition',
                        colour: ink.gold,
                        text: tr(ref, 'map_set_out_expedition')
                            .replaceAll('{zone}', zoneName ?? '?')),
                  const SizedBox(height: 4),
                  note('heard_setout_warning'),
                  if (busy) ...[
                    const SizedBox(height: 4),
                    note('map_busy'),
                  ],
                ] else
                  note(reasonLine!,
                      text: tr(ref, reasonLine)
                          .replaceAll('{n}', '${heard.chapter ?? ''}')
                          .replaceAll('{zone}', firstZone ?? '?')),
                if (isGoal) ...[
                  const SizedBox(height: 4),
                  note('map_goal_is', colour: ink.gold),
                ],
              ] else if (nodeId == null)
                note('map_no_road')
              else if (busy)
                note('map_busy'),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    key: const Key('map_cancel'),
                    onPressed: () => Navigator.of(sheet).pop(),
                    child: Text(tr(
                        ref,
                        here || (nodeId == null && heard == null)
                            ? 'close_button'
                            : 'cancel')),
                  ),
                  if (heard != null)
                    TextButton(
                      key: const Key('map_goal_button'),
                      onPressed: () => Navigator.of(sheet).pop(isGoal
                          ? _MapSheetChoice.clearGoal
                          : _MapSheetChoice.markGoal),
                      child: Text(
                          tr(ref, isGoal ? 'map_clear_goal' : 'map_mark_goal')),
                    ),
                  if (heard != null && heard.setsOut)
                    FilledButton(
                      key: const Key('map_set_out'),
                      onPressed: busy
                          ? null
                          : () =>
                              Navigator.of(sheet).pop(_MapSheetChoice.setOut),
                      child: Text(tr(ref, 'map_set_out')),
                    ),
                  if (!here && heard == null && nodeId != null)
                    FilledButton(
                      key: const Key('travel_go'),
                      onPressed: busy
                          ? null
                          : () =>
                              Navigator.of(sheet).pop(_MapSheetChoice.travel),
                      child: Text(tr(ref, 'map_travel_here')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _MapSheetChoice.markGoal:
        await ref.read(playerSessionProvider.notifier).setMapGoal(landmark.id);
        return;
      case _MapSheetChoice.clearGoal:
        await ref.read(playerSessionProvider.notifier).setMapGoal(null);
        return;
      case _MapSheetChoice.setOut:
        // The map's own route, kept (see travel below).
        final nav = Navigator.of(context);
        final mapRoute = ModalRoute.of(context);
        await setOutToHeardOf(context, ref, heard!);
        closeMapRoute(nav, mapRoute);
        return;
      case _MapSheetChoice.travel:
        if (nodeId == null) return;
        final place = ref.read(storyDataProvider).value?.nodeFor(nodeId);
        if (place == null) return;
        // The map's own route, kept: a notice may be showing over it by the
        // time the walk is done, so what is closed is this page, not the top.
        final nav = Navigator.of(context);
        final mapRoute = ModalRoute.of(context);
        await travelToPlace(context, ref, place);
        closeMapRoute(nav, mapRoute);
    }
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
    Color chapterColor(int n) => switch (look) {
          MapLook.night => mapChapter(n).dark,
          MapLook.parchment => mapChapter(n).light,
          MapLook.shroud => const Color(0xFFA3A3AA),
        };
    // The chapters reached, for the chips: each picks that chapter's places
    // and roads out, and turns the chart to its first place.
    final reachedLandmarks = [
      for (final l in worldMapLandmarks)
        if (worldDiscovered.contains(l.id)) l,
    ];
    final chaptersReached =
        {for (final l in reachedLandmarks) l.chapter}.toList()..sort();
    return TutorialTrigger(
      topic: TutorialTopic.map,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'map_full_title')),
          actions: const [TourInfoButton(topic: TutorialTopic.map)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TutorialTarget(
                  id: 'map.chart',
                  child: JourneyWorldMap(
                    key: const ValueKey('full_world_map'),
                    level: JourneyMapLevel.world,
                    palette: palette,
                    here: standing,
                    discovered: worldDiscovered,
                    legs: roadLegs(journeyOf(play.history, play.currentNodeId),
                        worldDiscovered),
                    ahead: nextPlace,
                    shopPlaces: _shops,
                    campPlaces: _camps,
                    chapterColor: chapterColor,
                    onLayers: () => showCalquesSheet(context, ref),
                    onSelect: _placeSheet,
                    focus: _focus,
                    heardOf: editing
                        ? const {}
                        : ref.watch(heardOfPlacesProvider).keys.toSet(),
                    goalId: ref.watch(mapGoalProvider),
                    chapterFilter: _chapterFilter,
                    replayLegs: _replayLegs,
                    replayToken: _replayToken,
                    fog: editing ? ChartFog.none : ChartFog.uncharted,
                  ),
                ),
              ),
              if (chaptersReached.length > 1)
                TutorialTarget(
                  id: 'map.chapters',
                  child: _ChapterChips(
                    chapters: chaptersReached,
                    selected: _chapterFilter,
                    colourOf: chapterColor,
                    onPick: (n) => setState(() {
                      _chapterFilter = n;
                      if (n != 0) {
                        _focus =
                            reachedLandmarks.firstWhere((l) => l.chapter == n);
                      }
                    }),
                  ),
                ),
              TutorialTarget(
                id: 'map.controls',
                child: _MapToolbar(
                  onLegend: () => showMapLegendSheet(context, ref,
                      palette: palette, chapterColor: chapterColor),
                  onStory: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JournalScreen()),
                  ),
                  onJourneys: () async {
                    final journey = journeyOf(play.history, play.currentNodeId);
                    final pick = await showMapJourneysSheet(context, ref,
                        journey: journey, chapterColor: chapterColor);
                    if (pick == null || !mounted) return;
                    setState(() {
                      if (pick.replay) {
                        _replayLegs = journey;
                        _replayToken++;
                      } else {
                        _focus = pick.to;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chapters reached as chips, "All" first: one picked out on the chart.
class _ChapterChips extends ConsumerWidget {
  const _ChapterChips({
    required this.chapters,
    required this.selected,
    required this.colourOf,
    required this.onPick,
  });

  final List<int> chapters;
  final int selected;
  final Color Function(int chapter) colourOf;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        key: const Key('map_chapter_chips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            for (final n in [0, ...chapters])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: Key('world_map_chip_$n'),
                  visualDensity: VisualDensity.compact,
                  selected: selected == n,
                  selectedColor:
                      (n == 0 ? ink.gold : colourOf(n)).withValues(alpha: 0.35),
                  side: BorderSide(color: n == 0 ? ink.gold : colourOf(n)),
                  label: Text(n == 0
                      ? tr(ref, 'world_map_all')
                      : '${tr(ref, 'world_map_chapter_short')} $n'),
                  onSelected: (_) => onPick(n),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Under the chart: what its marks mean, the story so far, the roads walked.
class _MapToolbar extends ConsumerWidget {
  const _MapToolbar({
    required this.onLegend,
    required this.onStory,
    required this.onJourneys,
  });

  final VoidCallback onLegend;
  final VoidCallback onStory;
  final VoidCallback onJourneys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget button(String key, IconData icon, String label, VoidCallback on) =>
        Expanded(
          child: InkWell(
            key: Key(key),
            onTap: on,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          button('map_legend', Icons.info_outline, tr(ref, 'map_legend'),
              onLegend),
          button('map_story', Icons.menu_book_outlined, tr(ref, 'map_story'),
              onStory),
          button('map_journeys', Icons.route_outlined, tr(ref, 'map_journeys'),
              onJourneys),
        ],
      ),
    );
  }
}
