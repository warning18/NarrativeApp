// Scene or map (docs/proposals/scene-vs-map-flow.md, with the user's
// answers): what the Journey shows after a choice. The map is for moving.
// While the next scene happens at the same stop, the scene view stays; a
// plain way to another stop hands the party the map, the destination
// pinned; a choice acted out here (a fight, a roll, a payment, a decision)
// whose aftermath is elsewhere carries the party there (a trip, no input);
// and an errand's way back to its town hub is a one-tap return.
//
// A scene's stop is its building, else its district, else its location
// (a site, a sea, a location with no districts). Derived from the story,
// the geography and the city plans, with no data of its own; pure, built
// once per story (see storyStopsProvider).
import '../models/story_node.dart';
import 'choice_shape.dart';
import 'city_plan_record.dart';
import 'geography.dart';
import 'port_helpers.dart';
import 'story_repository.dart';

/// What the Journey does after a choice is taken.
sealed class ChoiceFlow {
  const ChoiceFlow();
}

/// The next scene is at the same stop (or one end is nowhere: the
/// prologue, an ending): the scene view stays, the next scene in place.
final class FlowStay extends ChoiceFlow {
  const FlowStay();

  @override
  bool operator ==(Object other) => other is FlowStay;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'FlowStay()';
}

/// A plain way to another stop: the map, with [stop] (a building, district
/// or location id) pinned. Going there opens the arrival.
final class FlowMap extends ChoiceFlow {
  const FlowMap(this.stop);

  final String stop;

  @override
  bool operator ==(Object other) => other is FlowMap && other.stop == stop;

  @override
  int get hashCode => Object.hash('map', stop);

  @override
  String toString() => 'FlowMap($stop)';
}

/// Done here, its aftermath elsewhere (a fight, a roll, a payment, a
/// decision; a lost fight or a failed roll that moves the party): the party
/// is carried to [stop] (a trip on the map, no input), then the arrival.
final class FlowTripThenArrive extends ChoiceFlow {
  const FlowTripThenArrive(this.stop);

  final String stop;

  @override
  bool operator ==(Object other) =>
      other is FlowTripThenArrive && other.stop == stop;

  @override
  int get hashCode => Object.hash('trip', stop);

  @override
  String toString() => 'FlowTripThenArrive($stop)';
}

/// An errand's way back to the town hub it came from ([hubNodeId], at
/// [hubStop]): one tap, no map to pick on; the Journey lands at the hub and
/// says "You came back to ..." (see lastReturnProvider).
final class FlowReturnToHub extends ChoiceFlow {
  const FlowReturnToHub(this.hubStop, this.hubNodeId);

  final String hubStop;
  final String hubNodeId;

  @override
  bool operator ==(Object other) =>
      other is FlowReturnToHub &&
      other.hubStop == hubStop &&
      other.hubNodeId == hubNodeId;

  @override
  int get hashCode => Object.hash('return', hubStop, hubNodeId);

  @override
  String toString() => 'FlowReturnToHub($hubStop, $hubNodeId)';
}

/// What a place offers, for its service pins.
enum PlaceServiceKind {
  /// A shop: a choice that opens it, or one a port lists.
  shop,

  /// A rest: an inn or a healer (a choice that heals).
  rest,

  /// The trainer.
  trainer,

  /// A port, or the landing a settlement sails from.
  port,
}

/// One service: its [kind], its [id] (the shop or port id; the scene id for
/// a rest or the trainer), the scene that offers it ([nodeId]) and the
/// choice there that reaches it ([choiceIndex], null when the scene itself
/// is the service: a port's settlement, the trainer).
typedef PlaceService = ({
  PlaceServiceKind kind,
  String id,
  String nodeId,
  int? choiceIndex,
});

/// The scenes the trainer stands at (only chapter 1's today).
const Set<String> _trainerSceneIds = {'890_trainer'};

/// The story's stops, hubs and errands, worked out once: the queries of
/// the scene-or-map rule.
class StoryStops {
  StoryStops._(this._story, this._geography, this._plans, this._ports);

  /// The stops of [story] in [geography]: [cityPlans] give a village hub
  /// its district (the lot its scene stands on), [ports] (ports.json rows,
  /// by id) the shops a port lists.
  factory StoryStops.of({
    required StoryData story,
    required Geography geography,
    Map<String, CityPlanRecord> cityPlans = const {},
    Map<String, dynamic> ports = const {},
  }) =>
      StoryStops._(story, geography, cityPlans, ports).._index();

  final StoryData _story;
  final Geography _geography;
  final Map<String, CityPlanRecord> _plans;
  final Map<String, dynamic> _ports;

  final Set<String> _hubs = {};
  final Map<String, Set<String>> _errandOf = {};
  final Map<String, String> _wholeStop = {};
  final Map<String, String> _stops = {};
  List<PlaceService>? _services;

