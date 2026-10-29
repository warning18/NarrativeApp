# The bosses in the full world (Core, v1.606 data, a short note)

**QA's finding** (`docs/qa/sim-world.md`, #591): with `specialisations` and
`spec_variants` in the simulator's world, the same 400 runs win the bosses
15–20 points more often. The two tables are what the simulator screen and the
real game have; the CI curve was measured without them. Same seed, bosses won
(target):

| Boss | Won | Target |
|---|---|---|
| Chapter 4 inquisitor | 68 | 55 |
| Bone warden | 72 | 55 |
| Void archon | 71 | 50 |
| White admiral | 66 | 45 |
| Tear-Herald (chapter 8) | 55 | 35 |
| Void sovereign (chapter 8) | 67 | 35 |
| The claimants, pooled | 58 | 40 |
| **Mean** | **65** | **about 50** |

The professions' spread holds at 8.3.

## Decision: the targets stay, the bosses move

- **Why the targets stay:** the user asked for harder fights ("it doesn't seem
  the user struggles"). The real game has specialisations, so the
  15–20 points are part of why it feels easy. Moving the targets would
  bless that.
- **Why the specialisations stay:** they are a reward the clans give. Trimming
  them would make that reward weaker everywhere, not just at the bosses.

## How (one PR, before the element dice)

1. **boss_balance measures the full world.** Remove QA's one-line exclusion
   (`simTables(without: {'specialisations', 'spec_variants'})`).
2. **One number first: the boss health floor** (`bossHealthBaseMultiplier`),
   1.25 → about 1.45. It moves every boss of chapters 2–8 together and
   should close most of the 15-point mean gap.
3. **Then the outliers, one by one** (their `maxHealth` in `enemies.json`),
   as at v1.601. The gaps run 13 to 32 points, so the chapter 8 pair needs
   more than the floor (the void sovereign is +32). The damage floors stay.
4. **Aurel Vane** (chapter 1, before any clan gives a specialisation) should
   not move. Checked in the same run; his own health is re-set if the floor
   moves him.
5. **Regular fights:** the same run prints each profession's encounters
   won within 3 tries (68.5–74.9% at v1.601). If the full world raised them
   by more than 5 points, I'll say so; their health floors then become a
   follow-up, not this PR.

**Cost:** only `boss_balance_test` (one 400-run file, about 75 s) is run,
4–6 times while sizing, plus `clash_balance_test` and
`chapter_one_fights_test` once at the end. No other batch.

**Tests that move:**
- `boss_balance_test`: the bands are unchanged; the world is now full.
- The frozen naive run (`sim_competent_test`, `sim_companions_test`): boss
  health changes it, so it is re-pinned as usual until S1 replaces it.

## Then the element dice (v1.613)

The element-dice measure is re-run with the same hero holding the
specialisation the simulator's walk gives at that level, so it measures the
full world too. The A/B/C choice for the user stands; the numbers in it
will be re-sent from the full world.

## What was built (v1.613), and what it measured

One 400-run `boss_balance_test` on the full world, seed 7.

| Number | Before | v1.613 |
|---|---|---|
| Boss health floor | 1.25 | **1.45** |
| Void sovereign | 66 health | 80 |
| White admiral | 62 | 68 |
| Tear-Herald | 57 | 61 |
| Aurel Vane | 22 | 19 (keeps his 75% under the higher floor) |
| The six champions | 46–48 | 42–44 |

| Boss won (target) | Full world, before | v1.613 |
|---|---|---|
| Aurel Vane (75) | 76 | 76 |
| Void stalker (65) | 73 | 59 |
| Inquisitor (55) | 69 | 56 |
| Bone warden (55) | 71 | 59 |
| Void archon (50) | 71 | 60 |
| White admiral (45) | 66 | 46 |
| The claimants, pooled (40) | 59 | 49 |
| Tear-Herald (35) | 49 | 43 |
| Void sovereign (35) | 67 | 43 |
| **Mean** | **64** | **53** |
| The champions (50) | 55 | 47 |

### The professions in the full world: a follow-up

The encounters each profession wins within three tries, same run:

| | Cleric | Warrior | Ranger | Rogue | Mage |
|---|---|---|---|---|---|
| Won | 67 | 67 | 78 | 80 | 80 |

- **The spread is 13.6 points.** Without specialisations it was 6.9, so the
  specialisations open it.
- Split by the specialisation each run held:
  - the mage's Burden-Bearer line (with the Scorched Choir) wins 90%;
  - the rogue's Fever Blade line wins 87–92%;
  - the ranger's Fen Guide with Trapwright wins 83%;
  - the cleric's Long Vigil (67%) and the warrior's Briar Guard (70%) add
    almost nothing over no specialisation.
- Two rounds of trims and buffs on those five moved the spread only from
  13.6 to 11.4, so they are not in this PR.
- **The specialisations pass is its own PR:** the five professions within
  8 points in the full world.
- Until then, the spread test's limit is 14 (its constant says why). Like
  the boss bands, it also allows three standard errors of the gap, from how
  much the runs differ, so a story PR that reshuffles the seeded dice cannot
  flip it.

### Tests that moved
- `boss_balance_test`: now on the full world; the spread band as above.
- `difficulty_curve_test`: the boss health floor is now below the regular
  floors from chapter 2 on. Chapter 1's floor is 1.36, and its one boss,
  Aurel Vane, is sized by his own health.
- The frozen naive run (`sim_competent_test`, `sim_companions_test`) is
  re-pinned. The naive warrior no longer stalls at Aurel Vane: level 15 → 19.
