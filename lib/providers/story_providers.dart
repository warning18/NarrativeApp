import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/story_repository.dart';
import '../models/story_node.dart';

const String _autosaveNodePrefsKey = 'autosave_story_node';
const String _autosaveHistoryPrefsKey = 'autosave_story_history';
const String _autosaveVisitedPrefsKey = 'autosave_story_visited';

/// Scenes a story update took out, and where a save standing on one picks
/// up instead: the Court's old road (5001, 5002) became the fourth
/// chapter's camp and its main quest.
const Map<String, String> retiredNodeIds = {
  '5001': '4999_camp',
  '5002': '4999_camp',
};

/// [nodeId], or the scene that replaced it (see [retiredNodeIds]).
String liveNodeId(String nodeId) => retiredNodeIds[nodeId] ?? nodeId;

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final storyDataProvider = FutureProvider<StoryData>((ref) {
  return ref.watch(storyRepositoryProvider).load();
});

/// Persists [updated] as the new version of its node (identified by
/// [StoryNode.id]) and reloads [storyDataProvider] so every screen picks up
/// the change immediately.
Future<void> saveStoryNode(WidgetRef ref, StoryNode updated) async {
  final story = await ref.read(storyDataProvider.future);
  final rawNodes = <String, dynamic>{
    for (final entry in story.nodes.entries)
      entry.key: (entry.key == updated.id ? updated : entry.value).toJson(),
  };
  await ref.read(storyRepositoryProvider).saveNodes(rawNodes);
  ref.invalidate(storyDataProvider);
}

/// Discards all story edits and reverts to the bundled narrative data.
Future<void> resetStoryToDefaults(WidgetRef ref) async {
  await ref.read(storyRepositoryProvider).resetToDefaults();
  ref.invalidate(storyDataProvider);
}

class StoryPlayState {
  const StoryPlayState({
    required this.currentNodeId,
    required this.history,
    required this.visitedNodeIds,
    this.activeExcursionNode,
    this.excursionQueue = const [],
    this.resumeNodeId,
    this.excursionOrigin,
    this.excursionOriginFr,
  });

  final String currentNodeId;
  final List<String> history;

  /// Every real story-graph node id the player has ever actually landed on
  /// this playthrough -- grows monotonically (a [goBack] never un-visits a
  /// node, it just moves [currentNodeId] back to one already in this set).
  /// Drives the story map's fog-of-war: a node not in here is shown as an
  /// unrevealed shadow rather than its real content. Never includes
  /// procedurally generated excursion nodes, which aren't part of the real
  /// graph the map draws.
  final Set<String> visitedNodeIds;

  /// The procedurally generated node currently being shown, if the player
  /// is mid-excursion (a detour inserted between two main story beats).
  final StoryNode? activeExcursionNode;

  /// Remaining generated nodes to show after [activeExcursionNode].
  final List<StoryNode> excursionQueue;

  /// The real story node to resume once the excursion queue is exhausted.
  final String? resumeNodeId;

  /// The choice the player made that the excursion interrupts ("Take the
  /// Stone Bridge"): the detour's context card says it happens on the way
  /// there, and that the story picks up there afterwards.
  final String? excursionOrigin;
  final String? excursionOriginFr;

  /// [excursionOrigin] in the reader's language, or null.
  String? excursionOriginFor(bool fr) {
    final text = fr && (excursionOriginFr?.isNotEmpty ?? false)
        ? excursionOriginFr
        : excursionOrigin;
    return (text?.isEmpty ?? true) ? null : text;
  }

  bool get isInExcursion => activeExcursionNode != null;
}

class StoryPlayNotifier extends StateNotifier<StoryPlayState> {
  StoryPlayNotifier(String startId)
      : super(StoryPlayState(
          currentNodeId: startId,
          history: const [],
          visitedNodeIds: {startId},
        )) {
    _loadAutosave();
  }

