import 'dart:math';

import '../models/story_node.dart';
import 'chapter_grid_layout.dart';
import 'chapter_spine.dart';
import 'story_repository.dart';
import 'zone_gating.dart';

// From chapter 3 each chapter is an open loop around the camp: the party
// explores the chapter's lands from the camp (its expeditions, on foot or
// by boat), finds its places (a town, a village, other sites) and travels
// between them; once enough of the chapter is done, its main quest opens
// at the camp, and ends with a piece of the banner and the next chapter's
// camp. Chapters 1 and 2 stay a straight road. The loops are game data
// (chapters.json, see chaptersSchema); these are their pure readers.

/// One open chapter, read from a chapters.json row (already localized).
class ChapterLoop {
  const ChapterLoop({
    required this.id,
    required this.chapter,
    required this.label,
    required this.title,
    required this.campNodeId,
    required this.activityGoal,
    this.mainQuestNeedsPlaceIds = const [],
    this.mainQuestTitle = '',
    this.mainQuestHint = '',
  });

  final String id;

  /// Places and zones of this chapter belong to it.
  final int chapter;
  final String label;
  final String title;

  /// Where the story stands while the chapter is open.
  final String campNodeId;

  /// Activities (expeditions cleared, things done in the chapter's places)
  /// before the main quest opens.
  final int activityGoal;

  /// Places the main quest also needs found first.
  final List<String> mainQuestNeedsPlaceIds;
  final String mainQuestTitle;
  final String mainQuestHint;

