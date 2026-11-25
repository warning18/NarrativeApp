// What the Tower keeps between runs (v1.845, docs/proposals/tower-mechanics.md
// §7): the marks banked, the unlocks bought, and a few counts; what a new
// run may start with.

import 'dart:math';

import 'tower_coins.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

/// The Tower's lasting record.
class TowerProgress {
  const TowerProgress({
    this.marks = 0,
    this.unlocked = const {},
    this.bestFloor = 0,
    this.runs = 0,
    this.wins = 0,
    this.heatWon = -1,
    this.perks = const {},
    this.worn = const [],
    this.trims = const {},
    this.trim,
  });

  factory TowerProgress.fromJson(Map<String, dynamic> json) => TowerProgress(
        marks: (json['marks'] as num?)?.toInt() ?? 0,
        unlocked: {
          for (final u in (json['unlocked'] as List?) ?? const []) u.toString(),
        },
        bestFloor: (json['bestFloor'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        // A save from before Heat (v2.9.0): its wins were all at heat 0, so
        // one with a win opens Heat 1 at once.
        heatWon: ((json['heatWon'] as num?)?.toInt() ??
                (((json['wins'] as num?)?.toInt() ?? 0) > 0 ? 0 : -1))
            .clamp(-1, towerHeatMax),
        // The marks shop (v2.10.0): absent in a save from before, none.
        perks: {
          for (final p in (json['perks'] as List?) ?? const [])
            if (towerPerkOf(p.toString()) != null) p.toString(),
        },
        worn: towerWornPerks([
          for (final p in (json['worn'] as List?) ?? const []) p.toString(),
        ]),
        trims: {
          for (final t in (json['trims'] as List?) ?? const [])
            if (towerTrimOf(t.toString()) != null) t.toString(),
        },
        trim: json['trim']?.toString(),
      );

  /// Marks to spend.
  final int marks;

  /// The unlocks bought (their ids, tower_tables.dart's towerUnlocks).
  final Set<String> unlocked;

  /// The highest floor any run reached.
  final int bestFloor;
  final int runs;
  final int wins;

  /// The highest Heat whose top was won (v2.9.0, TowerRun.heat): -1, none
  /// yet; 0, the plain climb's.
  final int heatWon;

  /// The perks bought (v2.10.0, tower_coins.dart's towerPerks).
  final Set<String> perks;

  /// The perks chosen at the door for the next climbs (owned, at most
  /// towerPerkSlots): what a new run wears ([wornPerks]).
  final List<String> worn;

  /// The banner trims bought (towerTrims; no power). The Ash trim is
  /// earned, not bought: [trimsOwned].
  final Set<String> trims;

  /// The trim shown on the banner, or null (the plain one).
  final String? trim;

  /// Every unlock of the tree is bought: the perks and the trims are for
  /// sale ([canBuyPerk], [canBuyTrim]).
  bool get treeFull => towerUnlocks.every((u) => unlocked.contains(u.id));

  /// The perks a new run wears: those of [worn] still owned.
  List<String> get wornPerks => towerWornPerks([
        for (final p in worn)
          if (perks.contains(p)) p
      ]);

  /// The trims owned: those bought, and Ash's after a win at Heat 5.
  Set<String> get trimsOwned => {
        ...trims,
        if (heatWon >= towerHeatMax) towerAshTrim.id,
      };

  /// Whether perk [id] can be bought now: the tree full, not owned, its
  /// marks in hand.
  bool canBuyPerk(String id) {
    final perk = towerPerkOf(id);
    return perk != null &&
        treeFull &&
        !perks.contains(id) &&
        marks >= perk.cost;
  }

  /// This record with perk [id] bought ([canBuyPerk]), worn at once when a
  /// slot is free; as it is otherwise.
  TowerProgress buyPerk(String id) => canBuyPerk(id)
      ? copyWith(
          marks: marks - towerPerkOf(id)!.cost,
          perks: {...perks, id},
          worn: worn.length < towerPerkSlots ? [...worn, id] : worn,
        )
      : this;

  /// This record wearing [ids] on the next climbs: the owned ones, at most
  /// towerPerkSlots, in order.
  TowerProgress wear(Iterable<String> ids) => copyWith(
          worn: towerWornPerks([
        for (final p in ids)
          if (perks.contains(p)) p
      ]));

  /// This record with perk [id] put on (a free slot, else in place of the
  /// first worn: with one slot, the one worn) or, when worn, taken off. As it is when [id] is not owned.
  TowerProgress toggleWorn(String id) {
    if (!perks.contains(id)) return this;
    if (worn.contains(id)) return wear([...worn]..remove(id));
    final kept = worn.length >= towerPerkSlots ? worn.sublist(1) : worn;
    return wear([...kept, id]);
  }

  /// Whether trim [id] can be bought now: a sold one, the tree full, not
  /// owned, its marks in hand.
  bool canBuyTrim(String id) {
    final trim = towerTrimOf(id);
    return trim != null &&
        trim.cost > 0 &&
        treeFull &&
        !trims.contains(id) &&
        marks >= trim.cost;
  }

  /// This record with trim [id] bought ([canBuyTrim]) and shown; as it is
  /// otherwise.
  TowerProgress buyTrim(String id) => canBuyTrim(id)
      ? copyWith(
          marks: marks - towerTrimOf(id)!.cost,
          trims: {...trims, id},
          trim: id,
        )
      : this;

  /// This record showing trim [id] (one owned, [trimsOwned]), or the plain
  /// banner (null).
  TowerProgress showTrim(String? id) => id == null
      ? copyWith(clearTrim: true)
      : trimsOwned.contains(id)
          ? copyWith(trim: id)
          : this;

  /// The marks still to spend before everything is bought: the tree's
  /// unlocks, the perks and the trims not owned (the pace's "to go").
  int get marksToBuyAll => [
        for (final u in towerUnlocks)
          if (!unlocked.contains(u.id)) u.cost,
        for (final p in towerPerks)
          if (!perks.contains(p.id)) p.cost,
        for (final t in towerTrims)
          if (!trims.contains(t.id)) t.cost,
      ].fold<int>(0, (n, c) => n + c);

  /// The cheapest perk not owned (the end tally's "next perk: n more"), or
  /// null when all are.
  TowerPerk? get nextPerk {
    for (final p in towerPerks) {
      if (!perks.contains(p.id)) return p;
    }
    return null;
  }

  /// The highest Heat a new run may take: one above [heatWon] (Heat n + 1
  /// opens with a win at Heat n), at most towerHeatMax; 0 until the top is
  /// won once. The picker's default.
  int get heatOpen => min(towerHeatMax, heatWon + 1);

  /// The Heats a new run may take: 0 to [heatOpen].
  List<int> get heatsOpen => [for (var h = 0; h <= heatOpen; h++) h];

  /// Whether a new run may take Heat [heat].
  bool isHeatOpen(int heat) => heat >= 0 && heat <= heatOpen;

  /// Whether [id] can be bought now: not owned, its need bought, its cost
  /// in hand.
  bool canBuy(String id) {
    final unlock = towerUnlockOf(id);
    if (unlock == null || unlocked.contains(id)) return false;
    if (unlock.needs != null && !unlocked.contains(unlock.needs)) return false;
    return marks >= unlock.cost;
  }

  /// This record with [id] bought, or as it is when it can't be.
  TowerProgress buy(String id) => canBuy(id)
      ? copyWith(
          marks: marks - towerUnlockOf(id)!.cost,
          unlocked: {...unlocked, id},
        )
      : this;

  /// The first-win bonus ended [run] would add to this record
  /// (towerFirstWinBonusOf: +30 the first win, +20 the first at each Heat).
  int firstWinBonusOf(TowerRun run) =>
      run.isOver ? towerFirstWinBonusOf(run, heatWon) : 0;

  /// This record with ended [run]'s marks banked and counted, with its
  /// first-win bonus ([firstWinBonusOf]). Its coins are not: they end
  /// with it.
  TowerProgress afterRun(TowerRun run) => !run.isOver
      ? this
      : copyWith(
          marks: marks + run.marks + firstWinBonusOf(run),
          bestFloor:
              run.floorReached > bestFloor ? run.floorReached : bestFloor,
          runs: runs + 1,
          wins: wins + (run.status == TowerStatus.won ? 1 : 0),
          heatWon: run.status == TowerStatus.won && run.heat > heatWon
              ? run.heat
              : heatWon,
        );

  /// The professions a new run may take.
  Set<String> get professions => {
        ...towerStartProfessions,
        for (final u in towerUnlocks)
          if (u.kind == TowerUnlockKind.profession && unlocked.contains(u.id))
            u.value,
      };

  /// The clans a new run may be sworn to.
  Set<String> get clans => {
        ...towerStartClans,
        for (final u in towerUnlocks)
          if (u.kind == TowerUnlockKind.clan && unlocked.contains(u.id))
            u.value,
      };

  /// How many unlocks a new run takes the power of (towerHealthPerUnlock,
  /// towerUnlocksPerPotion).
  int get unlocksOwned => unlocked.length;

  /// The start dice and items a new run begins with.
  List<String> get startUnlocks => [
        for (final u in towerUnlocks)
          if ((u.kind == TowerUnlockKind.startDie ||
                  u.kind == TowerUnlockKind.startItem) &&
              unlocked.contains(u.id))
            u.id,
      ];

  TowerProgress copyWith({
    int? marks,
    Set<String>? unlocked,
    int? bestFloor,
    int? runs,
    int? wins,
    int? heatWon,
    Set<String>? perks,
    List<String>? worn,
    Set<String>? trims,
    String? trim,
    bool clearTrim = false,
  }) =>
      TowerProgress(
        marks: marks ?? this.marks,
        unlocked: unlocked ?? this.unlocked,
        bestFloor: bestFloor ?? this.bestFloor,
        runs: runs ?? this.runs,
        wins: wins ?? this.wins,
        heatWon: heatWon ?? this.heatWon,
        perks: perks ?? this.perks,
        worn: worn ?? this.worn,
        trims: trims ?? this.trims,
        trim: clearTrim ? null : trim ?? this.trim,
      );

  Map<String, dynamic> toJson() => {
        'marks': marks,
        if (unlocked.isNotEmpty) 'unlocked': (unlocked.toList()..sort()),
        'bestFloor': bestFloor,
        'runs': runs,
        'wins': wins,
        if (heatWon >= 0) 'heatWon': heatWon,
        if (perks.isNotEmpty) 'perks': (perks.toList()..sort()),
        if (worn.isNotEmpty) 'worn': worn,
        if (trims.isNotEmpty) 'trims': (trims.toList()..sort()),
        if (trim != null) 'trim': trim,
      };
}

/// Every unlock bought (the balance batch's "all unlocks" case).
TowerProgress get towerAllUnlocked =>
    TowerProgress(unlocked: {for (final u in towerUnlocks) u.id});
