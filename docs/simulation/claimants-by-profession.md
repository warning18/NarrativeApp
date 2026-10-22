# The claimants by profession (wave 17 item 1, the logging run)

> **Applied in v1.531: "C, complete"** (see the end), with the
> simulator's silence, hex and curse ("With silence and the hex
> modelled") in the same release. Morrow needed +40 health on today's
> data, not +20. The final numbers are under "v1.531: C, complete,
> applied".

Measured on v1.516 with `boss_balance_test`'s plan (400 runs, politics
events loaded), seed 7, checked at seeds 11 and 23. The fights were traced
with a throwaway hook in `sim_combat.dart` and a harness under `test/`.
Neither is committed. The hook doesn't change the results: the traced
baseline matches the untraced one run for run.

"Win %" is the encounter (3 tries). Everything else is **per try**,
averaged over the tries each profession made. "Heals" means the claimant's
own heals: phase heal plus heal moves.

## Per claimant, seed 7

**Cassian Oriel (`claimant_vane`)**: 620–720 health on the fight's scale. Resists Fire, weak to Electricity.

| | Win % (met) | Rounds | Dealt / rd | Taken / rd | Claimant heals | Lost to resist | Party heals |
|---|---|---|---|---|---|---|---|
| Cleric | 0 (14) | 16.1 | 19.1 | 14.9 | 12 | 55 | 112 (Mending Light) |
| Warrior | 0 (10) | 12.3 | 35.6 | 11.1 | 30 | 13 | 5 |
| Mage | 62.5 (16) | 9.6 | 53.0 | 10.4 | 35 | 24 (+145 weakness) | 0 |
| Ranger | 62.5 (8) | 15.6 | 37.5 | 9.0 | 40 | 40 | 4 |
| Rogue | 69.2 (13) | 14.0 | 38.9 | 9.7 | 35 | 60 | 2 |

**Maud Tallis (`claimant_tallis`)**: about 610 health. Resists Light, weak to Void. She is 264 of the 400 meetings.

| | Win % (met) | Rounds | Dealt / rd | Taken / rd | Claimant heals | Lost to resist | Party heals |
|---|---|---|---|---|---|---|---|
| Cleric | 5.3 (57) | 18.4 | 20.2 | 17.7 | 48 | 63 | 187 |
| Warrior | 22.8 (57) | 13.1 | 32.7 | 10.5 | 60 | 69 | 5 |
| Mage | 51.0 (51) | 10.5 | 47.6 | 10.9 | 67 | 9 | 3 |
| Ranger | 59.6 (52) | 14.5 | 33.3 | 9.2 | 69 | 44 | 8 |
| Rogue | 44.7 (47) | 13.4 | 34.1 | 9.0 | 69 | 49 | 3 |

**Hesk Morrow (`claimant_morrow`)**: 810–940 health. Resists Earth, weak to Electricity.

| | Win % (met) | Rounds | Dealt / rd | Taken / rd | Claimant heals | Lost to resist | Party heals |
|---|---|---|---|---|---|---|---|
| Cleric | 33.3 (9) | 16.5 | 28.3 | 15.1 | 29 | 28 | 110 |
| Warrior | 0 (13) | 12.5 | 31.7 | 10.6 | 12 | 77 | 2 |
| Mage | 100 (13) | 12.4 | 76.2 | 6.1 | 85 | 2 (+261 weakness) | 4 |
| Ranger | 45.0 (20) | 16.4 | 32.0 | 7.9 | 33 | 144 | 8 |
| Rogue | 55.0 (20) | 14.8 | 43.2 | 9.0 | 48 | 35 | 1 |

### All three claimants, by round of the fight (party side, per round still standing)

