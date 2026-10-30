// The ground and the sky as a fight's third party (v1.241): the place a fight
// happens in has a look (its stage, drawn behind the battle) and sometimes
// turns on someone -- a sandstorm rising, the earth breaking, a spring
// welling up -- for a few rounds, in favour of the party, of the enemies, or
// of neither. Each anomaly is announced a round ahead, so a party can read it
// coming (see [anomalyReadsSide]) and plan around it.
//
// Pure rules, no widgets: the fight screen rolls a plan once at the start
// (rollFieldAnomaly), asks it what each round changes, and applies that
// through the same hooks the day's weather already uses (damage by element,
// the Perception penalty) plus one new one, the round's tick. An anomaly
// wounds but never finishes: a tick leaves at least one health.
//
// The anomalies are code, not a table, as the doctrines are (doctrine.dart):
// each is tuned one by one. The biomes' road hazards (biomes.json) give most
// of them their names, so the sandstorm that stops a traveller on the road is
// the one that breaks over a fight in the dunes.
import 'dart:math';

import '../data/climate.dart';
import '../data/geography.dart' show BiomePattern;

/// Where a fight happens, as it is drawn and as the anomalies are chosen:
/// the biome's pattern (see geography.dart), or [hall] for the inside of a
/// building.
enum FightStage {
  fields,
  dunes,
  saltFlats,
  waves,
  ash,
  terraces,
  cliffs,
  reeds,
  snow,
  glass,
  hall,

  /// A town's or a city's streets (v1.662).
  streets,

  /// A ship's deck: a boarding fight (v1.662).
  deck,
}

/// The stage of a fight on land of [pattern]: a [ship]'s deck first, then
/// [indoors] (a hall, a crypt, a cellar), then a [town]'s streets; no
/// pattern at all is open country.
FightStage fightStageOf(BiomePattern? pattern,
    {bool indoors = false, bool town = false, bool ship = false}) {
  if (ship) return FightStage.deck;
  if (indoors) return FightStage.hall;
  if (town) return FightStage.streets;
  return switch (pattern) {
    null || BiomePattern.fields => FightStage.fields,
    BiomePattern.dunes => FightStage.dunes,
    BiomePattern.saltFlats => FightStage.saltFlats,
    BiomePattern.waves => FightStage.waves,
    BiomePattern.ash => FightStage.ash,
    BiomePattern.terraces => FightStage.terraces,
    BiomePattern.cliffs => FightStage.cliffs,
    BiomePattern.reeds => FightStage.reeds,
    BiomePattern.snow => FightStage.snow,
    BiomePattern.glass => FightStage.glass,
  };
}

/// The stage named [name] ('dunes', 'hall'…), or null.
FightStage? fightStageFromName(String? name) {
  for (final stage in FightStage.values) {
    if (stage.name == name) return stage;
  }
  return null;
}

/// What an anomaly is of, for the line that announces it.
enum AnomalyFamily { storm, ground, cold, heat, water, light }

/// Which side an anomaly falls on. [both] is every anomaly that does not pick
/// a side: the same for the party and the enemies.
enum AnomalySide { party, enemies, both }

/// How an anomaly ticks at the start of a round: it hurts or mends
/// [percent] of the maximum health of everyone on the side, or of one of
/// them chosen by the roll when [one] is set.
class AnomalyTick {
  const AnomalyTick({
    required this.mend,
    required this.percent,
    this.one = false,
  });

  final bool mend;
  final int percent;
  final bool one;
}

/// How much the day's weather has to say in whether an anomaly comes.
enum SkyRule {
  /// Whatever the sky.
  any,

  /// Likelier under one of its skies, rarer under the rest.
  prefers,

  /// Only under one of its skies.
  requires,
}

