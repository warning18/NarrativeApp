# clash_balance on the real walk (wave 17 item 3)

> **Applied in v1.524 (option a).** The test runs on the real walk and
> passes its existing limits: see "What was changed" at the end. The
> measurements below are the ones the choice was made on.

Wave 17 §3 proposed running `test/clash_balance_test.dart` on the real walk: the same tables as `boss_balance_test`, seeds 7, 11 and 23 pooled at 100 runs each, the 0.10 per-chapter limit kept, and a new check that the mean gap over chapters 2 to 8 stays under 0.08. Measured on v1.516, it fails at every seed. The proposal's numbers were taken with 18 tables plus `politics_events`; the real walk loads all 26.

## The gap (clash minus plain, attempt win rate), pooled over 300 runs

| Tables | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | Mean ch 2–8 |
|---|---|---|---|---|---|---|---|---|---|
| Proposal's 18 + events | | 0.094 (peak) | | | | | | | 0.069 |
| All 26 (the real walk) | 0.044 | **0.213** | **0.127** | **0.126** | **0.113** | **0.164** | **0.138** | **0.102** | **0.140** |

Limits: 0.25 for chapter 1, 0.10 for chapters 2 to 8, 0.08 for the mean. Each seed fails alone too (seed 7: chapter 2 at 0.295).

**Where it comes from.** Adding the missing tables one group at a time:
- `expedition_steps` is most of it (mean to about 0.105, chapter 2 to 0.145): the written expedition roads give many fights against several foes, where goals, packBreak and parry help most.
- `training_paths` adds a little (chapter 2 to 0.113, chapter 7 to 0.120).
- Houses, quests, NPCs and the land tables stay at the proposal's numbers.

**One clash rule off at a time** (all tables, pooled; mean 0.140 with all on): `goal` 0.098, `parry` 0.113, `packBreak` 0.114, `execute` 0.118; `reaction`, `morale`, `squad`, `kinds` 0.124 to 0.140; `fatigue`, `writ`, `response`, `tide` raise it (0.149 to 0.164). No single rule: on the real walk the clash rules as a whole are about 14 points kinder per try.

**Cost.** The rewritten test runs about 62 s of test body against about 20 s today (twice the runs, and the heavier walk).

## Options

- **(a) Recommended: tune the clash rules on multi-foe fights**, mainly `goal` and `execute`, until the real walk passes the existing limits, then land the test. This changes game numbers, so it is a balance item for the user.
- (b) Land the test with the proposal's 18-table loader. It passes (mean 0.069) but does not measure the game as played.
- (c) Re-set the limits for the real walk. This loosens them.

## What was changed (v1.524)

Measured with the simulator's tamper patch in (Hex, Silence and Curse,
see [sim-gaps.md](sim-gaps.md)), which alone moved the gap to the first
row below.

**Where the gap really is.** Fight by fight, chapter 2's pairs (two
Street Bandits, two Harbour Rats) are won 24% of the time under the plain
rules and 65% under the clash rules; lone foes 61% and 57%. Nearly every
pair the clash rules win ends early: of about 830 pair wins in chapter 2,
only 67 killed both foes. The rest fled when their leader fell (pack
break), fled hurt (morale), fell to the execute line, were routed or held.
Those rules overlap, which is why turning any one of them off moved the
gap so little (goal off: chapter 2 still 0.210). Chapters 3 to 8 show the
same in smaller fights.

**The rules, now (fight_length.dart, fight_goal.dart, parry.dart; the
fight screen and the simulator both play them):**

