// The Tower's rules 4 (docs/simulation/tower-round2-proposals.md, approved
// by the user as proposed): rules 3 and
// - A. the gamble card: on [towerGambleLootChance] of the loot tables and
//   [towerGambleLevelUpChance] of the Level Up tables one card (never an
//   oath) is dealt face down, its outcome drawn with the table on
//   TowerStream.gamble and saved apart (TowerRun.gambleOutcome), the hero's
//   Perception reading its back (towerGambleHintOf); taken, it is final;
// - B. the eight perks redesigned (their prices unchanged; rules 3 climbs
//   keep today's effects): Purse's coins and the pedlar (towerBuyPotion),
//   Deep pockets' and Early word's flask (towerFlaskOf), Old friend's gear
//   (towerOldFriendGearFor), Second wind after every floor, Keen eye's and
//   Fourth card's loot tables (towerLootTierBonusOf, towerLootCardsOf),
//   Free hand's reroll of each table (towerRerollPriceOf);
// - C. the stat-pick card: on [towerStatPickChance] of the Level Up tables
//   the die-or-spell card is "+1 to a stat of your choice", outside the
//   nudge caps and not counted in them;
// - the foes of floors 11 to 30 3% more (towerRoundTwoUpperScale).
//
// Every knob here is read behind `rules >= towerRoundTwoRules`: rules 1 to
// 3 deal, give and fight as before. Pure, as the rest of lib/data/tower/.

import 'dart:math';

import '../sim_combat.dart' show SimCharacter;
import 'tower_coins.dart';
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_levelup_loot.dart';
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

/// Whether a climb on [rules] plays the round-2 package.
bool towerRoundTwoOf(int rules) => rules >= towerRoundTwoRules;

// ---------------------------------------------------------------------------
// A. The gamble card.

/// The share of loot tables, and of Level Up tables, dealt a gamble card.
const double towerGambleLootChance = .15;
const double towerGambleLevelUpChance = .15;

/// The outcomes under a loot table's gamble card, by weight (70 good, 30
/// bad), in draw order.
const Map<TowerGambleOutcome, int> towerGambleLootWeights = {
  TowerGambleOutcome.gilded: 35,
  TowerGambleOutcome.twin: 25,
  TowerGambleOutcome.hoard: 10,
  TowerGambleOutcome.dud: 10,
  TowerGambleOutcome.wound: 12,
  TowerGambleOutcome.spill: 8,
};

/// The outcomes under a Level Up table's gamble card, by weight.
const Map<TowerGambleOutcome, int> towerGambleLevelUpWeights = {
  TowerGambleOutcome.bright: 35,
  TowerGambleOutcome.twin: 30,
  TowerGambleOutcome.dud: 15,
  TowerGambleOutcome.wound: 12,
  TowerGambleOutcome.hex: 8,
};

/// The good outcomes (the hint "it feels lucky"); the others are bad.
const Set<TowerGambleOutcome> towerGambleGood = {
  TowerGambleOutcome.gilded,
  TowerGambleOutcome.twin,
  TowerGambleOutcome.hoard,
  TowerGambleOutcome.bright,
};

/// The Perception that reads good or bad on the card's back, and the one
/// that reads what it is.
const int towerGambleHintGood = 3;
const int towerGambleHintKind = 5;

/// Gilded: the loot draw this many chest tiers up. Bright: the skill this
/// many rarity steps up.
const int towerGambleGildedTiers = 1;
const int towerGambleBrightSteps = 1;

/// Hoard: these coins on floors 1-10, and this many more a band above.
const int towerGambleHoardCoins = 4;
const int towerGambleHoardBand = 2;

/// Wound: this share of max health lost (never below 1); Spill with no
/// potion in the bag, this share.
const double towerGambleWoundShare = .20;
const double towerGambleSpillShare = .10;

/// Hex: the next floor's foes this much stronger (towerHexFloor).
const double towerHexFoeScale = 1.15;

/// Whether [outcome] is a good one.
bool towerGambleIsGood(TowerGambleOutcome outcome) =>
    towerGambleGood.contains(outcome);