class FieldAnomaly {
  const FieldAnomaly({
    required this.id,
    required this.family,
    required this.stages,
    this.skies = const {},
    this.skyRule = SkyRule.any,
    this.weight = 1,
    this.shared = false,
    this.boon = false,
    this.elements = const {},
    this.sideElements = const {},
    this.sideDamage = 1,
    this.perception = 0,
    this.tick,
    this.favouredBy = const {},
  });

  /// Also the key of its name: `anomaly_<id>`.
  final String id;
  final AnomalyFamily family;

  /// The stages it can come on.
  final Set<FightStage> stages;
  final Set<WeatherKind> skies;
  final SkyRule skyRule;
  final int weight;

  /// It falls on both sides alike (and [boon] means nothing); otherwise the
  /// roll picks the side it falls on.
  final bool shared;

  /// On an anomaly that picks a side: the side it falls on is helped, not
  /// hurt.
  final bool boon;

  /// How much a hit of each element deals, whoever strikes (the file's
  /// spelling: 'Fire', 'Water', 'Electricity'…).
  final Map<String, double> elements;

  /// The same, only for the side it falls on (the other side is spared).
  final Map<String, double> sideElements;

  /// What the side it falls on deals, all told: under 1 it is slowed, over 1
  /// it is spurred. A shared anomaly applies it to neither.
  final double sideDamage;

  /// Taken off the party's Perception while it lasts: whatever the sides.
  final int perception;

  final AnomalyTick? tick;

  /// The kinds of place (see geoPlaceTags) it is likelier in: a holy place
  /// favours a spring, a haunted one an eclipse.
  final Set<String> favouredBy;

  /// Whether it picks a side.
  bool get picksSide => !shared;

  /// Whether the roll for the weather and the stage lets it in, and how
  /// likely it is among the others.
  double weightUnder(FightStage stage, WeatherKind? sky,
      {Set<String> tags = const {}}) {
    if (!stages.contains(stage)) return 0;
    final matches = skies.isEmpty || (sky != null && skies.contains(sky));
    final base = switch (skyRule) {
      SkyRule.any => weight.toDouble(),
      SkyRule.prefers => matches ? weight * 3.0 : weight * 0.35,
      SkyRule.requires => matches ? weight.toDouble() : 0.0,
    };
    // A place of the kind it favours makes it three times likelier.
    return favouredBy.any(tags.contains) ? base * 3 : base;
  }
}

const Set<FightStage> _outdoors = {
  FightStage.fields,
  FightStage.dunes,
  FightStage.saltFlats,
  FightStage.waves,
  FightStage.ash,
  FightStage.terraces,
  FightStage.cliffs,
  FightStage.reeds,
  FightStage.snow,
  FightStage.glass,
  FightStage.streets,
  FightStage.deck,
};

