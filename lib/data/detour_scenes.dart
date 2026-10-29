// Detours as places to explore (Wave 11, docs/proposals/detours-wave11.md):
// detour_scenes.json, Narrative's, holds short scenes of one to four beats
// at a named place a little off the road. Each beat has the shape of an
// expedition step (expedition_steps.dart): Narrative writes the words,
// which ability a check asks and who a fight is against; the numbers are
// Core's (the chapter's DC, a rest's heal, a find's gold).
//
// A scene says where it happens (`where`: a biome, or a place of
// geography.json and every place under it), the chapters it fits, an
// optional flag it waits for (`requires`), and its tags: `landmark` (the
// chapter's memorable one, see detour_pacing.dart), `city` (a short scene
// inside a city's districts), `stop` (a single beat by the road).
//
// The scene plays as an excursion of the story: its beats one after the
// other, a "Leave it" on the first (backing away costs nothing), and a
// note after each choice saying what it did. A scene with a check or a
// fight takes a watch of the day; nothing else does, and none eats a
// ration.
import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import 'expedition_kinds.dart';
import 'expedition_steps.dart';
import 'sub_node_engine.dart';

/// Where a scene happens: biomes of biomes.json, or places of
/// geography.json (the scene fits each and every place under it). Each of
/// `biome` and `place` is one id or a list of them (v1.361).
class DetourWhere {
  const DetourWhere({this.biomes = const [], this.places = const []});

  factory DetourWhere.fromJson(Object? raw) => raw is Map
      ? DetourWhere(biomes: _ids(raw['biome']), places: _ids(raw['place']))
      : const DetourWhere();

  final List<String> biomes;
  final List<String> places;

  bool get isEmpty => biomes.isEmpty && places.isEmpty;

  /// Whether a road through [biomeId], at the places [chain] (the most
  /// specific first, see placeChainOf), is here.
  bool fits({String? biomeId, List<String> chain = const []}) =>
      biomes.contains(biomeId) || places.any(chain.contains);
}

/// One id, or a list of them, as a list ('' and nulls left out).
List<String> _ids(Object? raw) => [
      for (final id in raw is List ? raw : [raw])
        if (id != null && id.toString().isNotEmpty) id.toString(),
    ];

/// One scene of detour_scenes.json.
class DetourScene {
  const DetourScene({
    required this.id,
    this.title = '',
    this.titleFr = '',
    this.rumour = '',
    this.rumourFr = '',
    this.where = const DetourWhere(),
    this.minChapter = 1,
    this.maxChapter = 99,
    this.requiresFlags = const [],
    this.tags = const {},
    this.beats = const [],
  });

  factory DetourScene.fromJson(String id, Map raw) {
    final requires = raw['requires'];
    return DetourScene(
      id: id,
      title: raw['title']?.toString() ?? '',
      titleFr: raw['title_fr']?.toString() ?? '',
      rumour: raw['rumour']?.toString() ?? '',
      rumourFr: raw['rumour_fr']?.toString() ?? '',
      where: DetourWhere.fromJson(raw['where']),
      minChapter: (raw['minChapter'] as num?)?.toInt() ?? 1,
      maxChapter: (raw['maxChapter'] as num?)?.toInt() ?? 99,
      requiresFlags: requires is Map
          ? [..._ids(requires['flag']), ..._ids(requires['flags'])]
          : const [],
      tags: {
        for (final tag in (raw['tags'] as List? ?? const [])) tag.toString(),
      },
      beats: [
        for (final beat in (raw['beats'] as List? ?? const []))
          if (beat is Map) WrittenStep.fromJson(beat),
      ],
    );
  }

  final String id;
  final String title;
  final String titleFr;

  /// One line for the journey's details: what is heard of it.
  final String rumour;
  final String rumourFr;
  final DetourWhere where;
  final int minChapter;
  final int maxChapter;

  /// The flags the party must all hold for the scene to open (`requires`:
  /// `flag`, one or a list, and `flags`, a list; v1.361).
  final List<String> requiresFlags;
  final Set<String> tags;
  final List<WrittenStep> beats;

  String titleFor(bool french) =>
      french && titleFr.isNotEmpty ? titleFr : title;

  /// The chapter's memorable detour (see detour_pacing.dart).
  bool get isLandmark => tags.contains(detourLandmarkTag);

  /// A short scene inside a city, walked between its districts.
  bool get isCity => tags.contains(detourCityTag);

  bool get hasCheckOrFight =>
      beats.any((b) => b.type == 'check' || b.type == 'fight') ||
      beats.any(
          (b) => b.choices.any((c) => c.check != null || c.fight.isNotEmpty));

  /// The watches the scene takes (see [detourSceneWatches]).
  int get watches => hasCheckOrFight ? detourSceneWatches : 0;

  /// Whether the scene fits [chapter] and the party's [flags].
  bool opensFor({required int chapter, required Set<String> flags}) =>
      chapter >= minChapter &&
      chapter <= maxChapter &&
      requiresFlags.every(flags.contains);
}

const String detourLandmarkTag = 'landmark';
const String detourCityTag = 'city';

/// What a scene with a check or a fight takes of the day (the user's
/// decision on #279: one watch; a simple stop costs nothing).
const int detourSceneWatches = 1;

