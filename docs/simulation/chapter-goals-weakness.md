# Chapter goals: the weakness goal counted (chapters 4 to 6)

v2.5.0's `weakness` goal (a won fight with a foe's weakness struck once) was
met by 73 to 86% of runs in chapters 4 to 6, above the 30 to 70% the goals
were picked by. The goal now counts: `ChapterFightFacts.weaknessHits`, met at
`max(1, value)` hits in one won fight. Chapters 4 to 6 ask 3 (the lead's
pick; the user chooses between 2 and 3); chapter 7 keeps one (43/45%).

**Method.** The playthrough simulator, 100 typical + 100 competent runs,
seed 1, the balance plan (sim_batch_test's goals and professions), in
isolates. A temporary hook (not committed) in the fight-attempt loop built
`ChapterFightFacts` like the fight screen: rounds, hero health after and max,
the foes, `firstTry` = first attempt, a potion drunk, and the weakness hits
landed by the hero's die strike, splash, burns and spells (`takeHit` with a
multiplier above 1), allies' strikes left out. The real `chapterGoalTable`
was read once per chapter per run; a chapter stops counting once a later one
is seen. The sim plays no chapter chest, so the three variants are the same
runs. The base reproduces the earlier measure exactly (ch4 76/84, ch5 73/84,
ch6 79/86). T = typical, C = competent; every run reached chapter 8.

### Base: struck once (value 1, as v2.5.0)
| ch | goal | T % | C % |
|---|---|---|---|
| 4 | rounds | 35 | 48 |
| 4 | weakness | 76 | 84 |
| 4 | no_potion | 32 | 23 |
| 5 | rounds | 54 | 63 |
| 5 | weakness | 73 | 84 |
| 5 | no_potion | 45 | 27 |
| 6 | rounds | 38 | 46 |
| 6 | weakness | 79 | 86 |
| 6 | no_potion | 52 | 37 |
| 7 | rounds | 42 | 36 |
| 7 | weakness | 43 | 45 |
| 7 | first_try | 86 | 96 |
| 8 | rounds | 58 | 64 |
| 8 | first_try | 73 | 81 |
| 8 | no_potion | 41 | 34 |

| ch | policy | reached | Wooden | Iron | Silver | Gold | mean tier |
|---|---|---|---|---|---|---|---|
| 4 | T | 100 | 18 | 33 | 37 | 12 | 1.43 |
| 4 | C | 100 | 4 | 45 | 43 | 8 | 1.55 |
| 5 | T | 100 | 8 | 30 | 44 | 18 | 1.72 |
| 5 | C | 100 | 8 | 21 | 60 | 11 | 1.74 |
| 6 | T | 100 | 11 | 26 | 46 | 17 | 1.69 |
| 6 | C | 100 | 5 | 35 | 46 | 14 | 1.69 |
| 7 | T | 100 | 9 | 33 | 36 | 22 | 1.71 |
| 7 | C | 100 | 1 | 39 | 42 | 18 | 1.77 |
| 8 | T | 100 | 6 | 34 | 42 | 18 | 1.72 |
| 8 | C | 100 | 7 | 26 | 48 | 19 | 1.79 |

### Variant: 2 hits in one won fight (ch4–6)
| ch | goal | T % | C % |
|---|---|---|---|
| 4 | rounds | 35 | 48 |
| 4 | weakness | 70 | 83 |
| 4 | no_potion | 32 | 23 |
| 5 | rounds | 54 | 63 |
| 5 | weakness | 68 | 78 |
| 5 | no_potion | 45 | 27 |
| 6 | rounds | 38 | 46 |
| 6 | weakness | 77 | 84 |
| 6 | no_potion | 52 | 37 |
| 7 | rounds | 42 | 36 |
| 7 | weakness | 43 | 45 |
| 7 | first_try | 86 | 96 |
| 8 | rounds | 58 | 64 |
| 8 | first_try | 73 | 81 |
| 8 | no_potion | 41 | 34 |