/// Every anomaly, in the order the lab lists them.
const List<FieldAnomaly> fieldAnomalies = [
  // --- The dry lands ---
  FieldAnomaly(
    id: 'sandstorm',
    family: AnomalyFamily.storm,
    stages: {FightStage.dunes, FightStage.saltFlats, FightStage.glass},
    skies: {WeatherKind.dust},
    skyRule: SkyRule.prefers,
    weight: 3,
    shared: true,
    elements: {'Wind': 1.25, 'Fire': 1.1, 'Water': 0.85},
    perception: 4,
    tick: AnomalyTick(mend: false, percent: 3),
  ),
  FieldAnomaly(
    id: 'heatstroke',
    family: AnomalyFamily.heat,
    stages: {FightStage.dunes, FightStage.saltFlats, FightStage.terraces},
    weight: 2,
    elements: {'Fire': 1.15, 'Ice': 0.85},
    tick: AnomalyTick(mend: false, percent: 4),
  ),
  FieldAnomaly(
    id: 'salt_glare',
    family: AnomalyFamily.light,
    stages: {FightStage.saltFlats, FightStage.dunes},
    shared: true,
    elements: {'Light': 1.25},
    perception: 3,
  ),
  FieldAnomaly(
    id: 'brine_crust',
    family: AnomalyFamily.ground,
    stages: {FightStage.saltFlats},
    sideDamage: 0.85,
  ),
  // --- The sea shore and the heights ---
  FieldAnomaly(
    id: 'sea_storm',
    family: AnomalyFamily.storm,
    stages: {FightStage.waves},
    skies: {WeatherKind.rain},
    skyRule: SkyRule.prefers,
    weight: 2,
    elements: {'Water': 1.3, 'Electricity': 1.3, 'Fire': 0.7},
    perception: 2,
    tick: AnomalyTick(mend: false, percent: 8, one: true),
    favouredBy: {'sea'},
  ),
  FieldAnomaly(
    id: 'fog_bank',
    family: AnomalyFamily.water,
    stages: {FightStage.waves, FightStage.cliffs, FightStage.reeds},
    skies: {WeatherKind.fog},
    skyRule: SkyRule.prefers,
    shared: true,
    elements: {'Fire': 0.9},
    perception: 5,
    favouredBy: {'haunted', 'sea'},
  ),
  FieldAnomaly(
    id: 'racing_tide',
    family: AnomalyFamily.water,
    stages: {FightStage.glass, FightStage.waves},
    elements: {'Water': 1.3},
    tick: AnomalyTick(mend: false, percent: 8, one: true),
    favouredBy: {'sea'},
  ),
  FieldAnomaly(
    id: 'cliff_fall',
    family: AnomalyFamily.ground,
    stages: {FightStage.cliffs},
    sideDamage: 0.85,
    tick: AnomalyTick(mend: false, percent: 6, one: true),
    favouredBy: {'wild'},
  ),
  // --- The burnt lands ---
  FieldAnomaly(
    id: 'ash_storm',
    family: AnomalyFamily.storm,
    stages: {FightStage.ash},
    skies: {WeatherKind.ash},
    skyRule: SkyRule.prefers,
    weight: 3,
    shared: true,
    elements: {'Fire': 1.25, 'Wind': 1.1},
    perception: 3,
    tick: AnomalyTick(mend: false, percent: 3),
  ),
  FieldAnomaly(
    id: 'ember_pits',
    family: AnomalyFamily.heat,
    stages: {FightStage.ash, FightStage.terraces},
    weight: 2,
    elements: {'Fire': 1.15},
    tick: AnomalyTick(mend: false, percent: 6, one: true),
  ),
  FieldAnomaly(
    id: 'scalding_vent',
    family: AnomalyFamily.heat,
    stages: {FightStage.terraces},
    weight: 2,
    elements: {'Fire': 1.1, 'Ice': 0.8},
    tick: AnomalyTick(mend: false, percent: 7, one: true),
  ),
  FieldAnomaly(
    id: 'rockslide',
    family: AnomalyFamily.ground,
    stages: {FightStage.terraces, FightStage.cliffs},
    weight: 2,
    tick: AnomalyTick(mend: false, percent: 12, one: true),
    favouredBy: {'wild', 'ruin'},
  ),
  // --- The wet lands ---
  FieldAnomaly(
    id: 'flash_flood',
    family: AnomalyFamily.water,
    stages: {FightStage.fields, FightStage.reeds, FightStage.cliffs},
    skies: {WeatherKind.rain},
    skyRule: SkyRule.prefers,
    elements: {'Water': 1.3, 'Fire': 0.7},
    sideDamage: 0.85,
  ),
  FieldAnomaly(
    id: 'hailstorm',
    family: AnomalyFamily.storm,
    stages: {FightStage.fields, FightStage.terraces, FightStage.snow},
    skies: {WeatherKind.rain, WeatherKind.snow},
    skyRule: SkyRule.prefers,
    shared: true,
    elements: {'Ice': 1.2},
    perception: 2,
    tick: AnomalyTick(mend: false, percent: 4),
  ),
  FieldAnomaly(
    id: 'sinking_ground',
    family: AnomalyFamily.ground,
    stages: {FightStage.reeds, FightStage.fields},
    skies: {WeatherKind.rain},
    skyRule: SkyRule.prefers,
    sideDamage: 0.8,
  ),
  FieldAnomaly(
    id: 'marsh_lights',
    family: AnomalyFamily.light,
    stages: {FightStage.reeds},
    shared: true,
    elements: {'Light': 1.25, 'Void': 1.25},
    perception: 2,
    favouredBy: {'haunted'},
  ),
  // --- The frozen lands ---
  FieldAnomaly(
    id: 'whiteout',
    family: AnomalyFamily.cold,
    stages: {FightStage.snow},
    skies: {WeatherKind.snow},
    skyRule: SkyRule.prefers,
    weight: 3,
    shared: true,
    elements: {'Ice': 1.25, 'Fire': 0.75, 'Wind': 1.1},
    perception: 5,
  ),
  FieldAnomaly(
    id: 'black_ice',
    family: AnomalyFamily.cold,
    stages: {FightStage.snow},
    weight: 2,
    elements: {'Ice': 1.2},
    tick: AnomalyTick(mend: false, percent: 6),
  ),
  // --- The tear ---
  FieldAnomaly(
    id: 'glass_field',
    family: AnomalyFamily.light,
    stages: {FightStage.glass},
    weight: 3,
    shared: true,
    elements: {'Light': 1.3, 'Electricity': 1.15},
    tick: AnomalyTick(mend: false, percent: 3),
    favouredBy: {'haunted'},
  ),
  // --- Anywhere the sky is open ---
  FieldAnomaly(
    id: 'thunderstorm',
    family: AnomalyFamily.storm,
    stages: {
      FightStage.fields,
      FightStage.waves,
      FightStage.cliffs,
      FightStage.reeds,
      FightStage.terraces,
    },
    skies: {WeatherKind.rain},
    skyRule: SkyRule.requires,
    weight: 3,
    elements: {'Electricity': 1.4, 'Fire': 0.8},
    tick: AnomalyTick(mend: false, percent: 12, one: true),
  ),
  FieldAnomaly(
    id: 'downpour',
    family: AnomalyFamily.storm,
    stages: {
      FightStage.fields,
      FightStage.waves,
      FightStage.cliffs,
      FightStage.reeds,
      FightStage.terraces,
    },
    skies: {WeatherKind.rain},
    skyRule: SkyRule.requires,
    weight: 4,
    shared: true,
    elements: {'Fire': 0.6, 'Water': 1.3, 'Electricity': 1.3},
    perception: 3,
  ),
  FieldAnomaly(
    id: 'tailwind',
    family: AnomalyFamily.storm,
    stages: {
      FightStage.fields,
      FightStage.dunes,
      FightStage.saltFlats,
      FightStage.waves,
      FightStage.cliffs,
      FightStage.snow,
    },
    boon: true,
    sideElements: {'Wind': 1.4},
    sideDamage: 1.1,
  ),
  FieldAnomaly(
    id: 'sunburst',
    family: AnomalyFamily.light,
    stages: _outdoors,
    skies: {WeatherKind.cloud, WeatherKind.rain},
    skyRule: SkyRule.prefers,
    boon: true,
    sideElements: {'Light': 1.3},
    sideDamage: 1.1,
    favouredBy: {'holy'},
  ),
  FieldAnomaly(
    id: 'wellspring',
    family: AnomalyFamily.water,
    stages: {
      FightStage.fields,
      FightStage.reeds,
      FightStage.terraces,
      FightStage.cliffs,
    },
    boon: true,
    tick: AnomalyTick(mend: true, percent: 8),
    favouredBy: {'holy', 'wild'},
  ),
  FieldAnomaly(
    id: 'eclipse',
    family: AnomalyFamily.light,
    stages: _outdoors,
    shared: true,
    elements: {'Light': 0.7, 'Void': 1.3},
    perception: 2,
    favouredBy: {'haunted'},
  ),
  FieldAnomaly(
    id: 'earth_break',
    family: AnomalyFamily.ground,
    stages: {
      FightStage.fields,
      FightStage.dunes,
      FightStage.saltFlats,
      FightStage.ash,
      FightStage.terraces,
      FightStage.cliffs,
      FightStage.reeds,
      FightStage.snow,
      FightStage.glass,
      FightStage.hall,
    },
    weight: 2,
    elements: {'Earth': 1.3},
    tick: AnomalyTick(mend: false, percent: 10, one: true),
    favouredBy: {'underground'},
  ),
  // --- Under a roof ---
  FieldAnomaly(
    id: 'collapse',
    family: AnomalyFamily.ground,
    stages: {FightStage.hall},
    weight: 3,
    tick: AnomalyTick(mend: false, percent: 12, one: true),
    favouredBy: {'ruin', 'underground'},
  ),
  FieldAnomaly(
    id: 'blaze',
    family: AnomalyFamily.heat,
    stages: {FightStage.hall},
    weight: 2,
    shared: true,
    elements: {'Fire': 1.25, 'Ice': 0.85},
    tick: AnomalyTick(mend: false, percent: 3),
    favouredBy: {'stronghold', 'ruin'},
  ),
];

