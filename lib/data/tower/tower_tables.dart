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

/// The Tower's foes for a profession on the warden and boss floors (5,
/// 10, 15, 20, 25, 30), in place of its [towerProfessionScale] there
/// (docs/simulation/tower-cleric-retune.md). The cleric's 1.28 was set
/// when it healed itself through every fight (v1.848); it still wins the
/// ordinary floors as well as the others, but a warden's or boss's long
/// fight at 1.28 outlasted its heals: 43% of the clerics reaching floor 30
/// lost there (10 to 24% for the others) and its top with every unlock was
/// 13.3% (24.0 to 28.9% for the others). At 1.08 on those floors, 23.8%
/// (seeds 1 to 2000; 22.8% over 4,000 seeds, the mage 23.1%).
const Map<String, double> towerProfessionPeakScale = {
  'cleric': 1.08,
};

/// The rules a new climb plays (TowerRun.rules, docs/simulation/
/// tower-levelup-loot.md): 1, the stat picks, the spoils chest, the boon
/// floors and the clans' tables (every climb saved before the field); 2,
/// Tower XP and the Level Up card table, the stat nudges, the loot table;
/// 3, rules 2's systems with the survival curve (docs/simulation/
/// tower-difficulty-survival.md: slower levels, harder foes from floor 1,
/// more health an unlock). A climb keeps the rules it began with.
const int towerRulesLive = 3;

/// The first rules of the survival curve (towerRulesLive since it shipped):
/// rules 2 keeps its numbers for the climbs begun on it.
const int towerSurvivalRules = 3;

/// Every foe of a rules-2 climb, on top of the rest (the retune of
/// docs/simulation/tower-levelup-loot.md): the hero no longer grows a stat
/// point a level, so the foes come down to keep today's tops. .85 (the
/// proposal's prototype .82, re-measured with the loot table built: seeds
/// 1 to 2000, the top 14.0% with no unlocks and 22.4% with all, today 11.6%
/// and 24.7%). Rules 3 keeps it.
const double towerLootFoeScale = .85;

/// The calling pass of rules 2 (as [towerProfessionScale], on top of it and
/// of [towerLootFoeScale]): the cleric heals better with gear worn than with
/// stat points; the ranger, with every unlock, led by 4 points; the rogue
/// lost most from the stat picks (its Dexterity and Luck). With every
/// unlock the five within about 5 points (seeds 1 to 2000).
const Map<String, double> towerLootProfessionScale = {
  'cleric': 1.05,
  'ranger': 1.02,
  'rogue': .97,
};

/// The calling pass of rules 3, in place of [towerLootProfessionScale]
/// (docs/simulation/tower-difficulty-survival.md): with no unlocks the
/// mage, the rogue and the warrior within about 3 points at floors 10, 15
/// and 20; the cleric and the ranger (unlocks) set with every unlock.
const Map<String, double> towerSurvivalProfessionScale = {
  'cleric': .95,
  'ranger': .96,
  'rogue': .93,
  'mage': .96,
  'warrior': 1.04,
};

/// The calling pass of rules 3 from floor [towerSurvivalUpperFloor] (the
/// first boss) on, on top of [towerSurvivalProfessionScale]: the warrior
/// fell behind at the first boss and after it, the mage pulled ahead.
const Map<String, double> towerSurvivalProfessionUpperScale = {
  'warrior': .90,
  'mage': 1.04,
};
const int towerSurvivalUpperFloor = 10;

/// The survival curve of rules 3 (the user's call: a roguelike climb, hard
/// from floor 1, harder going up): every foe of floor n (index n - 1) this
/// much more, on top of the floor's extra and the rest. Floors 1 to 4 about
/// 4 rounds a fight (they fell in 1 or 2), floors 6 to 9 a step up, the
/// wardens and bosses peaks. Measured with the slower levels
/// (towerXpCostOf): fewer levels mean foes that grow less
/// (enemyScaledMaxHealth), so the curve is set with them.
const List<double> towerSurvivalScale = [
  3.0, 4.2, 4.5, 3.0, 2.1, // 1-5 (5: warden)
  2.1, 2.1, 2.1, 2.1, 1.8, // 6-10 (10: boss)
  1.5, 1.5, 1.5, 1.5, 1.6, // 11-15 (15: warden)
  1.53, 1.53, 1.53, 1.53, 1.78, // 16-20 (20: boss)
  1.56, 1.56, 1.56, 1.56, 1.66, // 21-25 (25: warden)
  1.56, 1.56, 1.56, 1.56, 1.75, // 26-30 (30: boss)
];

