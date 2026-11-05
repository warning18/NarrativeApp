// The Tower's own numbers (v1.845, docs/proposals/tower-mechanics.md): the
// floor budget, the bosses and wardens, the enemy pool's exclusions, the
// reward weights and rarities, the marks and the unlocks. The main game's
// numbers are not read here and none of these is read by it.

/// The share of max health the hero gets back after each floor won, on top
/// of what its levels add.
const double towerRecoveryShare = .30;

/// The healing potions the hero carries into each fight (refilled every
/// floor): the fight's Potion button, at the story's own heal.
const int towerFlask = 1;

/// The Tower's foes for each profession, on top of the floor's extra
/// (v1.848, the user's call on QA's #834): alone, the mage was the weakest
/// by far (the top won 1 run in 100) and the cleric, healing itself, the
/// strongest (half the runs with every unlock).
const Map<String, double> towerProfessionScale = {
  'mage': .65,
  'cleric': 1.35,
};

/// The foes' scale for [professionId] (1 for the others).
double towerProfessionScaleOf(String professionId) =>
    towerProfessionScale[professionId] ?? 1.0;

/// What the unlocks owned give a run (v1.848, the user's call: unlocks give
/// some power, not options only). Each one owned at the start: this share
/// more max health. (Start levels were tried first and made the Tower
/// harder: the foes grow with the hero's level.)
const double towerHealthPerUnlock = .02;

/// Every this many unlocks owned at the start: one more potion carried into
/// each fight.
const int towerUnlocksPerPotion = 5;

/// The top floor: winning it wins the run.
const int towerTop = 30;

/// What a floor holds.
enum TowerFloorKind {
  /// One fight drawn from the band's pool.
  fight,

  /// A lighter boss (floors 5, 15, 25), from its pool.
  warden,

  /// A boss (floors 10, 20, 30), always the same one.
  boss,
}

/// One floor's budget (§3 of the note): the chapter whose pool and curve
/// it fights in, the Tower's extra on top of the curve, how many foes,
/// how often a pack, the affixes forced on its strongest foe, how often a
/// lone foe is an Elite, and the hero's level once it is cleared.
class TowerBudget {
  const TowerBudget(
    this.chapter,
    this.extra, {
    this.minFoes = 1,
    this.maxFoes = 1,
    this.packChance = 0,
    this.minAffixes = 0,
    this.maxAffixes = 0,
    this.eliteChance = 0,
    required this.levelAfter,
    this.kind = TowerFloorKind.fight,
  });

  final int chapter;
  final double extra;
  final int minFoes;
  final int maxFoes;
  final double packChance;
  final int minAffixes;
  final int maxAffixes;
  final double eliteChance;
  final int levelAfter;
  final TowerFloorKind kind;
}