/// The anomaly [id], or null.
FieldAnomaly? fieldAnomalyById(String? id) {
  for (final anomaly in fieldAnomalies) {
    if (anomaly.id == id) return anomaly;
  }
  return null;
}

/// Odds any given fight meets an anomaly at all.
const double fieldAnomalyChance = 0.30;

/// The earliest round an anomaly can break, so the first round is always
/// read before it is changed; and the latest.
const int _anomalyEarliestOnset = 2;
const int _anomalyLatestOnset = 4;

/// The Perception that reads which side an omen falls on: below it the party
/// feels that something is coming and not for whom.
const int anomalyReadsSide = 5;

/// One fight's anomaly: which, on whom, from which round, for how long.
class FieldAnomalyPlan {
  const FieldAnomalyPlan({
    required this.anomaly,
    required this.side,
    required this.onset,
    required this.rounds,
  });

  final FieldAnomaly anomaly;
  final AnomalySide side;

  /// The round it breaks on (the omen is the round before).
  final int onset;
  final int rounds;

  /// The last round it lasts to.
  int get last => onset + rounds - 1;

  AnomalyPhase phaseAt(int round) {
    if (round < onset - 1) return AnomalyPhase.quiet;
    if (round == onset - 1) return AnomalyPhase.omen;
    if (round <= last) return AnomalyPhase.active;
    return AnomalyPhase.over;
  }

