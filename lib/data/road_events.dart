import 'dart:math';

import '../models/story_node.dart';
import 'geography.dart';
import 'journey_rules.dart';
import 'story_repository.dart';
import 'sub_node_engine.dart';

/// Road events: what may wait on the road between two places from chapter
/// 2 on. Which road holds what is fixed for a given road at a given point
/// of the journey (see [roadEventFor]), so the Journey map can show it
/// before the party sets out, and the party can pick its road by it:
///
/// * a champion barring the way: an Elite of the chapter's own foes (see
///   [championPoolFor]) a quarter tougher still, with a better chest, or
///   a hard sneak past it;
/// * a wayside shrine: health back, more for an offering;
/// * the Wayfarer's Caravan: rare stock for sale on the roadside;
/// * a hazard of the land the road runs through (v1.197): one of its
///   biome's two (see geography.dart), pushed through at a cost in health
///   or waited out at a cost in time (see [roadHazardFor]).
///
/// A road event takes the place of a detour on its road.
enum RoadEventKind { champion, shrine, caravan, hazard }

/// The odds a road holds an event.
const double roadEventChance = 0.3;

/// The share of a road's events that are hazards when the land it runs
/// through has a biome with hazards (see [hazardShareFor]); taken from
/// the shrines' and the caravan's shares in proportion.
const double roadHazardShare = 0.2;

/// The hazard share for a road through [biome]: [roadHazardShare] when it
/// has hazards, none otherwise (and the road's mix is as before).
double hazardShareFor(Biome? biome) =>
    (biome?.hazards.isNotEmpty ?? false) ? roadHazardShare : 0;

/// The road event marks of a hazard's two choices (see
/// StoryChoice.roadEvent): push on, or wait it out.
const String hazardPushEvent = 'hazard_push';
const String hazardWaitEvent = 'hazard_wait';

bool isHazardPush(StoryChoice choice) => choice.roadEvent == hazardPushEvent;
bool isHazardWait(StoryChoice choice) => choice.roadEvent == hazardWaitEvent;

/// What pushing on through a hazard costs each of the party in [chapter]:
/// a shrine's prayer in reverse, smaller.
int hazardWoundFor(int chapter) => 10 + 5 * max(1, chapter);

/// [health] after pushing on through a hazard that deals [wound]: never
/// the last point, and nothing for one already down.
int healthAfterHazard(int health, int wound) =>
    health <= 1 ? health : max(1, health - wound);

/// What a party nobody steers does about a hazard (the simulator,
/// autoplay): pushes on while above half health, else waits it out.
bool hazardPushesOn({required int health, required int maxHealth}) =>
    health * 2 > maxHealth;

/// Which of [biome]'s hazards waits on the road from [fromNodeId] to
/// [toNodeId], [historyLength] scenes into the journey: fixed for that
/// road at that point, as the event itself is (see [roadEventFor]). Null
/// for a biome with none.
BiomeHazard? roadHazardFor(
  Biome? biome, {
  required String fromNodeId,
  required String toNodeId,
  required int historyLength,
}) {
  final hazards = biome?.hazards ?? const <BiomeHazard>[];
  if (hazards.isEmpty) return null;
  final pick = stableHash('$fromNodeId>$toNodeId#$historyLength~hazard') %
      hazards.length;
  return hazards[pick];
}

/// The Wayfarer's Caravan's shop (see shops.json).
const String caravanShopId = 'wayfarer_caravan';

/// A stable hash of [text] (FNV-1a, then MurmurHash3's finalizer so that
/// close texts land far apart), the same on every run and device.
int stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  hash ^= hash >> 16;
  hash = (hash * 0x85ebca6b) & 0xffffffff;
  hash ^= hash >> 13;
  hash = (hash * 0xc2b2ae35) & 0xffffffff;
  hash ^= hash >> 16;
  return hash;
}

