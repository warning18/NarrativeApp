import 'dart:math';

/// The sea's great beasts (v1.185): Old Brinejaw, the Pale Leviathan and
/// the Tide-Mother, each an enemy_ships.json record with a `beast` block.
/// A beast is no raider: it roams its own waters, heals between blows,
/// dives under the Eel, and turns for the deep when it is hurt. The first
/// meeting is one to survive; every meeting after teaches the crew its
/// ways, and the wounds it takes stay with it. With enough signs of it
/// ([cluesNeeded]) the Harbor can send the Eel out to hunt it on her own
/// terms, a harpoon on the rail to hold it (see ShipWeapon.tetherRounds).
///
/// Pure rules: the battle side is [BeastProfile] (see ShipBattle.beast);
/// the hunt's side, what the session keeps of each beast, is
/// [BeastState].

/// What a beast does in battle beyond its weapons.
class BeastProfile {
  const BeastProfile({
    this.regen = 0,
    this.diveEvery = 0,
    this.breach = 0,
    this.fleeShare = 0.3,
    this.edge = 0,
  });

  /// The profile off an enemy_ships.json record's `beast` block, with the
  /// crew's [edge] against it.
  factory BeastProfile.fromRecord(Map<String, dynamic> record, {int edge = 0}) {
    final spec = beastSpecOf(record);
    return BeastProfile(
      regen: max(0, (spec['regen'] as num?)?.toInt() ?? 0),
      diveEvery: max(0, (spec['diveEvery'] as num?)?.toInt() ?? 0),
      breach: max(0, (spec['breach'] as num?)?.toInt() ?? 0),
      fleeShare:
          ((spec['fleeShare'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0),
      edge: max(0, edge),
    );
  }

  /// Hull it heals at the end of every round while its heart works and no
  /// harpoon holds it.
  final int regen;

  /// It dives every this many rounds (0: never): no volley that round, and
  /// it comes up under the Eel for [breach] hull and a leak.
  final int diveEvery;
  final int breach;

  /// At this share of its hull or less it turns for the deep, and the
  /// next round it is gone unless a harpoon holds it or its fins are out.
  final double fleeShare;

  /// Evasion the crew takes off it: they have met it before, or they
  /// came hunting (see [beastEdge]).
  final int edge;
}

/// The record's `beast` block (empty for a ship).
Map<String, dynamic> beastSpecOf(Map<String, dynamic>? record) {
  final spec = record?['beast'];
  return spec is Map ? Map<String, dynamic>.from(spec) : const {};
}

/// True for a beast's record: it never sails as a raider.
bool isBeastRecord(Map<String, dynamic>? record) => record?['beast'] is Map;

/// Every beast in enemy_ships.json, in the order they are met.
List<String> beastIdsIn(Map<String, dynamic> enemyShips) {
  final ids = [
    for (final e in enemyShips.entries)
      if (isBeastRecord(e.value as Map<String, dynamic>?)) e.key,
  ];
  int first(String id) =>
      beastWaters(enemyShips[id] as Map<String, dynamic>).reduce(min);
  ids.sort((a, b) {
    final byWaters = first(a).compareTo(first(b));
    return byWaters != 0 ? byWaters : a.compareTo(b);
  });
  return ids;
}

/// The chapters of the waters a beast roams (a crossing's chapter, see
/// VoyageScreen): its `waters` list, or its first chapter alone.
List<int> beastWaters(Map<String, dynamic> record) {
  final raw = beastSpecOf(record)['waters'];
  final waters = raw is List
      ? [for (final w in raw) (w as num).toInt()]
      : <int>[(record['minChapter'] as num?)?.toInt() ?? 1];
  return waters.isEmpty ? [1] : waters;
}

/// The item every slain beast leaves besides its part: a trophy to sell
/// or keep (items.json).
const String beastTrophyItemId = 'boss_trophy';

/// The ship part a slain beast leaves (a trophy fitted for free).
String? beastTrophyPartId(Map<String, dynamic> record) {
  final id = beastSpecOf(record)['trophyPartId']?.toString() ?? '';
  return id.isEmpty ? null : id;
}

/// What the session keeps of one beast.
class BeastState {
  const BeastState({
    this.seen = false,
    this.clues = 0,
    this.wounds = 0,
    this.encounters = 0,
    this.slain = false,
  });

  factory BeastState.fromJson(Map<String, dynamic> json) => BeastState(
        seen: json['seen'] == true,
        clues: (json['clues'] as num?)?.toInt() ?? 0,
        wounds: (json['wounds'] as num?)?.toInt() ?? 0,
        encounters: (json['encounters'] as num?)?.toInt() ?? 0,
        slain: json['slain'] == true,
      );

  /// The crew has laid eyes on it: the Harbor lists it.
  final bool seen;

  /// Signs of where it lairs, up to [cluesNeeded]; a hunt spends them.
  final int clues;

  /// Hull it has lost and not healed (at most [maxWoundShare] of it).
  final int wounds;

  /// Battles with it fought out and lived through (see [beastAfterBattle]):
  /// each teaches the crew its ways.
  final int encounters;
  final bool slain;

  /// Being tracked: seen and still out there.
  bool get tracked => seen && !slain;

  bool get huntReady => tracked && clues >= cluesNeeded;

  BeastState copyWith({
    bool? seen,
    int? clues,
    int? wounds,
    int? encounters,
    bool? slain,
  }) =>
      BeastState(
        seen: seen ?? this.seen,
        clues: (clues ?? this.clues).clamp(0, cluesNeeded),
        wounds: max(0, wounds ?? this.wounds),
        encounters: encounters ?? this.encounters,
        slain: slain ?? this.slain,
      );

  Map<String, dynamic> toJson() => {
        'seen': seen,
        'clues': clues,
        'wounds': wounds,
        'encounters': encounters,
        'slain': slain,
      };
}

/// Signs of a beast the Harbor needs before it can send the Eel hunting.
const int cluesNeeded = 3;

/// A crossing's odds of meeting a beast that roams its waters.
const double beastEncounterChance = 0.25;

/// The odds while a beast not yet seen roams these waters as the first it
/// roams: it is first met there, not a chapter later. (The Brinejaw's
/// chapter-3 waters are crossed only once or twice before chapter 4's.)
const double firstWatersEncounterChance = 0.5;

/// A beast never starts a battle below this share of its hull lost: what
/// it cannot heal of its wounds, it has learned to carry.
const double maxWoundShare = 0.5;

/// Evasion taken off a beast for each battle fought with it, at most
/// [maxEncounterEdge]; a hunt, on ground the crew chose, adds [huntEdge].
const int edgePerEncounter = 5;
const int maxEncounterEdge = 15;
const int huntEdge = 10;

/// The DC bonus of outrunning a beast (it is faster than any raider).
const int beastOutrunDcBonus = 2;

/// The hull a failed run from a beast costs: it rams the Eel's quarter.
const int beastOutrunFailHullLoss = 14;

/// A derelict in a tracked beast's waters, boarded, shows its marks this
/// often (a sign of it).
const double derelictClueChance = 0.4;

/// The crew's edge against a beast met in [state] ([hunt]: they came for
/// it).
int beastEdge(BeastState state, {required bool hunt}) =>
    min(maxEncounterEdge, edgePerEncounter * state.encounters) +
    (hunt ? huntEdge : 0);

/// The hull a beast of [maxHull] starts a battle with, carrying [state]'s
/// wounds.
int beastStartHull(int maxHull, BeastState state) => max(
    maxHull - (maxHull * maxWoundShare).round(),
    maxHull - max(0, state.wounds));

/// The wounds a beast of [maxHull] carries away from a battle it ended
/// with [hullAtEnd].
int woundsAfter({required int maxHull, required int hullAtEnd}) =>
    max(0, min((maxHull * maxWoundShare).round(), maxHull - hullAtEnd));

/// [state] after a battle the beast ended with [hullAtEnd] of [maxHull]
/// ([slain]: it went down). It keeps the wounds it took. A battle fought
/// out and lived through is a sign of it and teaches the crew its ways;
/// one the Eel ran from or sank in ([learned] false) teaches nothing.
BeastState beastAfterBattle(
  BeastState state, {
  required int maxHull,
  required int hullAtEnd,
  required bool slain,
  bool learned = true,
}) =>
    state.copyWith(
      seen: true,
      encounters: state.encounters + (learned ? 1 : 0),
      slain: slain || state.slain,
      clues: slain ? 0 : state.clues + (learned ? 1 : 0),
      wounds: slain ? 0 : woundsAfter(maxHull: maxHull, hullAtEnd: hullAtEnd),
    );

/// The beast met on a crossing at [chapter], or null: one that roams those
/// waters and still lives, [beastEncounterChance] of the time
/// ([firstWatersEncounterChance] while one not yet seen roams them first).
String? rollBeastEncounter({
  required Random random,
  required Map<String, dynamic> enemyShips,
  required int chapter,
  required Map<String, BeastState> beasts,
}) {
  final roaming = [
    for (final id in beastIdsIn(enemyShips))
      if (!(beasts[id]?.slain ?? false) &&
          beastWaters(enemyShips[id] as Map<String, dynamic>).contains(chapter))
        id,
  ];
  final firstLook = roaming.any((id) =>
      !(beasts[id]?.seen ?? false) &&
      beastWaters(enemyShips[id] as Map<String, dynamic>).reduce(min) ==
          chapter);
  final chance = firstLook ? firstWatersEncounterChance : beastEncounterChance;
  if (roaming.isEmpty || random.nextDouble() >= chance) return null;
  return roaming[random.nextInt(roaming.length)];
}

/// A tracked beast whose waters [chapter] is, for a sign found at sea (a
/// wreck with its marks, a shape under the keel), or null.
String? trackedBeastIn({
  required Map<String, dynamic> enemyShips,
  required int chapter,
  required Map<String, BeastState> beasts,
}) {
  for (final id in beastIdsIn(enemyShips)) {
    final state = beasts[id];
    if (state == null || !state.tracked || state.clues >= cluesNeeded) {
      continue;
    }
    if (beastWaters(enemyShips[id] as Map<String, dynamic>).contains(chapter)) {
      return id;
    }
  }
  return null;
}
