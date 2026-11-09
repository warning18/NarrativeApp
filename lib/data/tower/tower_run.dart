// A run of the Tower (v1.845, docs/proposals/tower-mechanics.md §2, §7):
// what the save holds, the three moves a run makes (a fight's result, a
// card picked or refused, leaving) and the marks it earns. Pure: the
// screens and the bot both move a run through these functions.

import 'dart:math';

import '../../combat/stat_rules.dart' show levelStatPicks;
import '../sim_combat.dart' show SimCharacter;
import '../training.dart' show StatPickOffer;
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
    this.clanId = '',
    this.clanPool = towerStartClanPool,
    this.startUnlocks = const [],
    this.unlocksOwned = 0,
    this.floor = 1,
    required this.health,
    this.status = TowerStatus.climbing,
    this.taken = const {},
    this.refused = const {},
    this.offer = const [],
    this.statPicks = const [],
    this.autoPicks = false,
    this.spoils = const {},
    this.potions = 0,
    this.antidotes = 0,
  });

  factory TowerRun.fromJson(Map<String, dynamic> json) => TowerRun(
        seed: (json['seed'] as num).toInt(),
        raceId: json['race'] as String,
        professionId: json['profession'] as String,
        clanId: json['clan']?.toString() ?? '',
        clanPool: [
          for (final c in (json['pool'] as List?) ?? towerStartClanPool)
            c.toString(),
        ],
        startUnlocks: [
          for (final u in (json['unlocks'] as List?) ?? const []) u.toString(),
        ],
        unlocksOwned: (json['owned'] as num?)?.toInt() ?? 0,
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
        statPicks: [
          for (final p in (json['picks'] as List?) ?? const [])
            (p as num).toInt(),
        ],
        // A save from before v1.857 has no picks: its levels keep the
        // points they gave then.
        autoPicks: !json.containsKey('picks'),
        spoils: {
          for (final MapEntry(:key, :value)
              in ((json['spoils'] as Map?) ?? const {}).entries)
            int.parse(key.toString()): [
              for (final id in value as List) id.toString(),
            ],
        },
        potions: (json['potions'] as num?)?.toInt() ?? 0,
        antidotes: (json['antidotes'] as num?)?.toInt() ?? 0,
      );

  /// The seed every floor and offer is drawn from.
  final int seed;
  final String raceId;
  final String professionId;

  /// The clan sworn at the start: '' for a run begun from v1.855, where
  /// the clans offer their oaths on the way up (the user's call); an older
  /// save's clan, sworn from floor 1.
  final String clanId;

  /// The clans that may offer their oath on this run (the player's open
  /// clans, TowerProgress.clans, when it began).
  final List<String> clanPool;

  /// The clans sworn, in the order they were: the start's, then each oath
  /// taken, floor by floor. The first is the main clan (the story's rule:
  /// one main clan, its die's Resonance, its patron's standing).
  List<String> get clanIds => [
        if (clanId.isNotEmpty) clanId,
        for (final f in taken.keys.toList()..sort())
          if (taken[f]!.kind == TowerRewardKind.clanOath &&
              taken[f]!.id != clanId)
            taken[f]!.id,
      ];

  /// The main clan: the first sworn, '' while none is.
  String get mainClanId => clanIds.isEmpty ? '' : clanIds.first;

  /// The clans still to swear to.
  List<String> get oathsLeft => [
        for (final c in clanPool)
          if (!clanIds.contains(c)) c,
      ];

  /// The unlocks the run started with (its start dice and items).
  final List<String> startUnlocks;

  /// How many unlocks the player owned when the run began: their power
  /// (towerHealthPerUnlock, towerUnlocksPerPotion) for the whole run.
  final int unlocksOwned;

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

  /// The stat picks taken (v1.857, the main game's level-up): for each pick
  /// earned, in order, the offer taken (0..2 of towerStatPickDraw's three).
  final List<int> statPicks;

  /// A save from before v1.857: each level's point goes to the damage
  /// stat, as it did then; no pick waits.
  final bool autoPicks;

  /// The spoils chest of each floor won (v1.860, floor -> its items): its
  /// gear worn when better than what the hero wears, its potions in the
  /// bag.
  final Map<int, List<String>> spoils;

  /// The bag (v1.860): the spoils' potions and antidotes the hero carries
  /// from floor to floor, on top of the flask that fills every floor
  /// ([towerFlask]).
  final int potions;
  final int antidotes;

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
    List<int>? statPicks,
    Map<int, List<String>>? spoils,
    int? potions,
    int? antidotes,
  }) =>
      TowerRun(
        seed: seed,
        raceId: raceId,
        professionId: professionId,
        clanId: clanId,
        clanPool: clanPool,
        startUnlocks: startUnlocks,
        unlocksOwned: unlocksOwned,
        floor: floor ?? this.floor,
        health: health ?? this.health,
        status: status ?? this.status,
        taken: taken ?? this.taken,
        refused: refused ?? this.refused,
        offer: offer ?? this.offer,
        statPicks: statPicks ?? this.statPicks,
        autoPicks: autoPicks,
        spoils: spoils ?? this.spoils,
        potions: potions ?? this.potions,
        antidotes: antidotes ?? this.antidotes,
      );

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'race': raceId,
        'profession': professionId,
        if (clanId.isNotEmpty) 'clan': clanId,
        'pool': clanPool,
        if (startUnlocks.isNotEmpty) 'unlocks': startUnlocks,
        if (unlocksOwned != 0) 'owned': unlocksOwned,
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
        if (!autoPicks) 'picks': statPicks,
        if (spoils.isNotEmpty)
          'spoils': {
            for (final MapEntry(:key, :value) in spoils.entries) '$key': value,
          },
        if (potions != 0) 'potions': potions,
        if (antidotes != 0) 'antidotes': antidotes,
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