  bool isActive(int round) => phaseAt(round) == AnomalyPhase.active;

  /// Whether it is the party that is helped (true), the enemies (false), or
  /// neither in particular (null: both alike).
  bool? get helpsParty {
    if (side == AnomalySide.both) return null;
    return anomaly.boon
        ? side == AnomalySide.party
        : side == AnomalySide.enemies;
  }

  bool _falls(bool onParty) =>
      side == AnomalySide.both ||
      (onParty ? side == AnomalySide.party : side == AnomalySide.enemies);

  /// [damage] after the anomaly (when it is active in [round]) for a hit of
  /// [element] struck by the party ([byParty]) or by an enemy.
  int damage(int damage, String element, {required bool byParty, int? round}) {
    if (damage <= 0) return damage;
    if (round != null && !isActive(round)) return damage;
    var factor = anomaly.elements[element] ?? 1;
    if (anomaly.picksSide && _falls(byParty)) {
      factor *= anomaly.sideElements[element] ?? 1;
      factor *= anomaly.sideDamage;
    }
    if (factor == 1) return damage;
    return max(1, (damage * factor).round());
  }

  /// What is taken off the party's Perception in [round].
  int perceptionPenalty(int round) => isActive(round) ? anomaly.perception : 0;

  /// The ticks of [round]: for each side it falls on, how much it hurts or
  /// mends. Empty when the anomaly does not tick or is not active.
  List<AnomalyTickHit> ticksAt(int round) {
    final tick = anomaly.tick;
    if (tick == null || !isActive(round)) return const [];
    return [
      for (final onParty in const [true, false])
        if (_falls(onParty))
          AnomalyTickHit(
            onParty: onParty,
            mend: tick.mend,
            percent: tick.percent,
            one: tick.one,
          ),
    ];
  }
}

