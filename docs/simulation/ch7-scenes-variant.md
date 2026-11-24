# Chapter 7 scenes variant: the night and the stair (held)

**Status:** held on branch `claude/core-ch7-scenes`, not to merge until the
user says. Base: `main` at v2.2.0 (`ce5f6924f`).

**What it wires** (Narrative's draft
`docs/narrative/drafts/p7-chapter-seven-night-and-stair.md`, branch
`claude/narrative-drafts`, `1fa13c89`):

- `7515_rest` → `7516_eve` → `7517_stair` → `7520_vane` / `_morrow` /
  `_tallis`. The three gated choices (`politicsIf` on `dominion_leader_<x>`
  or `throne_<x>`) move from `7515_rest` to `7517_stair`, as drafted; the
  rest keeps one choice.
- `7516_eve` (candlehold_gates, 16 loyalty callbacks, cap 5) and
  `7517_stair` (candlehold_lantern_hall, 12 earlier-choice callbacks with
  priorities, cap 6): text, French and callbacks copied from the draft.
- Both added to the chapter 7 spine (`chapter_spine.dart`, between the
  `7510_*` and `7520_*` beats) and to Candlehold's scenes (`world_map.dart`).
- **No fight**, as the draft recommends.

**Two changes the guards forced, beyond the draft:**

1. `story_rules_test` refuses a single choice that does nothing (a padding
   node). The rest's effects are split: the potion (`potion_major`) stays on
   `7515_rest`'s choice, the full heal and `rest_before_hall` (the
   provisions and mana refill) move to `7516_eve`'s "Sleep, and climb at
   dawn". Same effects, one scene later, before any fight.
2. `city_plan_record_test` wants every Candlehold scene anchored on a
   building (Maps' `city_plans.json`; the generator is frozen): `7516_eve`
   on `candlehold_b003` (the terrace of every fire, as `7515_rest`),
   `7517_stair` on `candlehold_b159`, a free lantern-hall building with no
   name yet (Narrative may name it).

## Measurement

Throwaway probe (deleted): the batch's plan (goals in turn, professions
rotating), balance plan, 100 runs a policy and seed, seeds 1 and 2, base vs
variant. Encounters are the fights the walk logs in chapter 7
(`byChapter`); level-ups are the level on arriving in ch8 minus ch7; tries
won count every try, retries included.

### Both seeds (200 runs a policy)

| | typical base | typical variant | competent base | competent variant |
|---|---|---|---|---|
| ch7 encounters / run | 1.72 | 1.72 | 1.70 | 1.70 |
| ch7 fights 1 / 2 (runs) | 57 / 143 | 57 / 143 | 60 / 140 | 60 / 140 |
| ch7 level-ups / run | 1.18 | 1.18 | 1.14 | 1.13 |
| level at first ch8 fight, median (Q1–Q3) | 23 (19–24) | 23 (19–24) | 23 (19–25) | 23 (19–25) |
| ch8 first-try wins | 81.3% | 85.3% | 86.9% | 86.0% |
| tear_herald tries won | 68.5% | 71.3% | 73.4% | 72.0% |
| void_sovereign tries won | 61.0% | 65.6% | 73.0% | 68.8% |
| runs reaching an ending | 200 | 200 | 200 | 200 |
| visits `7516_eve` / `7517_stair` | – | 200 / 200 | – | 200 / 200 |

### By seed

| policy, seed | ch8 first-try base → variant | tear_herald | void_sovereign |
|---|---|---|---|
| typical 1 | 81.4 → 87.0% | 69.9 → 70.5% | 61.0 → 66.7% |
| typical 2 | 81.2 → 83.5% | 67.2 → 72.1% | 61.0 → 64.4% |
| competent 1 | 88.4 → 85.7% | 74.4 → 77.7% | 79.5 → 71.0% |
| competent 2 | 85.5 → 86.3% | 72.4 → 66.9% | 67.4 → 66.7% |

Encounters, level-ups and the ch8 level are the same per seed in both
(seed 1: 1.72 T / 1.66 C encounters, 1.16 / 1.12 level-ups, median 23).

## Reading

- **No balance effect.** The two scenes add no fight, no XP and no gold;
  ch7's fights, level-ups and the level entering ch8 are unchanged. The ch8
  and boss swings (±3 to 8 points, in both directions, by seed and policy)
  are the random draws shifting by the two extra steps, not the scenes.
- Every run sees both scenes (they are on the only road to the Hall).
- This probe's ch7 encounter count (1.7) is lower than the 2.65 / 2.27 of
  the v2.1.5 report; its level-ups (1.16 / 1.12) and ch8 level (23) match.
  The older report counted encounters some other way (not checked) or
  main has changed since; the base and variant here are counted alike.
