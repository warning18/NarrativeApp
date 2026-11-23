// The Tower's floors (v1.845, docs/proposals/tower-mechanics.md §3-4): the
// same seed always builds the same 30 floors, each from its own random
// stream, so a floor's foes never depend on how the floors below it were
// played.

import 'dart:math';

import '../../combat/combat_engine.dart' show isBossEnemy;
import '../../combat/encounter.dart';
import '../../combat/enemy_affix.dart';
import 'tower_tables.dart';

/// What a random stream of the Tower is for: one stream per floor and
/// purpose ([towerRandom]).
/// (A stream added later goes last: the others keep their draws.)
enum TowerStream {
  foes,
  affix,
  offer,
  fight,
  start,
  oath,
  pick,
  spoils,
  boon,

  /// The bot's trial fights of the dice it owns (tower_bot.dart).
  dieTrial,

  /// The floor events (floor events PR 1,
  /// docs/proposals/tower-snakes-and-ladders.md): which floor holds one,
  /// its fall, its roll (towerEventOf).
  board,
}

/// The stream [purpose] of floor [floor] in the run of [seed]. Mixed by
/// hand (Object.hash may change from one launch to the next), so a seed
/// gives the same tower on every device.
Random towerRandom(int seed, int floor, TowerStream purpose) {
  var h = seed & 0x7fffffff;
  h = (h * 1000003 + floor * 7919 + (purpose.index + 1) * 104729) & 0x7fffffff;
  h ^= h >> 13;
  h = (h * 2654435761) & 0x7fffffff;
  return Random(h);
}

/// One floor of the run: what it holds and how it is fought.
class TowerFloor {
  const TowerFloor({
    required this.floor,
    required this.kind,
    required this.chapter,
    required this.extra,
    required this.enemyIds,
    this.affixes = const [],
    this.elite = false,
    this.elitePack = false,
    this.events = 0,
  });

  /// 1..[towerTop].
  final int floor;
  final TowerFloorKind kind;

  /// The band the fight runs in (its pool, its curve).
  final int chapter;

  /// The Tower's multiplier on the curve.
  final double extra;

  /// The foes, strongest first (the forced affixes go on the first).
  final List<String> enemyIds;

  /// The affixes forced on the first foe.
  final List<EnemyAffix> affixes;

  /// A lone ordinary foe made an Elite.
  final bool elite;

  /// A pack fought as an Elite pack (a shortcut's, towerShortcutFloor): its
  /// [extra] already carries the Elite's multiplier, so nothing else reads
  /// it but the screens (the Elite chip).
  final bool elitePack;

  /// The floor events' version of the run it is in (TowerRun.events): with
  /// them on, the foes' scale is towerEventsFoeScale and [extra] reads
  /// towerEventsExtras (floor events PR 2).
  final int events;

  bool get isPack => enemyIds.length > 1;

  /// The multiplier on the curve the fight of a hero of [professionId] runs
  /// at: the floor's extra and the profession's scale.
  double extraFor(String professionId) =>
      extra * towerProfessionScaleOf(professionId, events: events);

  /// What the fight screen is handed for this floor, for a hero of
  /// [professionId] (the Tower's context: no scene, no chest, no gold or
  /// XP, wounds carried, a loss handed back to the Tower rather than the
  /// death screen).
  EncounterModifiers modifiersFor(String professionId) => EncounterModifiers(
        chapter: chapter,
        difficultyMultiplier: extraFor(professionId),
        forcedAffixes: affixes,
        forceElite: elite,
        keepWounds: true,
        lossContinues: true,
        tower: true,
      );
}

/// The ordinary foes of band [chapter] (§3): in the chapter or before it,
/// not a boss, not a hunter's own, not the story's.
List<String> towerPoolOf(int chapter, Map<String, dynamic> enemies) => [
      for (final MapEntry(:key, :value) in enemies.entries)
        if (value is Map<String, dynamic> &&
            ((value['minChapter'] as num?)?.toInt() ?? 1) <= chapter &&
            !isBossEnemy(key, value) &&
            value['hunterOnly'] != true &&
            !key.endsWith('_turned') &&
            !towerExcludedEnemies.contains(key))
          key,
    ]..sort();

