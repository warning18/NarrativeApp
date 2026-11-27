# Tower: early floors that threaten (rules 5, as built)

Core. The user's feedback: "Still feels the firsts fights are too easy."
The user approved the proposal below as written (rules 5, for new climbs
only). This file is that proposal, updated to what was built and measured
on the real code. Rules 1 to 4 are untouched: climbs begun on them play as
before.

## What rules 5 does

On **floors 1 to 3** of a climb begun on rules 5 (`towerEarlyFloorOf`):

1. **The foes strike first.** `TowerFloor.modifiersFor` forces the app's
   own ambush (`forcedCondition: BattlefieldCondition.ambush`): the foes
   take a full turn before the first roll, and their intents are hidden
   that round. In place of the battlefield condition the fight would
   otherwise roll (a forced condition stands).
2. **Their damage grows with the unlocks' health.** A new damage-only
   `EncounterModifiers.damageMultiplier` (default 1.0, so every other
   fight is unchanged) is the hero's unlock health factor
   `1 + towerHealthPerUnlockFor(...) × unlocksOwned` to the power
   `towerEarlyUnlockDamage` = **0.9** (the proposal had 1.0, see the
   retune below): ×1 with no unlocks; with all ten, ×2.17 for a human
   warrior (×1.35 to ×2.56 over the peoples and callings). Their health
   does not change with it. `fight_setup.dart` applies it right after the
   curve, before the Elite, pack and squad multipliers.
3. **A little less health, more health back.** The foes' health scale on
   floors 1 to 3 is ×`towerEarlyScale` = .85 (3.0 / 4.2 / 4.5 →
   2.55 / 3.57 / 3.83, in `towerRulesScaleOf`). Health back after floors 1
   to 3 is `towerEarlyRecoveryShare` = 25% at every Heat (was 10%, 5% at
   Heat 3+; `towerRecoveryShareFor` takes the floor).

Floor 4 and up are rules 4's. `towerRulesLive` and `towerRulesMax` are 5:
a new climb plays rules 5. No new screen: the ambush, its log line and its
hidden intents are the fight screen's own. A line saying why the foes
strike first on floors 1 to 3 may be wanted (UX / Narrative, through the
manager).

## Knobs (old → new; read behind `rules >= towerEarlyRules`)

| knob | old | new | file |
|---|---|---|---|
| `towerRulesLive`, `towerRulesMax` | 4 | 5 | `lib/data/tower/tower_tables.dart` |
| `towerEarlyRules`, `towerEarlyFloors` | — | 5, 3 (floors 1–3) | `tower_tables.dart` |
| ambush on floors 1–3 | none (rolled, 25%) | forced (`TowerFloor.ambush`, `modifiersFor`) | `lib/data/tower/tower_floors.dart` |
| foes' damage on floors 1–3 | ×1 | × unlock health factor ^ `towerEarlyUnlockDamage` (.9) (`towerEarlyDamageFor`, `TowerFloor.damageFor`) | `tower_tables.dart`, `tower_floors.dart`, `lib/combat/encounter.dart` (`damageMultiplier`), `lib/screens/fight/fight_setup.dart` (one line, shared file) |
| foes' health on floors 1–3 | 3.0 / 4.2 / 4.5 | ×`towerEarlyScale` .85 | `tower_tables.dart` (`towerRulesScaleOf`) |
| health back after floors 1–3 | .10 (.05 at Heat 3+) | `towerEarlyRecoveryShare` .25 at every Heat | `tower_tables.dart` (`towerRecoveryShareFor`), `tower_levelup_loot.dart` |
| headless fight | — | `ambush`, `damageMultiplier` on `simulateSimFight` | `lib/data/sim_combat.dart`, `sim_combat/sim_fight.dart`, `sim_fight_setup.dart`; `tower_bot.dart` passes them |
| the app's fight | — | `towerFightScreen` passes the run's race and unlocks to `modifiersFor` | `lib/screens/tower/tower_fight_launcher.dart` |

## The ambush: the app's against the headless fight's

What the fight screen does with `BattlefieldCondition.ambush`
(`fight_setup.dart` `_startFight`, `fight_enemy_turn.dart`,
`fight_queries.dart`, `fight_clash.dart`):