/// Floors 1 to 30, in order ([towerBudgetOf] reads it). The extras are
/// the Tower's own and far below the story's 1.0: the Tower's hero climbs
/// alone, with no companion, no shop and no rest, so its foes stand at
/// about a third of the story's curve, bosses and wardens lower again
/// (the bot's batch, v1.845: no unlocks, median floor 14, floor 20 reached
/// by 26%, the top by 8%; every unlock, the top by 18%). The levels follow
/// the story's own pace by chapter.
const List<TowerBudget> towerBudgets = [
  TowerBudget(1, 0.30, levelAfter: 2),
  TowerBudget(1, 0.30, levelAfter: 2),
  TowerBudget(1, 0.30, levelAfter: 3),
  TowerBudget(2, 0.30,
      maxFoes: 2, packChance: .30, eliteChance: .12, levelAfter: 3),
  TowerBudget(2, 0.34, levelAfter: 4, kind: TowerFloorKind.warden),
  TowerBudget(2, 0.30,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 4),
  TowerBudget(2, 0.30,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 5),
  TowerBudget(3, 0.30,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 5),
  TowerBudget(3, 0.30,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 6),
  TowerBudget(3, 0.31, levelAfter: 7, kind: TowerFloorKind.boss),
  TowerBudget(4, 0.35,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 7),
  TowerBudget(4, 0.35,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 8),
  TowerBudget(4, 0.35,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 8),
  TowerBudget(4, 0.35,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 9),
  TowerBudget(4, 0.42,
      minAffixes: 1,
      maxAffixes: 1,
      levelAfter: 10,
      kind: TowerFloorKind.warden),
  TowerBudget(4, 0.37,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 10),
  TowerBudget(5, 0.37,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 11),
  TowerBudget(5, 0.37,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 11),
  TowerBudget(5, 0.37,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 12),
  TowerBudget(5, 0.28, levelAfter: 13, kind: TowerFloorKind.boss),
  TowerBudget(6, 0.39,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 13),
  TowerBudget(6, 0.39,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 14),
  TowerBudget(6, 0.39,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 14),
  TowerBudget(6, 0.39,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 15),
  TowerBudget(7, 0.44,
      minAffixes: 1,
      maxAffixes: 1,
      levelAfter: 16,
      kind: TowerFloorKind.warden),
  TowerBudget(7, 0.40,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 16),
  TowerBudget(7, 0.40,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 17),
  TowerBudget(8, 0.40,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 17),
  TowerBudget(8, 0.40,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 18),
  TowerBudget(8, 0.26, levelAfter: 18, kind: TowerFloorKind.boss),
];

/// Floor [floor]'s budget (1..[towerTop]).
TowerBudget towerBudgetOf(int floor) => towerBudgets[floor - 1];

/// The boss of each boss floor (Narrative's picks, the-tower-names.md).
const Map<int, String> towerBosses = {
  10: 'inquisition_legate',
  20: 'claimant_morrow',
  30: 'void_sovereign',
};

/// The warden pools of floors 5, 15 and 25: one is drawn by the seed.
const Map<int, List<String>> towerWardens = {
  5: [
    'rat_matriarch',
    'dock_overseer',
    'smuggler_captain',
    'plague_hound',
    'kroll_the_branded',
    'brine_jack',
  ],
  15: [
    'hollow_court_zealot',
    'hollow_court_inquisitor',
    'knell_keeper',
    'horn_taker',
    'purifier_vell',
  ],
  25: [
    'strand_colossus',
    'glass_shepherd',
    'white_admiral',
    'tear_spawn',
    'void_manifestation',
    'inquisition_penitent',
  ],
};

/// Foes never drawn on an ordinary floor: story duels and the story's own
/// fights, besides every `*_turned` companion, every boss and every
/// `hunterOnly` record (see towerPoolOf).
const Set<String> towerExcludedEnemies = {
  'inquisition_legate',
  'claimant_vane',
  'claimant_morrow',
  'claimant_tallis',
  'tear_herald',
  'aurel_vane',
  'masked_penitent',
  'den_bouncer',
  'den_looter',
  'sore_loser',
  'kraken_arm',
};

/// A floor met within this many floors is not drawn again while the pool
/// has another.
const int towerNoRepeatFloors = 3;

/// The Elite's stat multiplier in the headless fight, which has no Elite of
/// its own (the fight screen's `_eliteStatMultiplier`).
const double towerSimEliteMultiplier = 1.35;

/// What a reward card gives.
/// [clanOath]: a clan offers itself (v1.855, the user's call): sworn, the
/// hero holds its standing and its die (see [towerOathChance]).
enum TowerRewardKind { item, die, skill, spell, heal, clanGift, clanOath }

/// Each kind's weight on a card (§5 of the note).
const Map<TowerRewardKind, int> towerRewardWeights = {
  TowerRewardKind.item: 30,
  TowerRewardKind.die: 10,
  TowerRewardKind.skill: 18,
  TowerRewardKind.spell: 8,
  TowerRewardKind.heal: 16,
  TowerRewardKind.clanGift: 14,
};

/// Cards on the table after a win.
const int towerOfferSize = 3;

