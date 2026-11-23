# Clan gift dice: cinder, ossuary, tally (measured)

Follow-up to proposal 4 of `combinations-review.md` (row A7). The user's
decision: make the three dead clan dice worth keeping. Each should beat a
bought die of its tier, in its clan's style, without becoming the new
dominant die. The Headsman and every other die are unchanged.

## Batch

**CD989**: v1.989.0 (main 2b9a273d), seeds 1..100, one run per seed. The
plan is B976's: the 25 race x profession pairs x 4 goals. Typical (T) and
competent (C) policies, with `swapDiePerFight` off and on. That is 8 x 100
runs, before and after. The harness was a throwaway test (now deleted). It
read each run's `offerPicks` (clan dice taken), `die` (the final die),
`fightsWon`/`fightsLost`, the Tear Herald beaten or not, and, through
`onFightDie`, the dice rolled in fights.

## The faces, old and new

Ids, die names and face names are kept. Only values, weights, elements,
keywords and the tally's mix of faces change. Face counts stay the same
(6, 10, 12).

| Die | Old | New |
|---|---|---|
| `cinder_die` (Compact: Fire, the edge that breaks a guard) | Fire Atk 2, 2, 3 (w .9); Def 2 steady (w .9); Tempered (forgeheart, w .6); Def 1 | Fire Atk 2, 2 **pierce**, 3 (w .9); Def 2 steady (w .7); Tempered (w **.7**); Def **2** (w **.5**) |
| `ossuary_die` (Penitents: Earth, burdens carried) | Bone Cleaver Atk 2 growth; Strike Atk 3 x2; Grave Guard Def 3 (w .9); Guard Def 3; Marrow Mend Heal 3 (w .7); Mend Heal 3; Last Rites (w .5), Ossuary Calm (w .5), Open Grave (w .7) | Bone Cleaver Atk **3** growth; Strike Atk 3 **pain**, Strike Atk 3; Grave Guard (w **.7**); Guard (w **.6**); Marrow Mend Heal **4** (w **.6**); Mend (w **.6**); Last Rites (w **.8**), Ossuary Calm (w .5), Open Grave (w **.8**) |
| `tally_die` (Crows: salt water, many hits, the long game) | 12 plain faces of 2: Strike x4, Guard x4, Mend x4 | 12 plain faces of **3**: **Strike x8 (Water, two with growth)**, Guard x2 (w .8), Mend x2 (w .8). Still no Skill face (`dice_sizes_test` pins that). |

## simDieValue (no skills learned; base damage 6 / 8 / 10 / 12)

| Die | Cost | Old | New |
|---|---|---|---|
| cinder | 140 | 5.81 / 7.11 / 8.40 / 9.70 | 6.65 / 8.15 / 9.65 / 11.15 |
| ossuary | 220 | 6.07 / 7.21 / 8.36 / 9.50 | 7.08 / 8.43 / 9.78 / 11.13 |
| tally | 150 | 3.67 / 4.33 / 5.00 / 5.67 | 7.07 / 8.50 / 9.93 / 11.36 |
| starter (the die to beat) | 0 | 6.31 / 7.89 / 9.48 / 11.06 | unchanged |
| headsman | 180 | 6.32 / 7.77 / 9.21 / 10.66 | unchanged |
| void (bought, any profession) | 120 | 6.61 / 8.09 / 9.56 / 11.04 | unchanged |
| chorus (bought d12) | 160 | 4.12 / 4.91 / 5.70 / 6.50 | unchanged |
| gambler (bought d12) | 200 | 4.52 / 5.46 / 6.40 / 7.35 | unchanged |
| lantern (clan, which already works) | 140 | 7.10 / 8.72 / 10.34 / 11.97 | unchanged |
| court (clan, which already works) | 160 | 6.93 / 8.45 / 9.98 / 11.50 | unchanged |