/// A new run of [seed]: floor 1, the hero at full health, with the power
/// of the [unlocksOwned] unlocks (TowerProgress.unlocksOwned). It is sworn
/// to no clan (v1.855): the clans of [clanPool] (TowerProgress.clans)
/// offer their oaths on the way up. A [clanId] swears one from the start
/// (the start screen's pick, until it goes).
TowerRun towerStart({
  required int seed,
  required String raceId,
  required String professionId,
  String clanId = '',
  Iterable<String> clanPool = towerStartClanPool,
  Iterable<String> startUnlocks = const [],
  int unlocksOwned = 0,
  required TowerData data,
}) {
  final unlocks = [
    for (final id in startUnlocks)
      if (towerUnlockOf(id)?.kind
          case TowerUnlockKind.startDie || TowerUnlockKind.startItem)
        id,
  ];
  final hero = towerFreshHero(raceId, professionId, unlocks, data,
      unlocksOwned: unlocksOwned);
  return TowerRun(
    seed: seed,
    raceId: raceId,
    professionId: professionId,
    clanId: clanId,
    clanPool: [
      for (final c in towerClans)
        if (clanPool.contains(c)) c,
    ],
    startUnlocks: unlocks,
    unlocksOwned: unlocksOwned,
    health: hero.maxHealth,
  );
}

/// The floor [run] fights next (its foes, its fight settings).
TowerFloor towerFloorOf(TowerRun run, TowerData data) =>
    towerFloorsFor(run.seed, data.enemies)[run.floor - 1];