/// A tick falling on one side.
class AnomalyTickHit {
  const AnomalyTickHit({
    required this.onParty,
    required this.mend,
    required this.percent,
    required this.one,
  });

  final bool onParty;
  final bool mend;
  final int percent;
  final bool one;

  /// What it does to someone of [maxHealth]: at least 1.
  int amountFor(int maxHealth) => max(1, (maxHealth * percent / 100).round());
}

enum AnomalyPhase { quiet, omen, active, over }

/// Health left after a tick of [amount] on [health]: wounded, never finished.
int healthAfterHurt(int health, int amount) =>
    max(min(health, 1), health - amount);

/// Rolls this fight's anomaly, or null (the common case). [sky] is the day's
/// weather; a fight with nothing to hit the ground with has no anomaly.
FieldAnomalyPlan? rollFieldAnomaly({
  required FightStage stage,
  required WeatherKind? sky,
  required Random random,
  double chance = fieldAnomalyChance,
  double chanceFactor = 1,
  Set<String> tags = const {},
}) {
  // Danger raises the odds, but never past seven in ten (or the chance asked).
  if (random.nextDouble() >= min(chance * chanceFactor, max(chance, 0.7))) {
    return null;
  }
  return pickFieldAnomaly(stage: stage, sky: sky, random: random, tags: tags);
}

/// An anomaly for [stage] under [sky] among those that fit, whatever the
/// odds of a fight having one; null for a stage and sky none fits.
FieldAnomalyPlan? pickFieldAnomaly({
  required FightStage stage,
  required WeatherKind? sky,
  required Random random,
  Set<String> tags = const {},
}) {
  final weights = [
    for (final anomaly in fieldAnomalies)
      anomaly.weightUnder(stage, sky, tags: tags),
  ];
  final total = weights.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return null;
  var roll = random.nextDouble() * total;
  var chosen = fieldAnomalies.first;
  for (var i = 0; i < fieldAnomalies.length; i++) {
    roll -= weights[i];
    if (weights[i] > 0 && roll < 0) {
      chosen = fieldAnomalies[i];
      break;
    }
  }
  return planFor(chosen, random: random);
}

/// [anomaly] as a plan: the side it falls on (the roll's) and when it breaks.
FieldAnomalyPlan planFor(
  FieldAnomaly anomaly, {
  required Random random,
  AnomalySide? side,
  int? onset,
  int? rounds,
}) {
  return FieldAnomalyPlan(
    anomaly: anomaly,
    side: side ??
        (anomaly.shared
            ? AnomalySide.both
            : random.nextBool()
                ? AnomalySide.party
                : AnomalySide.enemies),
    onset: onset ??
        _anomalyEarliestOnset +
            random.nextInt(_anomalyLatestOnset - _anomalyEarliestOnset + 1),
    rounds: rounds ?? (random.nextInt(5) < 2 ? 3 : 2),
  );
}

/// The plan of a scene whose ground the story or the lab sets: the anomaly
/// [id] from the round after the first, for three rounds, falling on a side
/// the roll picks (or [side]). Null for an id no anomaly has.
FieldAnomalyPlan? forcedFieldAnomaly(String? id,
    {Random? random, AnomalySide? side}) {
  final anomaly = fieldAnomalyById(id);
  if (anomaly == null) return null;
  return planFor(anomaly,
      random: random ?? Random(),
      side: side,
      onset: _anomalyEarliestOnset,
      rounds: 3);
}
