// The district as places, not choices (the user's call, v1.580; see
// docs/proposals/presentation-contract.md §6 and district-places.md): the
// player first picks where to go, and the ways show once the party stands
// there. Each way of a scene in a town with a stored plan is taken at one
// place, and the list under the district's map holds the places, one entry
// each, with how many things there are to do there.
//
// A way's place, in order:
// * its own `place` (story data: a building of the plan, or `here`);
// * `here`, the party's own place, for a way acted out where the party
//   stands (a fight, a check, a payment, a decision: choiceShape's `here`)
//   or one leading to a scene at the same stop;
// * a way out, for a way that leaves the city (a road, a gate, a voyage);
// * the building of the scene it leads to (its anchor on the plan, in that
//   scene's district);
// * else `here`: a way with only a stand-in building (buildingOfWay's pick
//   by the scene's id) is never shown at a wrong place.
import 'chapter_spine.dart';
import 'choice_flow.dart';
import 'choice_shape.dart';
import 'city_districts.dart';
import 'city_plan_record.dart';
import 'geography.dart';
import 'story_repository.dart';
import '../models/story_node.dart';

/// The story's word for "the party's own place" in a choice's `place`.
const String herePlaceWord = 'here';

/// What kind of place a way is taken at.
enum WayPlaceKind {
  /// Where the party stands: things done on the spot.
  here,

  /// A building of the town's plan.
  building,

  /// A way out of the town (a road, a gate, a harbour).
  wayOut,
}

/// The place a way is taken at: [id] is the same for every way taken at
/// that place (`here`, `building:<plan id>`, `out:<place id>`), [buildingId]
/// the plan's building for a building, [placeId] the geography place it
/// stands for (the building of the scene it leads to, the place a way out
/// reaches) when the world knows one.
class WayPlace {
  const WayPlace._(this.id, this.kind, {this.buildingId, this.placeId});

  const WayPlace.here() : this._(herePlaceWord, WayPlaceKind.here);

  const WayPlace.building(String buildingId, {String? placeId})
      : this._('building:$buildingId', WayPlaceKind.building,
            buildingId: buildingId, placeId: placeId);

  const WayPlace.wayOut(String placeId)
      : this._('out:$placeId', WayPlaceKind.wayOut, placeId: placeId);

  final String id;
  final WayPlaceKind kind;
  final String? buildingId;
  final String? placeId;

  bool get isHere => kind == WayPlaceKind.here;

  @override
  bool operator ==(Object other) => other is WayPlace && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WayPlace($id)';
}

/// The place [choice] of [node] is taken at, on [record] (the plan of the
/// town [node] stands in). [stops] (the story's stops, choice_flow.dart)
/// tell a way to a scene at the same stop; without them only the same
/// `location` counts.
WayPlace placeOfWay(
  StoryNode node,
  StoryChoice choice, {
  required StoryData story,
  required Geography geography,
  required CityPlanRecord record,
  StoryStops? stops,
}) {
  final own = choice.place;
  if (own != null && own.isNotEmpty) {
    if (own == herePlaceWord) return const WayPlace.here();
    if (record.building(own) != null) return WayPlace.building(own);
  }
  final shape = choiceShape(node, choice, story: story, geography: geography);
  if (shape.here) return const WayPlace.here();
  final next = story.nodeFor(choice.nextId);
  if (next == null) return const WayPlace.here();
  final sameStop = stops != null
      ? stops.stopOf(next.id).isNotEmpty &&
          stops.stopOf(next.id) == stops.stopOf(node.id)
      : next.location == node.location;
  if (sameStop) return const WayPlace.here();
  final city = geography.locationOfNode(node);
  final there = geography.locationOfNode(next);
  if (city == null || there?.id != city.id) {
    final to = shape.to?.id ?? there?.id ?? next.location ?? next.id;
    return WayPlace.wayOut(to);
  }
  final district = districtOfNode(geography, next)?.id;
  final anchor = record.building(record.anchors[next.id] ?? '');
  if (anchor != null && (district == null || anchor.district == district)) {
    return WayPlace.building(anchor.id,
        placeId: geography.placeOfNode(next)?.id);
  }
  return const WayPlace.here();
}

/// Whether [choice] carries the party somewhere else in the town or out of
/// it (a walk, a journey), rather than being done where it stands.
bool wayCarriesParty(StoryNode node, StoryChoice choice,
    {required StoryData story, required Geography geography}) {
  final move =
      choiceShape(node, choice, story: story, geography: geography).move;
  return move == ChoiceMove.walk || move == ChoiceMove.travel;
}