| Rule | Before | Now |
|---|---|---|
| Goal chance | 25% of eligible fights | 25% for a lone foe, **12.5%** for a pack (`packGoalChance`) |
| Hold | 4 enemy turns against a pair, 5 against more | **foes + 4**: 6 against a pair, 7 against three |
| Rout | the captain falls, every other foe flees | each other foe flees at **50%** (`routFleeChance`), the rest fight on |
| Execute | any struck foe under 10% falls | in a pack fight, **only the last foe standing** (`executesInFight`) |
| Morale | a foe under 25% flees at 50% a round | **only a lone foe** wavers (`moraleFleeChanceFor`); a pack holds its nerve |
| Pack break | each other foe flees at 70% | the same, but **the last of a pack is cornered** and stands (`cornered`) |
| Parry | block x1.5 | x1.5 against a lone foe, **the block alone against a pack** |
| Pack stats (both rule sets) | 0.8 for a pair, 0.7 for three | **0.7 / 0.6** |

The pack-stat cut is the price of the rest: with the pack rules alone the
gap passed, but three professions fell under `boss_balance`'s 60%
floor (ranger 57.1, rogue 57.5, warrior 58.4 at seed
7). Pack fights now have fewer ways to end early, so their members are
smaller, under both rule sets.

Scaled morale was tried and dropped: a pack wavering at 25% a round (in
place of none) left chapter 2 at 0.113-0.117 at both seed sets.

**The gap, pooled over seeds 7, 11 and 23 (100 runs each):**

| Code | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | Mean ch 2–8 |
|---|---|---|---|---|---|---|---|---|---|
| main (v1.516 data) | 0.044 | 0.213 | 0.127 | 0.126 | 0.113 | 0.164 | 0.138 | 0.102 | 0.140 |
| main + tamper | 0.060 | **0.232** | 0.099 | 0.078 | 0.098 | **0.137** | 0.093 | 0.076 | **0.116** |
| + the pack rules | 0.041 | 0.062 | 0.018 | 0.026 | 0.047 | 0.073 | 0.026 | -0.023 | 0.033 |
| **+ pack stats 0.7/0.6 and the claimants (v1.524)** | 0.047 | 0.067 | -0.012 | 0.020 | 0.022 | 0.089 | 0.011 | -0.007 | **0.027** |

Limits: 0.25 for chapter 1, 0.10 for chapters 2 to 8, 0.08 for the mean.
The clash rules stay a net plus (mean +0.027); chapters 3 and 8 are now
about even.

**Margin.** The walk parts early, so a chapter's gap moves 0.02 to 0.05
with any change to the seeded stream. At seeds 1, 2 and 3 (not the
test's) the pack rules gave chapter 2 at 0.097, chapter 6 at 0.115 and a
mean of 0.066, against main's 0.251, 0.198 and 0.167 there. Chapter 6 is
the one to watch.

**What it costs the player.** Encounters won within 3 tries
(`boss_balance_test`'s 400 runs), main → v1.524:

| Seed | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 |
|---|---|---|---|---|---|---|---|---|
| 7 | 93.5 → 92.6 | 86.8 → 83.6 | 66.1 → 60.0 | 57.7 → 53.0 | 66.8 → 61.7 | 56.8 → 56.4 | 52.6 → 53.3 | 49.3 → 50.1 |
| 11 | 93.7 → 93.1 | 88.1 → 86.6 | 67.6 → 60.7 | 58.8 → 53.6 | 65.2 → 62.3 | 57.4 → 55.5 | 54.3 → 54.2 | 52.2 → 49.6 |
| 23 | 94.8 → 94.2 | 86.8 → 83.1 | 66.1 → 59.4 | 56.9 → 53.5 | 65.1 → 61.7 | 58.8 → 54.3 | 53.8 → 51.6 | 52.2 → 48.3 |

Chapters 3 to 5 are 3 to 7 points harder: those are the pack fights the
clash rules used to end early. The bosses and the professions stay in
their bands (see [difficulty-review.md](difficulty-review.md), v1.524).

The test (`test/clash_balance_test.dart`) is unchanged from the patch
measured above: 26 tables, seeds 7, 11 and 23 at 100 runs, 0.10 a
chapter (0.25 for chapter 1), mean of chapters 2 to 8 under 0.08.