/// What the back of the gamble card on [run]'s table tells [hero]: none
/// with no gamble card on it or a Perception under [towerGambleHintGood];
/// good or bad from it; the kind from [towerGambleHintKind]
/// (towerGambleOutcomeShown).
TowerGambleHint towerGambleHintOf(TowerRun run, SimCharacter hero) {
  final outcome = run.gambleOutcome;
  if (outcome == null ||
      !run.offer.any((c) => c.kind == TowerRewardKind.gamble)) {
    return TowerGambleHint.none;
  }
  if (hero.perception >= towerGambleHintKind) return TowerGambleHint.kind;
  if (hero.perception >= towerGambleHintGood) {
    return towerGambleIsGood(outcome)
        ? TowerGambleHint.good
        : TowerGambleHint.bad;
  }
  return TowerGambleHint.none;
}

/// The outcome of the gamble card on [run]'s table when [hero] reads what
/// it is (towerGambleHintOf kind), else null.
TowerGambleOutcome? towerGambleOutcomeShown(TowerRun run, SimCharacter hero) =>
    towerGambleHintOf(run, hero) == TowerGambleHint.kind
        ? run.gambleOutcome
        : null;

// ---------------------------------------------------------------------------
// C. The stat-pick card.

/// The share of Level Up tables whose die-or-spell card is the stat pick.
const double towerStatPickChance = .15;

/// The stats the stat-pick card can raise.
const List<String> towerStatPickStats = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
];

/// The stat the bot puts the stat-pick card's point in: its damage stat.
String towerBotStatChoice(SimCharacter hero) => hero.preferredStat;

// ---------------------------------------------------------------------------
// The deal.

/// [cards] (a table of [run] dealt on [table]) as rules 4 deals them: one
/// card, not an oath, turned face down on [towerGambleLootChance] /
/// [towerGambleLevelUpChance] of the tables (its outcome returned, by
/// weight); on a Level Up table, on [towerStatPickChance] of them, the last
/// card that is not the gamble, an oath or a clan's (the die or the spell)
/// made the stat pick. Drawn on TowerStream.gamble from the floor and the
/// Level Up's number, so a reload deals the same.
({List<TowerReward> offer, TowerGambleOutcome? outcome}) towerDealRoundTwo(
    TowerRun run, List<TowerReward> cards, TowerTableKind table) {
  final levelUp = table == TowerTableKind.levelUp;
  final random = towerRandom(
      run.seed,
      run.floor * 8 + (levelUp ? 1 + towerLevelUpsTaken(run) % 7 : 0),
      TowerStream.gamble);
  final out = [...cards];
  final open = [
    for (var i = 0; i < out.length; i++)
      if (out[i].kind != TowerRewardKind.clanOath) i,
  ];
  if (open.isEmpty) return (offer: out, outcome: null);
  // Every draw made whatever comes of it, so one never moves another.
  final gambleRoll = random.nextDouble();
  final gambleAt = open[random.nextInt(open.length)];
  final outcomeRoll = random.nextInt(1 << 30);
  final statRoll = random.nextDouble();
  TowerGambleOutcome? outcome;
  if (gambleRoll <
      (levelUp ? towerGambleLevelUpChance : towerGambleLootChance)) {
    outcome = _drawOutcome(
        levelUp ? towerGambleLevelUpWeights : towerGambleLootWeights,
        outcomeRoll);
    out[gambleAt] = const TowerReward(TowerRewardKind.gamble);
  }
  if (levelUp && statRoll < towerStatPickChance) {
    for (var i = out.length - 1; i >= 0; i--) {
      if (out[i].kind == TowerRewardKind.gamble ||
          out[i].kind == TowerRewardKind.clanOath ||
          out[i].clan.isNotEmpty) {
        continue;
      }
      out[i] = const TowerReward(TowerRewardKind.statPick);
      break;
    }
  }
  return (offer: out, outcome: outcome);
}

TowerGambleOutcome _drawOutcome(
    Map<TowerGambleOutcome, int> weights, int roll) {
  final total = weights.values.fold<int>(0, (n, w) => n + w);
  var r = roll % total;
  for (final MapEntry(:key, :value) in weights.entries) {
    if (r < value) return key;
    r -= value;
  }
  return weights.keys.last;
}