/// A clan's oath on the table (v1.855): always on the first floor won, then
/// on this share of the offers while a clan is left to swear to; one oath
/// an offer at most, never all three cards.
const double towerOathChance = 0.35;

/// A heal card's share of max health, and after a boss or a warden.
const double towerHealShare = .35;
const double towerBigHealShare = .50;

/// Below this share of health a heal is always on the table.
const double towerHealFloor = .40;

/// The rarity steps, lowest first, and each band's odds (floors 1-9,
/// 11-19, 21-29); a boss or warden floor draws one step up.
const List<List<double>> towerRarityOdds = [
  [.60, .35, .05, 0],
  [.25, .45, .27, .03],
  [.05, .35, .50, .10],
];

/// items.json's rarities, lowest first.
const List<String> towerItemRarities = ['Common', 'Uncommon', 'Rare', 'Relic'];

/// skills.json's rarities by step: the top step holds epic and legendary.
const List<List<String>> towerSkillRarities = [
  ['common'],
  ['uncommon'],
  ['rare'],
  ['epic', 'legendary'],
];

/// Dice never offered: the companions' own.
const Set<String> towerExcludedDice = {
  'liora_die',
  'vess_die',
  'grosh_die',
  'tobin_die',
  'malrik_die',
};

/// Marks: a floor cleared, a warden beaten, a boss beaten (10, 20), the
/// top, an offer refused.
const int towerMarksPerFloor = 1;
const int towerMarksPerWarden = 2;
const int towerMarksPerBoss = 5;
const int towerMarksForTop = 15;
const int towerMarksPerRefusal = 1;

/// The six main clans a run may be sworn to.
const List<String> towerClans = [
  'dominion',
  'vigil',
  'compact',
  'mire',
  'crows',
  'penitents',
];

/// Open before any unlock.
const Set<String> towerStartProfessions = {'warrior', 'mage', 'rogue'};
const Set<String> towerStartClans = {'dominion', 'mire', 'penitents'};

/// The clans a run may be offered before any is unlocked, in order.
const List<String> towerStartClanPool = ['dominion', 'mire', 'penitents'];

/// What an unlock opens.
enum TowerUnlockKind { startDie, clan, startItem, profession }

/// One entry of the unlock tree.
class TowerUnlock {
  const TowerUnlock(this.id, this.kind, this.value, this.cost, {this.needs});

  /// Its id, the save's and the screen's.
  final String id;
  final TowerUnlockKind kind;

  /// The die, clan, item or profession it opens.
  final String value;
  final int cost;

  /// The unlock it needs bought first, if any.
  final String? needs;
}

/// The first unlock tree (Narrative's ten, the-tower-names.md), cheapest
/// first.
const List<TowerUnlock> towerUnlocks = [
  TowerUnlock('flame_die', TowerUnlockKind.startDie, 'flame_die', 10),
  TowerUnlock('crows', TowerUnlockKind.clan, 'crows', 10),
  TowerUnlock('shield_t5', TowerUnlockKind.startItem, 'shield_t5', 15),
  TowerUnlock('cleric', TowerUnlockKind.profession, 'cleric', 15),
  TowerUnlock('tide_die', TowerUnlockKind.startDie, 'tide_die', 20,
      needs: 'flame_die'),
  TowerUnlock('vigil', TowerUnlockKind.clan, 'vigil', 20, needs: 'crows'),
  TowerUnlock('sword_t4', TowerUnlockKind.startItem, 'sword_t4', 25,
      needs: 'shield_t5'),
  TowerUnlock('ranger', TowerUnlockKind.profession, 'ranger', 25,
      needs: 'cleric'),
  TowerUnlock('compact', TowerUnlockKind.clan, 'compact', 30, needs: 'vigil'),
  TowerUnlock('tearglass_die', TowerUnlockKind.startDie, 'tearglass_die', 40,
      needs: 'tide_die'),
];

/// The unlock [id], or null.
TowerUnlock? towerUnlockOf(String id) {
  for (final u in towerUnlocks) {
    if (u.id == id) return u;
  }
  return null;
}
