// When a detour comes (Wave 11, docs/proposals/detours-wave11.md, section
// 5, and the user's decisions D1, D2 and D8 on the audit, #285): rolled
// when the road is chosen, on every change of place, paced so a chapter
// neither runs dry nor stacks them.
//
// - Which roads: a walk from one place to another, or between two
//   districts of one city (a city's streets, at half the odds); never
//   between two scenes of the same place (D1). From chapter 2 to
//   [lastDetourChapter] (D8: none in the last chapter), wherever the road
//   starts: a spine beat, a town's scene or the camp (D2: the camp's trips
//   to chapter 4's places roll too). Never into or out of a set piece
//   (`noDetour`).
// - A crisis (both scenes tense) holds nothing, but what its road rolled
//   is owed: paid on the next road at rest of the same chapter, after the
//   cooldown; it lapses when the chapter ends. A set piece owes nothing.
// - The pity timer: a road at rest rolls [detourBaseChance], and
//   [detourPityStep] more for each quiet road since the last detour, up to
//   [detourPityCap]. Then the factors: a city's streets
//   [detourCityFactor], a long road (two watches or more)
//   [detourLongRoadFactor], a deadline a day or less away
//   [detourDeadlineFactor].
// - No two in a row: after a detour, a hunter or a familiar face, the next
//   [detourCooldownRoads] roads at rest hold none of them.
// - A voyage's landing rolls as a road arriving there would (v1.361): the
//   sailed chapters (4 to 7) get their share.
// - The landmark: each chapter's memorable scene (tagged `landmark`) is
//   met once, wherever the party walks: on the chapter's first road at
//   rest that nothing else holds ([landmarkDueRoad]), cooldown or not.
//   Chapters 4 and 5 walk two or three such roads, so it can't wait
//   longer.
// - What the detour is: a written scene that fits the road (its place or
//   its biome, its chapter, its flag), never one met before, drawn by
//   length (detour_scenes.dart); with none, today's chain (SubNodeEngine).
//
// Pure rules: the story player, the camp's trips and the playthrough
// simulator play them.
import 'dart:math';

import 'story_repository.dart';
import 'detour_scenes.dart';
import 'geography.dart';
import 'place_pools.dart';
import 'sub_node_engine.dart';

/// The last chapter with detours (D8: the finale has none).
const int lastDetourChapter = 7;

/// What a road at rest rolls with no quiet road behind it, what each quiet
/// road adds, and the most it reaches.
const double detourBaseChance = 0.08;
const double detourPityStep = 0.06;
const double detourPityCap = 0.45;

/// Roads at rest after a detour, a hunter or a familiar face that hold
/// none of them.
const int detourCooldownRoads = 1;

/// The odds' factors: a move between districts of one city, a road of
/// [longRoadWatches] or more, a deadline [tightDeadlineDays] or fewer days
/// away.
const double detourCityFactor = 0.5;
const double detourLongRoadFactor = 1.3;
const double detourDeadlineFactor = 0.3;
const int longRoadWatches = 2;
const int tightDeadlineDays = 1;

/// The road at rest of a chapter from which its landmark comes (the first
/// one nothing else holds).
const int landmarkDueRoad = 1;

/// What the detours have done so far in a run: saved with the session.
class DetourPacing {
  const DetourPacing({
    this.chapter = 0,
    this.roads = 0,
    this.quiet = 1,
    this.cooldown = 0,
    this.owed = false,
    this.met = const [],
  });

  factory DetourPacing.fromJson(Object? raw) {
    if (raw is! Map) return const DetourPacing();
    int number(String key, int fallback) =>
        (raw[key] as num?)?.toInt() ?? fallback;
    return DetourPacing(
      chapter: number('chapter', 0),
      roads: number('roads', 0),
      quiet: number('quiet', 1),
      cooldown: number('cooldown', 0),
      owed: raw['owed'] == true,
      met: [for (final id in (raw['met'] as List? ?? const [])) id.toString()],
    );
  }