int _healthOf(String id, Map<String, dynamic> enemies) =>
    ((enemies[id] as Map?)?['maxHealth'] as num?)?.toInt() ?? 0;

/// The 30 floors of the run of [seed], against `enemies.json`, for a run
/// playing the floor events' version [events] (TowerRun.events: their
/// extras and foes' scale; the foes drawn are the same).
List<TowerFloor> towerFloorsFor(int seed, Map<String, dynamic> enemies,
    {int events = 0}) {
  final floors = <TowerFloor>[];
  for (var floor = 1; floor <= towerTop; floor++) {
    final recent = {
      for (final f in floors.reversed.take(towerNoRepeatFloors)) ...f.enemyIds,
    };
    floors.add(_floorOf(seed, floor, enemies, recent, events));
  }
  return floors;
}

TowerFloor _floorOf(int seed, int floor, Map<String, dynamic> enemies,
    Set<String> recent, int events) {
  final budget = towerBudgetOf(floor);
  final extra = events >= towerPeacefulEvents
      ? towerPeacefulExtras[floor] ?? towerEventsExtras[floor] ?? budget.extra
      : events >= 1
          ? towerEventsExtras[floor] ?? budget.extra
          : budget.extra;
  final random = towerRandom(seed, floor, TowerStream.foes);
  final affixRandom = towerRandom(seed, floor, TowerStream.affix);
  List<EnemyAffix> affixes(bool pack) {
    final count = budget.minAffixes +
        affixRandom.nextInt(budget.maxAffixes - budget.minAffixes + 1);
    final pool = [
      for (final a in EnemyAffix.values)
        if (pack || a != EnemyAffix.packLeader) a,
    ];
    final picked = <EnemyAffix>[];
    while (picked.length < count && pool.isNotEmpty) {
      picked.add(pool.removeAt(affixRandom.nextInt(pool.length)));
    }
    return picked;
  }

  switch (budget.kind) {
    case TowerFloorKind.boss:
      return TowerFloor(
          floor: floor,
          kind: budget.kind,
          chapter: budget.chapter,
          extra: extra,
          events: events,
          enemyIds: [towerBosses[floor]!]);
    case TowerFloorKind.warden:
      final pool = towerWardens[floor]!;
      return TowerFloor(
          floor: floor,
          kind: budget.kind,
          chapter: budget.chapter,
          extra: extra,
          events: events,
          enemyIds: [pool[random.nextInt(pool.length)]],
          affixes: affixes(false));
    case TowerFloorKind.fight:
      final pool = towerPoolOf(budget.chapter, enemies);
      final fresh = pool.where((id) => !recent.contains(id)).toList();
      final drawFrom = fresh.isEmpty ? pool : fresh;
      final packs = drawFrom
          .where((id) => (enemies[id] as Map?)?['packEligible'] == true)
          .toList();
      final size =
          budget.minFoes + random.nextInt(budget.maxFoes - budget.minFoes + 1);
      final pack = size > 1 &&
          packs.isNotEmpty &&
          (budget.minFoes > 1 || random.nextDouble() < budget.packChance);
      final List<String> ids;
      if (pack) {
        ids = [
          for (var i = 0; i < size; i++) packs[random.nextInt(packs.length)],
        ];
      } else {
        ids = [drawFrom[random.nextInt(drawFrom.length)]];
      }
      ids.sort(
          (a, b) => _healthOf(b, enemies).compareTo(_healthOf(a, enemies)));
      final elite = !pack && random.nextDouble() < budget.eliteChance;
      return TowerFloor(
          floor: floor,
          kind: budget.kind,
          chapter: budget.chapter,
          extra: extra,
          events: events,
          enemyIds: ids,
          affixes: affixes(pack),
          elite: elite);
  }
}
