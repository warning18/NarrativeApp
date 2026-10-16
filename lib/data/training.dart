// Training at level-up (Wave 7, docs/proposals/level-up-offers.md): the stat
// points a level brings are no longer spread one by one. Each level's five
// points are a **training offer**: three paths, each a bundle of stat gains
// toward a playstyle (training_paths.json), and the character takes one. A
// point short of a full offer (a Tome of Insight's) is a **small offer**: three
// single gains, each from a likely path. There is no "decide later": the offer
// stays on the table until something is taken.
//
// Stat picks (below) replace both: each point is one pick of three offers.
//
// Pure, and takes a Random like offers.dart; the session keeps the offer on
// the table and the paths taken, and applies the gains.
import 'dart:math';

/// The points a full training offer is worth: what a level brings.
const int trainingFullPoints = 5;

/// How many choices an offer brings.
const int trainingChoiceCount = 3;

/// The stats a path's gains may name (the session's own names).
const List<String> trainingStats = [
  'baseDamage',
  'baseArmor',
  'maxHealth',
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// What one point buys of [stat]: 10 max health, 1 of anything else (the
/// exchange the free stat points had).
int trainingUnitOf(String stat) => stat == 'maxHealth' ? 10 : 1;

/// The points [gains] are worth at that exchange.
int trainingPointsOf(Map<String, int> gains) =>
    gains.entries.fold(0, (sum, e) => sum + e.value ~/ trainingUnitOf(e.key));

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

  /// Its biggest gain as a single point: what it brings to a small offer.
  MapEntry<String, int> get leadGain {
    var best = gains.entries.first;
    for (final e in gains.entries) {
      if (e.value ~/ trainingUnitOf(e.key) >
          best.value ~/ trainingUnitOf(best.key)) {
        best = e;
      }
    }
    return MapEntry(best.key, trainingUnitOf(best.key));
  }
}

/// Every path of training_paths.json's [raw], by id, in the file's order.
Map<String, TrainingPath> trainingPathsFrom(Map<String, dynamic> raw) => {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is Map) key: TrainingPath.fromJson(key, value),
    };

/// One choice of an offer: the gains of [pathId] (all of them in a full
/// offer, its lead gain in a small one), worth [points].
class TrainingChoice {
  const TrainingChoice(
      {required this.pathId, required this.gains, required this.points});

  factory TrainingChoice.fromJson(Map raw) => TrainingChoice(
        pathId: raw['path']?.toString() ?? '',
        gains: {
          for (final MapEntry(:key, :value)
              in ((raw['gains'] as Map?) ?? const {}).entries)
            if (value is num) key.toString(): value.toInt(),
        },
        points: (raw['points'] as num?)?.toInt() ?? 0,
      );

  final String pathId;
  final Map<String, int> gains;
  final int points;

  /// A small offer's choice (one point).
  bool get small => points < trainingFullPoints;

  Map<String, dynamic> toJson() =>
      {'path': pathId, 'gains': gains, 'points': points};

  @override
  bool operator ==(Object other) =>
      other is TrainingChoice &&
      other.pathId == pathId &&
      other.points == points &&
      other.gains.length == gains.length &&
      other.gains.entries.every((e) => gains[e.key] == e.value);

  @override
  int get hashCode => Object.hash(pathId, points, gains.length);
}

/// The offer [points] (the character's unspent points) calls for: a full one
/// while five are there, a small one for fewer, none for none.
bool trainingDue(int points) => points > 0;

/// Draws an offer for a character with [points] unspent: three different
/// paths -- **the calling** (one leaning to [professionId] or [raceId],
/// weighted toward those [taken] before), **the habit** (the path taken
/// most, else the one closest to the character's [stats]), and **a turn**
/// (any other) -- as their full gains when [points] reaches a full offer,
/// else as their lead gains (a small offer). Empty when nothing is due or
/// fewer than three paths exist.
List<TrainingChoice> drawTraining({
  required Map<String, TrainingPath> paths,
  required int points,
  required Random random,
  String? professionId,
  String? raceId,
  Map<String, int> taken = const {},
  Map<String, int> stats = const {},
}) {
  if (!trainingDue(points) || paths.length < trainingChoiceCount) {
    return const [];
  }
  final chosen = _drawThree(
      paths: paths.values.toList(),
      random: random,
      professionId: professionId,
      raceId: raceId,
      taken: taken,
      stats: stats);
  final full = points >= trainingFullPoints;
  return [
    for (final p in chosen)
      full
          ? TrainingChoice(
              pathId: p.id, gains: p.gains, points: trainingPointsOf(p.gains))
          : TrainingChoice(
              pathId: p.id, gains: Map.fromEntries([p.leadGain]), points: 1),
  ];
}

