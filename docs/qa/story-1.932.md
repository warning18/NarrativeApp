# The story's softened walls on v1.932: before and after

QA, on main v1.932 (Core's #999: the chapter 3 inquisition soldier softened,
the drowned pilgrim and the chapter 5 void hounds toned down, chapter 2 one
fight up, the Tower's foes unchanged). The same runs as the difficulty review
of v1.914 (`docs/simulation/difficulty-review-1.914/`): the 100 naive
playthroughs, one per seed 1 to 100, and the 800-run check (seeds 11 and 23,
400 each), rerun with the review's own code. "1.914" below is the review's
file; the data this PR touches did not change between 1.914 and 1.932 for the
story. Raw figures: `story-1.932/story-summary.json` (its check key says
`v1914` because the script names it so; the data is 1.932).

## The Tower: identical

The 2,000-seed Tower batch on v1.932 and on v1.927 (70df955), compared byte
for byte (`tower_a.json`, 1,266,625 bytes each): **identical**. The Tower's
own copy of the six softened foes (`towerEnemyStats`) holds.

## The story

### Encounters won, per chapter (100 runs, naive; and the 800-run check)

| chapter | 100 runs 1.914 | 100 runs 1.932 | 800 runs 1.914 | 800 runs 1.932 | first deaths here 1.914 | 1.932 |
|---|---|---|---|---|---|---|
| 1 | 92.7% | 92.7% | 93.2% | 93.2% | 8 | 8 |
| 2 | 98.2% | 97.9% | 98.2% | 97.5% | 12 | 12 |
| 3 | 80.6% | 85.4% | 83.6% | 87.4% | 66 | 66 |
| 4 | 68.4% | 74.1% | 71.4% | 73.5% | 13 | 12 |
| 5 | 71.7% | 74.5% | 72.6% | 75.2% | 1 | 1 |
| 6 | 59.7% | 61.8% | 62.8% | 66.0% | 0 | 1 |
| 7 | 57.2% | 56.9% | 53.8% | 60.7% | 0 | 0 |
| 8 | 48.5% | 49.7% | 51.3% | 51.6% | 0 | 0 |

### The chapter bosses (800-run check, share of encounters won; must not move)

| boss | target | 1.914 fought | 1.914 won | 1.932 fought | 1.932 won |
|---|---|---|---|---|---|
| aurel_vane | 75 | 260 | 70.0% | 260 | 70.0% |
| void_stalker | 65 | 837 | 64.9% | 873 | 62.3% |
| hollow_court_inquisitor | 55 | 754 | 60.7% | 764 | 59.2% |
| bone_warden | 55 | 1044 | 62.3% | 1057 | 60.2% |
| void_archon | 50 | 647 | 47.4% | 684 | 43.9% |
| white_admiral | 45 | 506 | 47.8% | 530 | 43.4% |
| claimant_vane | 40 | 97 | 41.2% | 95 | 34.7% |
| claimant_tallis | 40 | 584 | 37.5% | 563 | 39.1% |
| claimant_morrow | 40 | 119 | 36.1% | 142 | 40.1% |
| tear_herald | 35 | 800 | 30.8% | 800 | 29.9% |
| void_sovereign | 35 | 469 | 34.3% | 461 | 34.9% |

### The foes the review named (800-run check, attempts lost / fought)

| foe | 1.914 | 1.932 |
|---|---|---|
| Chapter 3 inquisition_auxiliary | 540 of 1466 (36.8%) | 442 of 1460 (30.3%) |
| Chapter 3 inquisition_soldier | 697 of 1299 (53.7%) | 387 of 1304 (29.7%) |
| Chapter 4 drowned_pilgrim | 381 of 492 (77.4%) | - |
| Chapter 5 void_hound | 1707 of 3613 (47.2%) | 1455 of 3612 (40.3%) |
| Chapter 6 hollow_reflection | 892 of 2498 (35.7%) | 874 of 2539 (34.4%) |
| Chapter 8 hollow_reflection | 469 of 1114 (42.1%) | 449 of 1101 (40.8%) |
| Chapter 8 tear_herald | 554 of 800 (69.2%) | 561 of 800 (70.1%) |

### 100 runs, deadliest fights (deaths / fought)

- **1.914**: ch8 7810:tear_herald 78/100; ch5 zone:z_shroud_vigil:void_archon 53/86; ch7 7520_tallis:claimant_tallis 50/76; ch5 6200:void_hound 48/74; ch6 7002:hollow_reflection 48/87; ch5 6100:void_hound 46/59
- **1.932**: ch8 7810:tear_herald 73/100; ch5 zone:z_shroud_vigil:void_archon 52/83; ch7 7520_tallis:claimant_tallis 48/70; ch6 7002:hollow_reflection 46/87; ch6 zone:z_glass_strand:strand_colossus 43/64; ch5 zone:z_ember_run:rime_bailiff 43/97

Whole story, naive 100 runs: encounters won 73.9% (1.914) -> 76.9% (1.932); runs with no death 0 -> 0.

## What it says

- **Chapter 3 moved the way Core wanted.** Encounters won 80.6% to 85.4% (100
  runs) and 83.6% to 87.4% (800). The inquisition soldier's lost attempts
  fall from 53.7% to 29.7% of the attempts (800 runs; 697 to 387 lost); the
  auxiliary from 36.8% to 30.3%.
- **The drowned pilgrim fell off the wall.** 58 lost of 68 (85%) became 31 of
  61 (51%) in the 100 runs; in the 800-run check it left the ten foes who lose
  most. The void hound: 47.2% to 40.3% lost; its 6200 fight left the 100-run
  list of the six deadliest.
- **Chapter 2 is barely a step harder** (98.2% to 97.9%, 98.2% to 97.5%); its
  12 first deaths are unchanged.
- **First deaths did not move.** 66 of the 80 runs that reach chapter 3 still
  take their first death there: the soldier was one wall, the zone fights
  (void stalker, auxiliaries) still kill, and the naive player has no run
  with no death in either version.
- **The boss table moved a little, by the noise.** The bosses' stats did not
  change; the runs reach them with other levels and gold and a shifted random
  stream, so each boss reads a few points off: void stalker 64.9% to 62.3%,
  void archon 47.4% to 43.9%, white admiral 47.8% to 43.4%, claimant Vane 41.2%
  to 34.7% (96 fights), the others within 2 points, three up. Each move is
  under 1.5 standard errors of the difference (n of 500 to 1,000: about 2.8
  to 3.1 points; 96 fights: 7 points), so none is a real change, but the
  void archon and the white admiral now sit under their targets (50 and 45)
  and were over before (the review's own table of targets).
- **Whole story, naive 100 runs: 73.9% to 76.9% of encounters won.**

Chapter 4 won 68.4% to 74.1% (100) and 71.4% to 73.5% (800): the pilgrim's
change is the visible part; the Hollow Court inquisitor and the bone warden
still lose at about their targets.