/// Whether [choice] goes on with the main story: it leads to one of the
/// chapters' beats, or to a main-story scene ([stops]).
bool wayIsMainStory(StoryChoice choice, {StoryStops? stops}) =>
    chapterForNode(choice.nextId) != null ||
    (stops?.isMainStoryScene(choice.nextId) ?? false);

/// One entry of the district's list: a [place], the [ways] taken there (as
/// indices into the scene's choices, in the scene's order), whether one of
/// them goes on with the main story ([main]), whether one carries the
/// party on ([carries]), and whether all of them are shut ([locked]: their
/// district is locked, see lockedWays).
class WayPlaceEntry {
  const WayPlaceEntry({
    required this.place,
    required this.ways,
    this.main = false,
    this.carries = false,
    this.locked = false,
    this.openCount = 0,
  });

  final WayPlace place;
  final List<int> ways;
  final bool main;
  final bool carries;
  final bool locked;

  /// The things to do there: its ways that are not shut.
  final int openCount;

  @override
  String toString() =>
      'WayPlaceEntry(${place.id} $ways${main ? ' main' : ''}${locked ? ' locked' : ''})';
}

/// [places] (a place by way index) grouped into the district's list:
/// `here` first, then the places holding the main story, then the rest by
/// [distance] (nearest first; the plan's order without it), the ways out
/// after them, and a place whose every way is shut ([locked] way indices)
/// last. [main] and [carries] say which ways go on with the main story
/// and which carry the party.
List<WayPlaceEntry> groupWaysByPlace(
  Map<int, WayPlace> places, {
  Set<int> main = const {},
  Set<int> carries = const {},
  Set<int> locked = const {},
  double Function(WayPlace place)? distance,
}) {
  final order = <WayPlace>[];
  final byPlace = <WayPlace, List<int>>{};
  for (final i in places.keys.toList()..sort()) {
    final place = places[i]!;
    final ways = byPlace[place];
    if (ways == null) {
      order.add(place);
      byPlace[place] = [i];
    } else {
      ways.add(i);
    }
  }
  final entries = [
    for (final place in order)
      () {
        final ways = byPlace[place]!;
        final open = ways.where((i) => !locked.contains(i)).length;
        return WayPlaceEntry(
          place: place,
          ways: ways,
          main: ways.any(main.contains),
          carries: ways.any(carries.contains),
          locked: open == 0,
          openCount: open,
        );
      }(),
  ];
  int rank(WayPlaceEntry e) {
    if (e.locked) return 4;
    if (e.place.isHere) return 0;
    if (e.place.kind == WayPlaceKind.wayOut) return 3;
    return e.main ? 1 : 2;
  }

  final position = {for (final (i, e) in entries.indexed) e.place: i};
  entries.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    if (distance != null) {
      final d = distance(a.place).compareTo(distance(b.place));
      if (d != 0) return d;
    }
    return position[a.place]!.compareTo(position[b.place]!);
  });
  return entries;
}

/// The district list for [node]'s ways in [districtId] (see [placeOfWay],
/// [groupWaysByPlace]): the ways leading into that district (waysInDistrict),
/// and every way of a scene in it that stays where it is, gone out of town
/// included. [lockedWays] are shut; [distance] orders the places.
List<WayPlaceEntry> districtPlaces(
  StoryNode node, {
  required StoryData story,
  required Geography geography,
  required CityPlanRecord record,
  StoryStops? stops,
  Iterable<int>? ways,
  Set<int> lockedWays = const {},
  double Function(WayPlace place)? distance,
}) {
  final indices = ways ?? [for (var i = 0; i < node.choices.length; i++) i];
  final places = <int, WayPlace>{};
  final main = <int>{};
  final carries = <int>{};
  for (final i in indices) {
    final choice = node.choices[i];
    places[i] = placeOfWay(node, choice,
        story: story, geography: geography, record: record, stops: stops);
    if (wayIsMainStory(choice, stops: stops)) main.add(i);
    if (wayCarriesParty(node, choice, story: story, geography: geography)) {
      carries.add(i);
    }
  }
  return groupWaysByPlace(places,
      main: main, carries: carries, locked: lockedWays, distance: distance);
}

/// The name of [place] in the town of [record]: a building's name on the
/// plan (city_plans.json `names`), else the name of the geography place it
/// stands for, else [fallback] (the district's or the party's place's own
/// name, which `here` always takes).
String wayPlaceName(
  WayPlace place, {
  required CityPlanRecord record,
  required Geography geography,
  required bool french,
  required String fallback,
}) {
  if (place.isHere) return fallback;
  final building = place.buildingId;
  if (building != null) {
    final written = record.nameOf(building, french: french);
    if (written.isNotEmpty) return written;
  }
  final known = geography.place(place.placeId);
  if (known != null) return known.nameFor(french);
  return fallback;
}