  static ChapterLoop? fromJson(String id, Object? raw) {
    if (raw is! Map) return null;
    final camp = raw['campNodeId']?.toString() ?? '';
    if (camp.isEmpty) return null;
    return ChapterLoop(
      id: id,
      chapter: (raw['chapter'] as num?)?.toInt() ?? 3,
      label: raw['label']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      campNodeId: camp,
      activityGoal: max(0, (raw['activityGoal'] as num?)?.toInt() ?? 0),
      mainQuestNeedsPlaceIds: (raw['mainQuestNeedsPlaceIds'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      mainQuestTitle: raw['mainQuestTitle']?.toString() ?? '',
      mainQuestHint: raw['mainQuestHint']?.toString() ?? '',
    );
  }
}

/// Every loop in [chapters] (chapters.json), in chapter order.
List<ChapterLoop> chapterLoopsFrom(Map<String, dynamic> chapters) {
  final loops = [
    for (final entry in chapters.entries)
      if (ChapterLoop.fromJson(entry.key, entry.value) != null)
        ChapterLoop.fromJson(entry.key, entry.value)!,
  ]..sort((a, b) => a.chapter.compareTo(b.chapter));
  return loops;
}

/// The loop whose camp is [campNodeId], if any.
ChapterLoop? loopForCamp(String? campNodeId, List<ChapterLoop> loops) {
  if (campNodeId == null) return null;
  for (final loop in loops) {
    if (loop.campNodeId == campNodeId) return loop;
  }
  return null;
}

/// The camp the story comes back to: the last loop camp it has stood at
/// ([currentNodeId] first, then back through [history]). Null before the
/// first camp.
String? currentCampNodeId({
  required String currentNodeId,
  required List<String> history,
  required List<ChapterLoop> loops,
}) {
  final camps = {for (final loop in loops) loop.campNodeId};
  if (camps.contains(currentNodeId)) return currentNodeId;
  for (var i = history.length - 1; i >= 0; i--) {
    if (camps.contains(history[i])) return history[i];
  }
  return null;
}

/// The open chapter the story is in (see [currentCampNodeId]), if any.
ChapterLoop? currentLoop({
  required String currentNodeId,
  required List<String> history,
  required List<ChapterLoop> loops,
}) =>
    loopForCamp(
        currentCampNodeId(
            currentNodeId: currentNodeId, history: history, loops: loops),
        loops);

/// The chapter a scene belongs to for its fights, its detours and the
/// chart: a place's own chapter, else its spine chapter, else its id's.
int storyChapterOf(String nodeId, [StoryData? story]) {
  final settlementChapter = story?.nodeFor(nodeId)?.settlement?.chapter;
  if (settlementChapter != null) return settlementChapter;
  return chapterForNode(nodeId) ?? max(1, chapterOfNode(nodeId));
}

/// The chapter the party has reached: the open chapter's, or the scene's
/// when that is later (the main quest's road) or there is no loop yet.
int reachedChapter({
  required String currentNodeId,
  required List<String> history,
  required List<ChapterLoop> loops,
  StoryData? story,
}) {
  final loop =
      currentLoop(currentNodeId: currentNodeId, history: history, loops: loops);
  return max(loop?.chapter ?? 0, storyChapterOf(currentNodeId, story));
}

/// Whether [place] is known to the party in [chapter]: one of the places
/// of the chapters reached so far, found if it had to be.
bool placeKnown(StoryNode place, int chapter, Iterable<String> flags) {
  final settlement = place.settlement;
  if (settlement == null || settlement.isCamp) return false;
  final placeChapter = settlement.chapter;
  if (placeChapter == null || placeChapter > chapter) return false;
  return !settlement.mustDiscover || flags.contains(placeFoundFlag(place.id));
}

/// Every place (not a camp) of the open chapters, whether known or not,
/// latest chapter first, then by id.
List<StoryNode> loopPlaces(StoryData story) {
  final places = [
    for (final node in story.nodes.values)
      if (node.settlement != null &&
          !node.settlement!.isCamp &&
          node.settlement!.chapter != null)
        node,
  ]..sort((a, b) {
      final byChapter =
          b.settlement!.chapter!.compareTo(a.settlement!.chapter!);
      return byChapter != 0 ? byChapter : a.id.compareTo(b.id);
    });
  return places;
}

/// The places the party can travel to in [chapter].
List<StoryNode> knownPlaces(
  StoryData story, {
  required int chapter,
  required Iterable<String> flags,
}) {
  final held = flags.toSet();
  return [
    for (final place in loopPlaces(story))
      if (placeKnown(place, chapter, held)) place,
  ];
}

/// The markers of [place]'s own activities: the `hub_<id>_…` flags its
/// choices retire themselves with (see StoryChoice.hideIfFlags).
Set<String> placeActivityMarkers(StoryNode place) => {
      for (final choice in place.choices)
        for (final flag in choice.hideIfFlags)
          if (flag.startsWith('hub_${place.id}_')) flag,
    };

/// How many of [place]'s activities are done, of how many.
({int done, int total}) placeProgress(StoryNode place, Iterable<String> flags) {
  final markers = placeActivityMarkers(place);
  final held = flags.toSet();
  return (
    done: markers.where(held.contains).length,
    total: markers.length,
  );
}

/// How much of [chapter] is done: its expeditions cleared (not its main
/// zone, which is the main quest's) and the activities done in its places.
int chapterActivityCount({
  required StoryData story,
  required int chapter,
  required Iterable<String> flags,
  required Iterable<String> completedZoneIds,
  required Map<String, dynamic> zones,
}) {
  final held = flags.toSet();
  var count = 0;
  for (final place in loopPlaces(story)) {
    if (place.settlement!.chapter != chapter) continue;
    count += held.where((f) => f.startsWith('hub_${place.id}_')).length;
  }
  for (final zoneId in completedZoneIds.toSet()) {
    final zone = zones[zoneId];
    if (zone is! Map<String, dynamic> || zoneIsMain(zone)) continue;
    if (((zone['chapter'] as num?)?.toInt() ?? 1) == chapter) count++;
  }
  return count;
}

/// The places [loop]'s main quest still needs visited: found, then
/// travelled to at least once ([visitedNodeIds]), so the people there have
/// had their say before the main quest sets out.
List<String> missingMainQuestPlaces(
  ChapterLoop loop,
  StoryData story,
  Iterable<String> flags, {
  required Iterable<String> visitedNodeIds,
}) {
  final held = flags.toSet();
  final visited = visitedNodeIds.toSet();
  return [
    for (final id in loop.mainQuestNeedsPlaceIds)
      if (story.nodeFor(id) == null ||
          !placeKnown(story.nodeFor(id)!, loop.chapter, held) ||
          !visited.contains(id))
        id,
  ];
}

/// Whether [loop]'s main quest is open: its activity goal met and its
/// places visited.
bool mainQuestOpen({
  required ChapterLoop loop,
  required StoryData story,
  required int activityCount,
  required Iterable<String> flags,
  required Iterable<String> visitedNodeIds,
}) =>
    activityCount >= loop.activityGoal &&
    missingMainQuestPlaces(loop, story, flags, visitedNodeIds: visitedNodeIds)
        .isEmpty;

/// The places a zone reveals (zones.json `discoversPlaceIds`): the first
/// at the expedition's midpoint, the rest on clearing it.
List<String> zoneDiscoveries(Map<String, dynamic> zone) =>
    (zone['discoversPlaceIds'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList() ??
    const [];

/// What [zone] reveals at its midpoint ([atEnd] false) or on being cleared
/// ([atEnd] true): the first place at the midpoint, every place at the end
/// (so a party that never saw the midpoint still finds them all).
List<String> zoneDiscoveriesAt(Map<String, dynamic> zone,
    {required bool atEnd}) {
  final all = zoneDiscoveries(zone);
  if (atEnd || all.isEmpty) return all;
  return [all.first];
}

/// The scene a trip to [place] arrives at: its arrival scene the first
/// time (never read yet), else the place itself.
String arrivalNodeFor(StoryNode place, Iterable<String> visitedNodeIds) {
  final arrival = place.settlement?.arrivalNodeId;
  if (arrival == null || arrival.isEmpty) return place.id;
  return visitedNodeIds.contains(arrival) ? place.id : arrival;
}