| ch | policy | reached | Wooden | Iron | Silver | Gold | mean tier |
|---|---|---|---|---|---|---|---|
| 4 | T | 100 | 23 | 29 | 36 | 12 | 1.37 |
| 4 | C | 100 | 4 | 45 | 44 | 7 | 1.54 |
| 5 | T | 100 | 9 | 32 | 42 | 17 | 1.67 |
| 5 | C | 100 | 12 | 19 | 58 | 11 | 1.68 |
| 6 | T | 100 | 13 | 24 | 46 | 17 | 1.67 |
| 6 | C | 100 | 6 | 35 | 45 | 14 | 1.67 |
| 7 | T | 100 | 9 | 33 | 36 | 22 | 1.71 |
| 7 | C | 100 | 1 | 39 | 42 | 18 | 1.77 |
| 8 | T | 100 | 6 | 34 | 42 | 18 | 1.72 |
| 8 | C | 100 | 7 | 26 | 48 | 19 | 1.79 |

### Variant: 3 hits in one won fight (ch4–6), the build
| ch | goal | T % | C % |
|---|---|---|---|
| 4 | rounds | 35 | 48 |
| 4 | weakness | 54 | 72 |
| 4 | no_potion | 32 | 23 |
| 5 | rounds | 54 | 63 |
| 5 | weakness | 58 | 64 |
| 5 | no_potion | 45 | 27 |
| 6 | rounds | 38 | 46 |
| 6 | weakness | 67 | 71 |
| 6 | no_potion | 52 | 37 |
| 7 | rounds | 42 | 36 |
| 7 | weakness | 43 | 45 |
| 7 | first_try | 86 | 96 |
| 8 | rounds | 58 | 64 |
| 8 | first_try | 73 | 81 |
| 8 | no_potion | 41 | 34 |

| ch | policy | reached | Wooden | Iron | Silver | Gold | mean tier |
|---|---|---|---|---|---|---|---|
| 4 | T | 100 | 27 | 34 | 30 | 9 | 1.21 |
| 4 | C | 100 | 9 | 44 | 42 | 5 | 1.43 |
| 5 | T | 100 | 11 | 33 | 44 | 12 | 1.57 |
| 5 | C | 100 | 13 | 27 | 53 | 7 | 1.54 |
| 6 | T | 100 | 14 | 27 | 47 | 12 | 1.57 |
| 6 | C | 100 | 12 | 35 | 40 | 13 | 1.54 |
| 7 | T | 100 | 9 | 33 | 36 | 22 | 1.71 |
| 7 | C | 100 | 1 | 39 | 42 | 18 | 1.77 |
| 8 | T | 100 | 6 | 34 | 42 | 18 | 1.72 |
| 8 | C | 100 | 7 | 26 | 48 | 19 | 1.79 |


### Best weakness hits in one won fight (share of runs with at least k)

| ch | policy | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 4 | T | 76 | 70 | 54 | 37 | 19 |
| 4 | C | 84 | 83 | 72 | 44 | 17 |
| 5 | T | 73 | 68 | 58 | 37 | 13 |
| 5 | C | 84 | 78 | 64 | 45 | 19 |
| 6 | T | 79 | 77 | 67 | 42 | 15 |
| 6 | C | 86 | 84 | 71 | 42 | 22 |

## Reading

- **2 hits barely moves it** (−1 to −6 points): a run that strikes a weakness
  once usually does it again in the same fight. Competent ch4 and ch6 stay
  over 80%.
- **3 hits** brings all six cells inside 20–80% (54–72%); competent ch4 (72%)
  and ch6 (71%) sit just above 70. 4 hits would land 37–45%, in the 40–60
  band, if the user wants it harder still.
- The chapter chest's mean tier in ch4–6 drops from 1.43–1.74 (base) to
  1.21–1.57 (3 hits); Gold goes from 8–18% to 5–13%.
- Outside 20–80% in every variant, unchanged by this: ch7 `first_try`
  86/96%, ch8 `first_try` C 81%.
