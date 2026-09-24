import '../models/story_node.dart';
import 'story_repository.dart';

/// Whether [nodeId] is the place [placeNodeId] itself or one of its own
/// scenes ("2015_kelda" belongs to "2015"), which all lead back to it.
bool isWithinPlace(String nodeId, String placeNodeId) =>
    nodeId == placeNodeId || nodeId.startsWith('${placeNodeId}_');

/// Whether reaching the settlement at [settlementNodeId] from
/// [previousNodeId] is an arrival -- coming from elsewhere in the story --
/// rather than a return from one of its own scenes. Opening the game there
/// (no previous scene) is not: the player was already in the place.
bool isSettlementArrival(String settlementNodeId, String? previousNodeId) =>
    previousNodeId != null && !isWithinPlace(previousNodeId, settlementNodeId);

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

/// Whether a hub's choice keeps the player in the place (its scene leads
/// back to the hub) instead of moving the story on.
bool isLocalChoice(StoryChoice choice, String hubNodeId) =>
    isWithinPlace(choice.nextId, hubNodeId);