/// The factor rules [rules] put on the foes of floor [floor] for a hero of
/// [professionId]: 1 on rules 1; [towerLootFoeScale] times the calling's
/// [towerLootProfessionScale] on rules 2; on rules 3 [towerLootFoeScale],
/// the calling's [towerSurvivalProfessionScale] (and
/// [towerSurvivalProfessionUpperScale] from [towerSurvivalUpperFloor]) and
/// the floor's [towerSurvivalScale] (none for a [floor] of 0).
double towerRulesScaleOf(int rules, String professionId, {int floor = 0}) {
  if (rules < 2) return 1.0;
  if (rules < towerSurvivalRules) {
    return towerLootFoeScale * (towerLootProfessionScale[professionId] ?? 1.0);
  }
  return towerLootFoeScale *
      (towerSurvivalProfessionScale[professionId] ?? 1.0) *
      (floor >= towerSurvivalUpperFloor
          ? towerSurvivalProfessionUpperScale[professionId] ?? 1.0
          : 1.0) *
      (floor >= 1 && floor <= towerSurvivalScale.length
          ? towerSurvivalScale[floor - 1]
          : 1.0);
}

/// The max health an unlock gives on rules 3: [towerHealthPerUnlockOf]
/// this many times (the marks' unlocks make the top reachable: about 10%
/// with all of them, under 0.5% with none), and the calling's share of it
/// ([towerSurvivalProfessionHealthPerUnlock]).
const double towerSurvivalHealthPerUnlockScale = 5.33;
const Map<String, double> towerSurvivalProfessionHealthPerUnlock = {
  'cleric': .90,
  'rogue': .75,
  'mage': 1.15,
  'warrior': .85,
};

/// The share of max health a hero of [raceId] and [professionId] gains per
/// unlock owned on rules [rules] (rules 1 and 2: [towerHealthPerUnlockOf]).
double towerHealthPerUnlockFor(String raceId, String professionId,
        {required int rules}) =>
    towerHealthPerUnlockOf(raceId) *
    (rules >= towerSurvivalRules
        ? towerSurvivalHealthPerUnlockScale *
            (towerSurvivalProfessionHealthPerUnlock[professionId] ?? 1.0)
        : 1.0);

/// The share of max health back after a floor won on rules 3 (rules 1 and
/// 2: [towerRecoveryShare]): HP is the climb's resource. Heat 3 and up
/// keep [towerHeatRecoveryShare].
const double towerSurvivalRecoveryShare = .10;

/// The share of max health back after a floor won at [heat] on rules
/// [rules] (rules 1 and 2: [towerRecoveryShareOf]).
double towerRecoveryShareFor(int heat, {required int rules}) =>
    rules < towerSurvivalRules
        ? towerRecoveryShareOf(heat)
        : heat >= towerHeatFlame
            ? towerHeatRecoveryShare
            : towerSurvivalRecoveryShare;

/// The foes' scale for [professionId] (1 for the others; on a warden's or
/// boss's floor, [peak], its [towerProfessionPeakScale] if it has one),
/// with the Tower's own [towerFoeScale], [towerEventsFoeScale] in a run
/// playing the floor events ([events] 1 or more, TowerRun.events), or
/// [towerPeacefulFoeScale] in one playing the floors without a fight too
/// ([towerPeacefulEvents] or more).
double towerProfessionScaleOf(String professionId,
        {int events = 0, bool peak = false}) =>
    ((peak ? towerProfessionPeakScale[professionId] : null) ??
        towerProfessionScale[professionId] ??
        1.0) *
    (events >= towerPeacefulEvents
        ? towerPeacefulFoeScale
        : events >= 1
            ? towerEventsFoeScale
            : towerFoeScale);

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
/// 1.24 since the clans' offers (v2.6.0): the payback B (+0.06) on every
/// version's foes, so a run with the floor events off is paid back too.
const double towerFoeScale = 1.24;

