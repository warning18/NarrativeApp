// How a scene shows its choices (UX's in-place choices, v1.679): on the
// journey map's rings (a hub), acted out on the fight stage facing the one
// the scene faces, or in a panel under the scene. Derived from the story
// and the geography (choice_shape.dart), with no data of its own; the
// sprites are UX's to know ([hasSprite]).
import '../models/story_node.dart';
import 'choice_shape.dart';
import 'geography.dart';
import 'story_repository.dart';

/// How a scene shows its choices.
enum SceneChoiceMode {
  /// More than [panelChoiceLimit] choices acted out where the party stands:
  /// the map's rings, as today.
  hub,

  /// A fight among the choices, and the scene faces someone who has a
  /// standing sprite: the choices on the fight stage, facing them.
  stage,

  /// Everything else: a panel under the scene.
  panel,
}

/// A panel holds this many choices acted out here; one more makes a hub.
const int panelChoiceLimit = 4;

/// How [node] of [story] shows [choices] (its own by default; the caller
/// passes the ones not hidden). [hasSprite]: whether an NPC or enemy id has
/// a standing sprite (UX's, from the fight sprites); none, no stage.
SceneChoiceMode sceneChoiceMode(
  StoryNode node, {
  required StoryData story,
  required Geography geography,
  List<StoryChoice>? choices,
  bool Function(String facingId)? hasSprite,
}) {
  final shown = choices ?? node.choices;
  final shapes = [
    for (final c in shown)
      choiceShape(node, c, story: story, geography: geography),
  ];
  if (shapes.where((s) => s.here).length > panelChoiceLimit) {
    return SceneChoiceMode.hub;
  }
  final fight = shapes.any(
    (s) => s.action == ChoiceAction.fight || s.action == ChoiceAction.evade,
  );
  if (fight &&
      node.facing.isNotEmpty &&
      (hasSprite?.call(node.facing) ?? false)) {
    return SceneChoiceMode.stage;
  }
  return SceneChoiceMode.panel;
}

/// Where a choice's door leads: the [move] it makes and the [place] it
/// takes the party to (null when it stays, or the world doesn't know).
typedef ChoiceDoor = ({ChoiceMove move, GeoPlace? place});

/// [choice]'s door, taken in scene [from] of [story] ([shape]: its
/// [choiceShape], when the caller has it). [doorName] names it.
ChoiceDoor doorOf(
  StoryNode from,
  StoryChoice choice, {
  required StoryData story,
  required Geography geography,
  ChoiceShape? shape,
}) {
  final s =
      shape ?? choiceShape(from, choice, story: story, geography: geography);
  final goes = s.move == ChoiceMove.walk || s.move == ChoiceMove.travel;
  return (move: s.move, place: goes ? s.to : null);
}

/// The name on [door] in French or English; '' when it leads nowhere named.
String doorName(ChoiceDoor door, {bool french = false}) =>
    door.place?.nameFor(french) ?? '';