| Rounds | 1–4 | 5–7 | 8–10 | 11–13 | 14–16 | 17+ |
|---|---|---|---|---|---|---|
| Cleric: damage dealt | 13.7 | 12.4 | 16.1 | 21.1 | 23.0 | 17.0 |
| Cleric: damage taken | 6.8 | 7.6 | 13.3 | 22.7 | 27.9 | 32.2 |
| Cleric: healed | 1.1 | 2.0 | 5.9 | 13.6 | 16.5 | 14.8 |
| Warrior: damage dealt | 19.9 | 24.1 | 30.4 | 31.2 | 22.8 | 23.5 |
| Warrior: damage taken | 7.6 | 8.2 | 12.3 | 15.3 | 15.4 | 9.6 |
| Mage / ranger / rogue: damage dealt | 22–30 | 20–46 | 29–49 | 32–38 | 28–34 | 30–34 |

Average round of a lost try: cleric 17.7, warrior 12.7, mage 9.6, ranger 14.0, rogue 13.0. When the cleric falls, the claimant still has **50%** of its health; for the warrior it has 46%; for the others, 38–49%.

### What the trace rules out

- **Silence and the hex do nothing in the simulator.** `edict_of_silence` and `hex_of_ill_luck` are `tamper` moves, and `sim_combat` doesn't model tamper moves: the claimant spends its turn and nothing happens. They take 23% of Oriel's turns, so in the simulator they help the party. They can't be the cleric's 7.5%. In the app they would make it worse.
- **Statuses:** the only one the party suffers is the Stun from `radiant_judgment`. It is up 10–13% of rounds for the cleric and the warrior, and 6–11% for the others. That is a small factor.
- **Mana:** the cleric is starved in under 1% of rounds. It spends its mana on heals: 7.5 Mending Light per try against 0.7 Smite the Wicked.
- **No fight runs out of time:** every loss is a death.

## With silence and the hex modelled

`sim_combat` now lays the enemies' Hex, Silence and Curse on the hero's die
as the fight screen does (see [sim-gaps.md](sim-gaps.md)). Same plan
(400 runs, politics events), current `main`, before and after. Claimant
columns are win % per try as in the table below; "Professions" is each
profession's win % over all its fights.

| Run (seed) | Cl | Wa | Ma | Ra | Ro | Claimants | Vane | Tallis | Morrow | Ch 7 | Boss mean | Spread |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| before (7) | 7.5 | 16.2 | 61.2 | 56.2 | 51.2 | 38.5 | 39.3 | 35.6 | 48.0 | 52.6 | 50.1 | 5.9 |
| **after (7)** | 11.2 | 21.2 | 63.8 | 52.5 | 52.5 | 40.2 | 36.5 | 38.9 | 50.9 | 54.9 | 51.1 | 5.9 |
| before (11) | 6.2 | 30.0 | 63.8 | 65.0 | 36.2 | 40.2 | 30.6 | 39.0 | 54.1 | 54.3 | 50.6 | 5.3 |
| **after (11)** | 8.8 | 27.5 | 72.5 | 57.5 | 38.8 | 41.0 | 30.8 | 41.3 | 49.1 | 54.9 | 50.1 | 4.9 |
| before (23) | 15.0 | 32.5 | 63.8 | 43.8 | 42.5 | 39.5 | 31.5 | 40.8 | 40.6 | 53.8 | 49.6 | 2.9 |
| **after (23)** | 6.2 | 30.0 | 65.0 | 47.5 | 41.2 | 38.0 | 36.4 | 39.0 | 34.5 | 52.0 | 48.0 | 4.6 |

| Professions, all fights (seed) | Cleric | Warrior | Mage | Ranger | Rogue |
|---|---|---|---|---|---|
| before (7 / 11 / 23) | 67.0 / 65.2 / 66.5 | 63.2 / 66.8 / 64.9 | 67.6 / 70.0 / 67.1 | 64.9 / 68.0 / 65.9 | 69.1 / 64.7 / 67.8 |
| after (7 / 11 / 23) | 69.2 / 67.4 / 65.9 | 63.9 / 67.6 / 63.0 | 67.1 / 69.4 / 67.4 | 64.4 / 67.7 / 65.8 | 69.8 / 64.5 / 67.7 |

The cleric against Oriel alone (tries won, tries met): before 0 (14) /
9 (11) / 0 (8), after 23 (13) / 10 (10) / 6 (17).

