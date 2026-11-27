# Tower: early floors that threaten (proposal, rules 5)

Core, proposal only. The user's feedback: "Still feels the firsts fights are
too easy." Measured on the live rules 4 (v2.10.39), 2,000 seeds, the bot
(`playTowerRun`), floor events on. Nothing here is in the code yet.

## Recommendation

A new rules 5, for new climbs only (rules 1 to 4 untouched). On **floors 1
to 3**:

1. **The foes strike first.** Every fight opens with the app's own ambush
   (`BattlefieldCondition.ambush`, forced through
   `EncounterModifiers.forcedCondition`): the foes take a full turn before
   the first roll, and their intents are hidden that round.
2. **Their damage grows with the unlocks' health.** The foes' damage is
   multiplied by the hero's unlock health factor
   (`1 + towerHealthPerUnlockFor(...) × unlocksOwned`): ×1.0 with no unlocks,
   about ×2.2 with all of them. Their health does not change.
3. **To keep the climb's survival curve, the foes have a little less health
   and the hero heals a little more between fights.** The foes' health
   scale goes from 3.0 / 4.2 / 4.5 to 2.55 / 3.57 / 3.83 (×0.85). Health
   back after floors 1, 2 and 3 goes from 10% (5% at Heat 3+) to 25%.

Floor 4 does not change. With no unlocks it is already the hardest early
floor: 14% of its fights are lost, and it is where the packs start.

Result: in fights won on floors 1 to 3, the hero now loses about 22–23% of
max health after potions (29–32% before them), whatever the unlocks. That
was 18% with no unlocks and 10% with all of them. The foes land a hit in
round 1 in 76% of fights (was 59%). The late targets stay in place.

If only the no-unlock climb matters, the smallest version is option 1 alone
(the ambush, with 20% health back). But with every unlock it leaves fights
at 14–16% health lost, and that is the case that feels easy.

## Why the early fights feel easy (rules 4, floors 1–4)

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

## Options (floors 1–4, 2,000 seeds, Heat 0 unless noted)

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

## Knobs (old → new; read behind `rules >= 5`)

| knob | old | new | file |
|---|---|---|---|
| `towerRulesLive`, `towerRulesMax` | 4 | 5 | `lib/data/tower/tower_tables.dart` |
| new `towerEarlyFloors` | — | 3 (floors 1–3) | `tower_tables.dart` |
| ambush on floors 1–3 | none | `forcedCondition: BattlefieldCondition.ambush` in `TowerFloor.modifiersFor` | `lib/data/tower/tower_floors.dart` |
| foes' damage on floors 1–3 | ×1 | × the unlock health factor (new `towerEarlyUnlockDamage = 1.0`, the power) | `tower_floors.dart` (new `damageFor`), `lib/combat/encounter.dart` (new `damageMultiplier`), `lib/screens/fight/fight_setup.dart` (one line where enemy damage is built; a shared file) |
| `towerSurvivalScale` floors 1–3 (rules 5 only) | 3.0 / 4.2 / 4.5 | 2.55 / 3.57 / 3.83 (new `towerEarlyScale = .85`) | `tower_tables.dart` (`towerRulesScaleOf`) |
| health back after floors 1–3 | .10 (.05 at Heat 3+) | .25 at every Heat (new `towerEarlyRecoveryShare`) | `tower_tables.dart` (`towerRecoveryShareFor` takes the floor), `tower_levelup_loot.dart` |
| headless fight | — | `ambush` (the foes' turn before round 1) and `damageMultiplier` parameters | `lib/data/sim_combat.dart`, `sim_combat/sim_fight.dart`, `sim_fight_setup.dart`; `tower_bot.dart` passes them |

The ambush needs no new screen: the app already plays it (fight_setup.dart:
the foes' turn before the first roll, intents hidden in round 1). A line
saying why the foes strike first on floors 1–3 may be wanted (UX/Narrative,
through the manager).

## Guards affected

- `qa_tower_sim_test.dart` bands hold on the 500 guard seeds: median 8 (6–10),
  floor 20 3.0% (2–8%; was 3.8%), the top with none 0.0% (0–1%; was 0.2%),
  the top with all 8.6% (6–15%; unchanged). No re-band. The test "with
  none, floor 20 is reached" holds (15 climbs). The events-off guard was
  not re-measured.
- `qa_tower_live_pin_test.dart` moves, on purpose: none 1 / 19 / 3983 →
  0 / 15 / 4144; all 43 / 214 / 9013 → 43 / 213 / 8923 (top, floor 20,
  floor sum; measured with the prototype, to be re-read on the real code).
- `towerRulesLive == 4` pins: `test/tower_rules4_test.dart:583` and
  `test/tower_levelup_loot_test.dart:650-651` become 5. A rules-5 test
  should pin the ambush on floors 1–3 only, the damage factor, and that
  rules 4 climbs are unchanged.

## Uncertainties

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

## How it was measured

`TOWER_SEEDS=2000` with the live events and rules 4, `TOWER_BOT_COINS=full`,
no perks. A local scratch test played the bot with a probe in the headless
fight. The probe logged each main fight (the bot's trial fights for a new
die are left out): floor, foes and their damage and health, rounds,
health before, after round 1 and at the end, and potions drunk. Health lost
a fight won is (health before − health after) / max, after potions; "before
potions" adds back 8 a potion drunk. The rules-4 reach and the 500-seed pin
match the guards exactly (none 1 / 19 / 3983, all 43 / 214 / 9013). The
prototype knobs were globals, not committed.