  /// The chapter [roads], [cooldown] and [owed] count in.
  final int chapter;

  /// Roads at rest walked this chapter.
  final int roads;

  /// Roads at rest since the last detour (the pity timer).
  final int quiet;

  /// Roads at rest still to go before the next encounter.
  final int cooldown;

  /// A detour owed by a crisis this chapter.
  final bool owed;

  /// The written scenes met, in order.
  final List<String> met;

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'roads': roads,
        'quiet': quiet,
        'cooldown': cooldown,
        'owed': owed,
        'met': met,
      };

  DetourPacing copyWith({
    int? chapter,
    int? roads,
    int? quiet,
    int? cooldown,
    bool? owed,
    List<String>? met,
  }) =>
      DetourPacing(
        chapter: chapter ?? this.chapter,
        roads: roads ?? this.roads,
        quiet: quiet ?? this.quiet,
        cooldown: cooldown ?? this.cooldown,
        owed: owed ?? this.owed,
        met: met ?? this.met,
      );

  /// The pacing counted in [newChapter]: a new chapter starts its roads
  /// afresh, and an owed detour lapses with the chapter that owed it.
  DetourPacing inChapter(int newChapter) => newChapter == chapter
      ? this
      : DetourPacing(chapter: newChapter, quiet: quiet, met: met);
}

/// What kind of road it is.
enum DetourRoadKind {
  /// From one place to another.
  road,

  /// Between two districts of one city.
  streets,
}

/// A road a detour may hold, as [detourRoadBetween] reads it.
class DetourRoad {
  const DetourRoad({
    required this.chapter,
    this.kind = DetourRoadKind.road,
    this.setPiece = false,
    this.crisis = false,
    this.watches = 1,
    this.chain = const [],
    this.biome,
    this.daysToSpare,
  });

  final int chapter;
  final DetourRoadKind kind;

  /// Into or out of a set piece (`noDetour`): nothing on it, nothing owed.
  final bool setPiece;

  /// Both scenes tense: a crisis running on.
  final bool crisis;

  /// The watches the walk takes.
  final int watches;

  /// The places where the road leads, the most specific first (see
  /// placeChainOf), and the biome it runs through.
  final List<String> chain;
  final String? biome;

  /// Days left before a deadline the party is held to, if any.
  final int? daysToSpare;

  bool get atRest => !setPiece && !crisis;

  /// Whether a detour may come in its chapter (2 to [lastDetourChapter]).
  bool get detoursOpen =>
      chapter >= SubNodeEngine.firstDetourChapter &&
      chapter <= lastDetourChapter;
}

/// The road from scene [fromNodeId] to [toNodeId] in [chapter], or null
/// when there is none: the same place (the same location and district,
/// D1), or a place neither scene names with no change of landmark either.
/// [travels]: the choice walks between places whatever their scenes say
/// (the camp's trips, a choice that travels).
DetourRoad? detourRoadBetween(
  StoryData story,
  Geography world, {
  required String fromNodeId,
  required String toNodeId,
  required int chapter,
  bool travels = false,
  int watches = 1,
  int? daysToSpare,
}) {
  if (fromNodeId == toNodeId) return null;
  final from = story.nodeFor(fromNodeId);
  final to = story.nodeFor(toNodeId);
  final fromPlace = world.placeOfNode(from);
  final toPlace = world.placeOfNode(to);
  DetourRoadKind kind;
  if (travels || world.travelsBetween(story, fromNodeId, toNodeId)) {
    kind = DetourRoadKind.road;
  } else if (fromPlace != null &&
      toPlace != null &&
      fromPlace.id != toPlace.id) {
    kind = DetourRoadKind.streets;
  } else {
    return null;
  }
  final setPiece = (from?.noDetour ?? false) || (to?.noDetour ?? false);
  return DetourRoad(
    chapter: chapter,
    kind: kind,
    setPiece: setPiece,
    crisis:
        !setPiece && !SubNodeEngine.detourAllowedBetween(from?.mood, to?.mood),
    watches: watches,
    chain: placeChainOf(world, toPlace?.id),
    biome: world.roadBiome(story, fromNodeId, toNodeId)?.id,
    daysToSpare: daysToSpare,
  );
}