// ---------------------------------------------------------------------------
// The gamble taken.

Random _gambleRandom(TowerRun run, int salt) =>
    towerRandom(run.seed, 4000 + run.floor * 8 + salt, TowerStream.gamble);

void _wound(SimCharacter hero, double share) {
  hero.currentHealth =
      max(1, hero.currentHealth - (hero.maxHealth * share).round());
}

/// The cards of [run]'s table besides the gamble and the stat pick (and,
/// with [oaths] false, the oaths).
List<TowerReward> _others(TowerRun run, {bool oaths = true}) => [
      for (final c in run.offer)
        if (c.kind != TowerRewardKind.gamble &&
            c.kind != TowerRewardKind.statPick &&
            (oaths || c.kind != TowerRewardKind.clanOath))
          c,
    ];

/// [run] with its loot table's gamble card taken, [outcome] under it:
/// Gilded the best gear of a draw [towerGambleGildedTiers] tier up (taken as
/// the loot card); Twin the first two other cards (the first as the loot
/// card, the second in TowerRun.gambles); Hoard its coins; Wound and Spill
/// [hero]'s health or the bag. The floor's loot card is the gamble's mark
/// (TowerReward(gamble, id: the outcome)) for those that give no card.
TowerRun towerTakeLootGamble(TowerRun run, TowerGambleOutcome outcome,
    SimCharacter hero, TowerData data) {
  final mark = {
    ...run.loot,
    run.floor: TowerReward(TowerRewardKind.gamble, id: outcome.name),
  };
  final others = _others(run);
  switch (outcome) {
    case TowerGambleOutcome.gilded:
      final drawn = towerRunLootFor(run, data, hero,
          random: _gambleRandom(run, 0), tierBonus: towerGambleGildedTiers);
      TowerReward? best;
      for (final c in drawn) {
        if (c.kind != TowerRewardKind.gear) continue;
        if (best == null ||
            towerGearScore(c.id, data) > towerGearScore(best.id, data)) {
          best = c;
        }
      }
      best ??= drawn.isEmpty
          ? null
          : drawn.firstWhere((c) => c.kind == TowerRewardKind.bundle,
              orElse: () => drawn.first);
      return best == null
          ? run.copyWith(loot: mark)
          : towerTakeLoot(run, best, hero, data);
    case TowerGambleOutcome.twin:
      if (others.isEmpty) return run.copyWith(loot: mark);
      final next = towerTakeLoot(run, others.first, hero, data);
      if (others.length < 2) return next;
      return towerTakeLoot(next, others[1], hero, data).copyWith(loot: {
        ...run.loot,
        run.floor: others.first
      }, gambles: {
        ...run.gambles,
        run.floor: [...?run.gambles[run.floor], others[1]],
      });
    case TowerGambleOutcome.hoard:
      final coins = towerGambleHoardCoins +
          towerGambleHoardBand * towerLootBandOf(run.floor);
      return run.copyWith(
          loot: mark,
          coins: run.coins + coins,
          coinsEarned: run.coinsEarned + coins);
    case TowerGambleOutcome.wound:
      _wound(hero, towerGambleWoundShare);
      return run.copyWith(loot: mark);
    case TowerGambleOutcome.spill:
      if (run.potions > 0) {
        return run.copyWith(loot: mark, potions: run.potions - 1);
      }
      _wound(hero, towerGambleSpillShare);
      return run.copyWith(loot: mark);
    default:
      return run.copyWith(loot: mark);
  }
}

