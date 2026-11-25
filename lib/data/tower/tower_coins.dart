// The Tower's coins and perks (v2.10.0, the rules; docs/simulation/
// tower-coins.md, brief 6 of tower-briefs-6-7-8-spec.md and Core's note
// docs/proposals/tower-coins.md, approved by the user).
//
// Two currencies, one job each. Tower coins last one climb: earned on each
// floor won (towerCoinsFor), spent on a reroll of the table, a banished
// card and the merchant's stall (tower_events.dart's towerBuy), lost when
// the climb ends. Ash Marks last between climbs: the unlock tree, then the
// perks (one worn a climb) and the banner trims (no power) of this file,
// and the first-win bonuses. Heat multiplies marks, never coins.
//
// Pure: the screens and the bot move a run through these functions.

import 'dart:math';

import '../sim_combat.dart' show SimCharacter;
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

// ---------------------------------------------------------------------------
// Coins earned (brief 6's fixed table).

/// Coins an ordinary floor won pays, a band (floors 1-10 band 1, 11-20
/// band 2, 21-29 band 3).
const int towerCoinsPerBand = 1;

/// Coins an Elite adds (a lone foe made Elite, a shortcut's), a band.
const int towerCoinsElite = 1;

/// Coins a warden (5, 15, 25) pays, a band: 3, 6, 9.
const int towerCoinsWarden = 3;

/// Coins a boss (10, 20) pays, a band: 5, 10. The top pays none: the climb
/// ends there and its coins with it.
const int towerCoinsBoss = 5;

/// The coin band of [floor]: 1 for floors 1-10, 2 for 11-20, 3 for 21-30.
int towerCoinBandOf(int floor) => ((floor - 1) ~/ 10 + 1).clamp(1, 3);

/// The coins [floor] pays when won for the first time (brief 6): its kind's
/// coins times its band, an Elite's bonus on top; none for the top.
/// towerAfterFight adds them; a floor met again, a parley passed and a
/// floor skipped pay none (they never reach that point).
int towerCoinsFor(TowerFloor floor) {
  if (floor.floor >= towerTop) return 0;
  final band = towerCoinBandOf(floor.floor);
  final base = switch (floor.kind) {
    TowerFloorKind.fight => towerCoinsPerBand,
    TowerFloorKind.warden => towerCoinsWarden,
    TowerFloorKind.boss => towerCoinsBoss,
  };
  return band * (base + (floor.elite || floor.elitePack ? towerCoinsElite : 0));
}

// ---------------------------------------------------------------------------
// Coins spent: reroll, banish (the stall is tower_events.dart's towerBuy).

/// A reroll of a table: this, then [towerRerollStep] more each further
/// reroll of the same table (3, 5, 7...).
const int towerRerollPrice = 3;
const int towerRerollStep = 2;

/// A banished card's price; one a table, [towerBanishesPerRun] a run.
const int towerBanishPrice = 4;
const int towerBanishesPerRun = 5;

/// The merchant's boon (a skill, a die or a spell, choose one): its price
/// in coins, halved (rounded up) for one sworn to the merchant's clan (8).
/// The note's 15: with one perk slot (the user's decision) the top with
/// every unlock and the best perk stays inside QA's 18 to 32% band
/// (docs/simulation/tower-coins.md).
const int towerBoonPrice = 15;

/// The stall's boon in the stock's ids (TowerRun.bought): beside 'salve'
/// and 'potions' (towerStockIds), sold apart (TowerEventView.boon).
const String towerStallBoonId = 'boon';

/// The draw index of [floor]'s nth reroll (0 the first) and of its
/// stall's boon on TowerStream.reroll.
int _rerollDraw(int floor, int n) => floor * 16 + min(n, 14);
int _stallDraw(int floor) => floor * 16 + 15;

/// Whether [run]'s table can be rerolled: [run] is choosing and its table
/// holds a card that is not an oath (an oath is never redrawn nor removed:
/// a reroll redraws the gifts or the boon beside it).
bool towerCanReroll(TowerRun run) =>
    run.status == TowerStatus.choosing &&
    run.offer.any((c) => c.kind != TowerRewardKind.clanOath);

/// What the next reroll of [run]'s table costs: free for the climb's first
/// with Free hand worn, else [towerRerollPrice] and [towerRerollStep] more
/// for each reroll already bought on this table.
int towerRerollPriceOf(TowerRun run) {
  final done = run.rerolls[run.floor] ?? 0;
  final any = run.rerolls.values.fold<int>(0, (n, r) => n + r);
  if (run.wears(towerPerkFreeHand) && any == 0) return 0;
  return towerRerollPrice + towerRerollStep * done;
}