/// The odds a road at rest holds a detour, after [quiet] quiet roads.
double detourChanceFor(int quiet, DetourRoad road) {
  var chance = min(detourPityCap, detourBaseChance + detourPityStep * quiet);
  if (road.kind == DetourRoadKind.streets) chance *= detourCityFactor;
  if (road.watches >= longRoadWatches) chance *= detourLongRoadFactor;
  final spare = road.daysToSpare;
  if (spare != null && spare <= tightDeadlineDays) {
    chance *= detourDeadlineFactor;
  }
  return min(1.0, chance);
}

/// What took a road.
enum RoadTurnKind {
  /// Nothing: a quiet road, a cooldown, or no detour on it at all.
  quiet,

  /// A crisis: whatever the road rolled is owed.
  owed,

  /// Something else held the road first (a road event, a hunter).
  taken,

  /// Someone met before (recurring_encounters.dart).
  familiar,

  /// A detour: a written [RoadTurn.scene], or today's chain.
  detour,
}

/// What a road holds, and the pacing after it.
class RoadTurn {
  const RoadTurn(this.kind, this.next,
      {this.scene, this.landmark = false, this.paysOwed = false});

  final RoadTurnKind kind;
  final DetourPacing next;

  /// The written scene of a detour; null for today's chain.
  final DetourScene? scene;

  /// The detour is the chapter's landmark.
  final bool landmark;

  /// The detour pays one owed by a crisis.
  final bool paysOwed;

  bool get isDetour => kind == RoadTurnKind.detour;
}

/// The scenes that may come on [road] for a party holding [flags], met
/// [met] before: open in its chapter, never met, of the road's kind (a
/// city's scenes in its streets, the others on its roads), and where the
/// road goes.
List<DetourScene> scenesFitting(
  Map<String, DetourScene> scenes,
  DetourRoad road, {
  required Set<String> flags,
  List<String> met = const [],
}) =>
    [
      for (final scene in scenes.values)
        if (!met.contains(scene.id) &&
            scene.opensFor(chapter: road.chapter, flags: flags) &&
            scene.isCity == (road.kind == DetourRoadKind.streets) &&
            scene.where.fits(biomeId: road.biome, chain: road.chain))
          scene,
    ];

/// The landmark of [chapter] not met yet, if any (the first by id).
DetourScene? landmarkOf(
  Map<String, DetourScene> scenes, {
  required int chapter,
  required Set<String> flags,
  List<String> met = const [],
}) {
  final open = [
    for (final scene in scenes.values)
      if (scene.isLandmark &&
          !met.contains(scene.id) &&
          scene.opensFor(chapter: chapter, flags: flags))
        scene,
  ]..sort((a, b) => a.id.compareTo(b.id));
  return open.isEmpty ? null : open.first;
}

/// Whether the chapter's landmark is due on [road] (see [planRoad]): it
/// then comes before a hunter (a road event still holds the road), so a
/// chapter with one road at rest (the march to Candlehold) meets it.
bool landmarkDueOn({
  required DetourPacing pacing,
  required DetourRoad road,
  required Map<String, DetourScene> scenes,
  required Set<String> flags,
}) {
  if (!road.atRest || !road.detoursOpen) return false;
  final p = pacing.inChapter(road.chapter);
  return p.roads + 1 >= landmarkDueRoad &&
      landmarkOf(scenes, chapter: road.chapter, flags: flags, met: p.met) !=
          null;
}

