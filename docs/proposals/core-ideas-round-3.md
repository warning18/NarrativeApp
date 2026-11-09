# Core: improvement ideas, round 3

Core's third round (the manager's brief of 2026-11-09): new items only, in
Core's scope (rules, numbers, state, Journey, the simulator), with removing,
simplifying and optimizing first. Nothing here repeats `core-improvements.md`
(P1–P6, R1–R5, B1–B4), `core-improvements-2.md` (N1–N11),
`cleanup-improvements.md`, or anything merged or held. R5 (one new-game
build and one XP rule for the game and the simulator) is the closest; item 1
below covers a different rule (healing in a fight).

Measured on main at v1.860.0 (cc029450).

## Ranked

| # | Idea | Kind | Size | Risk | What the user would notice |
|---|---|---|---|---|---|
| 1 | One healing rule for the fight and the simulator | simplify | M | medium | nothing, except the simulator's numbers matching the game more closely; fewer bugs like Mending Light's |
| 2 | Build the Tower hero once per move, not six times | optimize | S | low | nothing (the bot and QA's Tower batch run about twice as fast) |
| 3 | Cap the Tower's potion bag | rule | S | low (a number) | the bag stops ending a climb with 11 to 28 potions; potions stay a choice |
| 4 | Remove the Tower's card code that nothing deals any more | remove | S | low | nothing |
| 5 | Re-draw the chest slots the Tower throws away | rule | S | low (a number) | no floor drops an empty chest (15.5% do now) |
| 6 | Migrate old Tower saves once, then drop their three legacy branches | remove | S | low | nothing (a run saved before v1.855 keeps playing) |

My recommendation is 1, then 2 and 4 together (one small PR), then 3 and 5
together (one balance PR, measured with the bot), then 6.

## 1. One healing rule for the fight and the simulator (M, medium)

**What.** A heal in a fight passes through several rules:

- the Anvil-Deaf's wall (no Heal faces);
- the shrine (×1.5);
- the fight-length rule (`rule.heal`, by round);
- healing fatigue (each heal a little less, except the cleric's);
- the Watchfire (what heals past full feeds the fire; a die's heal also
  burns).

Each heal path writes its own copy of these rules:

- on the fight screen: `_healDealt` in `fight_rounds.dart`, and the potion
  and the spell in `fight_actions.dart`;
- in the simulator: the potion and the face in `sim_fight_party_turn.dart`,
  and the spell in `sim_spell_cast.dart`.

That makes five copies, spread over 16 call sites in 5 files. The idea is
one pure function in `lib/combat/` that both the screen and the simulator
call:

- `healOutcome(source, raw, ctx)` → the amount healed, the fire after it,
  and the burn;
- `source` is one of face, spell or potion.

**Why.**

- **The Mending Light bug (v1.859) came from this.** The spell's copy left
  out the Watchfire. The simulator's copy had the same gap, so no balance
  test could see it.
- **At least one copy still differs today.** On screen, a cleric's spell
  heal goes through the fight-length rule (`fight_actions.dart`:
  `_length.rule.heal`). In the simulator, the same heal skips it
  (`sim_fight_party_turn.dart` passes `healed: null` for the cleric, so
  `ctx.heal` is never applied). A die's heal goes through the rule in both.
- One function would also remove three of `_castSpellIfWorth`'s twenty
  named parameters.

**Size and risk.**

- M: one new file with its tests, and the five sites rewritten.
- Medium risk: every heal in the game passes through it. Guard it with a
  table test (each source × each rule), then re-run the simulator batch and
  the Tower bot and compare.
- The fix to the divergence above moves the cleric's simulated numbers a
  little.

## 2. Build the Tower hero once per move, not six times (S, low)

**What.** `towerHeroOf(run, data)` rebuilds the hero from scratch by
replaying the start, every floor's level and picks, every chest and every
card. A move rebuilds it several times:

- `towerAfterFight` alone calls it four times;
- the bot calls it again to choose.

Measured: one rebuild at floor 30 takes 0.21 ms, and a floor of the bot
costs 1.43 ms in all, so the rebuilds are most of the bot's time. The idea
is to keep the last hero built for a given run (an `Expando` on the
`TowerRun`, which is immutable) and build the next one from it.

**Why.**

- QA's Tower guard plays 1,000 runs on every CI build, and its report batch
  plays 4,000.
- My balance measures (1,500 seeds × 2) took about 20 minutes each. This
  would roughly halve them.

**Size and risk.**

- S: one file.
- Low risk: the hero is a pure function of the run. A test can compare the
  cached hero with a fresh one over a few hundred runs.

**The user notices:** nothing.

## 3. Cap the Tower's potion bag (S, low, a number)

**What.** Since v1.860, the chest's potions go in a bag carried from floor
to floor, with no limit. The bot ends a climb with these potions in the
bag:

| | Median | Most |
|---|---|---|
| Every unlock | 11 | 28 |
| No unlocks | 7 | |

The idea is a cap of 5, the story's own feel for a carried stock. What a
full bag can't hold is drunk at once, healing as the potion does, so
nothing is wasted.

**Why.** A bag of 20 potions makes the late floors a matter of pressing
Potion, and takes the choice out of each one.

**Size and risk.**

- S: one constant and two lines in `towerAfterFight`.
- Low risk, but it is a number: re-measure with the bot. The top may drop
  a point or two, which `towerFoeScale` can take back.

**The user notices:** the bag stays small. A full bag heals right away at
the chest.

## 4. Remove the Tower's card code that nothing deals any more (S, low)

**What.** Since v1.860, a floor offers boons (a skill, a die or a spell) or
an oath. Nothing deals a heal, item or clan-gift card any more, but this
code is still there:

- the three cases of `towerOfferFor`'s `draw`;
- `towerRewardWeights` and `towerOfferSize`;
- `towerHealShare`, `towerBigHealShare` and `towerHealFloor`;
- the bot's heal and gift branches.

That is 26 references. The idea is to remove them and keep
`towerApplyReward`'s cases, so an old save's waiting offer still applies
(or, with item 6, migrate it).

**Why.**

- Less to read in the Tower's two biggest files.
- The tables no longer list numbers that do nothing.

**Size and risk.**

- S, low: `tower_engine_test` and `tower_oaths_test` already cover what is
  dealt.

**The user notices:** nothing.

## 5. Re-draw the chest slots the Tower throws away (S, low, a number)

**What.** The Tower keeps only a chest's gear and potions. It drops the
gold pouch, charms, tomes and materials, which a Tower hero can't use. So
15.5% of floors won drop an empty chest (300 runs, 4,793 floors). On
average a chest gives 0.61 gear and 0.77 potions. The idea is to re-draw a
dropped slot from the same tier's gear-or-potion weights, so every chest
holds something.

**Why.**

- An empty chest after a fight reads as a bug.
- The user asked for the main game's spoils, and in the main game a chest
  is never empty.

**Size and risk.**

- S: a small loop in `towerSpoilsFor`.
- Low risk, but more gear and potions make the climb easier: measure it
  with item 3 in the same PR, and take any gain back with `towerFoeScale`.

**The user notices:** every floor's chest has something in it.

## 6. Migrate old Tower saves once, then drop their legacy branches (S, low)

**What.** `TowerRun` carries three paths for saves made before recent
releases:

- `clanId` sworn at the start (before v1.855);
- `autoPicks`, a level's point given to the damage stat (before v1.857);
- an offer holding the old cards (before v1.860).

A Tower run is short, a climb of minutes. The idea is to convert a saved
run once at load, then remove the three branches from the hero, the run and
the session:

- the start clan becomes the first oath taken, on floor 0;
- the auto picks become the calling's pick;
- the old cards are applied as they are.

**Why.** Each new Tower rule has had to read around these branches: the
v1.857 picks, the v1.860 spoils and the oaths' main clan.

**Size and risk.**

- S, with one migration test per old shape (the save JSON of each version
  is in the tests).
- Low risk: a run started before v1.855 becomes a run sworn to its clan
  from floor 1, as it was.

**The user notices:** nothing.

## Looked at and dropped

- **Folding `towerFoeScale` into the floor extras.** It is one factor on
  top of a table, as N5 was for the damage floor. But each Tower step has
  used it as the one knob that keeps the climb's difficulty, so it earns
  its place while the Tower is still moving.
- **A smarter bot potion policy** (drink before a boss, not below 40%). It
  would change what the bot measures, not the game. Item 3 deals with the
  hoard in the game itself.
