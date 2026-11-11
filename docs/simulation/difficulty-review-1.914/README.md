# Difficulty review, v1.914 (Core)

The user: "review difficulty and do 50 tower and 100 story playthroughs".

- Measured on main at v1.914 (3309315f), the game as the player has it.
- The Tower runs are also measured on PR #965 (v1.916, ships next).
- Every share gives its count. Next to each one is a larger batch, the more
  reliable figure.
- **No change is made from this review until the user chooses.**

Files in this folder:

| File | What |
|---|---|
| `tower-runs-1.914.csv`, `tower-runs-1.916.csv` | the 50 Tower runs, one row each |
| `tower-summary.json` | both versions side by side, with the 2,000-seed batch |
| `tower_runs_test.dart.txt` | the code that reruns them (see its header) |
| `story-runs-1.914.csv` | the 100 story runs, naive and competent player (200 rows) |
| `story-summary.json` | per chapter, per fight, by people and calling |
| `story_runs_test.dart.txt`, `story_summary.py` | the code that reruns them |

## 1. Tower: 50 runs

**How the runs were picked**
- Seeds 1001–1050, no unlocks.
- Spread over the 25 people × calling pairs: pair i = (seed − 1001) mod 25,
  2 runs each.
  - people: i ÷ 5 → dwarf, elf, human, orc, voidkin;
  - calling: i mod 5 → warrior, mage, rogue, cleric, ranger.
- Cleric and ranger need an unlock. They are allowed here by passing them to
  the bot directly.
- The 2,000-seed batch uses the bot's own draw, which is warrior, mage and
  rogue only.

| | 1.914 (50) | 1.914 (2,000) | 1.916 (50) | 1.916 (2,000) |
|---|---|---|---|---|
| reach floor 10 | 42 of 50 | 1,816 | 47 of 50 | 1,926 |
| reach floor 20 | 20 of 50 | 848 | 30 of 50 | 1,051 |
| reach floor 25 | 14 of 50 | 554 | 19 of 50 | 702 |
| **reach the top** | **8 of 50** | **351 (17.6%)** | **9 of 50** | **442 (22.1%)** |
| health entering floors 21–30 | 0.90 | 0.88 | 0.88 | 0.88 |

**Deadliest floors** (2,000 seeds; deaths of the runs that reached the floor):

| | 1st | 2nd | 3rd | 4th | 5th |
|---|---|---|---|---|---|
| 1.914 | 17 (177 of 1,230) | 25, warden (70 of 554) | 20, boss (94 of 848) | 18 (116 of 1,053) | 29 (39 of 392) |
| 1.916 | 17 (182 of 1,514) | 18 (152 of 1,332) | 19 (129 of 1,180) | 29 (55 of 503) | 21 (103 of 1,001) |

**Deaths by floor kind** (2,000 seeds):

| | Boss floors | Warden floors |
|---|---|---|
| 1.914 | 137 | 192 |
| 1.916 | 56 | 94 |

The floor-10 boss alone goes from 41 deaths to 0.

**Wins by people** (2,000 seeds, 1.914 → 1.916):

| People | 1.914 | 1.916 |
|---|---|---|
| dwarf | 93 of 377 | 116 |
| elf | 95 of 393 | 116 |
| orc | 93 of 433 | 108 |
| human | 39 of 410 | 64 |
| voidkin | 31 of 387 | 38 |

- In the fixed 50 on 1.916, human and voidkin each win 0 of 10.

**Wins by calling** (2,000 seeds): mage 95 of 653 → **203**, rogue 135 of
644 → 132, warrior 121 of 703 → 107.

## 2. Story: 100 playthroughs

**How the runs were picked**
- Seeds 1–100, one run per seed.
- 4 runs for each of the 25 people × calling pairs, one per walk goal:
  random, favorGood, favorEvil, maximizeGold.
- The main batch is the **naive player**: the one the reports, the CI bands
  and the 800-run check use. The same seeds are also run with the
  **competent player**, the in-app simulator's.