/// [run] after its fight of [TowerRun.floor]: lost, the run is over; won,
/// the hero levels (its new health added to what it has left,
/// [healthLeft]), the floor's spoils drop (v1.860) and its offer is dealt
/// (a boon, a clan's oath, or nothing), or, on the top floor, the run is
/// won. [potionsLeft] and [antidotesLeft] are what the fight left of what
/// it carried (the flask's potions are drunk first: what the bag held is
/// gone only past them); null, the bag as it was. [maxHealthBefore], when
/// given, is the hero's max health as the fight began (the bot has built
/// it: towerHeroOf replays the whole run).
TowerRun towerAfterFight(TowerRun run, TowerData data,
    {required bool won,
    required int healthLeft,
    int? potionsLeft,
    int? antidotesLeft,
    int? maxHealthBefore}) {
  if (run.status != TowerStatus.climbing) return run;
  if (!won) return run.copyWith(status: TowerStatus.dead, health: 0);
  final potions =
      potionsLeft == null ? run.potions : min(run.potions, max(0, potionsLeft));
  final antidotes = antidotesLeft == null
      ? run.antidotes
      : min(run.antidotes, max(0, antidotesLeft));
  if (run.floor >= towerTop) {
    return run.copyWith(
        status: TowerStatus.won,
        health: max(1, healthLeft),
        potions: potions,
        antidotes: antidotes);
  }
  final before = maxHealthBefore ?? towerHeroOf(run, data).maxHealth;
  final leveled = run.copyWith(status: TowerStatus.choosing);
  // The hero with the floor's levels: built once, then given the spoils
  // (as towerHeroOf would replay them).
  final hero = towerHeroOf(leveled, data);
  final drop = towerSpoilsFor(
    seed: run.seed,
    floor: towerFloorOf(run, data),
    luck: hero.luck,
    ownedItemIds: hero.ownedItemIds,
    preferredScalingStat:
        (data.professions[run.professionId] as Map?)?['preferredScalingStat']
                ?.toString() ??
            '',
    items: data.items,
  );
  final choosing = leveled.copyWith(
    spoils: {...run.spoils, run.floor: drop},
    potions:
        potions + drop.fold(0, (n, id) => n + (towerSpoilsPotions[id] ?? 0)),
    antidotes: antidotes + drop.where((id) => id == towerSpoilsAntidote).length,
  );
  towerWearSpoils(hero, drop, data);
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
      oaths: run.oathsLeft,
      // The first floor won always offers a clan (the user's call).
      oathDue: run.floor == 1 && run.clanIds.isEmpty,
      items: data.items,
      dice: data.dice,
      skills: data.skills,
      spells: data.spells,
    ),
  );
}

/// The level the hero stands at with [floorsCleared] floors won.
int towerLevelAfter(int floorsCleared) => floorsCleared <= 0
    ? 1
    : max(1, towerBudgetOf(min(floorsCleared, towerTop)).levelAfter);

/// The stat picks [run]'s hero has earned and not yet taken (v1.857, the
/// main game's level-up: [levelStatPicks] a level gained). Held by the run
/// itself: the picks earned by its level, less those it took.
int towerPendingPicks(TowerRun run) {
  if (run.autoPicks || run.isOver) return 0;
  final earned = (towerLevelAfter(run.floorsCleared) - 1) * levelStatPicks;
  return max(0, earned - run.statPicks.length);
}

/// The stat pick on the table for [run]: the three offers of its next
/// pending pick (the main game's draw, towerStatPickDraw), or none.
/// [hero], when given, is [run]'s hero already built (towerHeroOf).
List<StatPickOffer> towerStatPickOffer(TowerRun run, TowerData data,
    {SimCharacter? hero}) {
  if (towerPendingPicks(run) <= 0) return const [];
  return towerStatPickDraw(
      hero ?? towerHeroOf(run, data), run.seed, run.statPicks.length, data);
}

/// [run] with offer [index] of its stat pick on the table taken; [run] as
/// it is when no pick waits or there is no such offer. [offer], when given,
/// is [run]'s pick on the table already drawn (towerStatPickOffer).
TowerRun towerTakeStatPick(TowerRun run, TowerData data, int index,
    {List<StatPickOffer>? offer}) {
  offer ??= towerStatPickOffer(run, data);
  if (index < 0 || index >= offer.length) return run;
  return run.copyWith(statPicks: [...run.statPicks, index]);
}

/// [run] after its cards: card [index] taken, or none (null) refused for a
/// mark (an empty offer refuses nothing: the floor gave its spoils only);
/// then on to the next floor. The floor's level-up picks come first
/// (the screen opens the Level Up before the cards); a pick still waiting
/// here is given its first offer, the calling, so the climb never stalls.
/// [hero], when given, is [run]'s hero already built (towerHeroOf); it is
/// given the card.
TowerRun towerPick(TowerRun run, TowerData data, int? index,
    {SimCharacter? hero}) {
  if (run.status != TowerStatus.choosing) return run;
  for (var guard = 0; towerPendingPicks(run) > 0 && guard < 64; guard++) {
    final taken = towerTakeStatPick(run, data, 0);
    if (identical(taken, run)) break;
    run = taken;
    hero = null;
  }
  if (index == null || index < 0 || index >= run.offer.length) {
    return run.copyWith(
      status: TowerStatus.climbing,
      floor: run.floor + 1,
      refused: run.offer.isEmpty ? run.refused : {...run.refused, run.floor},
      offer: const [],
    );
  }
  final card = run.offer[index];
  hero ??= towerHeroOf(run, data);
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