/// Every foe of the Tower in a run with the floor events on (floor events
/// PR 2, docs/proposals/tower-snakes-and-ladders.md, TowerRun.events 1 or
/// more): the curve with them on. The shortcut, the setback and the rival
/// at [towerFoeScale] took the top to 10.2% with no unlocks, 22.1% with
/// all (seeds 1 to 2000); at 1.14, with [towerEventsExtras], 13.5% and
/// 25.3% (the events cost the unlocked runs more: no one scale gives back
/// both 12.6% and 26.8%). The live curve since v1.944 (events version 1).
/// 1.16 since a pack's shortcut is an Elite pack (towerShortcutFloor, no
/// foe added): 13.2% and 24.9%, every ordinary floor under 9%.
/// 1.22 since the clans' offers (v2.6.0, the payback B's +0.06).
const double towerEventsFoeScale = 1.22;

/// The floor events' version that adds the floors without a fight (floor
/// events PR 3 and 4, docs/proposals/tower-peaceful-floors-and-stores.md:
/// the parley, the merchant and the bargain). A run plays them only when
/// its TowerRun.events is this or more, so switching the setback, the
/// rival and the shortcut on (towerEventsLive 1) leaves them off.
const int towerPeacefulEvents = 2;

/// Every foe of the Tower in a run playing the floors without a fight
/// ([towerPeacefulEvents]): 1.15, set for the whole set (the events, the
/// parley, the merchant and the bargain: 14.0% and 24.8%, seeds 1 to 2000);
/// 1.17 since the shortcut's Elite pack (v1.961), which made 1.15 give
/// 16.1% and 28.2%: with [towerPeacefulExtras], 14.25% and 26.55%, every
/// ordinary floor under 9% (seeds 1 to 2000).
/// 1.23 since the clans' offers (v2.6.0, the user's payback B): their gifts
/// had taken the top to 16.0% and 31.2% (seeds 1 to 2000); at 1.23, 11.3%
/// and 23.75%, about the v2.4.0 curve.
const double towerPeacefulFoeScale = 1.23;

/// The floors' extras that differ in a run with the floor events on
/// (floor -> extra, in place of its [towerBudgets] one): the floor-20 boss
/// .30 (was .29: at [towerEventsFoeScale] alone it killed 9.4%, under its
/// 10 to 15%; now 13.5% / 11.9%) and the floor-30 boss .35 (was .34: 17.9%
/// alone, now 24.6% / 21.3%).
const Map<int, double> towerEventsExtras = {20: .30, 30: .35};

/// The floors' extras that differ again in a run playing the floors without
/// a fight ([towerPeacefulEvents] or more; read before [towerEventsExtras]):
/// the floor-25 warden .42 (was .43) and the floor-30 boss .34 (was .35),
/// so that at [towerPeacefulFoeScale] they end about as many climbs as in
/// version 1 (13.8% and 27.5% of those reaching them, against 13.5% and
/// 26.2%; at .43 and .35, 15.4% and 29.9%). The user's option 2, v1.963.
const Map<int, double> towerPeacefulExtras = {25: .42, 30: .34};

/// The climb above floor 10 made harder (v2.4.0, docs/simulation/
/// tower-roguelike-briefs.md brief 1, the user's option B): every floor's
/// extra ×1.08 on floors 11 to 20 and ×1.06 on 21 to 29 and on the
/// floor-30 boss (the user's pick of the late-floor variants), the first
/// ten floors as they were. The top had been won by 14.3% of runs with no
/// unlocks and 26.9% with all, over the design's 5 to 12% and 15 to 25%;
/// now 11.95% and 23.65% (seeds 1 to 2000).
double towerClimbScale(int floor) => floor >= 11 && floor <= 20
    ? 1.08
    : floor >= 21 && floor <= 29
        ? 1.06
        : floor == 30
            ? 1.06
            : 1.0;

/// What the unlocks owned give a run (v1.848, the user's call: unlocks give
/// some power, not options only). Each one owned at the start: this share
/// more max health. (Start levels were tried first and made the Tower
/// harder: the foes grow with the hero's level.) v1.860: .04 (was .02):
/// the cards the unlocked runs took most are gone, and the top with every
/// unlock had fallen to 7% (the design asks 15 to 25%). The Tower curve
/// review (fix #5): .03 (the top with every unlock 31% to 29%).
const double towerHealthPerUnlock = .03;