- **The effect is small and inside the seeds' noise.** Every number moves
  by a few points either way; the runs part early (a hex or a curse in
  chapters 2–4 changes the dice that follow), so a single cell is not a
  measure of the tamper. The claimants' average moves −1.5 to +1.7, the
  boss mean −1.6 to +1.0, the spread stays at 6 or less.
- **The cleric is not measurably worse against Oriel.** Silence blanks
  only the Skill faces of the round after it (a skill set on a basic face
  falls back to it), and the simulated player rerolls a blank like any
  blank, up to three rolls, so most silenced rounds still land a basic
  face. The hex rolls one die again before the player's own rerolls,
  which for a solo die that keeps any non-blank face is close to neutral.
  Oriel's turns spent on them cost him more than they cost the party.
- `boss_balance` and `nemesis_quests` pass with no bound changed.
  **`clash_balance` fails:** at its seed (11) chapter 2 reads plain 0.395,
  clash 0.525, a gap of 0.129 against its bound of 0.10 (before: 0.457 and
  0.486). Over seeds 1–4 the chapter-2 gap is 0.05–0.10 (before
  0.04–0.08): the tampering makes the plain rules' fights a little harder
  (chapters 2, 4, 6, 8 by 1–5 points) and the clash rules' not, so the gap
  widens a few points and seed 11 crosses the line. No single tamper does
  it: with the hex off the gap is 0.02, with silence off 0.10, with the
  curse off 0.08. Nothing was tuned. Root causes and fixes below stand as
  measured.
- On v1.530's data (v1.531) the same test passes with the tamper and the
  claimants' rules in.

## Root causes, ranked by impact

1. **The cleric deals half the damage, and the boss Tide punishes the long fight that follows.** About 34% of the cleric's rolls make mana and deal nothing: Mana faces (17%) and `cleric_prayer` (17%). That mana becomes heals. Another 17% are Defend. As a result it deals 13–20 per round against the others' 33–53, and its fights run to round 16–18. From round 8 the Tide raises a boss's blows by 18% a round (`tideBossEnemyStep`), so by round 16 they are ×2.6 and by round 18 ×3.0. The cleric's heals don't grow with the Tide. Damage taken climbs from 7 a round to 28–32, and the cleric dies with the claimant at half health. The cleric's regular fights are shorter and never reach that ramp, which is why it wins 63.5% of them.
   - What-if, claimant blows on the Tide's ordinary step (0.10): cleric 7.5 → 37.5%.
   - What-if, removing the claimants' heals: cleric only reaches 16%.
2. **The warrior has neither the damage nor the staying power, so the claimant's heals and resists decide its fights.** It deals about 32 a round (like the ranger and rogue), but it dodges 11–12% against their 30–37%. It has no heals and falls around round 12.7. Its fights are lost by a small margin, so the following settle them:
   - Tallis' 12% phase heal plus `cleric_sanctuary`: 60 health per try, about 10% of her pool.
   - Resists against its two main elements: Earth (`warrior_quarry_break`) against Morrow and Light (`celestial_ward`) against Tallis, which cost it 70–77 per try.
   - What-ifs: no claimant heals takes the warrior 16 → 40%. No resists takes it 16 → 30%.
3. **Resists hit the cleric only a little.** Fire against Oriel and Light against Tallis cost it about 3 a round, about 15% of its output. Removing them takes the cleric only from 7.5 to 15%.

## Candidate fixes, measured

All were run in the harness only and reverted. Columns are the claimant encounter win % by profession (Cl, Wa, Ma, Ra, Ro), the claimants' average, each claimant's rate (band 28–52), chapter 7 overall, the boss-curve mean (42–58) and the profession spread in the boss test (8 or less).