/// [run] with its Level Up table's gamble card taken, [outcome] under it;
/// [level] is the floor's Level Up entries, given this one (a card, or null
/// for a level spent). Bright a skill card [towerGambleBrightSteps] rarity
/// step up; Twin the first two other cards (the second in TowerRun.gambles),
/// each with its nudge; Wound [hero]'s health; Hex its mark in
/// TowerRun.gambles (the next floor's foes, towerHexFloor); Dud nothing.
TowerRun towerTakeLevelUpGamble(TowerRun run, TowerGambleOutcome outcome,
    SimCharacter hero, TowerData data, List<TowerReward?> level) {
  void give(TowerReward card) {
    towerApplyReward(hero, card, data, bag: run.dieChoice != null);
    towerNudgeOn(hero, card, data, rules: run.rules);
  }

  final others = _others(run, oaths: false);
  switch (outcome) {
    case TowerGambleOutcome.bright:
      final drawn = towerOfferFor(
        seed: run.seed,
        floor: run.floor,
        hero: towerHeroView(run, hero),
        items: data.items,
        dice: data.dice,
        skills: data.skills,
        spells: data.spells,
        random: _gambleRandom(run, 1 + towerLevelUpsTaken(run) % 7),
        avoid: {for (final c in run.offer) c.id},
        levelUp: true,
        levelUpOaths: false,
        rarityBonus: towerGambleBrightSteps,
      );
      final skills = drawn.where((c) =>
          c.kind == TowerRewardKind.skill || c.kind == TowerRewardKind.rankUp);
      final got = skills.isNotEmpty
          ? skills.first
          : (drawn.isNotEmpty ? drawn.first : null);
      level.add(got);
      if (got != null) give(got);
      return run;
    case TowerGambleOutcome.twin:
      if (others.isEmpty) {
        level.add(null);
        return run;
      }
      level.add(others.first);
      give(others.first);
      if (others.length < 2) return run;
      give(others[1]);
      return run.copyWith(gambles: {
        ...run.gambles,
        run.floor: [...?run.gambles[run.floor], others[1]],
      });
    case TowerGambleOutcome.wound:
      level.add(null);
      _wound(hero, towerGambleWoundShare);
      return run;
    case TowerGambleOutcome.hex:
      level.add(null);
      return run.copyWith(gambles: {
        ...run.gambles,
        run.floor: [
          ...?run.gambles[run.floor],
          towerHexMark,
        ],
      });
    default:
      level.add(null);
      return run;
  }
}

/// Hex's mark in TowerRun.gambles.
const TowerReward towerHexMark = TowerReward(TowerRewardKind.gamble, id: 'hex');

/// Whether [run]'s next fight is hexed: a Hex taken on the floor below it.
bool towerHexedOf(TowerRun run) =>
    towerRoundTwoOf(run.rules) &&
    (run.gambles[run.floor - 1] ?? const []).contains(towerHexMark);

/// [floor] (the one [run] fights next) as it is fought: its foes
/// [towerHexFoeScale] stronger when hexed ([towerHexedOf]). Both the app's
/// fight (towerFloorOf, TowerFloor.modifiersFor) and the bot's read it.
TowerFloor towerHexFloor(TowerRun run, TowerFloor floor) =>
    towerHexedOf(run) ? floor.scaledBy(towerHexFoeScale) : floor;

// ---------------------------------------------------------------------------
// B. The perks on rules 4.

/// Purse: the coins in hand at the start (rules 3: towerPurseCoins).
const int towerRoundTwoPurseCoins = 15;

/// Purse's pedlar: a potion for this many coins on any landing.
const int towerPedlarPrice = 4;

/// Deep pockets: the flask holds this many potions more (every fight).
const int towerDeepPocketsFlask = 1;

/// Early word: the flask holds this many more on a warden's or a boss's
/// floor.
const int towerEarlyWordFlask = 2;

/// Old friend: the start's piece of gear, the best of a loot draw this many
/// chest tiers up.
const int towerOldFriendTiers = 2;

/// Second wind: this share of max health back after every other floor won.
const double towerSecondWindFloorShare = .08;

/// Keen eye: the loot tables one chest tier up up to this floor.
const int towerKeenEyeLootFloors = 10;
const int towerKeenEyeLootTiers = 1;

/// Free hand: the first reroll of each table free up to this floor.
const int towerFreeHandFloors = 10;

/// Fourth card: every loot table one card more up to this floor.
const int towerFourthCardLootFloors = 20;
const int towerFourthCardLootExtra = 1;

/// The coins [worn]'s Purse puts in hand at the start on [rules].
int towerPurseCoinsFor(int rules) =>
    towerRoundTwoOf(rules) ? towerRoundTwoPurseCoins : towerPurseCoins;

