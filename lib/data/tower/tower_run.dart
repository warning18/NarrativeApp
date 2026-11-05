// A run of the Tower (v1.845, docs/proposals/tower-mechanics.md §2, §7):
// what the save holds, the three moves a run makes (a fight's result, a
// card picked or refused, leaving) and the marks it earns. Pure: the
// screens and the bot both move a run through these functions.

import 'dart:math';

import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_rewards.dart';
import 'tower_tables.dart';

/// Where a run stands.
enum TowerStatus {
  /// The next fight is floor [TowerRun.floor].
  climbing,

  /// Floor [TowerRun.floor] is won; its cards wait on [TowerRun.offer].
  choosing,

  /// A fight was lost: the run is over.
  dead,

  /// Floor 30 is won: the run is over.
  won,

  /// The player left the Tower: the run is over, its marks earned.
  abandoned,
}

/// One run: its start, where it stands and what it took. The hero is
/// never saved; [towerHeroOf] rebuilds it from this.
class TowerRun {
  const TowerRun({
    required this.seed,
    required this.raceId,
    required this.professionId,
    required this.clanId,
    this.startUnlocks = const [],
    this.floor = 1,
    required this.health,
    this.status = TowerStatus.climbing,
    this.taken = const {},
    this.refused = const {},
    this.offer = const [],
  });

  factory TowerRun.fromJson(Map<String, dynamic> json) => TowerRun(
        seed: (json['seed'] as num).toInt(),
        raceId: json['race'] as String,
        professionId: json['profession'] as String,
        clanId: json['clan'] as String,
        startUnlocks: [
          for (final u in (json['unlocks'] as List?) ?? const []) u.toString(),
        ],
        floor: (json['floor'] as num?)?.toInt() ?? 1,
        health: (json['health'] as num?)?.toInt() ?? 0,
        status: TowerStatus.values.byName(json['status'] as String),
        taken: {
          for (final MapEntry(:key, :value)
              in ((json['taken'] as Map?) ?? const {}).entries)
            int.parse(key.toString()):
                TowerReward.fromJson(value as Map<String, dynamic>),
        },
        refused: {
          for (final f in (json['refused'] as List?) ?? const [])
            (f as num).toInt(),
        },
        offer: [
          for (final r in (json['offer'] as List?) ?? const [])
            TowerReward.fromJson(r as Map<String, dynamic>),
        ],
      );

  /// The seed every floor and offer is drawn from.
  final int seed;
  final String raceId;
  final String professionId;
  final String clanId;

  /// The unlocks the run started with (its start dice and items).
  final List<String> startUnlocks;

  /// The floor to fight next, or, [TowerStatus.choosing], the one just won.
  final int floor;

  /// The hero's health now.
  final int health;
  final TowerStatus status;

  /// The card taken after each floor (floor -> card).
  final Map<int, TowerReward> taken;

  /// The floors whose cards were refused.
  final Set<int> refused;

  /// The cards on the table ([TowerStatus.choosing]); empty otherwise.
  final List<TowerReward> offer;

  bool get isOver =>
      status == TowerStatus.dead ||
      status == TowerStatus.won ||
      status == TowerStatus.abandoned;

  /// Floors won.
  int get floorsCleared => switch (status) {
        TowerStatus.won => towerTop,
        TowerStatus.choosing => floor,
        _ => floor - 1,
      };

  /// The highest floor reached (fought, won or lost).
  int get floorReached => status == TowerStatus.won ? towerTop : floor;

  /// The marks the run has earned so far (§7): banked when it ends.
  int get marks => towerMarksOf(floorsCleared, refused.length);

  TowerRun copyWith({
    int? floor,
    int? health,
    TowerStatus? status,
    Map<int, TowerReward>? taken,
    Set<int>? refused,
    List<TowerReward>? offer,
  }) =>
      TowerRun(
        seed: seed,
        raceId: raceId,
        professionId: professionId,
        clanId: clanId,
        startUnlocks: startUnlocks,
        floor: floor ?? this.floor,
        health: health ?? this.health,
        status: status ?? this.status,
        taken: taken ?? this.taken,
        refused: refused ?? this.refused,
        offer: offer ?? this.offer,
      );

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'race': raceId,
        'profession': professionId,
        'clan': clanId,
        if (startUnlocks.isNotEmpty) 'unlocks': startUnlocks,
        'floor': floor,
        'health': health,
        'status': status.name,
        if (taken.isNotEmpty)
          'taken': {
            for (final MapEntry(:key, :value) in taken.entries)
              '$key': value.toJson(),
          },
        if (refused.isNotEmpty) 'refused': (refused.toList()..sort()),
        if (offer.isNotEmpty) 'offer': [for (final r in offer) r.toJson()],
      };
}

