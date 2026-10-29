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