- A lost fight never ends a run: after 3 tries the walk moves on.
  - A **death** below is an encounter lost after 3 tries: where a run would
    end with permadeath.
  - All 100 runs reach the ending.
- The larger figure is the 800-run check rerun on 1.914 (naive, seeds 11
  and 23, 400 runs each).

| Chapter | Encounters won | 800-run check | Deaths | Runs with a death | Median level and gold on arrival |
|---|---|---|---|---|---|
| 1 | 92.7% | 93.2% | 8 (+20 story losses) | 8 of 100 | 1, 110 |
| 2 | 98.2% | 98.2% | 12 | 12 of 100 | 3, 370 |
| **3** | **80.6%** | 83.6% | 253 | **85 of 100** | 5, 404 |
| 4 | 68.4% | 71.4% | 315 | 94 of 100 | 8, 908 |
| 5 | 71.7% | 72.6% | 381 | 98 of 100 | 11, 1,615 |
| 6 | 59.7% | 62.8% | 314 | 94 of 100 | 15, 2,457 |
| 7 | 57.2% | 53.8% | 74 | 69 of 100 | 18, 3,274 |
| 8 | 48.5% | 51.3% | 202 | 94 of 100 | 19, 3,610 |

- Overall, 73.9% of encounters are won (4,464 of 6,043); the 800-run check
  gives 75.9%.
- **With permadeath, 0 of 100 naive runs would finish.** The first death
  falls in chapter 3 for 66 of them.
- **The competent player wins 99.0% of encounters** (6,843 of 6,910). 70 of
  100 would finish with no death.

**Deadliest fights** (naive; losses of times fought):

| Chapter | Fight | Foe | Losses | 800-run |
|---|---|---|---|---|
| 8 | `7810` | tear_herald | 78 of 100 | |
| 5 | `zone:z_shroud_vigil` | void_archon | 53 of 86 | |
| 7 | `7520_tallis` | claimant_tallis | 50 of 76 | |
| 5 | `6200` | void_hound | 48 of 74 | void hounds lost 1,707 times in chapter 5 |
| 6 | `7002` | hollow_reflection | 48 of 87 | |
| 4 | `5100` | drowned_pilgrim | 45 of 52 | 77%, 381 of 492 |
| 3 | `3200` | inquisition_soldier | 40 of 68 | 54%, 697 of 1,299 |

**Bosses** (800-run check, target in brackets). Every boss is within
7 points of its target:

| Boss | Win rate (target) |
|---|---|
| aurel_vane | 70 (75) |
| void_stalker | 65 (65) |
| inquisitor | 61 (55) |
| bone_warden | 62 (55) |
| void_archon | 47 (50) |
| white_admiral | 48 (45) |
| claimant Vane | 41 (40) |
| claimant Tallis | 38 (40) |
| claimant Morrow | 36 (40) |
| tear_herald | 31 (35) |
| void_sovereign | 34 (35) |

**By people and calling** (naive, 20 runs each; the 800-run check is the more
reliable):
- People: orc 80.2 (75.9), elf 77.8 (78.8), dwarf 73.9 (76.8), human 69.4
  (74.7), voidkin 67.2 (74.1). Over 800 runs the spread is only 4.7 points.
- Callings: rogue 76.8 (76.4), mage 74.9 (80.1), warrior 74.0 (75.2), ranger
  73.8 (73.7), cleric 69.8 (73.9).
- With the competent player, every people and calling is at 98.4–99.6%.

## 3. What the simulators don't do that a player would

**Tower bot**
- No battlefield conditions, momentum or Quick Resolve.
- Card order is fixed (oath, skill, die, spell). It never refuses a card,
  and takes the first oath offered.
- Stat picks are fixed shares.
- It rerolls a face only when it is below the die's mean.
- It drinks a potion only below 40% health, and never abandons a run.
- On 1.916 it picks its die from 4 trial fights against the next floor's real
  foes at full health. That is better informed than a player.