/// The marks of a run that cleared [floorsCleared] floors and refused
/// [refusals] offers (§7): 1 a floor, 2 a warden, 5 a boss of 10 or 20, 15
/// the top, 1 a refusal. A won run: 61 and its refusals.
int towerMarksOf(int floorsCleared, int refusals) {
  var marks =
      floorsCleared * towerMarksPerFloor + refusals * towerMarksPerRefusal;
  for (var floor = 1; floor <= floorsCleared; floor++) {
    final kind = towerBudgetOf(floor).kind;
    if (kind == TowerFloorKind.warden) marks += towerMarksPerWarden;
    if (kind == TowerFloorKind.boss) {
      marks += floor == towerTop ? towerMarksForTop : towerMarksPerBoss;
    }
  }
  return marks;
}

/// A new run of [seed]: floor 1, the hero at full health.
TowerRun towerStart({
  required int seed,
  required String raceId,
  required String professionId,
  required String clanId,
  Iterable<String> startUnlocks = const [],
  required TowerData data,
}) {
  final unlocks = [
    for (final id in startUnlocks)
      if (towerUnlockOf(id)?.kind
          case TowerUnlockKind.startDie || TowerUnlockKind.startItem)
        id,
  ];
  final hero = towerFreshHero(raceId, professionId, unlocks, data);
  return TowerRun(
    seed: seed,
    raceId: raceId,
    professionId: professionId,
    clanId: clanId,
    startUnlocks: unlocks,
    health: hero.maxHealth,
  );
}

/// The floor [run] fights next (its foes, its fight settings).
TowerFloor towerFloorOf(TowerRun run, TowerData data) =>
    towerFloorsFor(run.seed, data.enemies)[run.floor - 1];

/// [run] after its fight of [TowerRun.floor]: lost, the run is over; won,
/// the hero levels (its new health added to what it has left,
/// [healthLeft]) and the floor's cards are dealt, or, on the top floor,
/// the run is won.
TowerRun towerAfterFight(TowerRun run, TowerData data,
    {required bool won, required int healthLeft}) {
  if (run.status != TowerStatus.climbing) return run;
  if (!won) return run.copyWith(status: TowerStatus.dead, health: 0);
  if (run.floor >= towerTop) {
    return run.copyWith(status: TowerStatus.won, health: max(1, healthLeft));
  }
  final before = towerHeroOf(run, data).maxHealth;
  final choosing = run.copyWith(status: TowerStatus.choosing);
  final hero = towerHeroOf(choosing.copyWith(health: 1 << 20), data);
  final health = (healthLeft +
          hero.maxHealth -
          before +
          (hero.maxHealth * towerRecoveryShare).round())
      .clamp(1, hero.maxHealth);
  hero.currentHealth = health;
  return choosing.copyWith(
    health: health,
    offer: towerOfferFor(
      seed: run.seed,
      floor: run.floor,
      hero: towerHeroView(choosing, hero),
      items: data.items,
      dice: data.dice,
      skills: data.skills,
      spells: data.spells,
    ),
  );
}

/// [run] after its cards: card [index] taken, or none (null) refused for a
/// mark; then on to the next floor.
TowerRun towerPick(TowerRun run, TowerData data, int? index) {
  if (run.status != TowerStatus.choosing) return run;
  if (index == null || index < 0 || index >= run.offer.length) {
    return run.copyWith(
      status: TowerStatus.climbing,
      floor: run.floor + 1,
      refused: {...run.refused, run.floor},
      offer: const [],
    );
  }
  final card = run.offer[index];
  final hero = towerHeroOf(run, data);
  towerApplyReward(hero, card, data);
  return run.copyWith(
    status: TowerStatus.climbing,
    floor: run.floor + 1,
    health: hero.currentHealth.clamp(1, hero.maxHealth),
    taken: {...run.taken, run.floor: card},
    offer: const [],
  );
}

/// [run] left by the player: over, its marks earned.
TowerRun towerAbandon(TowerRun run) =>
    run.isOver ? run : run.copyWith(status: TowerStatus.abandoned);