- The fight opens, its log says the condition, then `_roundsStarted = 0`
  and `_takeEnemyTurn` runs: the squad's healers, then each foe's move as
  in any turn (a fresh roll; guards, charges, heals and tampering
  included), against a party that has played nothing (no block). Then the
  next moves are rolled ahead and `_startPartyRound` opens round 1.
- **Hidden intents**: `_effectiveTierFor` is `TelegraphTier.none` while
  `_roundsStarted <= 1`, so through round 1 the party reads nothing. What
  that changes in play: a Defend face does not brace for a visible blow
  (`_isTelegraphedTarget`, the ×2 brace), the elements' resistances are
  not shown, and the Perception chest slot is not earned that round. The
  parry chip still offers any foe with an attack waiting
  (`_canParryEnemy` reads the pending move, not the telegraph).
- Also: the sellsword's opening strike and the ground's first word wait
  for round 1; the round-0 blows read round 0 wherever a rule reads the
  round (as the headless fight's do). Damage, dodge, block and armour
  are the ordinary turn's. No initiative roll, no first-round penalty, no
  extra damage. An ambush pays +10 on the spoils chest's fortune (no chest
  in the Tower). Open Eyes (a sign) cancels an ambush by Void foes (the
  Tower hero wears no signs).

The headless fight (`simulateSimFight(ambush: true)`): one `_enemyTurn`
before round 1, with `rounds` 0, no block and no guard, then the rounds as
before. It matches the app's turn. Differences, and their likely size:

- **The brace.** The headless fight never models the ×2 brace of a
  telegraphed blow, in any round, so hiding it in round 1 changes nothing
  there. In the app a player who Defends against a visible blow in round 1
  of a rules-4 fight blocks twice as much; in a rules-5 early fight he
  cannot. So the app's round 1 on floors 1 to 3 is a little harder for a
  careful player than for the bot (the bot was already weaker than such a
  player on every other round). Small: one Defend face's block, once a
  fight.
- **The parry.** The bot parries the strongest attack rolled ahead, as the
  app's chip allows even under the ambush. Same.
- **Reading the foes.** The bot reads nothing in any round, so the hidden
  resistances do not matter to it.
- **The conditions the app rolls.** The headless fight plays none, so on
  rules 4 the app was a little harder than the bot on floors 1 to 3 (a 25%
  roll, an ambush among them). On rules 5 the forced ambush replaces that
  roll on floors 1 to 3: there the bot and the app now play the same
  condition.
- **Rounding.** The app rounds the foe's damage after the curve, after
  `damageMultiplier`, then after the pack; the headless fight rounds once
  over the product (as it already did for the curve and the pack). At
  most 1 point a blow.

## Results on the real code (2,000 seeds, events on, no perks, full coins)

Rules 4 reproduces the proposal's baseline exactly (reach none 28.25 /
3.65 / 0.25, all 81.85 / 44.10 / 9.45, H3 all 76.50 / 30.25 / 4.20; 24.15%
and 1.2% of climbs ending before floor 5).

| | case | f10 | f20 | top | end < f5 | f1–3 rounds | f1–3 HP lost a fight won, after (before) potions | f1–3 foes' first turn lands | f1–3 hit before the 2nd roll |
|---|---|---|---|---|---|---|---|---|---|
| rules 4 | none | 28.25 | 3.65 | 0.25 | 24.15% | 4.31 | 17.6% (29.0%) | 61% | 61% |
| | all | 81.85 | 44.10 | 9.45 | 1.20% | 3.38 | 10.1% (11.4%) | 60% | 60% |
| | H3 all | 76.50 | 30.25 | 4.20 | 1.60% | 3.51 | 10.4% (12.1%) | 61% | 61% |
| proposal (prototype) | none | 30.30 | 3.55 | 0.20 | 21.1% | | 21.9% (32%) | 76% | |
| | all | 80.30 | 43.00 | 9.15 | 3.4% | | 22.8% (29%) | 76% | |
| | H3 all | 73.40 | 28.90 | 3.75 | | | | | |
| rules 5 at power 1.0 (as proposed) | none | 30.30 | 3.55 | 0.20 | 21.15% | 3.89 | 21.9% (32.1%) | 69% | 81% |
| | all | 79.20 | 42.70 | 8.80 | 4.30% | 3.08 | 22.7% (28.9%) | 70% | 82% |
| | H3 all | 72.70 | 28.30 | 3.65 | 5.65% | 3.18 | 23.4% (30.3%) | 70% | 82% |
| **rules 5 as built (power .9)** | none | **30.30** | **3.55** | **0.20** | **21.15%** | 3.89 | **21.9% (32.1%)** | 69% | 81% |
| | all | **80.20** | **43.30** | **9.15** | **3.15%** | 3.09 | **21.7% (27.0%)** | 70% | 82% |
| | H3 all | **74.00** | **28.90** | **3.90** | 4.10% | 3.20 | 22.3% (28.4%) | 70% | 82% |

