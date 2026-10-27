// Which view a scene opens in (v1.580, docs/proposals/presentation-contract.md
// §4 and §7, the user's "Let's go" to the default rule): the page, a sheet
// over the map, the street before a building, a room's plan, or the place's
// map. The rule reads the data there is; Narrative's `scene` block (its
// `view` and `weight`) tags the scenes the rule gets wrong, and wins.
//
// The rule, the first that fits:
// 1. a scene tagged with a `scene.view` opens in it;
// 2. an ending opens the ending;
// 3. a page turn (`page_turn`, its one Continue to the next page of the
//    same scene, never read through) opens in the view of the page it turns
//    to, so a scene never changes view between its pages;
// 4. a hub or a camp scene opens its place's map;
// 5. a beat of the chapter's spine opens the page;
// 6. a scene inside a building (not at its doorstep) opens the room;
// 7. a scene at a building's doorstep opens the street, unless it goes on
//    with a main scene played at the same stop (every way into it a card, a
//    fight's loss or a check's failure there): then the page;
// 8. any other main-story scene opens the page, a side scene the sheet.
import '../models/story_node.dart';
import 'chapter_spine.dart';
import 'choice_flow.dart';
import 'choice_shape.dart';
import 'geography.dart';
import 'story_repository.dart';

/// The views a scene opens in.
enum SceneView {
  /// The full page: the scene's words, its choices as cards.
  page,

  /// A sheet over the map.
  sheet,

  /// The street before a building: the words in a band, the choices as
  /// pins in the street.
  street,

  /// A building's room: its plan, the choices at their spots.
  room,

  /// The place's map: a town's or the camp's things to do.
  map,

  /// The story's end.
  ending,
}

/// How much a scene weighs in the story.
enum SceneWeight { main, side, ambient }

SceneView? sceneViewNamed(String? name) =>
    SceneView.values.where((v) => v.name == name).firstOrNull;

SceneWeight? sceneWeightNamed(String? name) =>
    SceneWeight.values.where((w) => w.name == name).firstOrNull;

/// The views of the story's scenes, worked out once: who comes into each
/// scene, and from where.
class ScenePresentation {
  ScenePresentation._(this._story, this._geography, this._stops);

  factory ScenePresentation.of({
    required StoryData story,
    required Geography geography,
    required StoryStops stops,
  }) =>
      ScenePresentation._(story, geography, stops).._index();

  final StoryData _story;
  final Geography _geography;
  final StoryStops _stops;

  /// By scene: the scenes whose ways lead into it, and whether each such
  /// way is acted out where the party stands (a card, a fight's loss, a
  /// check's failure: choiceShape's `here`).
  final Map<String, List<({String from, bool card})>> _into = {};
  final Map<String, SceneView> _views = {};

  void _index() {
    for (final node in _story.nodes.values) {
      for (final choice in node.choices) {
        final card =
            choiceShape(node, choice, story: _story, geography: _geography)
                .here;
        void add(String? to, {required bool card}) {
          if (to == null || to.isEmpty) return;
          (_into[to] ??= []).add((from: node.id, card: card));
        }

        add(choice.nextId, card: card);
        add(choice.failNextId, card: true);
        add(choice.loseNextId, card: true);
      }
    }
  }

  /// [nodeId]'s weight: its `scene.weight`, else main for a beat or a
  /// main-story scene, ambient for a hub or a camp scene, side otherwise.
  SceneWeight weightOf(String nodeId) {
    final node = _story.nodeFor(nodeId);
    final tagged = sceneWeightNamed(node?.sceneWeight);
    if (tagged != null) return tagged;
    if (chapterForNode(nodeId) != null) return SceneWeight.main;
    if (_stops.isHub(nodeId) || _stops.isCampScene(nodeId)) {
      return SceneWeight.ambient;
    }
    return _stops.isMainStoryScene(nodeId)
        ? SceneWeight.main
        : SceneWeight.side;
  }

  /// The view [nodeId] opens in (the rule above).
  SceneView viewOf(String nodeId) =>
      _views[nodeId] ??= _viewOf(nodeId, const {});

  SceneView _viewOf(String nodeId, Set<String> turning) {
    final node = _story.nodeFor(nodeId);
    if (node == null) return SceneView.page;
    final tagged = sceneViewNamed(node.sceneView);
    if (tagged != null) return tagged;
    if (isStoryEnding(node)) return SceneView.ending;
    if (node.pageTurn && node.choices.length == 1) {
      final next = node.choices.single.nextId;
      if (!turning.contains(next)) {
        return _viewOf(next, {...turning, nodeId});
      }
    }
    if (_stops.isHub(nodeId) || _stops.isCampScene(nodeId)) {
      return SceneView.map;
    }
    if (chapterForNode(nodeId) != null) return SceneView.page;
    final place = _geography.placeOfNode(node);
    final doorstep = _geography.doorstepOfNode(node) != null;
    if (place != null && place.isBuilding && !doorstep) return SceneView.room;
    final main = weightOf(nodeId) == SceneWeight.main;
    if (doorstep) {
      return main && _continued(nodeId) ? SceneView.page : SceneView.street;
    }
    return main ? SceneView.page : SceneView.sheet;
  }

  /// Whether [nodeId] goes on with a scene at its own stop: something leads
  /// into it, and every way that does is acted out at that stop.
  bool _continued(String nodeId) {
    final into = _into[nodeId] ?? const [];
    if (into.isEmpty) return false;
    final stop = _stops.stopOf(nodeId);
    return into.every((w) => w.card && _stops.stopOf(w.from) == stop);
  }
}