| Run (seed) | Cl | Wa | Ma | Ra | Ro | Claimants | Vane | Tallis | Morrow | Ch 7 | Boss mean | Spread |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v1.516 (7) | 7.5 | 16.2 | 61.2 | 56.2 | 51.2 | 38.5 | 39.3 | 35.6 | 48.0 | 52.6 | 50.1 | 5.9 |
| v1.516 (11) | 6.2 | 30.0 | 63.8 | 65.0 | 36.2 | 40.2 | 30.6 | 39.0 | 54.1 | 54.3 | 50.6 | 5.3 |
| v1.516 (23) | 15.0 | 32.5 | 63.8 | 43.8 | 42.5 | 39.5 | 31.5 | 40.8 | 40.6 | 53.8 | 49.6 | 2.9 |
| **A** heal once + Morrow +10 (7) | 6.2 | 20.0 | 61.2 | 53.8 | 48.8 | 38.0 | 39.3 | 35.6 | 45.3 | 52.3 | 50.3 | 5.4 |
| A (11) | 8.8 | 27.5 | 63.8 | 61.2 | 35.0 | 39.2 | 36.7 | 38.6 | 44.3 | 53.7 | 49.8 | 4.9 |
| A (23) | 11.2 | 33.8 | 58.8 | 48.8 | 36.2 | 37.8 | 37.0 | 39.4 | 31.2 | 52.8 | 49.2 | 3.2 |
| **B** Tide capped at level 6 for claimants (7) | 41.2 | 17.5 | 61.2 | 57.5 | 51.2 | 45.8 | 44.3 | 45.5 | 48.0 | 56.7 | 51.8 | 5.9 |
| B (11) | 37.5 | 32.5 | 62.5 | 71.2 | 37.5 | 48.2 | 36.7 | 48.6 | 55.7 | 58.9 | 52.0 | 5.2 |
| B (23) | 48.8 | 38.8 | 63.8 | 60.0 | 45.0 | 51.2 | 38.9 | 53.2 | 53.1 | 60.7 | 52.5 | 2.8 |
| **C** B + heal once + Morrow +10 + no resists (7) | 37.5 | 32.5 | 66.2 | 58.8 | 47.5 | 48.5 | 50.8 | 48.9 | 45.3 | 58.2 | 52.2 | 5.2 |
| C (11) | 43.8 | 36.2 | 62.5 | 73.8 | 40.0 | 51.2 | 40.8 | 53.4 | 49.2 | 60.6 | 52.3 | 4.9 |
| C (23) | 42.5 | 48.8 | 61.2 | 57.5 | 46.2 | 51.2 | 40.7 | 52.8 | 53.1 | 60.7 | 52.6 | 3.0 |
| **C, complete:** C + Tallis +5, Morrow +20 (7) | 37.5 | 25.0 | 61.2 | 56.2 | 50.0 | 46.0 | 50.8 | 44.7 | 46.7 | 56.8 | 51.8 | 5.4 |
| C, complete (11) | 43.8 | 30.0 | 57.5 | 65.0 | 38.8 | 47.0 | 40.8 | 48.3 | 45.9 | 58.2 | 51.9 | 4.5 |
| C, complete (23) | 35.0 | 37.5 | 58.8 | 60.0 | 40.0 | 46.2 | 40.7 | 46.5 | 50.0 | 57.7 | 52.1 | 3.0 |

- **A, the proposal's rule:** each claimant heals once a fight (its first heal of any kind; then its heal moves leave its list), and Morrow gets +10 health. It does nothing for the cleric and gives the warrior +4 points at seed 7. The first heal is usually the big one: the 30% phase heal or `cleric_sanctuary`. Not enough on its own.
- **B, the counter to cause 1:** in a claimant's fight its blows stop growing at Tide level 6 (×2.08, from round 13 on). The cleric gets 38–49% at every seed. Mage, ranger and rogue barely move, because their fights end before round 13. The claimants average 46–51, the boss mean is 51.8–52.5 and the spread is unchanged. The warrior isn't fixed: it falls around round 12.7, before the cap starts to act. It reaches only 17.5% at seed 7. Tallis (53.2) and Morrow (53.1, 55.7 at seed 11) sit just over the band at some seeds. Cap 5 overshoots: Oriel and Tallis go to 55–56. Cap 4 takes the cleric to 70%.
- **C, B plus the warrior's two levers:** heal once, Morrow +10, and the claimants lose their resists. Their weaknesses stay. Every profession is at 32.5% or more at all three seeds. The claimants average 48.5–51.2 and the boss mean is 52.2–52.6. Tallis goes 0.9–1.4 points over the band at seeds 11 and 23, and Morrow 1.1 at seed 23. A few more points of health on Tallis would settle that, but I didn't measure it.