/// What waits on the road from scene [fromNodeId] to [toNodeId] of [story]
/// in [chapter], [historyLength] scenes into the journey; null for a quiet
/// road. Only a road between two places (see [isRoadStep]) holds one, from
/// chapter 2, and never in the middle of a crisis (see
/// SubNodeEngine.detourAllowedBetween). The chapter's condition (see
/// chapter_conditions.dart) may make events likelier ([oddsFactor]) and
/// change their mix ([championShare], [shrineShare]; the rest are the
/// caravan). A road through a land with hazards ([hazardShare], see
/// [hazardShareFor]) holds hazards too, at the shrines' and the caravan's
/// expense in proportion; with none, the mix is as it always was.
RoadEventKind? roadEventFor({
  required StoryData story,
  required String fromNodeId,
  required String toNodeId,
  required int historyLength,
  required int chapter,
  double oddsFactor = 1,
  double championShare = 0.4,
  double shrineShare = 0.3,
  double hazardShare = 0,
}) {
  if (!roadRulesApply(chapter) || !isRoadStep(fromNodeId, toNodeId)) {
    return null;
  }
  final from = story.nodeFor(fromNodeId);
  final to = story.nodeFor(toNodeId);
  if (from == null || to == null || isStoryEnding(to)) return null;
  if (!SubNodeEngine.detourAllowedBetweenScenes(from, to, chapter: chapter)) {
    return null;
  }
  // Two independent draws: whether the road holds anything, and what.
  final key = '$fromNodeId>$toNodeId#$historyLength#$chapter';
  double draw(String salt) => stableHash('$key$salt') / 0x100000000;
  if (draw('?') >= roadEventChance * oddsFactor) return null;
  final roll = draw('!');
  if (roll < championShare) return RoadEventKind.champion;
  // The hazards' share comes out of the shrines' and the caravan's, each
  // giving up the part of it its own share is of theirs together.
  final rest = max(0.0, 1 - championShare);
  final hazard = rest <= 0 ? 0.0 : min(max(0.0, hazardShare), rest);
  final shrine = rest <= 0 ? shrineShare : shrineShare * (1 - hazard / rest);
  if (roll < championShare + shrine) return RoadEventKind.shrine;
  if (roll < championShare + shrine + hazard) return RoadEventKind.hazard;
  return RoadEventKind.caravan;
}

/// The foes a champion is drawn from in [chapter]: the random draws of
/// [enemies] (see SubNodeEngine.filterEnemyPool) first met in this
/// chapter or the one before, so that a champion is one of the chapter's
/// own and not an old foe the party has long outgrown. On a road through
/// [biome] (v1.197), the ones that live there (enemies.json's `biomes`)
/// when there are two or more of them.
List<String> championPoolFor(Map<String, dynamic> enemies, int chapter,
    {String? biome}) {
  final pool = [
    for (final id in SubNodeEngine.filterEnemyPool(
        enemies: enemies, unlockedEnemyIds: const [], chapter: chapter))
      if ((((enemies[id] as Map<String, dynamic>?)?['minChapter'] as num?)
                  ?.toInt() ??
              1) >=
          chapter - 1)
        id,
  ];
  if (biome == null || biome.isEmpty) return pool;
  final local = [
    for (final id in pool)
      if (enemyLivesIn(enemies[id], biome)) id,
  ];
  return local.length >= 2 ? local : pool;
}

/// Whether the enemy record [enemy] lives in [biome] (its `biomes`).
bool enemyLivesIn(Object? enemy, String biome) {
  final biomes = enemy is Map ? enemy['biomes'] : null;
  return biomes is List && biomes.any((b) => b.toString() == biome);
}

/// What praying at a shrine heals in [chapter], and what an offering
/// costs and heals.
int shrineHealFor(int chapter) => 25 + 10 * max(1, chapter);
int shrineOfferingFor(int chapter) => 10 * max(1, chapter);
int shrineOfferingHealFor(int chapter) => 2 * shrineHealFor(chapter);