/// [run] with its table rerolled, when [towerCanReroll] and its coins pay
/// [towerRerollPriceOf]; [run] as it is otherwise. The table is drawn again
/// on TowerStream.reroll (no draw of the climb moves): a boon floor's
/// boon, a clans' table's gifts (the oaths due stay, first), the cards just
/// shown kept off it while others are left; the cards taken and banished
/// never come back. [hero], when given, is [run]'s hero already built.
TowerRun towerReroll(TowerRun run, TowerData data, {SimCharacter? hero}) {
  if (!towerCanReroll(run)) return run;
  final price = towerRerollPriceOf(run);
  if (price > run.coins) return run;
  final done = run.rerolls[run.floor] ?? 0;
  final drawn = towerRunOfferFor(
      run, data, run.floor, hero ?? towerHeroOf(run, data),
      clansDue: run.offer.any((c) => c.clan.isNotEmpty),
      random: towerRandom(
          run.seed, _rerollDraw(run.floor, done), TowerStream.reroll),
      avoid: {for (final c in run.offer) c.id});
  // The oaths on the table stay, first, as they were.
  return run.copyWith(
    coins: run.coins - price,
    rerolls: {...run.rerolls, run.floor: done + 1},
    offer: [
      for (final c in run.offer)
        if (c.kind == TowerRewardKind.clanOath) c,
      for (final c in drawn)
        if (c.kind != TowerRewardKind.clanOath) c,
    ],
  );
}

/// Whether card [index] of [run]'s table can be banished: a skill, a die or
/// a spell (not an oath, not a rank-up), none banished on this table yet,
/// fewer than [towerBanishesPerRun] this run, [towerBanishPrice] in hand.
bool towerCanBanish(TowerRun run, int index) =>
    run.status == TowerStatus.choosing &&
    index >= 0 &&
    index < run.offer.length &&
    const {
      TowerRewardKind.skill,
      TowerRewardKind.die,
      TowerRewardKind.spell,
    }.contains(run.offer[index].kind) &&
    !run.banished.containsKey(run.floor) &&
    run.banished.length < towerBanishesPerRun &&
    run.coins >= towerBanishPrice;

/// [run] with card [index] of its table banished ([towerCanBanish]): off
/// the table (not refilled: a reroll does that), never offered again this
/// run (TowerHeroView.takenIds), its price paid. [run] as it is otherwise.
TowerRun towerBanish(TowerRun run, int index) {
  if (!towerCanBanish(run, index)) return run;
  return run.copyWith(
    coins: run.coins - towerBanishPrice,
    banished: {...run.banished, run.floor: run.offer[index].id},
    offer: [...run.offer]..removeAt(index),
  );
}

/// The stall's boon for [run] at the merchant of [storeFloor]: three cards
/// (a skill, a die and a spell, as a boon floor's), drawn on
/// TowerStream.reroll.
List<TowerReward> towerStallBoonFor(
        TowerRun run, TowerData data, int storeFloor, SimCharacter hero) =>
    towerRunOfferFor(run, data, storeFloor, hero,
        boon: true,
        random:
            towerRandom(run.seed, _stallDraw(storeFloor), TowerStream.reroll));

/// The cards dealt on [floor] of [run] (towerOfferFor with the run's state
/// and its perks): [hero] is the hero as it stands. Fourth card's extra
/// skill on the first [towerFourthCardTables] boon floors, Keen eye's step
/// on the first, Early word's sooner oath. [clansDue], [random], [avoid]
/// and [boon] as towerOfferFor's.
List<TowerReward> towerRunOfferFor(
  TowerRun run,
  TowerData data,
  int floor,
  SimCharacter hero, {
  bool clansDue = false,
  Random? random,
  Set<String> avoid = const {},
  bool boon = false,
}) {
  final boons = towerBoonFloorsOf(run.heat).toList()..sort();
  final rank = boon ? -1 : boons.indexOf(floor);
  return towerOfferFor(
    seed: run.seed,
    floor: floor,
    hero: towerHeroView(run, hero),
    clanPool: run.clanPool,
    standing: towerStandingOf(run, data),
    oathOpen: run.clanIds.isEmpty,
    clansDue: clansDue,
    heat: run.heat,
    clans: data.clans,
    items: data.items,
    dice: data.dice,
    skills: data.skills,
    spells: data.spells,
    random: random,
    avoid: avoid,
    boon: boon,
    extraSkills: run.wears(towerPerkFourthCard) &&
            rank >= 0 &&
            rank < towerFourthCardTables
        ? towerFourthCardExtra
        : 0,
    rarityBonus:
        run.wears(towerPerkKeenEye) && rank == 0 ? towerKeenEyeSteps : 0,
    oathSooner: run.wears(towerPerkEarlyWord) ? towerEarlyWordFloors : 0,
  );
}

// ---------------------------------------------------------------------------
// Perks (marks, bought once after the tree, one worn a climb).

/// One perk of the marks shop (Narrative's names: `tower_perk_<id>` and
/// `tower_perk_<id>_line`).
class TowerPerk {
  const TowerPerk(this.id, this.cost);

  final String id;

  /// Its price in marks.
  final int cost;

  String get nameKey => 'tower_perk_$id';
  String get lineKey => 'tower_perk_${id}_line';
}