  /// On construction the state above is a placeholder (always the story's
  /// very first node) so the widget tree has something to render
  /// immediately; if an autosaved position exists, this quietly replaces it
  /// a moment later — the same fire-and-forget-then-overwrite pattern
  /// PlayerSessionNotifier uses for its own async load. Without this, every
  /// app relaunch would silently reset the visible story position back to
  /// the very start even though the player's stats/inventory (which persist
  /// continuously via PlayerSessionNotifier) still reflect real progress.
  Future<void> _loadAutosave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNodeId = prefs.getString(_autosaveNodePrefsKey);
    if (savedNodeId == null) return;
    final nodeId = liveNodeId(savedNodeId);
    final historyJson = prefs.getString(_autosaveHistoryPrefsKey);
    final history = historyJson != null
        ? (json.decode(historyJson) as List).map((e) => e.toString()).toList()
        : const <String>[];
    final visitedJson = prefs.getString(_autosaveVisitedPrefsKey);
    // A save from before fog-of-war tracking existed has no visited-set key
    // yet -- backfill from history + the current node rather than shadowing
    // every node a returning player has already actually read.
    final visitedNodeIds = visitedJson != null
        ? (json.decode(visitedJson) as List).map((e) => e.toString()).toSet()
        : {...history, nodeId};
    state = StoryPlayState(
      currentNodeId: nodeId,
      history: history,
      visitedNodeIds: visitedNodeIds,
    );
    restoredFromAutosave = history.isNotEmpty;
  }

  /// Whether this launch picked a story back up from the autosave (with at
  /// least one scene behind it) -- the story view then offers a
  /// "Previously..." recap once.
  bool restoredFromAutosave = false;

  Future<void> _persistAutosave() async {
    // Snapshot everything from `state` before the first await -- this runs
    // fire-and-forget from choose()/goBack()/etc, so by the time an awaited
    // SharedPreferences call resumes, the notifier (and its `state` getter)
    // may already have been disposed (e.g. the widget tree torn down right
    // after a choice). Reading `state` only synchronously, up front, avoids
    // that "Tried to use StoryPlayNotifier after dispose" race entirely.
    final nodeId = state.currentNodeId;
    final history = state.history;
    final visitedNodeIds = state.visitedNodeIds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autosaveNodePrefsKey, nodeId);
    await prefs.setString(_autosaveHistoryPrefsKey, json.encode(history));
    await prefs.setString(
        _autosaveVisitedPrefsKey, json.encode(visitedNodeIds.toList()));
  }

  void choose(String nextId) {
    state = StoryPlayState(
      currentNodeId: nextId,
      history: [...state.history, state.currentNodeId],
      visitedNodeIds: {...state.visitedNodeIds, nextId},
    );
    _persistAutosave();
  }

  void jumpTo(String nodeId) => choose(nodeId);

  /// Puts the play state back exactly as [snapshot] had it, fog of war
  /// included -- used to undo a failed autoplay attempt so the next one
  /// starts from the same place.
  void restore(StoryPlayState snapshot) {
    state = StoryPlayState(
      currentNodeId: snapshot.currentNodeId,
      history: snapshot.history,
      visitedNodeIds: snapshot.visitedNodeIds,
    );
    _detourOwed = false;
    _persistAutosave();
  }

  void goBack() {
    if (state.history.isEmpty) return;
    final newHistory = List<String>.from(state.history);
    final previousId = newHistory.removeLast();
    state = StoryPlayState(
      currentNodeId: previousId,
      history: newHistory,
      visitedNodeIds: state.visitedNodeIds,
    );
    _persistAutosave();
  }

  /// Resets to the very start — also overwrites the autosave, since a
  /// restart (only reachable via the Edit Mode "Reset" action) is a
  /// deliberate "begin again," and the next relaunch should honor that
  /// rather than silently reviving the position it just left. The map's
  /// fog of war resets with it: a fresh run starts fully unrevealed again.
  void restart(String startId) {
    state = StoryPlayState(
      currentNodeId: startId,
      history: const [],
      visitedNodeIds: {startId},
    );
    _persistAutosave();
  }

  /// Restores play position to [nodeId] with the given [history] — used to
  /// restore a manually saved checkpoint. Drops any in-progress excursion,
  /// since excursions are procedurally generated side content not meant to
  /// survive a save/load round trip. The fog-of-war set only ever grows, so
  /// loading an earlier checkpoint doesn't re-shadow map ground already
  /// revealed past that point.
  void loadState(String savedNodeId, List<String> history) {
    final nodeId = liveNodeId(savedNodeId);
    state = StoryPlayState(
      currentNodeId: nodeId,
      history: history,
      visitedNodeIds: {...state.visitedNodeIds, ...history, nodeId},
    );
    _persistAutosave();
  }

  /// A detour rolled while a crisis ran from one scene into the next, put
  /// off until the story reaches a transition at rest (see
  /// SubNodeEngine.detourAllowedBetween). Session-only: a relaunch simply
  /// forgets it.
  bool _detourOwed = false;

  bool get detourOwed => _detourOwed;

  /// Marks a detour as owed for the next transition at rest.
  void oweDetour() => _detourOwed = true;

  /// Whether a detour is owed, clearing it: the caller takes it now.
  bool takeOwedDetour() {
    final owed = _detourOwed;
    _detourOwed = false;
    return owed;
  }

  /// Inserts a procedurally generated chain of nodes before the player
  /// reaches [resumeNodeId], the real node they were about to move to.
  /// [origin]/[originFr] are the label of the choice that set off, shown
  /// on each of the chain's nodes so the detour reads as something met on
  /// the way rather than a scene out of nowhere.
  void startExcursion(
    List<StoryNode> chain,
    String resumeNodeId, {
    String? origin,
    String? originFr,
  }) {
    if (chain.isEmpty) return;
    state = StoryPlayState(
      currentNodeId: state.currentNodeId,
      history: state.history,
      visitedNodeIds: state.visitedNodeIds,
      activeExcursionNode: chain.first,
      excursionQueue: chain.skip(1).toList(),
      resumeNodeId: resumeNodeId,
      excursionOrigin: origin,
      excursionOriginFr: originFr,
    );
  }

  /// Advances past the current excursion node, either to the next generated
  /// node in the queue or, once it's empty, back to the real story.
  /// Leaves the detour at once, back to the scene it set out from -- the
  /// party slipped away from it.
  void leaveExcursion() {
    final resume = state.resumeNodeId;
    if (resume != null) choose(resume);
  }

  void advanceExcursion() {
    if (state.excursionQueue.isEmpty) {
      final resume = state.resumeNodeId;
      if (resume != null) choose(resume);
      return;
    }
    state = StoryPlayState(
      currentNodeId: state.currentNodeId,
      history: state.history,
      visitedNodeIds: state.visitedNodeIds,
      activeExcursionNode: state.excursionQueue.first,
      excursionQueue: state.excursionQueue.skip(1).toList(),
      resumeNodeId: state.resumeNodeId,
      excursionOrigin: state.excursionOrigin,
      excursionOriginFr: state.excursionOriginFr,
    );
  }
}

final storyPlayProvider =
    StateNotifierProvider<StoryPlayNotifier, StoryPlayState>((ref) {
  return StoryPlayNotifier(StoryRepository.startNodeId);
});