/// The scene [kind] plays as a detour on its road in [chapter]: one node
/// with its choices. A champion is drawn from [enemyPool] (see
/// [championPoolFor]); with none to draw, a shrine stands there instead.
/// A hazard is [hazard] (see [roadHazardFor]); with none, a shrine too.
/// [seed] picks the lines and the foe.
List<StoryNode> roadEventChain(
  RoadEventKind kind, {
  required int chapter,
  required List<String> enemyPool,
  required int seed,
  BiomeHazard? hazard,
}) {
  final random = Random(seed);
  final id = 'road_${kind.name}_$seed';
  if (kind == RoadEventKind.hazard && hazard != null) {
    return [_hazardNode(id, hazard, chapter: chapter)];
  }
  if (kind == RoadEventKind.champion && enemyPool.isNotEmpty) {
    final enemyId = enemyPool[random.nextInt(enemyPool.length)];
    final line = random.nextInt(_championEn.length);
    return [
      StoryNode(
        id: id,
        description: _championEn[line],
        descriptionFr: _championFr[line],
        contextNote: _championNoteEn,
        contextNoteFr: _championNoteFr,
        choices: [
          StoryChoice(
            text: 'Face the champion',
            textFr: 'Affronter le champion',
            nextId: id,
            triggerEnemyId: enemyId,
            roadEvent: 'elite',
          ),
          StoryChoice(
            text: 'Slip around it',
            textFr: 'Le contourner en douce',
            nextId: id,
            triggerEnemyId: enemyId,
            roadEvent: 'elite',
            checkAbility: 'dexterity',
            checkDC: SubNodeEngine.detourCheckDc(chapter) + 3,
            avoidFightOnSuccess: true,
            forcedCondition: 'ambush',
          ),
        ],
      ),
    ];
  }
  if (kind == RoadEventKind.caravan) {
    final line = random.nextInt(_caravanEn.length);
    return [
      StoryNode(
        id: id,
        description: _caravanEn[line],
        descriptionFr: _caravanFr[line],
        contextNote: _caravanNoteEn,
        contextNoteFr: _caravanNoteFr,
        choices: const [
          StoryChoice(
            text: 'See what they sell',
            textFr: 'Voir ce qu’ils vendent',
            nextId: '',
            unlockShopId: caravanShopId,
            roadEvent: 'caravan',
          ),
          StoryChoice(
            text: 'Walk on',
            textFr: 'Passer votre chemin',
            nextId: '',
            roadEvent: 'caravan',
          ),
        ],
      ),
    ];
  }
  final line = random.nextInt(_shrineEn.length);
  final offering = shrineOfferingFor(chapter);
  return [
    StoryNode(
      id: id,
      description: _shrineEn[line],
      descriptionFr: _shrineFr[line],
      contextNote: _shrineNoteEn,
      contextNoteFr: _shrineNoteFr,
      choices: [
        StoryChoice(
          text: 'Kneel a while',
          textFr: 'Vous agenouiller un moment',
          nextId: '',
          healAmount: shrineHealFor(chapter),
          roadEvent: 'shrine',
        ),
        StoryChoice(
          text: 'Leave an offering ($offering gold)',
          textFr: 'Laisser une offrande ($offering or)',
          nextId: '',
          goldMod: -offering,
          healAmount: shrineOfferingHealFor(chapter),
          alignmentMod: 1,
          roadEvent: 'shrine',
        ),
        const StoryChoice(
          text: 'Walk on',
          textFr: 'Passer votre chemin',
          nextId: '',
          roadEvent: 'shrine',
        ),
      ],
    ),
  ];
}

/// [hazard] on the road in [chapter]: its scene, then push on (each of the
/// party wounded, never to death; see [hazardWoundFor]) or wait it out (a
/// day on the road, with its ration).
StoryNode _hazardNode(String id, BiomeHazard hazard, {required int chapter}) {
  final wound = hazardWoundFor(chapter);
  String note(String template, String name) =>
      template.replaceAll('{hazard}', name).replaceAll('{n}', '$wound');
  String or(String text, String fallback) => text.isEmpty ? fallback : text;
  return StoryNode(
    id: id,
    description: or(hazard.text, hazard.name),
    descriptionFr: or(hazard.textFr, hazard.nameFor(true)),
    contextNote: note(_hazardNoteEn, hazard.name),
    contextNoteFr: note(_hazardNoteFr, hazard.nameFor(true)),
    choices: [
      StoryChoice(
        text: or(hazard.push, _hazardPushEn),
        textFr: or(hazard.pushFr, _hazardPushFr),
        nextId: '',
        healAmount: -wound,
        roadEvent: hazardPushEvent,
      ),
      StoryChoice(
        text: or(hazard.wait, _hazardWaitEn),
        textFr: or(hazard.waitFr, _hazardWaitFr),
        nextId: '',
        roadEvent: hazardWaitEvent,
      ),
    ],
  );
}