By floor, every unlock, as built: health lost a fight won 19.8 / 24.0 /
21.8%, floor 4 unchanged at 19.3% (rules 4: 8.3 / 11.9 / 10.6 / 18.9%).
No unlocks: 23.4 / 23.5 / 18.1%, floor 4 25.6% (more climbs reach it).
Fights won untouched on floors 1 to 3: 15.7% with none (rules 4 22.1%),
15.3% with all (30.1%). Fights lost on floors 1 to 3: none 3.7% (4.3%), all
0.7% (0.02%).

- **No unlocks matches the prototype exactly** (the ambush, the health and
  the give-back are the prototype's; the damage factor is 1 there).
- **The retune.** With every unlock, the power 1.0 on the real code ran a
  little harder than the prototype: floor 10 79.2% (80.3%), 4.3% of climbs
  ending before floor 5 (3.4%), the top 8.8% (9.15%), and at Heat 3 the top
  3.65%, the edge the proposal named ("if it holds, the unlock-damage power
  can go to 0.9"). At 0.9 every unlock lands on the proposal's numbers
  (80.2 / 43.3 / 9.15, 3.15%; H3 74.0 / 28.9 / 3.90), and floors 1 to 3
  still cost 21.7% of max health a fight won, beside no unlocks' 21.9%.
  The likely cause of the gap is where the prototype put its factor (its
  knobs were globals, not committed); the real code applies it to the
  foe's damage stat after the curve, as the app does.
- **Round 1.** Two readings, since the proposal's 76% is not reproduced by
  either: the foes' first turn lands a blow in 69–70% of the early fights
  (61% on rules 4); a blow lands before the hero's second roll (the
  ambush's turn and round 1's) in 81–82% (61%). The prototype's probe
  likely counted something between the two.

## Guards

- `qa_tower_sim_test.dart`: the bands hold on the 500 guard seeds, no
  re-band. Events on: median 8 (6–10), floor 20 3.0% (2–8%), the top with
  none 0.0% (0–1%), with all 8.0% (6–15%); events off: 8, 3.0%, 0.0%, 7.2%.
  "With none, floor 20 is reached" holds (15 climbs). A comment records the
  numbers.
- `qa_tower_live_pin_test.dart` moves on purpose: none 1 / 19 / 3983 →
  0 / 15 / 4144 (the prototype's exactly); all 43 / 214 / 9013 →
  40 / 210 / 8889 (prototype 43 / 213 / 8923).
- `towerRulesLive` pins: `test/tower_rules4_test.dart` (a rules-4 climb
  stays rules 4) and `test/tower_levelup_loot_test.dart` read 5.
- New `test/tower_rules5_test.dart`: the modifiers per floor and rules, the
  app's fight screen carrying them, the damage factor with none and all,
  the health scale, 25% back after floors 1 to 3 at Heat 0 and 3, the
  headless fight's ambush and damage, the save round trip, a new climb on
  rules 5.
- Rules 1 to 4 are byte-identical: the bot's whole climbs (`TowerRun.toJson`
  of every run) on rules 1, 2, 3, 4 and rules 4 at Heat 3, seeds 1 to 1000,
  none and all, compared with `cmp` against main.

## The proposal (as approved)

The sections below are the proposal's, measured on rules 4 (v2.10.39)
with the prototype. Its recommendation is what was built, with the power
0.9 (above).

### Why the early fights felt easy (rules 4, floors 1–4)

| | no unlocks | every unlock |
|---|---|---|
| hero max health at floor 1 | 24 | 52 |
| foes a fight (f1 / f2 / f3 / f4) | 1 / 1 / 1 / 1.15 | same |
| foes' damage stat a round, share of hero max | 14–17% (f4 27%) | 6–8% (f4 14%) |
| rounds a fight won | 4.3 | 3.6 (f1 2.8; 11% in one round) |
| health lost a fight won, after potions (f1 / f2 / f3 / f4) | 18.0% (21 / 17 / 13 / 19) | 12.5% (8 / 12 / 11 / 19) |
| same, before potions | 32% | 15% |
| spread (p10 / p50 / p90) | 0 / 15 / 46% | 0 / 8 / 34% |
| fights won with no damage taken | 27% | 27% (f1 35%) |
| foes land a hit in round 1 | 59% | 60% |
| damage taken in round 1 (share of max) | 10% | 5% (f1 4%) |
| fights lost on floors 1–4 | 6.8% (f4 14%) | 0.3% |
| potions drunk a fight, floors 1–4 | 0.45 | 0.15 |
| health entering floors 2 / 3 / 4 | 85 / 78 / 79% | 96 / 91 / 90% |
| climbs that end before floor 5 | 24.1% | 1.2% |

- **The hero always acts first.** The headless fight and the app play the
  hero's roll before the foes' turn. Round 1 only hurts if the foe survives
  the roll and then lands a blow. About 40% of the time it guards,
  charges, heals or tampers instead, or the hero's Defend face blocks the
  blow, so 4 fights in 10 open with no hit.
- **The scale is mostly health.** A curve multiplier of m gives health ×m
  but damage only ×(1 + (m − 1)/2) (`damageShareOf`). So ×4.5 health on
  floor 3 is only ×2.75 damage, which makes long fights rather than
  dangerous ones.
- **The unlocks double the hero's health; the foes do not notice.** With
  every unlock the hero has 52 health against the same foes. Their
  blows drop from 14–17% of max to 6–8%, and floors 1 to 3 cost 10% a
  fight. This is the likely source of the feedback.
- **With no unlocks the early floors already kill, but the potion hides
  the damage.** A potion heals 8, a third of 24, and the flask refills
  every floor. Before potions a fight costs 32%; after them it costs 18%.
  Already 24% of climbs end before floor 5.
- **The hero does not heal fully between floors.** It enters floors 2 to 4
  at 78–85% health with no unlocks and 90–96% with all of them (10% back a
  floor).

### Options (floors 1–4, 2,000 seeds, Heat 0 unless noted)

Columns: rounds a fight won; health lost a fight won after potions (before
potions); fights where the foes land a hit in round 1; climbs ending before
floor 5; then reach.

| option | case | rounds | HP lost | hit r1 | end < f5 | f10 | f20 | top |
|---|---|---|---|---|---|---|---|---|
| rules 4 today | none | 4.3 | 18.0% (32%) | 59% | 24.1% | 28.25 | 3.65 | 0.25 |
| | all | 3.6 | 12.5% (15%) | 60% | 1.2% | 81.85 | 44.10 | 9.45 |
| | H3 all | | | | | 76.50 | 30.25 | 4.20 |
| **A. damage for health**: f1–3 foes damage ×1.5, health ×0.85, 20% back | none | 3.9 | 22.5% (37%) | 61% | 33.8% | 24.25 | 2.70 | 0.20 |
| | all | 3.4 | 15.3% (18%) | 60% | 1.6% | 81.35 | 44.20 | 9.15 |
| | H3 all | | | | | 76.65 | 29.80 | 4.05 |
| **B. ambush**: f1–3 foes act first, 20% back | none | 4.3 | 22.8% (38%) | 73% | 29.8% | 26.45 | 3.15 | 0.30 |
| | all | 3.7 | 15.8% (19%) | 73% | 1.4% | 81.25 | 44.10 | 9.20 |
| | H3 all | | | | | 76.50 | 29.80 | 4.25 |
| **C. damage × unlock health**: f1–3 only | none | (unchanged) | 18.0% (32%) | 59% | 24.1% | 28.25 | 3.65 | 0.25 |
| | all | 3.7 | 16.8% (24%) | 62% | 4.3% | 78.80 | 43.40 | 8.80 |
| | H3 all | | | | | 72.75 | 28.30 | 3.65 |
| **D. a second foe** on f2–4, 25% back | none | 4.3 | 23.2% (36%) | 71% | 41.8% | 22.35 | 2.70 | 0.20 |
| | all | 3.9 | 16.0% (20%) | 73% | 5.1% | 78.85 | 43.10 | 8.90 |
| | H3 all | | | | | 73.50 | 29.20 | 4.30 |
| **B + C, rebalanced (recommended)**: ambush, damage × unlock health, health ×0.85, 25% back, all on f1–3 | none | 4.0 | 22.8% (35%) | 72% | 21.1% | 30.30 | 3.55 | 0.20 |
| | all | 3.4 | 21.7% (28%) | 73% | 3.4% | 80.30 | 43.00 | 9.15 |
| | H3 all | | | | | 73.40 | 28.90 | 3.75 |

For the recommended option, floors 1–3 alone: no unlocks 21.9% lost a
fight won (32% before potions), 76% hit in round 1, 19% fights untouched
(was 28%). Every unlock: 22.8% (29%), 76%, 16% (was 31%). By floor, every
unlock: 21 / 25 / 23%, with floor 4 unchanged at 19%.

What I also tried:
- An opening strike of the foes' full damage (no intents, always lands) on
  floors 1–4. It is too strong: 33–38% of climbs with no unlocks end before
  floor 5.
- The ambush on floor 4 as well: 22% of floor-4 fights lost, f10 22.
- The unlock damage at power 1.2: every unlock 24.6% a fight, but f10 77,
  top 8.5, and H3 top 3.65.
- Recovery alone does not move the health lost a fight. It only buys back
  the climbs that end early.

Readings:
- With no unlocks, health lost after potions stays at about 22–23% in
  every option. A fight that would cost more is lost, and the climb ends
  (survivor bias), and the potion covers a third of a 24-health hero.
  Pushing past 25% only adds deaths before floor 5. Before potions, the
  recommended option already sits at 35%.
- A (damage for health) and D (a second foe) hit the no-unlock climb hard
  (34–42% end before floor 5, f10 22–24) and barely touch every unlock.
- B (ambush) is the felt part: round-1 hits go from 59% to 73–76% and fights
  with no damage from 27% to 19%. C (unlock damage) is what reaches the
  unlocked climbs. Together, with the health and recovery give-back, both
  cases land at about 22% a fight.

### Uncertainties (as proposed)

- **Bot vs human.** A human reads the intents, Defends against a telegraphed
  blow and drinks the potion at a better time. Under the ambush, round 1's
  intents are hidden for everyone. A careful human will lose less than the
  bot's 22%, but should still feel round 1.
- **The headless fight plays no battlefield conditions.** In the app a Tower
  fight already rolls one sometimes (an ambush included), so today's app
  is a little harder than the bot. On floors 1–3 the forced ambush takes the
  place of that roll.
- **The prototype's ambush** is the headless fight's own enemy turn, run
  before round 1. The app's version also hides the intents, which the bot
  never reads, so the numbers should carry over. It is still worth one
  check after the real code is built.
- **Which climb the user played.** If it was with unlocks, which is likely
  after several climbs, rules 4 cost about 10% a fight on floors 1–3, and
  that matches the feedback. If it was before rules 3, every number above
  was much lower then.
- **Noise.** 2,000 seeds: about ±0.7 points at 10% and ±0.45 at 4%. The H3
  top of 3.75 against 4.20 is at the edge of that. If it holds, the
  unlock-damage power can go to 0.9.
- **Recovery at Heat 3+.** 25% after floors 1–3 replaces Heat's 5% there,
  a bigger step than at Heat 0. It was measured that way (H3 numbers
  above).

### How the prototype was measured

`TOWER_SEEDS=2000` with the live events and rules 4, `TOWER_BOT_COINS=full`,
no perks. A local scratch test played the bot with a probe in the headless
fight. The probe logged each main fight (the bot's trial fights for a new
die are left out): floor, foes and their damage and health, rounds,
health before, after round 1 and at the end, and potions drunk. Health lost
a fight won is (health before − health after) / max, after potions; "before
potions" adds back 8 a potion drunk. The rules-4 reach and the 500-seed pin
match the guards exactly (none 1 / 19 / 3983, all 43 / 214 / 9013). The
prototype knobs were globals, not committed.