/// The share of [towerHealthPerUnlock] a people takes, in place of it
/// (docs/simulation/tower-race-trim.md, the user's call: trim the two
/// ahead, lift no one). With every unlock the dwarf (28.7%) and the elf
/// (28.0%) won the top far more than the human (24.0%), the orc (22.7%)
/// and the voidkin (20.7%): with most runs reaching floor 20, the long
/// fights of floors 21 to 30 decide, and there their health and armour
/// (dwarf) and dexterity, perception and luck (elf) hold. The unlocks' extra
/// health is what keeps them standing longest: half of it for the dwarf
/// (×1.15 with every unlock, was ×1.30), a third for the elf (×1.10).
/// Over 4,000 seeds the top with every unlock: dwarf 23.6%, elf 23.5%,
/// human 24.3%, orc 22.2%, voidkin 20.2%. No unlocks: unchanged.
const Map<String, double> towerPeopleHealthPerUnlock = {
  'dwarf': .015,
  'elf': .01,
};

/// The max health a hero of [raceId] gains per unlock owned
/// ([towerPeopleHealthPerUnlock], else [towerHealthPerUnlock]).
double towerHealthPerUnlockOf(String raceId) =>
    towerPeopleHealthPerUnlock[raceId] ?? towerHealthPerUnlock;

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
/// floor 20 12%, floor 30 23%; it had been 1%). Floor events PR 2 (QA's
/// finding on v1.922: floor 28 killed 10.6%, over the 10% an ordinary
/// floor may): floors 27 and 28 at .31 (were .32 and .34), every run;
/// with the events off the worst ordinary floor 9.3% (f28), the top 12.9%
/// with no unlocks, 27.4% with all (was 12.6%, 26.8%).
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
  TowerBudget(7, 0.31,
      minFoes: 2,
      maxFoes: 3,
      packChance: .70,
      minAffixes: 2,
      maxAffixes: 2,
      eliteChance: .25,
      levelAfter: 17),
  TowerBudget(8, 0.31,
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
///
/// [rankUp] (v2.4.0, brief 2): a skill card whose skill would sit on no
/// face of the die in play becomes a tier for the best skill on it
/// (combat_engine's applySkillTier, up to maxSkillTier): its id is that
/// skill's.
///
/// The loot cards of rules 2 (TowerRun.rules, tower_levelup_loot.dart): a
/// piece of gear ([TowerReward.id] the item), a bundle of potions and
/// antidotes ([TowerReward.id] its contents, towerBundleOf) and a purse of
/// coins ([TowerReward.amount] the coins). Added last, so a save's names
/// keep their meaning.
enum TowerRewardKind {
  die,
  skill,
  spell,
  clanOath,
  rankUp,
  gear,
  bundle,
  purse,
}

/// The table on a rules-2 run's floor won (TowerRun.table): the loot table,
/// a Level Up table, or a clan's oath alone (tower_levelup_loot.dart).
enum TowerTableKind { loot, levelUp, oath }

/// A clan's offer on the table (v1.855; since the clans' offers their gifts,
/// docs/simulation/tower-clan-offers.md): always on the first floor won,
/// then on this share of the other floors (not a boon's, v1.860).
const double towerOathChance = 0.35;

/// The clans' offers (docs/simulation/tower-clan-offers.md §1): at
/// most this many suitors a floor, each a different clan of the run's pool.
const int towerSuitorsPerOffer = 3;

/// Standing with a clan in a run: 0 to [towerOathStep], rebuilt from the
/// cards taken (towerStandingOf). A gift taken gives its clan
/// [towerGiftStanding], each of its allies (relations.json step
/// [towerAllyRelationStep] or more) [towerAllyStanding], and takes
/// [towerRivalStanding] from each rival (step [towerRivalRelationStep] or
/// less). At [towerOathStep] the clan's oath is dealt (the user's call: 6).
const int towerOathStep = 6;
const int towerGiftStanding = 2;
const int towerAllyStanding = 1;
const int towerRivalStanding = 1;
const int towerAllyRelationStep = 6;
const int towerRivalRelationStep = 3;

/// From this floor won (#1153, the user's call: "floor-15 oath only"), a
/// climb with no oath sworn and none due by standing is offered one anyway:
/// the oath of its highest-standing clan (towerPityOathClan), on every
/// floor won that is not a boon's until one is sworn (still one a run).
/// Floor 15 is itself a boon floor ([towerBoonFloors]), so the first such
/// offer comes after floor 16.
const int towerPityOathFloor = 15;

/// The floors whose win offers a boon (v1.860, the main game's earning
/// offers): a choose-one of a skill, a die and a spell. The other floors
/// give their spoils only, and a clan's oath when one comes.
/// v2.4.0 (brief 3, option B): three more late, on 13, 23 and 28.
const Set<int> towerBoonFloors = {5, 10, 13, 15, 20, 23, 25, 28};

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

/// The floor events' version new runs start with (floor events PR 1,
/// docs/proposals/tower-snakes-and-ladders.md; TowerRun.events): 1, the
/// setback, the rival and the shortcut, switched on by the user's call of
/// 12 November 2026 once UX-2's cards had shipped (v1.944); 2
/// ([towerPeacefulEvents]: the parley, the merchant and the bargain too)
/// since the user's call of 12 November 2026 (option 2 of Core's switch
/// review, v1.963). A run saved before keeps the version it started with
/// (0 plays as before the events).
const int towerEventsLive = 2;

/// The share of ordinary floors that hold a rival (floor events PR 1, the
/// proposal's "Others"): win the floor's fight within [towerRivalRounds]
/// rounds and the next floor is skipped. Only where a skip fits: the floor
/// skipped and the one landed on both ordinary floors, so a skip never
/// passes a warden or a boss.
const double towerRivalShare = .10;

/// The rounds a rival's fight is won within to skip the next floor.
const int towerRivalRounds = 3;

/// The share of ordinary floors that hold a setback (floor events PR 1,
/// the proposal's option (a), cap 1): after the win and the card, the
/// story's d20 check. Pass, a potion; fail, down 1 to 3 floors (drawn and
/// shown before the roll), never below the floor after the last gate
/// beaten. Measured: passed 71% of the time, about a point off the top.
const double towerSetbackShare = .20;

/// The setbacks a run may take: with none left, the test is not offered.
const int towerSetbacksPerRun = 1;

/// The ability each setback's check reads, by floor in turn (floor 1
/// strength, 2 dexterity, 3 wisdom, 4 strength...).
const List<String> towerSetbackAbilities = ['strength', 'dexterity', 'wisdom'];

/// The setback check's DC: this on floors 1 to 6, one more every
/// [towerSetbackDcFloors] floors (10 to 14).
const int towerSetbackDcBase = 10;
const int towerSetbackDcFloors = 6;

/// The most floors a setback falls (1 to this, drawn).
const int towerSetbackMaxFall = 3;

/// The share of ordinary floors that hold a shortcut (floor events PR 2,
/// the proposal's "Shortcut floors" and recommended set): before the fight,
/// fight the floor's foe as an Elite (a pack one foe more) and skip 1 to
/// [towerSetbackMaxFall] floors (drawn, shown), never past the floor before
/// the next gate; won, the floor's spoils and card and a card on landing;
/// lost, the run ends. Only where a skip fits.
const double towerShortcutShare = .15;

/// The draw of the floors you may get past without fighting, and of the
/// stores (floor events PR 3, docs/proposals/tower-peaceful-floors-and-stores.md):
/// one more draw per floor on the board stream, at this index plus the
/// floor (towerRandom), so no draw of the floor events moves. Only on an
/// ordinary floor from [towerPeacefulFirstFloor] to the one below the top
/// that holds no floor event. Its ranges, in this order: a parley under
/// [towerParleyShare] (0 to .15), a merchant in the next
/// [towerMerchantShare] (.15 to .20), a bargain in the next
/// [towerBargainShare] (.20 to .30; floor events PR 4); nothing above.
/// Only in a run playing [towerPeacefulEvents] or more.
const int towerPeacefulDraw = 3000;

/// The first floor the draw above may hold one (floor 1 deals the first
/// oath).
const int towerPeacefulFirstFloor = 2;

/// The share of those floors that hold a parley (floor events PR 3): before
/// the fight, a guardian of a clan (drawn from [towerClans]) bars the way.
/// Talk, the setback's d20 check (its DC, [towerParleyAbilities] by floor),
/// or pass with no roll when sworn to the guardian's clan: past the floor,
/// its level and its marks given (by height), its spoils, its card and its
/// recovery given up. A talk failed, or a fight chosen: the floor's fight.
const double towerParleyShare = .15;

/// The ability each parley's talk reads, by floor in turn (floor 1
/// charisma, 2 wisdom, 3 dexterity, 4 charisma...).
const List<String> towerParleyAbilities = ['charisma', 'wisdom', 'dexterity'];

/// The share of those floors whose landing holds a merchant (floor events
/// PR 4): on the landing after the floor's win and its card, before the
/// next fight, a merchant of a clan (drawn from [towerClans]) sells its
/// stock ([towerSalvePrice], [towerBundlePrice], towerBoonPrice) for the
/// run's Tower coins (v2.10.0; TowerRun.coins; before, its marks), at half price
/// (rounded up) to a hero sworn to its clan. It takes no floor of its own.
const double towerMerchantShare = .05;

/// The share of those floors whose landing holds a bargain (floor events
/// PR 4): [towerBargainHealthShare] of the max health, for the rest of the
/// run, for [towerBargainPoints] to the calling's damage stat. Taken or
/// refused, once.
const double towerBargainShare = .10;

/// The floors whose landing always holds a merchant (floor events PR 4: a
/// shop room after each boss below the top). Its clan is drawn on the
/// floor's own index of the peaceful draw ([towerPeacefulDraw] + floor),
/// which a gate floor never otherwise reads.
const Set<int> towerShopFloors = {10, 20};

/// The merchant's salve: its price in coins (v2.10.0, brief 6's option A:
/// the stall takes Tower coins, TowerRun.coins; it was 3 marks) and the
/// share of the max health it heals.
const int towerSalvePrice = 4;
const double towerSalveShare = .40;

/// The merchant's potion bundle: its price in coins (v2.10.0; it was 4
/// marks) and the potions it puts in the bag (up to the bag's cap,
/// towerBagCapOf).
const int towerBundlePrice = 5;
const int towerBundlePotions = 2;

/// The bargain's price, a share of the max health as it stands when it is
/// taken (at least 1), cut for the rest of the run, and the points it gives
/// the calling's damage stat.
const double towerBargainHealthShare = .10;
const int towerBargainPoints = 1;

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

/// The foes as the Tower fights them, where the story's were retuned after
/// the Tower's curve was set (v1.926, the story difficulty review's findings
/// 5 to 7, enemies.json): the Tower keeps their stats as they were, so the
/// story's walls coming down does not move the climb (v1.922's curve). Each
/// entry: the fields replaced, and `moves` the chance of each skill move
/// (skillID -> chance). Only the Tower reads them ([towerEnemyRecord],
/// TowerData.enemies, the floor's fight).
const Map<String, Map<String, Object>> towerEnemyStats = {
  'inquisition_soldier': {
    'maxHealth': 30,
    'moves': {'brace': 25},
  },
  'inquisition_auxiliary': {'maxHealth': 24},
  'drowned_pilgrim': {'maxHealth': 33, 'damage': 4},
  'void_hound': {
    'maxHealth': 27,
    'guile': 4,
    'moves': {'pack_howl': 20},
  },
  'dock_overseer': {'maxHealth': 22, 'damage': 3, 'guile': 2},
  'hollow_court_inquisitor': {'maxHealth': 46},
};

/// [record], foe [id]'s (enemies.json, localized or not), as the Tower
/// fights it: its [towerEnemyStats] put back, the rest as it is. [record]
/// itself is left as it is.
Map<String, dynamic> towerEnemyRecord(String id, Map<String, dynamic> record) {
  final stats = towerEnemyStats[id];
  if (stats == null) return record;
  final moves = stats['moves'] as Map<String, int>?;
  return {
    ...record,
    for (final MapEntry(:key, :value) in stats.entries)
      if (key != 'moves') key: value,
    if (moves != null && record['skillMoves'] is List)
      'skillMoves': [
        for (final move in record['skillMoves'] as List)
          if (move is Map && moves[move['skillID']] != null)
            {...move.cast<String, dynamic>(), 'chance': moves[move['skillID']]}
          else
            move,
      ],
  };
}

/// [enemies] (enemies.json's records) as the Tower fights them
/// ([towerEnemyRecord]). [enemies] itself is left as it is.
Map<String, dynamic> towerEnemyTable(Map<String, dynamic> enemies) {
  if (!towerEnemyStats.keys.any(enemies.containsKey)) return enemies;
  return {
    for (final MapEntry(:key, :value) in enemies.entries)
      key: value is Map<String, dynamic> ? towerEnemyRecord(key, value) : value,
  };
}

// Heat (v2.9.0, docs/simulation/tower-heat.md, the user's call on Core's
// docs/proposals/tower-heat.md): five named curses a climb may carry, each
// level adding one to those below it. A run's heat is TowerRun.heat, fixed
// for the climb; heat 0 is the plain climb, every number as it was.

/// One level of Heat: its number (1..[towerHeatMax]), its id, and the keys
/// of its name and curse line in app_strings.dart (`tower_heat_<id>`,
/// `tower_heat_<id>_line`).
class TowerHeatLevel {
  const TowerHeatLevel(this.heat, this.id);

  final int heat;
  final String id;

  String get nameKey => 'tower_heat_$id';
  String get lineKey => 'tower_heat_${id}_line';
}

/// The five levels, in order (Narrative's names).
const List<TowerHeatLevel> towerHeatLevels = [
  TowerHeatLevel(towerHeatEmbers, 'embers'),
  TowerHeatLevel(towerHeatSmoke, 'smoke'),
  TowerHeatLevel(towerHeatFlame, 'flame'),
  TowerHeatLevel(towerHeatPyre, 'pyre'),
  TowerHeatLevel(towerHeatAsh, 'ash'),
];

/// The level of Heat [heat] (1..[towerHeatMax]), or null (0, the plain
/// climb, has none).
TowerHeatLevel? towerHeatLevelOf(int heat) =>
    heat >= 1 && heat <= towerHeatMax ? towerHeatLevels[heat - 1] : null;

/// The plain climb's name and line keys (heat 0, the picker's first step).
const String towerHeatPlainKey = 'tower_heat_plain';
const String towerHeatPlainLineKey = 'tower_heat_plain_line';

/// The level each curse comes in at (a run at that heat or above has it).
/// Embers: every foe [towerHeatFoeScale].
const int towerHeatEmbers = 1;

/// Smoke: [towerHeatPeakAffixes] more forced affix on every warden and boss
/// (floors 5, 10, 15, 20, 25, 30).
const int towerHeatSmoke = 2;

/// Flame: [towerHeatRecoveryShare] of max health back after a floor (was
/// towerRecoveryShare), and an Elite [towerHeatEliteBonus] more often on
/// the ordinary floors from [towerHeatUpperFloor] to 29.
const int towerHeatFlame = 3;

/// Pyre: the foes [towerHeatPyreFoeScale] from [towerHeatUpperFloor] up,
/// the floors of [towerHeatCutBoons] give nothing (no boon, no
/// clan's offer in its place), the late oath from
/// [towerHeatPityOathFloor] (was towerPityOathFloor).
const int towerHeatPyre = 4;

/// Ash: the foes [towerHeatAshFoeScale] from [towerHeatUpperFloor] up (in
/// place of Embers' factor there), and a gift takes
/// [towerHeatRivalStanding] from each rival (was towerRivalStanding).
const int towerHeatAsh = 5;

/// The highest level.
const int towerHeatMax = towerHeatAsh;

/// Embers' factor on every foe, every floor (brief 7's ×1.05, measured).
const double towerHeatFoeScale = 1.05;

/// Ash's factor on the foes of floors [towerHeatUpperFloor] to 30. The
/// note's 1.10 left the top at 8.4% with every unlock (seeds 1 to 2000,
/// over its 3 to 7% band); 1.12, with Flame's [towerHeatRecoveryShare],
/// 6.8% (1.14 gave 6.2% and floor 26 over 13%).
const double towerHeatAshFoeScale = 1.12;

/// Pyre's factor on the foes of floors [towerHeatUpperFloor] to 30, on top
/// of Embers' (and of Ash's at Heat 5): the user's power lever beside
/// option (a). Every unlock, seeds 1 to 2000: 1.03 cost 2.6 points of top
/// (Heat 3 10.8% to 8.3%), 1.04 3.5 (7.35%; 4.2 on seeds 10001 to 12000),
/// with Ash at 4.6%.
const double towerHeatPyreFoeScale = 1.04;

/// The first floor of the upper Tower, where Flame's Elites and Ash's
/// factor begin (floors 1 to 10 stay gentle).
const int towerHeatUpperFloor = 11;

/// Smoke's affixes added on a warden's or boss's floor.
const int towerHeatPeakAffixes = 1;

/// Flame's share of max health back after a floor won. The note's .08 cost
/// 2.8 points of top (15.4% to 12.6% with every unlock, seeds 1 to 2000,
/// under the 3-point band); .05, 11.8%.
const double towerHeatRecoveryShare = .05;

/// Flame's Elite chance added on an ordinary floor of the upper Tower.
const double towerHeatEliteBonus = .05;

/// Pyre's boon floors taken away. Since v2.9.x (the user's option (a),
/// docs/simulation/tower-heat.md) they give nothing at all: with the clans'
/// offer dealt in the boon's place, Pyre cost 0.7 points of top.
const Set<int> towerHeatCutBoons = {13, 23};

/// Pyre's late oath floor.
const int towerHeatPityOathFloor = 18;

/// Ash's standing a gift takes from each rival clan.
const int towerHeatRivalStanding = 2;

/// The marks a run banks, raised this share a level of Heat (rounded down,
/// [towerHeatMarksOf]).
const double towerHeatMarks = .25;

/// The factor on floor [floor]'s foes at [heat] (1 at heat 0): Embers'
/// (Ash's on the upper Tower), times Pyre's on the upper Tower.
double towerHeatScaleOf(int heat, int floor) =>
    (heat >= towerHeatAsh && floor >= towerHeatUpperFloor
        ? towerHeatAshFoeScale
        : heat >= towerHeatEmbers
            ? towerHeatFoeScale
            : 1.0) *
    (heat >= towerHeatPyre && floor >= towerHeatUpperFloor
        ? towerHeatPyreFoeScale
        : 1.0);

/// The affixes added to a floor of [kind] at [heat].
int towerHeatAffixesOf(int heat, TowerFloorKind kind) =>
    heat >= towerHeatSmoke && kind != TowerFloorKind.fight
        ? towerHeatPeakAffixes
        : 0;

/// The share of max health back after a floor won at [heat].
double towerRecoveryShareOf(int heat) =>
    heat >= towerHeatFlame ? towerHeatRecoveryShare : towerRecoveryShare;

/// The Elite chance of a lone foe on floor [floor] (its budget's [base])
/// at [heat]: Flame's [towerHeatEliteBonus] on the ordinary floors from
/// [towerHeatUpperFloor] (the top boss's floor has no Elite).
double towerEliteChanceOf(int heat, int floor, double base) =>
    heat >= towerHeatFlame && floor >= towerHeatUpperFloor && floor < towerTop
        ? base + towerHeatEliteBonus
        : base;

/// The floors whose win offers a boon at [heat].
Set<int> towerBoonFloorsOf(int heat) => heat >= towerHeatPyre
    ? towerBoonFloors.difference(towerHeatCutBoons)
    : towerBoonFloors;

/// The floors whose win offers nothing at all at [heat] (Pyre's
/// [towerHeatCutBoons]: no boon, no clan's offer, no oath).
Set<int> towerHeatEmptyFloorsOf(int heat) =>
    heat >= towerHeatPyre ? towerHeatCutBoons : const {};

/// The late oath's floor at [heat].
int towerPityOathFloorOf(int heat) =>
    heat >= towerHeatPyre ? towerHeatPityOathFloor : towerPityOathFloor;

/// The standing a gift takes from each rival clan at [heat].
int towerRivalStandingOf(int heat) =>
    heat >= towerHeatAsh ? towerHeatRivalStanding : towerRivalStanding;

/// The marks multiplier at [heat]: 1, 1.25, 1.5 ... 2.25 (for the screens'
/// "Marks ×1.25"; [towerHeatMarksOf] pays them).
double towerHeatMarksFactor(int heat) => 1 + towerHeatMarks * heat;

/// [marks] raised for [heat] ([towerHeatMarks] a level, rounded down).
int towerHeatMarksOf(int marks, int heat) =>
    heat <= 0 ? marks : (marks * towerHeatMarksFactor(heat)).floor();

/// The curses in force at [heat], lowest first (the curse list's rows: its
/// levels' line keys; the last is the one [heat] added).
List<TowerHeatLevel> towerHeatCursesOf(int heat) => [
      for (final level in towerHeatLevels)
        if (level.heat <= heat) level,
    ];
