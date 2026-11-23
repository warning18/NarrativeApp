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
| `cinder_die` (Compact: Fire, the edge that breaks a guard) | Fire Atk 2, 2, 3 (w .9); Def 2 steady (w .9); Tempered (forgeheart, w .6); Def 1 | Fire Atk 2, 2 **pierce**, 3 **pierce** (w .9); Def 2 steady (w .7); Tempered (w **.8**); Def **2** (w **.5**) |
| `ossuary_die` (Penitents: Earth, burdens carried) | Bone Cleaver Atk 2 growth; Strike Atk 3 x2; Grave Guard Def 3 (w .9); Guard Def 3; Marrow Mend Heal 3 (w .7); Mend Heal 3; Last Rites (w .5), Ossuary Calm (w .5), Open Grave (w .7) | Bone Cleaver Atk **3** growth; Strike Atk 3 **pain**, Strike Atk 3; Grave Guard (w **.7**); Guard (w **.6**); Marrow Mend Heal **4** (w **.6**); Mend (w **.6**); Last Rites (w **.8**), Ossuary Calm (w .5), Open Grave (w **.8**) |
| `tally_die` (Crows: salt water, many hits, the long game) | 12 plain faces of 2: Strike x4, Guard x4, Mend x4 | 12 plain faces of **3**: **Strike x8 (Water, two with growth)**, Guard x2 (w .8), Mend x2 (w .8). Still no Skill face (`dice_sizes_test` pins that). |

## simDieValue (no skills learned; base damage 6 / 8 / 10 / 12)

| Die | Cost | Old | New |
|---|---|---|---|
| cinder | 140 | 5.81 / 7.11 / 8.40 / 9.70 | 6.68 / 8.19 / 9.70 / 11.21 |
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

## Results (CD989): final die / clan die taken

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