/// What [road] holds, for a party at [pacing] holding [flags], in the
/// order the game rolls it: [taken] (a road event or a hunter got there
/// first), the chapter's landmark when it is due, the cooldown, an owed
/// detour, a familiar face ([familiar] rolls one, and says whether one
/// came; it is asked only when one may come), then the pity timer.
/// [random] is the road's own (see detourRandomFor), so the same road
/// chosen the same way holds the same thing.
RoadTurn planRoad({
  required DetourPacing pacing,
  required DetourRoad road,
  required Map<String, DetourScene> scenes,
  required Set<String> flags,
  required Random random,
  bool taken = false,
  bool Function()? familiar,
}) {
  var p = pacing.inChapter(road.chapter);
  if (road.setPiece) return RoadTurn(RoadTurnKind.quiet, p);
  if (road.crisis) {
    if (road.detoursOpen &&
        !p.owed &&
        random.nextDouble() < detourChanceFor(p.quiet, road)) {
      p = p.copyWith(owed: true);
      return RoadTurn(RoadTurnKind.owed, p);
    }
    return RoadTurn(RoadTurnKind.quiet, p);
  }
  p = p.copyWith(roads: p.roads + 1);
  if (taken) {
    return RoadTurn(
        RoadTurnKind.taken, p.copyWith(cooldown: detourCooldownRoads));
  }
  RoadTurn detour(DetourScene? scene, {required bool paysOwed}) => RoadTurn(
        RoadTurnKind.detour,
        p.copyWith(
          quiet: 0,
          cooldown: detourCooldownRoads,
          owed: paysOwed ? false : p.owed,
          met: scene == null ? p.met : [...p.met, scene.id],
        ),
        scene: scene,
        landmark: scene?.isLandmark ?? false,
        paysOwed: paysOwed,
      );

  final landmark = road.detoursOpen
      ? landmarkOf(scenes, chapter: road.chapter, flags: flags, met: p.met)
      : null;
  if (landmark != null && p.roads >= landmarkDueRoad) {
    return detour(landmark, paysOwed: p.owed);
  }
  if (p.cooldown > 0) {
    return RoadTurn(RoadTurnKind.quiet, p.copyWith(cooldown: p.cooldown - 1));
  }
  if (road.detoursOpen && p.owed) {
    return detour(_sceneFor(road, scenes, flags, p.met, random),
        paysOwed: true);
  }
  if (familiar != null && familiar()) {
    return RoadTurn(
        RoadTurnKind.familiar, p.copyWith(cooldown: detourCooldownRoads));
  }
  if (!road.detoursOpen) return RoadTurn(RoadTurnKind.quiet, p);
  if (random.nextDouble() < detourChanceFor(p.quiet, road)) {
    return detour(_sceneFor(road, scenes, flags, p.met, random),
        paysOwed: false);
  }
  return RoadTurn(RoadTurnKind.quiet, p.copyWith(quiet: p.quiet + 1));
}

/// The scene a detour on [road] plays: the chapter's landmark when the
/// road fits it, else one drawn among those that fit; null for today's
/// chain.
DetourScene? _sceneFor(DetourRoad road, Map<String, DetourScene> scenes,
    Set<String> flags, List<String> met, Random random) {
  final fitting = scenesFitting(scenes, road, flags: flags, met: met);
  final landmarks = fitting.where((s) => s.isLandmark).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (landmarks.isNotEmpty) return landmarks.first;
  return drawDetourScene(fitting, random);
}

/// The road's own dice: the same road ([fromNodeId] to [toNodeId], taken
/// [historyLength] steps into the story) rolls the same, so what it holds
/// is known when it is chosen (as a road event is, see road_events.dart).
Random detourRandomFor(
        {required String fromNodeId,
        required String toNodeId,
        required int historyLength,
        int salt = 0}) =>
    Random(_hash('detour:$fromNodeId>$toNodeId#$historyLength:$salt'));

int _hash(String text) {
  var h = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return h;
}