/// detour_scenes.json parsed: the scenes by id (keys starting with `_` are
/// notes, not scenes; a scene with no beat is left out).
Map<String, DetourScene> detourScenesFrom(Map<String, dynamic> raw) {
  final scenes = raw['scenes'] is Map ? raw['scenes'] as Map : raw;
  return {
    for (final MapEntry(:key, :value) in scenes.entries)
      if (!key.toString().startsWith('_') && value is Map)
        if (DetourScene.fromJson(key.toString(), value) case final scene
            when scene.beats.isNotEmpty)
          key.toString(): scene,
  };
}

/// How often a drawn scene has one beat, two, or three or four (the
/// user's decision on #279: about 30%, 45% and 25%). A length with no
/// scene that fits gives its share to the others.
const Map<int, double> detourLengthShare = {1: 0.30, 2: 0.45, 3: 0.25};

int _lengthBucket(DetourScene scene) => min(3, scene.beats.length);

/// One scene of [candidates] drawn by [detourLengthShare], evenly within a
/// length; null for none. Sorted by id first, so the draw doesn't hang on
/// the file's order.
DetourScene? drawDetourScene(List<DetourScene> candidates, Random random) {
  if (candidates.isEmpty) return null;
  final byLength = <int, List<DetourScene>>{};
  for (final scene in [...candidates]..sort((a, b) => a.id.compareTo(b.id))) {
    byLength.putIfAbsent(_lengthBucket(scene), () => []).add(scene);
  }
  final total = [
    for (final length in byLength.keys) detourLengthShare[length] ?? 0,
  ].fold<double>(0, (a, b) => a + b);
  var roll = random.nextDouble() * total;
  for (final length in byLength.keys.toList()..sort()) {
    final share = detourLengthShare[length] ?? 0;
    final scenes = byLength[length]!;
    if (roll < share || length == byLength.keys.reduce(max)) {
      return scenes[random.nextInt(scenes.length)];
    }
    roll -= share;
  }
  return null;
}

/// The node id of a scene's "Leave it" (see [buildDetourScene]): the story
/// player backs out of the detour on it, at no cost.
const String detourLeaveNextId = '@leave_detour';

/// A scene as the story plays it: its beats as excursion nodes, and what
/// each choice of each beat does besides (by node id, the choices in
/// order), with what the scene takes of the day.
class DetourScenePlay {
  const DetourScenePlay({
    required this.scene,
    required this.nodes,
    required this.outcomes,
  });

  final DetourScene scene;
  final List<StoryNode> nodes;
  final Map<String, List<StepOutcome>> outcomes;

  int get watches => scene.watches;

  /// The first beat's id: taking a way on from it (not "Leave it") is
  /// going in, which costs the scene's watches.
  String get firstNodeId => nodes.isEmpty ? '' : nodes.first.id;
}

/// [scene] built for [chapter]: each beat by the expedition's rule (the
/// chapter's DC, a `hard` choice harder, a rest's heal; foes the engine
/// doesn't know dropped, a pack only of the pack tier); a discovery's first
/// way finds a cache of the chapter's gold (as a detour's treasure does);
/// the first beat offers "Leave it".
DetourScenePlay buildDetourScene(
  DetourScene scene, {
  required int chapter,
  required Random random,
  Map<String, dynamic> enemies = const {},
}) {
  final nodes = <StoryNode>[];
  final outcomes = <String, List<StepOutcome>>{};
  for (final (i, beat) in scene.beats.indexed) {
    final step = buildWrittenStep(beat,
        zoneId: 'detour_${scene.id}',
        chapter: chapter,
        random: random,
        enemies: enemies,
        discoveryGold: beat.type == 'discovery'
            ? SubNodeEngine.treasureGoldFor(chapter, 5 + random.nextInt(16))
            : 0);
    var node = step.node;
    var stepOutcomes = step.outcomes;
    if (i == 0) {
      node = StoryNode(
        id: node.id,
        description: node.description,
        descriptionFr: node.descriptionFr,
        choices: [
          ...node.choices,
          StoryChoice(
            text: trFor(AppLanguage.en, 'detour_leave_it'),
            textFr: trFor(AppLanguage.fr, 'detour_leave_it'),
            nextId: detourLeaveNextId,
          ),
        ],
      );
      stepOutcomes = [...stepOutcomes, const StepOutcome()];
    }
    nodes.add(node);
    outcomes[node.id] = stepOutcomes;
  }
  return DetourScenePlay(scene: scene, nodes: nodes, outcomes: outcomes);
}

/// The words a choice's [outcome] says after it ([passed]: how its roll
/// went; null for no roll), in the reader's language; '' for none.
String detourOutcomeNote(StepOutcome outcome,
    {required bool french, bool? passed}) {
  String pick(String en, String fr) => french && fr.isNotEmpty ? fr : en;
  return [
    pick(outcome.note, outcome.noteFr),
    if (passed == true) pick(outcome.successNote, outcome.successNoteFr),
    if (passed == false) pick(outcome.failNote, outcome.failNoteFr),
  ].where((line) => line.isNotEmpty).join(' ');
}