**Story simulator**
- Companions:
  - The naive player has only Vica.
  - The competent player recruits companions, but plays no combos or duo
    techniques.
- No Quick Resolve, momentum, Luck nudges or Hammersmith.
- No conditions, chapter threat, affixes or Elites on the story walk.
- A loss gives no XP and refills health. Permadeath is never played.
- Shops are visited once a chapter. The naive player never wears loot.
- Not played: the companions' crises, the detour choices, the thieves'
  purse.

**Small samples.** 50 and 100 runs are small. A gap of a few runs between two
people or callings is noise. Trust the 2,000-seed and 800-run figures.

## 4. Review: what is too hard, too easy or unfair

Ranked. "Covered" means a fix the user has already picked.

| # | Finding | Evidence | What I'd change | Size | Covered? |
|---|---|---|---|---|---|
| 1 | **Tower: the bosses are free passes and there is no attrition** (on 1.916, which ships next) | floor-10 boss 0 deaths; boss floors 137 → 56; health 0.88 entering floors 21–30 | heal 30% → 15%, wardens and bosses as real peaks, floors 17–29 smoothed (candidate ready: top 22.1% → 13.6%, last boss 22.8%) | Tower numbers, 1 PR | **#5** |
| 2 | **Tower: the wall on floors 17–19** | 1.914 floor 17: 177 of 1,230 die; 1.916: floors 17–19 at 10–12% each | as #1: those floors' extras down | in #1 | **#5** |
| 3 | **Tower: humans and voidkin are about half as strong** | wins 39 and 31 against about 93 for the others (1.914); human and voidkin 0 of 10 each in the fixed 50 on 1.916; #5's candidate widens it (human 7.8%, voidkin 4.7% vs elf 24.2%) | a Tower-only start for those two (health, or a stat point); the story's 800-run spread is only 4.7 points, so this is a Tower problem | small, 1 PR | **new** (review #8, not picked) |
| 4 | **Tower: the mage doubles on 1.916** | 95 → 203 of 653 wins, while the warrior drops 121 → 107 | the profession scales, already in #5's candidate (mage 14%, rogue 14%, warrior 13%) | in #1 | **#5** |
| 5 | **Story chapter 3 is a wall made by an ordinary foe** | inquisition_soldier at `3200`: 40 of 68 lost (54% of 1,299 over 800 runs, against the void stalker's 35%); 66 of 100 runs take their first death in chapter 3 | the inquisition soldier's health or damage down about 10%, or a guard face on its die | data, 1 small PR | **new** |
| 6 | **Story: two ordinary foes kill more than any boss** | drowned_pilgrim `5100` (chapter 4) 77%; void hounds lost 1,707 times in chapter 5, five times the void archon | drowned pilgrim and void hound toned to their chapter's ordinary band | data, 1 small PR | **new** |
| 7 | **Story: chapter 2 is a free pass** | 98.2% won; 11 of 12 deaths at one fight, `2020` | one ordinary fight a step harder, or leave it as the breather before the chapter 3 wall | data, tiny | **new** |
| 8 | **Story: for a competent player the whole story is easy** | 99.0% won; only chapter 8 pushes back (tear_herald 9 of 100) | first measure where a real player sits, between naive (74%) and competent (99%); then maybe a "veteran" difficulty | measure first | **new** |
| 9 | **Tower: the boon cards** | die card worse than refusing (review #6) | after #5 | 1 small PR | **#6** |

**My reading:**
- **For the Tower,** #5's candidate already fixes 1, 2 and 4. Of what's left,
  the people gap (3) is the one players will feel. I'd do it right after #5,
  as a small Tower-only PR.
- **For the story,** the walls (5, 6) are ordinary foes tuned above their
  chapter. Two small data PRs fix them, and they don't touch the bosses,
  which are all on target.
- **Item 8 needs a measure, not a change.** The naive and competent players
  bracket a real player very widely.