const String towerPerkPurse = 'purse';
const String towerPerkDeepPockets = 'deep_pockets';
const String towerPerkEarlyWord = 'early_word';
const String towerPerkOldFriend = 'old_friend';
const String towerPerkSecondWind = 'second_wind';
const String towerPerkKeenEye = 'keen_eye';
const String towerPerkFreeHand = 'free_hand';
const String towerPerkFourthCard = 'fourth_card';

/// The eight perks, cheapest first (the note's prices +10 each, the user's
/// decision: 405 marks in all).
const List<TowerPerk> towerPerks = [
  TowerPerk(towerPerkPurse, 40),
  TowerPerk(towerPerkDeepPockets, 40),
  TowerPerk(towerPerkEarlyWord, 45),
  TowerPerk(towerPerkOldFriend, 50),
  TowerPerk(towerPerkSecondWind, 50),
  TowerPerk(towerPerkKeenEye, 55),
  TowerPerk(towerPerkFreeHand, 55),
  TowerPerk(towerPerkFourthCard, 70),
];

/// The perk of [id], or null.
TowerPerk? towerPerkOf(String id) {
  for (final p in towerPerks) {
    if (p.id == id) return p;
  }
  return null;
}

/// The perks worn on a climb, whatever is owned: one (the user's decision;
/// the Heat targets are read without perks).
const int towerPerkSlots = 1;

/// [ids] as a climb wears them: known perks, no repeat, the first
/// [towerPerkSlots] (a save or a list with more keeps the first).
List<String> towerWornPerks(Iterable<String> ids) {
  final out = <String>[];
  for (final id in ids) {
    if (out.length >= towerPerkSlots) break;
    if (towerPerkOf(id) != null && !out.contains(id)) out.add(id);
  }
  return out;
}

/// Purse: the coins in hand at the start.
const int towerPurseCoins = 5;

/// Deep pockets: potions more in the bag (towerBagCap 5 to 6).
const int towerDeepPocketsPotions = 1;

/// Early word: the late oath this many floors sooner (15 to 12; 18 to 15
/// at Pyre).
const int towerEarlyWordFloors = 3;

/// Second wind: this share of max health back after a warden or a boss
/// won, on top of the floor's recovery.
const double towerSecondWindShare = .15;

/// Keen eye: the first boon table's skill this many rarity steps up.
const int towerKeenEyeSteps = 1;

/// Fourth card: the first this many boon tables show [towerFourthCardExtra]
/// card more (a skill).
const int towerFourthCardTables = 2;
const int towerFourthCardExtra = 1;

/// The most potions [run]'s bag holds: [towerBagCap], one more with Deep
/// pockets.
int towerBagCapOf(TowerRun run) =>
    towerBagCap +
    (run.wears(towerPerkDeepPockets) ? towerDeepPocketsPotions : 0);

/// Second wind's share back after [run]'s floor (a warden or a boss), else
/// 0.
double towerSecondWindShareOf(TowerRun run) => run.wears(towerPerkSecondWind) &&
        towerBudgetOf(run.floor).kind != TowerFloorKind.fight
    ? towerSecondWindShare
    : 0;

// ---------------------------------------------------------------------------
// Looks and bonuses.

/// One banner trim (no power): `tower_trim_<id>`.
class TowerTrim {
  const TowerTrim(this.id, this.cost);

  final String id;

  /// Its price in marks; 0, never sold ([towerAshTrim]).
  final int cost;

  String get nameKey => 'tower_trim_$id';
}

/// The five trims sold (10 marks each).
const List<TowerTrim> towerTrims = [
  TowerTrim('moth', 10),
  TowerTrim('stitch', 10),
  TowerTrim('brass', 10),
  TowerTrim('bone', 10),
  TowerTrim('lamp', 10),
];

/// The Ash trim: earned with a win at Ash (Heat 5), never sold.
const TowerTrim towerAshTrim = TowerTrim('ash', 0);

/// The trim of [id] (sold or Ash's), or null.
TowerTrim? towerTrimOf(String id) {
  if (id == towerAshTrim.id) return towerAshTrim;
  for (final t in towerTrims) {
    if (t.id == id) return t;
  }
  return null;
}

/// Marks for the first win of the top (the plain climb's), once.
const int towerFirstWinMarks = 30;

/// Marks for the first win at each Heat from 1, once each.
const int towerFirstHeatWinMarks = 20;

/// The bonus marks ended [run] adds to a record whose highest Heat won is
/// [heatWon] (TowerProgress.heatWon, read before the run): a win above it
/// is that Heat's first (Heat n opens only with a win at n - 1), paid
/// [towerFirstWinMarks] at Heat 0, [towerFirstHeatWinMarks] above. Not
/// raised by Heat. 0 otherwise.
int towerFirstWinBonusOf(TowerRun run, int heatWon) =>
    run.status != TowerStatus.won || run.heat <= heatWon
        ? 0
        : run.heat == 0
            ? towerFirstWinMarks
            : towerFirstHeatWinMarks;

/// Everything the marks shop sells after the tree: the perks and the trims
/// (marks).
int get towerShopMarksTotal =>
    towerPerks.fold<int>(0, (n, p) => n + p.cost) +
    towerTrims.fold<int>(0, (n, t) => n + t.cost);
