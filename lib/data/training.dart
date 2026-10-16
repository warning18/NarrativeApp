// Stat picks at level-up (docs/proposals/stat-picks.md, and the scale of
// docs/proposals/stat-scale.md): each level brings one **pick** (a Tome of
// Insight one more): three offers, each an ability a training path
// (training_paths.json, a bundle of abilities toward a playstyle) leans to
// -- the calling, the habit and a turn -- and the character takes one. The
// pick's **rarity** is drawn once for all three (Common +1, Rare +2, Epic
// +3, Heroic +4, Luck raising the odds). There is no "decide later": a pick
// stays on the table until taken.
//
// Pure, and takes a Random like offers.dart; the session keeps the pick on
// the table and the paths taken, and applies the gains.
import 'dart:math';

import 'signs.dart' show SignRarity;

/// How many offers a pick brings.
const int statPickOfferCount = 3;

/// The abilities a path's gains may name (the session's own names). Base
/// damage and health are not offered: the damage stat and Constitution
/// raise them (stat_rules.dart).
const List<String> trainingStats = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// The points [gains] are worth: one a point of an ability.
int trainingPointsOf(Map<String, int> gains) =>
    gains.values.fold(0, (sum, v) => sum + v);

/// A path (training_paths.json).
class TrainingPath {
  const TrainingPath({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.blurb = '',
    this.blurbFr = '',
    this.icon = '',
    this.gains = const {},
    this.professions = const [],
    this.races = const [],
  });

  factory TrainingPath.fromJson(String id, Map raw) => TrainingPath(
        id: id,
        name: raw['name']?.toString() ?? id,
        nameFr: raw['name_fr']?.toString() ?? '',
        blurb: raw['blurb']?.toString() ?? '',
        blurbFr: raw['blurb_fr']?.toString() ?? '',
        icon: raw['icon']?.toString() ?? '',
        gains: {
          for (final MapEntry(:key, :value)
              in ((raw['gains'] as Map?) ?? const {}).entries)
            if (value is num) key.toString(): value.toInt(),
        },
        professions: [
          for (final p in (raw['professions'] as List? ?? const []))
            p.toString()
        ],
        races: [
          for (final r in (raw['races'] as List? ?? const [])) r.toString()
        ],
      );

  final String id;
  final String name;
  final String nameFr;
  final String blurb;
  final String blurbFr;
  final String icon;

  /// The stats it raises and by how much (see [trainingStats]).
  final Map<String, int> gains;

  /// The professions and races it leans to: only the draw's weights.
  final List<String> professions;
  final List<String> races;

  String nameFor(bool fr) => fr && nameFr.isNotEmpty ? nameFr : name;
  String blurbFor(bool fr) => fr && blurbFr.isNotEmpty ? blurbFr : blurb;

  bool leansTo({String? professionId, String? raceId}) =>
      professions.contains(professionId) || races.contains(raceId);
}

/// Every path of training_paths.json's [raw], by id, in the file's order.
Map<String, TrainingPath> trainingPathsFrom(Map<String, dynamic> raw) => {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is Map) key: TrainingPath.fromJson(key, value),
    };

/// The three paths of a pick, in order: **the calling** (one leaning to
/// [professionId] or [raceId], weighted toward those [taken] before), **the
/// habit** (the path taken most, else the one closest to [stats]) and **a
/// turn** (any other).
List<TrainingPath> _drawThree({
  required List<TrainingPath> paths,
  required Random random,
  String? professionId,
  String? raceId,
  Map<String, int> taken = const {},
  Map<String, int> stats = const {},
}) {
  final chosen = <TrainingPath>[];
  final all = paths;
  List<TrainingPath> left() => [
        for (final p in all)
          if (!chosen.contains(p)) p
      ];

  // The calling: a path of the profession or the people, the ones taken
  // before likelier.
  final calling = [
    for (final p in all)
      if (p.leansTo(professionId: professionId, raceId: raceId)) p
  ];
  chosen.add(_weighted(calling.isEmpty ? all : calling,
      (p) => 1.0 + 2 * (taken[p.id] ?? 0), random));

  // The habit: the path taken most; with none taken, the one whose gains
  // follow the stats the character has most of.
  double affinity(TrainingPath p) => p.gains.entries
      .fold(0.0, (sum, e) => sum + e.value * (stats[e.key] ?? 0));
  final rest = left();
  rest.sort((a, b) {
    final t = (taken[b.id] ?? 0).compareTo(taken[a.id] ?? 0);
    if (t != 0) return t;
    final f = affinity(b).compareTo(affinity(a));
    return f != 0 ? f : a.id.compareTo(b.id);
  });
  chosen.add(rest.first);

  // A turn: any other, so a build can change course.
  final others = left();
  chosen.add(others[random.nextInt(others.length)]);
  return chosen;
}

