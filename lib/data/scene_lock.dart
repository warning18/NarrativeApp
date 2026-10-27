// The scene lock (v1.553): a scene the story brought the party to, with a
// way acted out there, holds the Journey on its page until a way is taken.
// The page shows every way as a card (the ways somewhere as road cards);
// the map, its tabs and "Back to the map" wait ("Choose first"). Taking a
// road card goes back to the map and walks it; a card acted out here goes
// on to the next scene, which locks in turn if it is lockable.
//
// The decision is state-based: it reads the scene's ways and the play
// state, not how the party got there, so a save picked back up on such a
// scene opens on its page too. Where the story brought the party (a pin, a
// card, a new game's first scene, a save loaded) is the Journey's to say;
// a jump (Edit Mode, a test) never locks.
import '../models/story_node.dart';
import 'quest_hints.dart' show hubChoiceCount;

/// One way out of a scene, as the lock weighs it: whether it is acted out
/// where the party stands ([here], see choice_shape.dart) and whether it
/// can be taken now ([takeable]: not shut by its conditions; a hidden way
/// is left out of the list).
typedef LockWay = ({bool here, bool takeable});

/// Whether a scene with [ways] holds the party on its page: at least one
/// way acted out here can be taken. Never a hub ([hub], see [isHubScene]),
/// an ending ([ending]), a scene with nothing takeable, or in Edit Mode.
bool sceneLocked({
  required List<LockWay> ways,
  required bool hub,
  required bool ending,
  required bool editMode,
}) =>
    !editMode &&
    !hub &&
    !ending &&
    ways.isNotEmpty &&
    ways.any((w) => w.here && w.takeable);

/// Whether [node] is a hub: a town's or the camp's scene (a settlement), or
/// one with more choices than a decision has (the story view's own rule).
/// Its choices are things to do there, in any order: it never locks.
bool isHubScene(StoryNode node) =>
    node.settlement != null || node.choices.length > hubChoiceCount;