### C, complete

C's last points are its health. It needs Tallis +5 (72 → 77) and Morrow
+20 (108 → 128, not C's +10). With those, every claimant is in band
(28–52) at all three seeds, and every profession wins the claimants at
25% or more. The warrior is exactly at 25.0 at seed 7.

| Tallis step | Tallis (7 / 11 / 23) | Morrow +10 (7 / 11 / 23) |
|---|---|---|
| +0 (C) | 48.9 / 53.4 / 52.8 | 45.3 / 49.2 / 53.1 |
| **+5** | 44.7 / 48.3 / 46.5 | 45.3 / 49.2 / 53.1 |
| +10 | 40.2 / 45.2 / 44.3 | 45.3 / 49.2 / 53.1 |

With Tallis +5, Morrow at seed 23 is 53.1 at +10, still 53.1 at +15, and
50.0 at +20, where seeds 7 and 11 give 46.7 and 45.9. Steps between +15
and +20 were not tried. "C, complete" in full:
- in claimant fights, the Tide's level is capped at 6;
- each claimant heals once a fight;
- the claimants lose their resists (they keep their weaknesses);
- Tallis gets +5 health and Morrow +20.

The claimants average 46.0–47.0, chapter 7 is won 56.8–58.2%, the boss mean
is 51.8–52.1 and the professions' spread is 3.0–5.4.

Variants that were rejected:
- **Claimant blows on the ordinary Tide step (0.10):** cleric 37.5 and warrior 32.5, but it lifts everyone. Oriel goes to 54.1 and Morrow to 56.0, out of band.
- **No claimant heals at all:** warrior 40, but cleric only 16.2, and Morrow goes to 56.0.
- **Heals rising with the Tide in boss fights (cleric-side, step 0.10):** cleric 47.5 on the claimants, but 77% overall, a spread of 12.5.

**My advice is B or C.** B is one rule in `fight_length.dart`, read by the fight screen and `sim_combat`, keyed to the claimants or to a field in `enemies.json`. It fixes the cleric cleanly. C also fixes the warrior, but it changes three things in data.

Separately, **silence and the hex need modelling in `sim_combat`** before any final tuning. Today they are free turns for the party, so the simulator overrates the cleric against Oriel.

## v1.531: C, complete, applied

The rules (fight_length.dart; the fight screen and `sim_combat` both play
them, keyed to fields in `enemies.json`):

- **`tideCap: 6`** on the three claimants: in a fight with one, the
  enemies' Tide stops at level 6 (x2.08 from round 13 on, where it went on
  to x3.0 by round 18). The party's Tide keeps rising. The fight screen's
  Tide chip and log say the capped share (`fightTideCap`,
  `enemyTideLevel`).
- **`healsOnce: true`**: a claimant mends itself once a fight, by a phase
  or by a move; then its heal moves leave its list and its later phases
  heal nothing (`healsOnce`, `withoutHealMoves`).
- **No resists** (`resists: []`): Oriel loses Fire, Tallis Light, Morrow
  Earth. Their weaknesses stay.
- **Health:** Tallis 72 → 77, Morrow 108 → **148**. With the planned +20
  (128) Morrow came out at 56.1% at seed 7, over the band, on v1.530's data
  with the tamper modelled. +10 left it at 56.1; +20 more (148) gives
  47.4 / 48.2 / 40.0.

