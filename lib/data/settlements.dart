import '../models/story_node.dart';
import 'story_repository.dart';

/// Set when the camp is founded (3001_camp): from then on the camp is the
/// party's base, and towns are places visited away from it.
const String campFoundedFlag = 'camp_founded';

/// Whether [nodeId] is the place [placeNodeId] itself or one of its own
/// scenes ("2015_kelda" belongs to "2015"), which all lead back to it.
bool isWithinPlace(String nodeId, String placeNodeId) =>
    nodeId == placeNodeId || nodeId.startsWith('${placeNodeId}_');

/// Whether reaching the settlement at [settlementNodeId] from
/// [previousNodeId] is an arrival -- coming from elsewhere in the story --
/// rather than a return from one of its own scenes. Opening the game there
/// (no previous scene) is not: the player was already in the place. Given
/// the scenes read so far ([history]), a first visit is an arrival even
/// through one of the place's own scenes (the Reliquary Quarter's gate).
bool isSettlementArrival(String settlementNodeId, String? previousNodeId,
        {List<String>? history}) =>
    previousNodeId != null &&
    (!isWithinPlace(previousNodeId, settlementNodeId) ||
        (history != null && !history.contains(settlementNodeId)));

/// The town or camp node the player stands in at [currentNodeId]: the node
/// itself when it is one, or the settlement one of whose scenes it is.
StoryNode? settlementNodeAt(String currentNodeId, StoryData story) {
  final parts = currentNodeId.split('_');
  for (var i = parts.length; i >= 1; i--) {
    final node = story.nodeFor(parts.sublist(0, i).join('_'));
    if (node?.settlement != null) return node;
  }
  return null;
}

/// Whether a hub's choice keeps the player in the place -- its scene leads
/// back to the hub -- instead of moving the story on. Read off the story
/// graph when [story] is given (a scene named after the hub can still be
/// its way out, like the Reliquary Quarter's thread); by the scene's name
/// otherwise.
bool isLocalChoice(StoryChoice choice, String hubNodeId, [StoryData? story]) {
  if (story == null) return isWithinPlace(choice.nextId, hubNodeId);
  return leadsBackTo(choice.nextId, hubNodeId, story);
}

/// Whether the story from [startId] comes back to [hubNodeId] within
/// [depth] scenes, following every way on (success, failure and defeat
/// branches alike).
bool leadsBackTo(String startId, String hubNodeId, StoryData story,
    {int depth = 6}) {
  if (startId == hubNodeId) return true;
  final seen = <String>{startId};
  var frontier = [startId];
  for (var step = 0; step < depth && frontier.isNotEmpty; step++) {
    final next = <String>[];
    for (final id in frontier) {
      for (final choice
          in story.nodeFor(id)?.choices ?? const <StoryChoice>[]) {
        for (final target in [
          choice.nextId,
          if (choice.failNextId != null) choice.failNextId!,
          if (choice.loseNextId != null) choice.loseNextId!,
        ]) {
          if (target == hubNodeId) return true;
          if (seen.add(target)) next.add(target);
        }
      }
    }
    frontier = next;
  }
  return false;
}
