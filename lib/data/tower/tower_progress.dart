// What the Tower keeps between runs (v1.845, docs/proposals/tower-mechanics.md
// §7): the marks banked, the unlocks bought, and a few counts; what a new
// run may start with.

import 'dart:math';

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

  /// This record with ended [run]'s marks banked and counted.
  TowerProgress afterRun(TowerRun run) => !run.isOver
      ? this
      : copyWith(
          marks: marks + run.marks,
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
  }) =>
      TowerProgress(
        marks: marks ?? this.marks,
        unlocked: unlocked ?? this.unlocked,
        bestFloor: bestFloor ?? this.bestFloor,
        runs: runs ?? this.runs,
        wins: wins ?? this.wins,
        heatWon: heatWon ?? this.heatWon,
      );

  Map<String, dynamic> toJson() => {
        'marks': marks,
        if (unlocked.isNotEmpty) 'unlocked': (unlocked.toList()..sort()),
        'bestFloor': bestFloor,
        'runs': runs,
        'wins': wins,
        if (heatWon >= 0) 'heatWon': heatWon,
      };
}

/// Every unlock bought (the balance batch's "all unlocks" case).
TowerProgress get towerAllUnlocked =>
    TowerProgress(unlocked: {for (final u in towerUnlocks) u.id});