Before the change, all three were below the starter die, so no policy rolled
them. The typical player needs a die 0.25 better than the one in play. Now
each one beats the Headsman, the void die and the bought d12s, and stays
below the lantern die (the court die for cinder). Resonance (+1 on faces of
1 to 3) lifts them further in fights for the clan's own loyalists. All
tally faces are 3, so all twelve get the bonus.

## Results (CD989), first cut (de35d632)

These tables are for the first cut: Forge Strike with pierce and Tempered
at w .8. The final faces are in "Cinder trimmed" at the end.

### Final die / clan die taken: final die / clan die taken

| | T off | T on | C off | C on |
|---|---|---|---|---|
| cinder, before | 0 / 63 | 0 / 60 | 1 / 51 | 0 / 50 |
| cinder, after | **5 / 63** | **4 / 62** | **9 / 58** | **7 / 62** |
| ossuary, before | 0 / 37 | 0 / 37 | 0 / 6 | 0 / 8 |
| ossuary, after | **7 / 38** | **8 / 36** | 0 / 9 | 1 / 11 |
| tally, before | 0 / 22 | 0 / 21 | 0 / 25 | 0 / 21 |
| tally, after | **7 / 22** | **6 / 21** | 2 / 31 | 2 / 31 |
| headsman final, before / after | 15 / 2 | 17 / 1 | 6 / 1 | 8 / 2 |
| fight win %, before / after | 92.9 / 92.5 | 95.3 / 95.4 | 93.8 / 93.1 | 95.8 / 95.2 |
| Tear Herald beaten, before / after | 88 / 86 | 98 / 95 | 91 / 89 | 94 / 91 |

"Taken" counts the clan die chosen from a banner card. Tally also comes
from the Candle Count quest. With swap on, the clan dice are also held for
fights: cinder in 61 T runs, ossuary in 33, tally in 21 (tally in 0 before).

**Final-die shares after (T off):** starter 26, shadow 20, berserker 8,
ossuary 7, tally 7, cinder 5, lantern 5, iron 4. **C off:** starter 23,
shadow 16, court 15, iron 14, cinder 9, berserker 6, stone 5.

**No new dominant die.** No clan die is the final die in more than 9 of
100 runs. Within a profession, the most any of them reaches is 7 of 20
(cinder, cleric, C off). Before, the Headsman was the clerics' final die
in 11 of 20 T runs, and it now drops to 2 overall: the clan dice take its
place among the clerics. The profession tops that were above 50% are
unchanged and were already there: rogue on shadow (20/20 T, 16/20 C),
ranger on starter (13/20 T, 16/20 C), warrior on starter (13/20 T) and on
iron (13 to 14/20, C off).

The bought dice of the same tier (chorus, gambler, Headsman aside) are the
final die in 0 runs, before and after. The void die drops from 2 to 0.

A first try (cinder at 8.38, with Hold the Heat at weight .4 and Forge
Strike at 1.0) made cinder the final die in 18 C runs. That was more than
the Headsman's 15 in T, so it was cut back to the faces above.

**Caveat.** Fight win % and Tear Herald wins dip by 0.4 to 0.7 points and
2 to 3 runs on all four lines. That is within what one batch of 100 moves
(the first try moved them -0 to -3 and +1), but the direction is the same
everywhere. The simulator ignores keywords (pierce, pain, growth) when it
values a die, and it never fills the tally's plain faces with skills.

## Second batch: seeds 101..200 (swap off)

The same plan, both policies, before (main 2b9a273d faces) and after
(de35d632). Each cell is runs ending on the die / times taken, first for
seeds 1..100, then for 101..200.