  // --- Stops -----------------------------------------------------------

  /// The stop of scene [nodeId]: its building, else its district, else its
  /// location; '' for a scene that happens nowhere (the prologue, a scene
  /// the world doesn't place).
  ///
  /// Two rules on top of the place the story gives:
  /// * the prologue (a scene whose every way opens the making of the
  ///   character, node `0`) is nowhere, whatever its `location` says;
  /// * a scene tagged with a whole village (or town or site) that has
  ///   districts and a hub, not a camp, takes the hub's district: the
  ///   district of the lot the hub's scene stands on in the city plan (so
  ///   White Wells' scenes are all at the Pool, Rimewell's at the Bell
  ///   Square). With no plan, the location itself.
  String stopOf(String nodeId) =>
      _stops[nodeId] ??= _stopOf(_story.nodeFor(nodeId));

  String _stopOf(StoryNode? node) {
    if (node == null || isPrologue(node)) return '';
    final place = _geography.placeOfNode(node);
    if (place == null) return '';
    if (place.level == GeoLevel.location) {
      return _wholeStop[place.id] ?? place.id;
    }
    return place.id;
  }

  /// Whether [node] is the prologue: it has ways, and each opens the
  /// making of the character. It happens nowhere.
  static bool isPrologue(StoryNode node) =>
      node.choices.isNotEmpty &&
      node.choices.every((c) => c.opensCharacterCreation);

  /// Whether scenes [fromId] and [toId] are at different stops (one end
  /// nowhere counts as no change): the read-through stops there.
  bool changesStop(String fromId, String toId) {
    if (fromId == toId) return false;
    final a = stopOf(fromId), b = stopOf(toId);
    if (a.isEmpty || b.isEmpty) {
      // Neither known: a change of location, else of landmark, decides.
      return _geography.travelsBetween(_story, fromId, toId);
    }
    return a != b;
  }

  // --- Hubs ------------------------------------------------------------

  /// Whether [nodeId] is a hub: a town, village, site or camp (a
  /// `settlement`), a scene with `hub_progress`, or a scene with a way back
  /// to itself (the Blind Beggar's tables, the High Quay).
  bool isHub(String nodeId) => _hubs.contains(nodeId);

  /// The hubs [nodeId] is an errand of: reached from the hub without
  /// passing another, and leading back to it.
  Set<String> hubsOfErrand(String nodeId) => _errandOf[nodeId] ?? const {};

  /// Whether [nodeId] happens at a camp.
  bool isCampScene(String nodeId) {
    final node = _story.nodeFor(nodeId);
    if (node == null) return false;
    if (node.settlement?.isCamp ?? false) return true;
    return _geography.locationOfNode(node)?.kind == 'camp';
  }

  /// Whether [nodeId] is a main-story scene, played in the full scene view
  /// (S1): not a hub, not an errand of one, not a camp scene. The others
  /// open as a sheet over the map (S2).
  bool isMainStoryScene(String nodeId) =>
      _story.nodeFor(nodeId) != null &&
      !isHub(nodeId) &&
      hubsOfErrand(nodeId).isEmpty &&
      !isCampScene(nodeId);

  // --- The flow --------------------------------------------------------

  /// What the Journey does after [choice] is taken in scene [from]. The
  /// story goes to [nextId] (the choice's own by default; its fail or lose
  /// scene, or the scene a read-through lands on, when that is where it
  /// went).
  ///
  /// * Same stop, an ending (`EXIT`, no next scene), or one end nowhere
  ///   (the prologue, the making of the character): [FlowStay].
  /// * An errand of a town hub back to that hub, at another stop of the
  ///   same town: [FlowReturnToHub].
  /// * Another stop, the choice acted out here (choiceShape's `here`), or a
  ///   fail or lose branch: [FlowTripThenArrive].
  /// * Another stop, a plain way: [FlowMap].
  ChoiceFlow flowOf(StoryNode from, StoryChoice choice, {String? nextId}) {
    final to = nextId ?? choice.nextId;
    if (choice.isEnding || to.isEmpty || _story.nodeFor(to) == null) {
      return const FlowStay();
    }
    final a = stopOf(from.id), b = stopOf(to);
    if (a.isEmpty || b.isEmpty || a == b) return const FlowStay();
    if (isHub(to) && hubsOfErrand(from.id).contains(to) && _inTown(a, b)) {
      return FlowReturnToHub(b, to);
    }
    final branch = to != choice.nextId &&
        (to == choice.failNextId || to == choice.loseNextId);
    final shape =
        choiceShape(from, choice, story: _story, geography: _geography);
    return branch || shape.here ? FlowTripThenArrive(b) : FlowMap(b);
  }