/// The potions [run]'s flask holds for its next fight: [towerFlask], one an
/// [towerUnlocksPerPotion] unlocks owned, and on rules 4 Deep pockets' and
/// (a warden's or a boss's floor) Early word's. The app's fight
/// (towerSessionOf) and the bot's read it through towerHeroOf.
int towerFlaskOf(TowerRun run) {
  var flask = towerFlask + run.unlocksOwned ~/ towerUnlocksPerPotion;
  if (!towerRoundTwoOf(run.rules)) return flask;
  if (run.wears(towerPerkDeepPockets)) flask += towerDeepPocketsFlask;
  if (run.wears(towerPerkEarlyWord) &&
      towerBudgetOf(run.floor).kind != TowerFloorKind.fight) {
    flask += towerEarlyWordFlask;
  }
  return flask;
}

/// The chest tiers [run]'s loot table is raised by its perk (Keen eye on
/// rules 4, floors 1 to [towerKeenEyeLootFloors]).
int towerLootTierBonusOf(TowerRun run) => towerRoundTwoOf(run.rules) &&
        run.wears(towerPerkKeenEye) &&
        run.floor <= towerKeenEyeLootFloors
    ? towerKeenEyeLootTiers
    : 0;

/// The cards [run]'s loot table deals (Fourth card on rules 4, floors 1 to
/// [towerFourthCardLootFloors]: one more).
int towerLootCardsOf(TowerRun run) =>
    towerLootCards +
    (towerRoundTwoOf(run.rules) &&
            run.wears(towerPerkFourthCard) &&
            run.floor <= towerFourthCardLootFloors
        ? towerFourthCardLootExtra
        : 0);

/// Whether [run]'s next reroll is free by Free hand's rules-4 effect: the
/// first of each table, floors 1 to [towerFreeHandFloors].
bool towerFreeHandTableOf(TowerRun run) =>
    towerRoundTwoOf(run.rules) &&
    run.wears(towerPerkFreeHand) &&
    (run.rerolls[run.floor] ?? 0) == 0 &&
    run.floor <= towerFreeHandFloors;

/// Old friend's piece of gear for a climb of [seed] by [hero] (its start):
/// the best of floor 1's loot draw [towerOldFriendTiers] chest tiers up, on
/// TowerStream.gamble; null when the draw holds no gear.
TowerReward? towerOldFriendGearFor(
    int seed, String professionId, SimCharacter hero, TowerData data,
    {int events = 0, int heat = 0, required int rules}) {
  final floor = towerFloorsFor(seed, data.enemies,
      events: events, heat: heat, rules: rules)[0];
  final drawn = towerLootFor(
    seed: seed,
    floor: floor,
    ownedItemIds: hero.ownedItemIds,
    preferredScalingStat:
        (data.professions[professionId] as Map?)?['preferredScalingStat']
                ?.toString() ??
            '',
    items: data.items,
    random: towerRandom(seed, 999, TowerStream.gamble),
    tierBonus: towerOldFriendTiers,
  );
  TowerReward? best;
  for (final c in drawn) {
    if (c.kind != TowerRewardKind.gear) continue;
    if (best == null ||
        towerGearScore(c.id, data) > towerGearScore(best.id, data)) {
      best = c;
    }
  }
  return best;
}

/// Whether [run] can buy a potion from Purse's pedlar: rules 4, Purse worn,
/// on a landing (climbing, its fight not begun), [towerPedlarPrice] coins in
/// hand, the bag below its cap (towerBagCapOf).
bool towerCanBuyPotion(TowerRun run) =>
    towerRoundTwoOf(run.rules) &&
    run.wears(towerPerkPurse) &&
    run.status == TowerStatus.climbing &&
    !run.fightBegun &&
    run.coins >= towerPedlarPrice &&
    run.potions < towerBagCapOf(run);

/// [run] with a potion bought from the pedlar ([towerCanBuyPotion]): one
/// in the bag, [towerPedlarPrice] coins paid; [run] as it is otherwise.
TowerRun towerBuyPotion(TowerRun run) => !towerCanBuyPotion(run)
    ? run
    : run.copyWith(
        coins: run.coins - towerPedlarPrice, potions: run.potions + 1);
