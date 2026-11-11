// The Tower's own numbers (v1.845, docs/proposals/tower-mechanics.md): the
// floor budget, the bosses and wardens, the enemy pool's exclusions, the
// reward weights and rarities, the marks and the unlocks. The main game's
// numbers are not read here and none of these is read by it.

/// The share of max health the hero gets back after each floor won, on top
/// of what its levels add. The Tower curve review (fix #5): .15 (was .30),
/// so a hard fight still shows a few floors on (health entering floors 21
/// to 29 about 3/4 of max, was 0.9).
const double towerRecoveryShare = .15;

/// The healing potions the hero carries into each fight (refilled every
/// floor): the fight's Potion button, at the story's own heal.
const int towerFlask = 1;

/// The Tower's foes for each profession, on top of the floor's extra
/// (v1.848, the user's call on QA's #834): alone, the mage was the weakest
/// by far (the top won 1 run in 100) and the cleric, healing itself, the
/// strongest (half the runs with every unlock). v1.860 (the spoils and
/// the boons, fewer skills and dice than the cards gave): the ranger, who
/// leans on them most, at .88 (else 1 run in 25 won the top with every
/// unlock); the rogue, whom the spoils' gear lifts most, at 1.04. The
/// Tower curve review (fix #5), with the harder curve: the mage .72 (was
/// .65: it kept its apprentice die and led), the warrior .90, the rogue .98
/// (the three about even with no unlocks).
const Map<String, double> towerProfessionScale = {
  'mage': .72,
  'cleric': 1.28,
  'ranger': .88,
  'warrior': .90,
  'rogue': .98,
};

/// The foes' scale for [professionId] (1 for the others), with the
/// Tower's own [towerFoeScale].
double towerProfessionScaleOf(String professionId) =>
    (towerProfessionScale[professionId] ?? 1.0) * towerFoeScale;

/// Every foe of the Tower, on top of the floors' extras (v1.857): the
/// level-up's stat picks are the player's, the main game's way, and spread
/// their points as the story's builds do (less into the damage stat than
/// the point a level gave before), so the foes come down to keep the
/// climb as hard as it was. v1.865: 1.02 (was 0.95), as full chests
/// (rollLootBox's gearAndPotionsOnly) gave the hero much more gear. The
/// Tower curve review (fix #5): 1.14 (was 1.02), with the floors' extras
/// re-spread (towerBudgets): the dice gone to the bag had taken the top
/// with no unlocks to 22%. v1.922: 1.18 (was 1.14), with the humans' and
/// voidkin's start (towerPeoplePoints): the top with no unlocks back near
/// the curve review's (12.6%; 17.9% with the start alone).
const double towerFoeScale = 1.18;

/// What the unlocks owned give a run (v1.848, the user's call: unlocks give
/// some power, not options only). Each one owned at the start: this share
/// more max health. (Start levels were tried first and made the Tower
/// harder: the foes grow with the hero's level.) v1.860: .04 (was .02):
/// the cards the unlocked runs took most are gone, and the top with every
/// unlock had fallen to 7% (the design asks 15 to 25%). The Tower curve
/// review (fix #5): .03 (the top with every unlock 31% to 29%).
const double towerHealthPerUnlock = .03;