  /// Whether stops [a] and [b] lie in one town that is no camp.
  bool _inTown(String a, String b) {
    final here = _geography.locationOf(a), there = _geography.locationOf(b);
    return here != null && here.id == there?.id && here.kind != 'camp';
  }

  // --- Services --------------------------------------------------------

  /// The services at [placeId] (a location, district or building): every
  /// one offered by a scene whose place or stop lies at or inside it.
  List<PlaceService> servicesAt(String placeId) {
    final all = _services ??= _allServices();
    return [
      for (final s in all)
        if (_isAt(s.nodeId, placeId)) s,
    ];
  }

  bool _isAt(String nodeId, String placeId) {
    final stop = stopOf(nodeId);
    if (stop == placeId) return true;
    final place = _geography.placeOfNode(_story.nodeFor(nodeId));
    return [
      ..._geography.pathOf(stop),
      ..._geography.pathOf(place?.id),
    ].any((p) => p.id == placeId);
  }

  List<PlaceService> _allServices() {
    final out = <PlaceService>[];
    final seen = <String>{};
    void add(PlaceServiceKind kind, String id, String nodeId, int? index) {
      if (id.isEmpty || !seen.add('${kind.name}|$id|$nodeId|$index')) return;
      out.add((kind: kind, id: id, nodeId: nodeId, choiceIndex: index));
    }

    for (final node in _story.nodes.values) {
      if (_trainerSceneIds.contains(node.id)) {
        add(PlaceServiceKind.trainer, node.id, node.id, null);
      }
      final settlement = node.settlement;
      for (final port in [settlement?.portId, settlement?.landingPortId]) {
        if (port == null || port.isEmpty) continue;
        add(PlaceServiceKind.port, port, node.id, null);
        final row = _ports[port];
        if (row is Map<String, dynamic>) {
          for (final shop in portShopIds(row)) {
            add(PlaceServiceKind.shop, shop, node.id, null);
          }
        }
      }
      for (var i = 0; i < node.choices.length; i++) {
        final c = node.choices[i];
        add(PlaceServiceKind.shop, c.unlockShopId ?? '', node.id, i);
        if (c.healAmount > 0) add(PlaceServiceKind.rest, node.id, node.id, i);
      }
    }
    return out;
  }

  // --- Index -------------------------------------------------------------

  /// The scenes a scene leads to: its ways', and their fail and lose
  /// scenes.
  Iterable<String> _next(StoryNode node) sync* {
    for (final c in node.choices) {
      for (final id in [c.nextId, c.failNextId, c.loseNextId]) {
        if (id != null && id.isNotEmpty && _story.nodeFor(id) != null) {
          yield id;
        }
      }
    }
  }

  void _index() {
    final nodes = _story.nodes;
    for (final node in nodes.values) {
      if (node.settlement != null ||
          node.hubProgress != null ||
          node.choices.any((c) => c.nextId == node.id)) {
        _hubs.add(node.id);
      }
    }
    // A hub's errands: the scenes reached from it without passing another
    // hub, from which the story leads back to it.
    for (final hub in _hubs) {
      final reached = <String>{};
      final stack = [
        for (final id in _next(nodes[hub]!))
          if (!_hubs.contains(id)) id,
      ];
      while (stack.isNotEmpty) {
        final id = stack.removeLast();
        if (!reached.add(id)) continue;
        for (final n in _next(nodes[id]!)) {
          if (!_hubs.contains(n) && !reached.contains(n)) stack.add(n);
        }
      }
      final back = <String>{};
      for (var grew = true; grew;) {
        grew = false;
        for (final id in reached) {
          if (back.contains(id)) continue;
          if (_next(nodes[id]!).any((n) => n == hub || back.contains(n))) {
            back.add(id);
            grew = true;
          }
        }
      }
      for (final id in back) {
        (_errandOf[id] ??= {}).add(hub);
      }
    }
    // A whole place with districts and a hub, not a camp: its scenes take
    // the hub's district (the hub's lot on the plan).
    for (final hub in _hubs) {
      final node = nodes[hub]!;
      final place = _geography.placeOfNode(node);
      if (place == null ||
          place.level != GeoLevel.location ||
          place.kind == 'camp' ||
          (node.settlement?.isCamp ?? false) ||
          _wholeStop.containsKey(place.id)) {
        continue;
      }
      final hasDistricts = _geography
          .childrenOf(place.id)
          .any((c) => c.level == GeoLevel.district);
      if (!hasDistricts) continue;
      final plan = _plans[place.id];
      final lot = plan?.building(plan.anchors[hub] ?? '');
      final district = _geography.place(lot?.district);
      if (district != null && district.parent == place.id) {
        _wholeStop[place.id] = district.id;
      }
    }
  }
}