| | T before | T after | C before | C after |
|---|---|---|---|---|
| cinder | 0/63, 0/50 | 5/63, 6/49 | 1/51, 0/48 | 9/58, 14/52 |
| ossuary | 0/37, 0/41 | 7/38, 7/40 | 0/6, 0/19 | 0/9, 1/17 |
| tally | 0/22, 0/28 | 7/22, 7/28 | 0/25, 0/25 | 2/31, 4/32 |
| Headsman (final only) | 15, 21 | 2, 2 | 6, 14 | 1, 1 |
| fight win % | 92.9, 93.1 | 92.5, 93.0 | 93.8, 95.4 | 93.1, 94.0 |
| Tear Herald beaten | 88, 94 | 86, 92 | 91, 91 | 89, 90 |

**Pooled over 200 seeds, before → after:**
- Fight win: T 93.0 → 92.7, C 94.6 → 93.6.
- Tear Herald beaten: T 182 → 178, C 182 → 179.

The dip holds on the second batch. For T it is small, 0.3 points and 4
runs. For C it is 1.0 point, and 1.4 points on seeds 101..200. On these
seeds cinder is the competent player's final die in 14 runs, and in 8 of
20 mage runs. The Headsman had 14 on the same seeds (12 of 20 clerics).

## Cinder trimmed (final faces)

The coordinator asked to trim cinder only, to close the competent dip.
1. **Step 1:** Forge Strike loses pierce. The die value is unchanged (8.19
   at damage 8), because the bot ignores keywords when it values a die.
2. **Step 2:** Tempered's weight goes from .8 to .7. Cinder is now 8.15 at
   damage 8 (6.65 / 8.15 / 9.65 / 11.15).

Ossuary and tally are unchanged. Same plan, swap off, against the same
before (main 2b9a273d). Each cell is runs ending on the die / times taken,
first for seeds 1..100, then for 101..200.

| | before | first cut | pierce off | final (also Tempered .7) |
|---|---|---|---|---|
| T cinder | 0/63, 0/50 | 5/63, 6/49 | 5/63, 6/49 | 5/63, 5/49 |
| T ossuary | 0/37, 0/41 | 7/38, 7/40 | 7/38, 7/40 | 7/39, 7/42 |
| T tally | 0/22, 0/28 | 7/22, 7/28 | 7/22, 7/28 | 7/22, 7/28 |
| T Headsman (runs ending on it) | 15, 21 | 2, 2 | 2, 2 | 2, 2 |
| T fight win % | 92.9, 93.1 | 92.5, 93.0 | 92.6, 93.0 | 92.5, 93.0 |
| T Tear Herald beaten | 88, 94 | 86, 92 | 87, 92 | 86, 93 |
| C cinder | 1/51, 0/48 | 9/58, 14/52 | 10/58, 17/52 | 6/57, 13/51 |
| C ossuary | 0/6, 0/19 | 0/9, 1/17 | 0/9, 1/17 | 1/9, 1/17 |
| C tally | 0/25, 0/25 | 2/31, 4/32 | 2/31, 4/33 | 3/31, 5/33 |
| C Headsman (runs ending on it) | 6, 14 | 1, 1 | 1, 1 | 1, 1 |
| C fight win % | 93.8, 95.4 | 93.1, 94.0 | 93.1, 93.9 | 93.2, 94.1 |
| C Tear Herald beaten | 91, 91 | 89, 90 | 89, 88 | 89, 92 |

**Pooled over 200 seeds:**

| | before | first cut | pierce off | final |
|---|---|---|---|---|
| T fight win % | 93.0 | 92.7 | 92.8 | 92.8 |
| T Tear Herald beaten | 182 | 178 | 179 | 179 |
| C fight win % | 94.6 | 93.6 | 93.5 | 93.6 |
| C Tear Herald beaten | 182 | 179 | 177 | 181 |

The competent fight-win dip does **not** close: it is 1.0 point with the
final faces. Trimming cinder lowers its share (C final die 23 → 19 runs out
of 200, at most 7 of 20 in one profession), and C Tear Herald wins come
back to 181 of 182. Fight win does not move, so the dip is not cinder's
pierce or Tempered. It may come from the clan dice taking the Headsman's
place in general, or from ossuary and tally, which were not changed here.