/// The three paths of an offer, in order: **the calling** (one leaning to
/// [professionId] or [raceId], weighted toward those [taken] before), **the
/// habit** (the path taken most, else the one closest to [stats]) and **a
/// turn** (any other). With [keyOf], the habit and the turn also skip a path
/// whose key one already chosen has (a pick's lead gain), when another is
/// left.
List<TrainingPath> _drawThree({
  required List<TrainingPath> paths,
  required Random random,
  String? professionId,
  String? raceId,
  Map<String, int> taken = const {},
  Map<String, int> stats = const {},
  Object? Function(TrainingPath)? keyOf,
}) {
  final chosen = <TrainingPath>[];
  final all = paths;
  List<TrainingPath> left() {
    final rest = [
      for (final p in all)
        if (!chosen.contains(p)) p
    ];
    if (keyOf == null) return rest;
    final keys = {for (final c in chosen) keyOf(c)};
    final fresh = [
      for (final p in rest)
        if (!keys.contains(keyOf(p))) p
    ];
    return fresh.isEmpty ? rest : fresh;
  }

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
  double affinity(TrainingPath p) => p.gains.entries.fold(
      0.0,
      (sum, e) =>
          sum +
          (e.value / trainingUnitOf(e.key)) *
              ((stats[e.key] ?? 0) / trainingUnitOf(e.key)));
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
// Each stat point is a **pick**: three one-point offers, each a path's lead
// gain -- the calling, the habit and a turn, drawn as above -- and the
// character takes one. Now and then the turn is a **rare** offer worth two
// points. Like a training offer, a pick stays on the table until taken.

/// The chance that a pick's turn is a rare offer, worth two points.
const double statPickRareChance = 0.12;

/// One offer of a pick: [gains] from [pathId] (one entry, or two for a rare
/// offer of two stats), worth [points]; [rare] for the two-point offer.
class StatPickOffer {
  const StatPickOffer(
      {required this.pathId, required this.gains, this.rare = false});

  factory StatPickOffer.fromJson(Map raw) => StatPickOffer(
        pathId: raw['path']?.toString() ?? '',
        gains: {
          for (final MapEntry(:key, :value)
              in ((raw['gains'] as Map?) ?? const {}).entries)
            if (value is num) key.toString(): value.toInt(),
        },
        rare: raw['rare'] == true,
      );

  final String pathId;
  final Map<String, int> gains;
  final bool rare;

  /// What it is worth at the exchange (trainingUnitOf): 1, or 2 when rare.
  int get points => trainingPointsOf(gains);

  Map<String, dynamic> toJson() =>
      {'path': pathId, 'gains': gains, if (rare) 'rare': true};

  @override
  bool operator ==(Object other) =>
      other is StatPickOffer &&
      other.pathId == pathId &&
      other.rare == rare &&
      other.gains.length == gains.length &&
      other.gains.entries.every((e) => gains[e.key] == e.value);

  @override
  int get hashCode => Object.hash(pathId, rare, gains.length);
}

/// Draws a pick: the lead gains (one point each) of **the calling**, **the
/// habit** and **a turn**, as drawTraining draws its paths, with no two
/// offers showing the same gain. With [statPickRareChance] the turn is a
/// rare two-point offer instead: its lead gain doubled, or its two biggest
/// gains at one point each (half and half; doubled for a path of one
/// gain). Empty when fewer than three paths with gains exist.
List<StatPickOffer> drawStatPick({
  required Map<String, TrainingPath> paths,
  required Random random,
  String? professionId,
  String? raceId,
  Map<String, int> taken = const {},
  Map<String, int> stats = const {},
}) {
  final usable = [
    for (final p in paths.values)
      if (p.gains.isNotEmpty) p
  ];
  if (usable.length < trainingChoiceCount) return const [];
  final chosen = _drawThree(
      paths: usable,
      random: random,
      professionId: professionId,
      raceId: raceId,
      taken: taken,
      stats: stats,
      keyOf: (p) => p.leadGain.key);
  final offers = [
    for (final p in chosen)
      StatPickOffer(pathId: p.id, gains: Map.fromEntries([p.leadGain])),
  ];
  if (random.nextDouble() < statPickRareChance) {
    final turn = chosen.last;
    final lead = turn.leadGain;
    final doubled = turn.gains.length < 2 || random.nextBool();
    final Map<String, int> gains;
    if (doubled) {
      gains = {lead.key: 2 * lead.value};
    } else {
      final second =
          (turn.gains.entries.where((e) => e.key != lead.key).toList()
                ..sort((a, b) => (b.value ~/ trainingUnitOf(b.key))
                    .compareTo(a.value ~/ trainingUnitOf(a.key))))
              .first
              .key;
      gains = {lead.key: lead.value, second: trainingUnitOf(second)};
    }
    offers.last = StatPickOffer(pathId: turn.id, gains: gains, rare: true);
  }
  return offers;
}

/// The offer of [offer] a build after [stat] takes (the simulator's and
/// autoplay's policy): one raising [stat], the rare one first, else the
/// calling (the first).
int statPickFor(List<StatPickOffer> offer, String stat) {
  var best = -1;
  for (var i = 0; i < offer.length; i++) {
    if (!offer[i].gains.containsKey(stat)) continue;
    if (best < 0 || (offer[i].rare && !offer[best].rare)) best = i;
  }
  return best < 0 ? 0 : best;
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