// --- Stat picks (docs/proposals/stat-picks.md) ------------------------------
//
// The paths of a pick are drawn as above (_drawThree); each offers one of
// its abilities, at the pick's rarity.

/// The points a pick of [tier] gives: Common 1, Rare 2, Epic 3, Heroic 4.
int statPickPointsOf(SignRarity tier) => tier.index + 1;

/// The odds (out of 100) of each rarity of a pick, before Luck.
const Map<SignRarity, double> statPickBaseOdds = {
  SignRarity.common: 90,
  SignRarity.rare: 8,
  SignRarity.epic: 1.6,
  SignRarity.heroic: 0.4,
};

/// Each point of Luck, up to this many, moves 1% of a pick's odds from
/// Common up: [statPickLuckShares] of it to each rarer tier.
const int statPickLuckCap = 15;
const Map<SignRarity, double> statPickLuckShares = {
  SignRarity.rare: 0.6,
  SignRarity.epic: 0.3,
  SignRarity.heroic: 0.1,
};

/// The odds (out of 100) of each rarity of a pick for a character with
/// [luck] (statPickBaseOdds moved by statPickLuckShares).
Map<SignRarity, double> statPickOdds(int luck) {
  final l = luck.clamp(0, statPickLuckCap).toDouble();
  return {
    SignRarity.common: statPickBaseOdds[SignRarity.common]! - l,
    for (final tier in [SignRarity.rare, SignRarity.epic, SignRarity.heroic])
      tier: statPickBaseOdds[tier]! + l * statPickLuckShares[tier]!,
  };
}

/// The points a pick is worth on average for a character with [luck].
double statPickExpectedPoints(int luck) => statPickOdds(luck)
    .entries
    .fold(0.0, (sum, e) => sum + e.value / 100 * statPickPointsOf(e.key));

/// A pick's rarity, drawn for a character with [luck].
SignRarity drawStatPickTier(int luck, Random random) {
  final odds = statPickOdds(luck);
  var roll = random.nextDouble() * 100;
  for (final tier in [SignRarity.heroic, SignRarity.epic, SignRarity.rare]) {
    roll -= odds[tier]!;
    if (roll < 0) return tier;
  }
  return SignRarity.common;
}

/// One offer of a pick: [gains] from [pathId] (its ability, and at Rare or
/// better maybe a second), worth [points] -- what its [tier] gives.
class StatPickOffer {
  const StatPickOffer(
      {required this.pathId,
      required this.gains,
      this.tier = SignRarity.common});

  /// A saved offer; one saved as `rare: true` (before the four rarities)
  /// reads as Rare.
  factory StatPickOffer.fromJson(Map raw) => StatPickOffer(
        pathId: raw['path']?.toString() ?? '',
        gains: {
          for (final MapEntry(:key, :value)
              in ((raw['gains'] as Map?) ?? const {}).entries)
            if (value is num) key.toString(): value.toInt(),
        },
        tier: SignRarity.values
                .where((t) => t.name == raw['tier']?.toString())
                .firstOrNull ??
            (raw['rare'] == true ? SignRarity.rare : SignRarity.common),
      );

  final String pathId;
  final Map<String, int> gains;
  final SignRarity tier;

  /// Rarer than Common.
  bool get rare => tier != SignRarity.common;

  /// What it is worth: one a point of each ability it raises.
  int get points => trainingPointsOf(gains);

  /// The ability it is offered for (the first of its gains).
  String get stat => gains.keys.isEmpty ? '' : gains.keys.first;

  Map<String, dynamic> toJson() => {
        'path': pathId,
        'gains': gains,
        if (tier != SignRarity.common) 'tier': tier.name,
      };

  @override
  bool operator ==(Object other) =>
      other is StatPickOffer &&
      other.pathId == pathId &&
      other.tier == tier &&
      other.gains.length == gains.length &&
      other.gains.entries.every((e) => gains[e.key] == e.value);

  @override
  int get hashCode => Object.hash(pathId, tier, gains.length);
}

/// The gains of an offer of [stat] at [tier], [second] being another
/// ability of its path ('' for none): Common +1; Rare +2, or +1 and +1 to
/// [second] ([split]); Epic +2 and +1 to [second]; Heroic +2 and +2 to
/// [second]. Without a second, every point goes to [stat].
Map<String, int> statPickGains(String stat, SignRarity tier,
    {String second = '', bool split = false}) {
  final points = statPickPointsOf(tier);
  if (second.isEmpty || second == stat || tier == SignRarity.common) {
    return {stat: points};
  }
  final own = switch (tier) {
    SignRarity.rare => split ? 1 : 2,
    _ => 2,
  };
  return {stat: own, if (points > own) second: points - own};
}

