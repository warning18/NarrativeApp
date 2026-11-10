// What the Tower keeps between runs (v1.845, docs/proposals/tower-mechanics.md
// §7): the marks banked, the unlocks bought, and a few counts; what a new
// run may start with.

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
  });

  factory TowerProgress.fromJson(Map<String, dynamic> json) => TowerProgress(
        marks: (json['marks'] as num?)?.toInt() ?? 0,
        unlocked: {
          for (final u in (json['unlocked'] as List?) ?? const []) u.toString(),
        },
        bestFloor: (json['bestFloor'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
      );

  /// Marks to spend.
  final int marks;

  /// The unlocks bought (their ids, tower_tables.dart's towerUnlocks).
  final Set<String> unlocked;

  /// The highest floor any run reached.
  final int bestFloor;
  final int runs;
  final int wins;

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
  }) =>
      TowerProgress(
        marks: marks ?? this.marks,
        unlocked: unlocked ?? this.unlocked,
        bestFloor: bestFloor ?? this.bestFloor,
        runs: runs ?? this.runs,
        wins: wins ?? this.wins,
      );

  Map<String, dynamic> toJson() => {
        'marks': marks,
        if (unlocked.isNotEmpty) 'unlocked': (unlocked.toList()..sort()),
        'bestFloor': bestFloor,
        'runs': runs,
        'wins': wins,
      };
}

/// Every unlock bought (the balance batch's "all unlocks" case).
TowerProgress get towerAllUnlocked =>
    TowerProgress(unlocked: {for (final u in towerUnlocks) u.id});