/// The Tower's start for a people (the difficulty review's finding 3, a
/// Tower-only start): this many points in the calling's damage stat, with
/// what they bring (its base damage). Human and voidkin climbed about half
/// as well as the others (no unlocks, the top: human 8%, voidkin 6%
/// against dwarf and elf 20%): their races' bonuses go to stats the
/// Tower's fights barely read. The story's races are unchanged (their
/// 800-run spread is under 5 points).
const Map<String, int> towerPeoplePoints = {
  'human': 2,
  'voidkin': 3,
};

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
/// the story's own pace by chapter. The Tower curve review (fix #5): the
/// deaths spread evenly over the ordinary floors (chapter 5's floors 17 to
/// 19 had killed 12% of those who reached them, the floors around 5%), the
/// bosses and wardens made peaks (floor 10 about 9% of those who reach it,
/// floor 20 12%, floor 30 23%; it had been 1%).
const List<TowerBudget> towerBudgets = [
  TowerBudget(1, 0.30, levelAfter: 2),
  TowerBudget(1, 0.30, levelAfter: 2),
  TowerBudget(1, 0.30, levelAfter: 3),
  TowerBudget(2, 0.30,
      maxFoes: 2, packChance: .30, eliteChance: .12, levelAfter: 3),
  TowerBudget(2, 0.62, levelAfter: 4, kind: TowerFloorKind.warden),
  TowerBudget(2, 0.36,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 4),
  TowerBudget(2, 0.36,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 5),
  TowerBudget(3, 0.34,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 5),
  TowerBudget(3, 0.34,
      maxFoes: 2,
      packChance: .30,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 6),
  TowerBudget(3, 0.52, levelAfter: 7, kind: TowerFloorKind.boss),
  TowerBudget(4, 0.31,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 7),
  TowerBudget(4, 0.31,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 8),
  TowerBudget(4, 0.33,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 8),
  TowerBudget(4, 0.33,
      maxFoes: 2,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .12,
      levelAfter: 9),
  TowerBudget(4, 0.50,
      minAffixes: 1,
      maxAffixes: 1,
      levelAfter: 10,
      kind: TowerFloorKind.warden),
  TowerBudget(4, 0.34,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 10),
  TowerBudget(5, 0.26,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 11),
  TowerBudget(5, 0.26,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 11),
  TowerBudget(5, 0.28,
      maxFoes: 3,
      packChance: .50,
      minAffixes: 1,
      maxAffixes: 1,
      eliteChance: .15,
      levelAfter: 12),
  TowerBudget(5, 0.29, levelAfter: 13, kind: TowerFloorKind.boss),
  TowerBudget(6, 0.30,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 13),
  TowerBudget(6, 0.31,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 14),
  TowerBudget(6, 0.33,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 14),
  TowerBudget(6, 0.32,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 1,
      maxAffixes: 2,
      eliteChance: .20,
      levelAfter: 15),
  TowerBudget(7, 0.43,
      minAffixes: 1,
      maxAffixes: 1,
      levelAfter: 16,
      kind: TowerFloorKind.warden),
  TowerBudget(7, 0.30,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 16),
  TowerBudget(7, 0.32,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 17),
  TowerBudget(8, 0.34,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 17),
  TowerBudget(8, 0.30,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 18),
  TowerBudget(8, 0.34, levelAfter: 18, kind: TowerFloorKind.boss),
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

/// What a reward card gives: a boon's skill, die or spell (v1.860), or
/// [clanOath], a clan offering itself (v1.855, the user's call): sworn, the
/// hero holds its standing and its die (see [towerOathChance]). The item,
/// heal and clan-gift cards of v1.845 are gone (v1.867): an old save's are
/// brought up to date as it loads (TowerRun.fromJson).
enum TowerRewardKind { die, skill, spell, clanOath }

/// A clan's oath on the table (v1.855): always on the first floor won, then
/// on this share of the floors (not a boon's, v1.860) while a clan is left
/// to swear to; one oath a floor at most.
const double towerOathChance = 0.35;

/// The floors whose win offers a boon (v1.860, the main game's earning
/// offers): a choose-one of a skill, a die and a spell. The other floors
/// give their spoils only, and a clan's oath when one comes.
const Set<int> towerBoonFloors = {5, 10, 15, 20, 25};

/// What a boon's three cards are, one of each while each has one to give.
const List<TowerRewardKind> towerBoonKinds = [
  TowerRewardKind.skill,
  TowerRewardKind.die,
  TowerRewardKind.spell,
];

/// The spoils chest's potions in the bag, as the story counts them
/// (PlayerSessionNotifier: a major potion is two).
const Map<String, int> towerSpoilsPotions = {
  'potion_minor': 1,
  'potion_major': 2,
};

/// The chest's antidote.
const String towerSpoilsAntidote = 'antidote';

/// The most potions the bag holds (v1.865, the user's pick): what a chest
/// gives past it is drunk at once, each healing the story's potion
/// (fight_numbers.dart's potionHealAmount), so a climb never ends on a
/// hoard of 20.
const int towerBagCap = 5;

/// The rarity steps, lowest first, and each band's odds (floors 1-9,
/// 11-19, 21-29); a boss or warden floor draws one step up.
const List<List<double>> towerRarityOdds = [
  [.60, .35, .05, 0],
  [.25, .45, .27, .03],
  [.05, .35, .50, .10],
];

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

/// The Tower's own faces of its three dice unlocks (the Tower review,
/// docs/proposals/tower-mechanics-review.md §2.1 (c)): each a side-grade of
/// the starter die, where the game's (dice.json, sold in the story's shops
/// and left as they are) were all worse. Each face is one of the die's own
/// (`from`, by its name: its name, element and keywords kept) with its
/// type, value or weight changed; the die keeps its size. Only the Tower
/// reads them ([towerDiceTable], TowerData.dice).
/// - flame d8, a mage's: six Skill and Attack faces of eight, no heal;
/// - tide d8, a cleric's: a big heal, a guard, two strikes;
/// - tearglass d12: bigger values, one Defend and one Heal face.
const Map<String, List<Map<String, Object>>> towerDieFaces = {
  'flame_die': [
    {'from': 'Fireball', 'weight': 1.0},
    {'from': 'Ember Slash', 'value': 3},
    {'from': 'Profession Technique', 'weight': 1.0},
    {'from': 'Meteor', 'weight': 0.8},
    {'from': 'Profession Technique', 'weight': 1.0},
    {'from': 'Profession Technique', 'weight': 1.0},
    {'from': 'Strike', 'value': 3},
    {'from': 'Profession Technique', 'weight': 1.0},
  ],
  'tide_die': [
    {'from': 'Cleansing Wave', 'value': 5, 'weight': 0.6},
    {'from': 'Riptide Slash', 'value': 3},
    {'from': 'Tide Wall', 'value': 3, 'weight': 0.6},
    {'from': 'Holy Light', 'weight': 0.8},
    {'from': 'Purify', 'weight': 0.4},
    {'from': 'Heavy Strike', 'weight': 0.8},
    {'from': 'Strike', 'value': 3},
    {'from': 'Profession Technique', 'weight': 1.0},
  ],
  'tearglass_die': [
    {'from': 'Glass Edge', 'value': 6},
    {'from': 'Guard', 'value': 3, 'weight': 0.5},
    {'from': 'Riftcut', 'weight': 0.8},
    {'from': 'Seal the Crack', 'value': 5, 'weight': 0.5},
    {'from': 'Blank Facet', 'weight': 1.0},
    {'from': 'Final Shard', 'weight': 0.6},
    {'from': 'Strike', 'value': 6},
    {'from': 'Glass Edge', 'value': 6},
    {'from': 'Blank Facet', 'weight': 1.0},
    {'from': 'Strike', 'value': 6},
    {'from': 'Glass Edge', 'value': 6},
    {'from': 'Strike', 'value': 6},
  ],
};

/// [dice] (dice.json's records) as the Tower rolls them: the dice of
/// [towerDieFaces] with their Tower faces, the others as they are. [dice]
/// itself is left as it is.
Map<String, dynamic> towerDiceTable(Map<String, dynamic> dice) {
  if (!towerDieFaces.keys.any(dice.containsKey)) return dice;
  return {
    for (final MapEntry(:key, :value) in dice.entries)
      key: switch ((towerDieFaces[key], value)) {
        (final List<Map<String, Object>> faces, final Map die) => {
            ...die.cast<String, dynamic>(),
            'faces': [
              for (final face in faces)
                {
                  ...?_faceNamed(die, face['from']),
                  for (final MapEntry(:key, :value) in face.entries)
                    if (key != 'from') key: value,
                },
            ],
          },
        _ => value,
      },
  };
}

Map<String, dynamic>? _faceNamed(Map die, Object? name) {
  for (final face in (die['faces'] as List?) ?? const []) {
    if (face is Map && face['faceName'] == name) {
      return face.cast<String, dynamic>();
    }
  }
  return null;
}