/// Draws a pick for a character with [luck]: **the calling**, **the
/// habit** and **a turn**, their paths drawn by _drawThree, each offering
/// one of its path's abilities, drawn by its weight in the path. No two
/// offers show the same ability: the ability is drawn again within the
/// path first, then the path. The pick's rarity (drawStatPickTier) is drawn
/// once and every offer shows it, a second ability of its path coming with
/// the rarer ones (statPickGains). Empty when fewer than three paths with
/// gains exist.
List<StatPickOffer> drawStatPick({
  required Map<String, TrainingPath> paths,
  required Random random,
  String? professionId,
  String? raceId,
  int luck = 0,
  Map<String, int> taken = const {},
  Map<String, int> stats = const {},
}) {
  final usable = [
    for (final p in paths.values)
      if (p.gains.isNotEmpty) p
  ];
  if (usable.length < statPickOfferCount) return const [];
  final chosen = _drawThree(
      paths: usable,
      random: random,
      professionId: professionId,
      raceId: raceId,
      taken: taken,
      stats: stats);
  double size(MapEntry<String, int> e) => max(1, e.value).toDouble();
  final used = <String>{};
  final picked = <TrainingPath>[];
  final gainOf = <String>[];
  for (var i = 0; i < chosen.length; i++) {
    var path = chosen[i];
    List<MapEntry<String, int>> fresh(TrainingPath p) => [
          for (final e in p.gains.entries)
            if (!used.contains(e.key)) e
        ];
    if (fresh(path).isEmpty) {
      // Every gain of the path is shown already: another path instead.
      final others = [
        for (final p in usable)
          if (!chosen.contains(p) && !picked.contains(p) && fresh(p).isNotEmpty)
            p
      ];
      if (others.isEmpty) return const [];
      path = others[random.nextInt(others.length)];
    }
    final gain = _weighted(fresh(path), size, random);
    used.add(gain.key);
    picked.add(path);
    gainOf.add(gain.key);
  }
  final tier = drawStatPickTier(luck, random);
  return [
    for (var i = 0; i < picked.length; i++)
      () {
        final rest = [
          for (final e in picked[i].gains.entries)
            if (e.key != gainOf[i]) e
        ];
        final second = tier == SignRarity.common || rest.isEmpty
            ? ''
            : _weighted(rest, size, random).key;
        final split = tier == SignRarity.rare && random.nextBool();
        return StatPickOffer(
            pathId: picked[i].id,
            gains: statPickGains(gainOf[i], tier, second: second, split: split),
            tier: tier);
      }(),
  ];
}

/// The abilities a build takes when its own stat is not offered, in order
/// (statPickFor).
const List<String> statPickPriority = ['constitution', 'dexterity', 'luck'];

/// The offer of [offer] a build after [stat] takes (autoplay's policy): the
/// first offer raising [stat], else [priority]'s first ability offered,
/// the one giving it most first; else the calling (the first).
int statPickFor(List<StatPickOffer> offer, String stat,
    {List<String> priority = statPickPriority}) {
  for (final want in [stat, ...priority]) {
    var best = -1;
    for (var i = 0; i < offer.length; i++) {
      if (!offer[i].gains.containsKey(want)) continue;
      if (best < 0 || offer[i].gains[want]! > offer[best].gains[want]!) {
        best = i;
      }
    }
    if (best >= 0) return best;
  }
  return 0;
}

/// The offer of [offer] a build that keeps its abilities in [shares]
/// (ability -> share of the points, e.g. Str 0.6, Con 0.3) takes, having
/// put [taken] points into each so far (the simulator's policy): the one
/// whose ability is furthest below its share; else the calling (the first).
int statPickForShares(List<StatPickOffer> offer, Map<String, double> shares,
    Map<String, int> taken) {
  final total = taken.values.fold<int>(0, (a, b) => a + b) + 1;
  var best = 0;
  var bestGap = double.negativeInfinity;
  for (var i = 0; i < offer.length; i++) {
    final share = shares[offer[i].stat];
    if (share == null) continue;
    final gap = share - (taken[offer[i].stat] ?? 0) / total;
    if (gap > bestGap) {
      bestGap = gap;
      best = i;
    }
  }
  return best;
}

T _weighted<T>(List<T> items, double Function(T) weight, Random random) {
  final total = items.fold<double>(0, (s, i) => s + weight(i));
  var roll = random.nextDouble() * total;
  for (final item in items) {
    roll -= weight(item);
    if (roll < 0) return item;
  }
  return items.last;
}