Measured on v1.530 (main) and on the final code (tamper and C),
`boss_balance_test`'s plan, 400 runs, politics events loaded. Columns as
in "Candidate fixes, measured" (claimant encounters won, by profession;
each claimant's band is 28–52).

| Run (seed) | Cl | Wa | Ma | Ra | Ro | Claimants | Vane | Tallis | Morrow | Ch 7 | Boss mean | Spread |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| main (7) | 8.8 | 17.5 | 61.2 | 56.2 | 43.8 | 37.5 | 33.9 | 35.6 | 47.3 | 51.9 | 49.7 | 6.1 |
| **v1.531 (7)** | **37.5** | **30.0** | 60.0 | 56.2 | 45.0 | 45.8 | 40.0 | 46.4 | 47.4 | 57.8 | 51.4 | 5.8 |
| main (11) | 7.5 | 28.8 | 63.8 | 62.5 | 32.5 | 39.0 | 26.5 | 38.4 | 52.5 | 53.4 | 50.4 | 5.6 |
| **v1.531 (11)** | **36.2** | 35.0 | 72.5 | 55.0 | 36.2 | 47.0 | 38.5 | 48.3 | 48.2 | 58.3 | 51.6 | 5.0 |
| main (23) | 17.5 | 35.0 | 63.8 | 47.5 | 40.0 | 40.8 | 36.2 | 41.8 | 40.0 | 55.4 | 50.2 | 2.7 |
| **v1.531 (23)** | **31.2** | 36.2 | 50.0 | 61.2 | 46.2 | 45.0 | 42.3 | 46.5 | 40.0 | 56.0 | 50.2 | 5.1 |

Every claimant is in band at every seed (Oriel 38.5–42.3, Tallis
46.4–48.3, Morrow 40.0–48.2), and every profession wins the claimants 30%
or more. The cleric goes from 7.5–17.5 to 31.2–37.5, the warrior from
17.5–35.0 to 30.0–36.2.

Each profession's encounters won, all fights (cleric / warrior / mage /
ranger / rogue; `boss_balance` wants each at 60 or more, within 8 of each
other):

| Seed | main | v1.531 |
|---|---|---|
| 7 | 67.0 / 63.0 / 67.7 / 65.0 / 69.1 | 69.6 / 63.8 / 66.9 / 64.8 / 69.7 |
| 11 | 65.7 / 66.5 / 69.9 / 67.8 / 64.3 | 68.1 / 67.9 / 69.7 / 67.2 / 64.7 |
| 23 | 66.8 / 65.0 / 67.7 / 66.3 / 67.4 | 66.1 / 63.2 / 67.2 / 66.5 / 68.2 |

Each claimant by profession, won % (meetings), main → v1.531. Oriel and
Morrow are met 3 to 17 times per profession, so a single cell moves 10
points or more with one fight.

| Seed | Claimant | Cleric | Warrior | Mage | Ranger | Rogue |
|---|---|---|---|---|---|---|
| 7 | Oriel | 7 → 36 | 0 → 8 | 62 → 60 | 62 → 62 | 38 → 44 |
| 7 | Tallis | 5 → 40 | 25 → 38 | 51 → 54 | 59 → 57 | 40 → 45 |
| 7 | Morrow | 30 → 17 | 0 → 0 | 100 → 81 | 44 → 50 | 55 → 46 |
| 11 | Oriel | 9 → 42 | 18 → 21 | 71 → 89 | 33 → 17 | 18 → 27 |
| 11 | Tallis | 7 → 39 | 32 → 41 | 53 → 62 | 69 → 62 | 33 → 39 |
| 11 | Morrow | 10 → 11 | 14 → 12 | 94 → 100 | 54 → 44 | 45 → 29 |
| 23 | Oriel | 0 → 12 | 23 → 67 | 71 → 64 | 44 → 50 | 20 → 50 |
| 23 | Tallis | 19 → 40 | 41 → 40 | 54 → 41 | 57 → 69 | 44 → 45 |
| 23 | Morrow | 25 → 18 | 12 → 8 | 100 → 75 | 22 → 44 | 40 → 56 |

Tallis is two thirds of the meetings and carries the cleric's and the
warrior's gain. Morrow is still the hard one for both (0–18 over 6 to 12
meetings): Earth was the warrior's main element against him, and the
cleric's long fights still meet his 148 health. That is the cell to watch
in the next L3.

Tests: `test/claimant_rules_test.dart` (the Tide cap, one heal in the
simulator, no resists and the health in data).

The clash rules' pack change measured in the same wave is not in v1.531:
it moved to `claude/core-6` with the real-walk `clash_balance`
(see that branch's clash-balance-real-walk.md).