const String _hazardNoteEn = '{hazard} on the road. Pushing on costs each of '
    'you {n} health, never the last; waiting it out costs a day and its '
    'ration.';
const String _hazardNoteFr = '{hazard} sur la route. Forcer le passage coûte '
    '{n}\u00a0points de vie à chaque membre du groupe, jamais le '
    'dernier\u00a0; attendre coûte une journée et sa ration.';
const String _hazardPushEn = 'Push on through it';
const String _hazardPushFr = 'Forcer le passage';
const String _hazardWaitEn = 'Wait it out';
const String _hazardWaitFr = 'Attendre que cela passe';

const String _championNoteEn =
    'A champion holds this road: the fight is harder, and so is what it guards.';
const String _championNoteFr =
    'Un champion tient cette route : le combat est plus dur, et ce qu’il garde aussi.';
const String _shrineNoteEn =
    'A wayside shrine: a place to mend before the road goes on.';
const String _shrineNoteFr =
    'Un sanctuaire au bord de la route : de quoi vous remettre avant la suite.';
const String _caravanNoteEn =
    'The Wayfarer’s Caravan is on this road today. It sells what towns do not.';
const String _caravanNoteFr =
    'La Caravane du Voyageur passe sur cette route aujourd’hui. Elle vend ce que les villes n’ont pas.';

const List<String> _championEn = [
  'Someone has planted a spear across the road and waits beside it, scarred and patient. The travellers who turned back left their footprints in the mud. The ones who did not left more.',
  'A figure in mismatched armour blocks the ford. Trophies hang from its belt, each a different colour. It looks you over the way a buyer looks at a horse.',
  'The road narrows between two rocks, and on the higher one sits a fighter sharpening a blade that does not need it. “Toll,” it says, and does not name a price.',
];
const List<String> _championFr = [
  'Quelqu’un a planté une lance en travers de la route et attend à côté, couturé de cicatrices et patient. Les voyageurs qui ont rebroussé chemin ont laissé leurs traces dans la boue. Les autres ont laissé davantage.',
  'Une silhouette en armure dépareillée barre le gué. Des trophées pendent à sa ceinture, chacun d’une couleur différente. Elle vous jauge comme un acheteur jauge un cheval.',
  'La route se resserre entre deux rochers, et sur le plus haut est assis un combattant qui affûte une lame qui n’en a pas besoin. « Péage », dit-il, sans donner de prix.',
];
const List<String> _shrineEn = [
  'A shrine no taller than a child stands where two paths meet, its saint worn smooth by hands. Someone keeps its candle lit. The air around it is quieter than it should be.',
  'Under a stone arch, a basin of clear water and a bench worn hollow by pilgrims. The wind drops as you step beneath the arch, as if it had been asked to.',
  'Ribbons tied to a hawthorn mark a wayside altar. Coins lie in the grass at its foot, and nobody has taken them.',
];
const List<String> _shrineFr = [
  'Un sanctuaire pas plus haut qu’un enfant se dresse à la croisée de deux chemins, son saint poli par les mains. Quelqu’un entretient sa bougie. L’air autour est plus calme qu’il ne devrait l’être.',
  'Sous une arche de pierre, un bassin d’eau claire et un banc creusé par les pèlerins. Le vent tombe dès que vous passez sous l’arche, comme si on le lui avait demandé.',
  'Des rubans noués à une aubépine signalent un autel au bord du chemin. Des pièces traînent dans l’herbe à son pied, et personne ne les a prises.',
];
const List<String> _caravanEn = [
  'Mules, bells and a painted wagon: the Wayfarer’s Caravan has stopped to water its animals. Its master waves you over before you can decide not to come.',
  'A line of carts under patched canvas crawls toward you. The lead driver lifts a lantern in greeting: “Rare goods, fair prices, no questions asked. Well, few.”',
];
const List<String> _caravanFr = [
  'Des mules, des clochettes et une roulotte peinte : la Caravane du Voyageur s’est arrêtée pour abreuver ses bêtes. Son maître vous fait signe avant que vous ayez pu décider de ne pas venir.',
  'Une file de charrettes sous des bâches rapiécées avance vers vous. Le premier conducteur lève une lanterne pour vous saluer : « Marchandises rares, prix honnêtes, pas de questions. Enfin, peu. »',
];
