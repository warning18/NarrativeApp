# clash_balance on the real walk (wave 17 item 3)

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

## Decision: option (c), no gameplay change (v1.535)

The user chose **(c)**. The gap is the clash rules doing their job: goals
(rout, subdue, hold), pack break, morale and parry end multi-foe fights before
every foe is down, so those fights are kinder than under the plain rules. That
is the game's design, not a bug to tune away.

The rule changes of option (a), "3a" (clash-only pack rules, then lone foes
not executed), and the pack-stat options (b) and (b+) were measured and
dropped: they closed the gap but pushed professions under `boss_balance`'s
60% floor or cost the player wins. See the two appendix sections below, kept for the record (the code
lived only on branch `claude/core-6` and was not merged).

`test/clash_balance_test.dart` now runs on the real walk (26 tables, seeds
7/11/23, pooled) and guards the gap against drifting further. Measured on
v1.535:

| Runs a seed | Ch 1 | Ch 2 | Ch 3 | Ch 4 | Ch 5 | Ch 6 | Ch 7 | Ch 8 | Mean ch 2–8 |
|---|---|---|---|---|---|---|---|---|---|
| 100 | 0.032 | **0.230** | 0.139 | 0.112 | 0.136 | 0.178 | 0.138 | 0.124 | **0.151** |
| 40 (the test) | 0.008 | **0.278** | 0.133 | 0.102 | 0.153 | 0.189 | 0.169 | 0.133 | **0.165** |

The test runs 40 a seed to keep the suite cheap (about a minute locally,
against two at 100). Its limits are its own measured values plus 0.03 of
seed room, rounded up: **0.31** for chapters 2 to 8, **0.25** for chapter 1
(unchanged since v1.429), **0.20** for the mean over chapters 2 to 8, and the
mean must stay **above 0** (the clash rules stay a net plus). The user's
guide was about 0.24 a chapter and 0.16 for the mean, read on the 100-run
numbers.

## Appendix: what was changed in the dropped 3a work (v1.524)

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

## Appendix: the three options, measured on v1.531 (claude/core-6 + main)

Base: `claude/core-6` merged with main at v1.531 (tamper and claimants in),
so "base" below is v1.531 + the clash-only pack rules, pack stats 0.8/0.7.
"Main" is v1.531 alone. Measured with a throwaway harness (reverted):
gaps as `clash_balance_test` (26 tables, seeds 7/11/23 at 100 runs,
pooled); everything else as `boss_balance_test` (400 runs a seed,
politics events in) and `nemesis_quests_test` (200 runs a seed,
`championFights`).

Note: on v1.531 the base gives chapter 6 at **0.099** and a mean of 0.046
(the real test, run on the branch, prints the same), not the 0.076 / 0.032
in the note at the top of this page. The test passes by 0.001.

**Two things to read the numbers right.**
- `boss_balance`'s professions, chapters and bosses are **clash-rule**
  numbers: `simulatePlaythroughs` always plays the clash rules (the game's
  own). Plain-rule play (the gap's other side) puts the cleric at 80-86%
  and every other profession at 40-59% under every option, so no option
  passes a 60% floor on plain rules; the floor in the table is the test's
  (clash rules).
- The pack rules are clash-only, so the plain-rule numbers depend on the
  pack stats alone: a and c share the base's plain numbers, b and b+
  share theirs.

### The options

- **(a)** base + one clash-only lone-foe lever: **under the clash rules
  a lone foe no longer falls to the execute line** (it still wavers and
  may flee; packs keep their wave-17 rule, only the last one standing
  falls). Pack stats 0.8/0.7. Of the lone-foe levers tried (each rule off
  for lone foes only, one at a time): execute 0.066 at chapter 6, morale
  0.092, reaction 0.090, parry 0.093; goal (0.103) and Tide (0.141) off
  made it worse. A lower lone execute line was not enough (0.07: 0.093;
  0.05: 0.096), so the lever is all or nothing.
- **(b)** pack stats 0.7/0.6 in both rule sets, main's clash rules (no pack
  rules).
- **(b+)** pack stats 0.7/0.6 and the clash pack rules.
- **(a+)**, not asked, for reference: a with 0.7/0.6.
- **(c)** no rule change; the limits the test would need.

### Gap (clash minus plain), seeds 7/11/23 pooled

| Option | Ch1 | Ch2 | Ch3 | Ch4 | Ch5 | Ch6 | Ch7 | Ch8 | Mean 2-8 | Worst 2-8 |
|---|---|---|---|---|---|---|---|---|---|---|
| main (v1.531) | 0.032 | 0.230 | 0.139 | 0.112 | 0.136 | 0.178 | 0.138 | 0.124 | 0.151 | 0.230 |
| base (pack rules, 0.8/0.7) | 0.006 | 0.033 | 0.036 | 0.046 | 0.056 | 0.099 | 0.031 | 0.024 | 0.046 | 0.099 |
| **a** base + lone foes not executed | -0.009 | 0.057 | 0.025 | 0.027 | 0.025 | 0.066 | 0.028 | 0.000 | 0.033 | 0.066 |
| **b** 0.7/0.6, no pack rules | 0.017 | 0.168 | 0.109 | 0.116 | 0.117 | 0.182 | 0.097 | 0.124 | 0.130 | 0.182 |
| **b+** 0.7/0.6 + pack rules | 0.010 | 0.047 | -0.003 | 0.035 | 0.029 | 0.122 | 0.009 | 0.031 | 0.039 | 0.122 |
| a+ (a with 0.7/0.6) | 0.030 | 0.058 | 0.002 | 0.034 | 0.016 | 0.096 | 0.040 | 0.017 | 0.037 | 0.096 |

### What the player sees (`boss_balance`, clash rules, 400 runs a seed)

Encounters won within 3 tries, mean of the three seeds:

| Option | Ch1 | Ch2 | Ch3 | Ch4 | Ch5 | Ch6 | Ch7 | Ch8 |
|---|---|---|---|---|---|---|---|---|
| main | 94.0 | 87.2 | 67.0 | 57.4 | 66.2 | 58.1 | 57.4 | 51.8 |
| base | 92.6 | 79.8 | 57.7 | 49.0 | 59.5 | 50.4 | 46.4 | 39.1 |
| **a** | 92.5 | 78.9 | 57.6 | 48.8 | 58.5 | 46.0 | 43.8 | 36.4 |
| **b** | 94.5 | 88.9 | 70.6 | 62.3 | 70.5 | 63.0 | 63.2 | 62.3 |
| **b+** | 93.3 | 84.4 | 60.0 | 53.3 | 62.0 | 55.6 | 52.2 | 48.8 |
| a+ | 93.2 | 84.5 | 60.3 | 51.7 | 60.3 | 51.4 | 50.8 | 47.8 |

Plain rules, same runs: base pack stats (a, c) 91.9 / 70.2 / 52.5 / 45.4 /
54.6 / 38.8 / 43.6 / 40.2; 0.7/0.6 (b, b+) 93.0 / 80.1 / 57.4 / 49.0 /
57.9 / 43.1 / 52.8 / 49.9.

Professions (cleric / warrior / mage / ranger / rogue; floor 60, spread 8),
lowest per seed 7 / 11 / 23; champions won (floor 0.38) at 7 / 11 / 23;
boss mean (42-58):

| Option | Professions, lowest (7 / 11 / 23) | Floor | Champions % | Boss mean |
|---|---|---|---|---|
| main | 63.8 / 64.7 / 63.2 | pass | 39.9 / 42.3 / 46.7 | 51.4 / 51.6 / 50.2 |
| base | 56.8 / 56.6 / 56.6 (ranger, rogue, warrior under 60 at every seed) | fail by 3.4 | 39.8 / 43.3 / 37.7 | 50.9 / 50.6 / 48.4 |
| **a** | 54.7 / 56.0 / 56.8; seed 7 spread 10.3 (warrior 54.7, cleric 65.0) | fail by 5.3, and the spread | 44.0 / 41.3 / 42.3 | 50.3 / 50.1 / 46.6 |
| **b** | 69.7 / 70.2 / 68.6 | pass | 42.0 / 44.1 / 44.5 | 53.0 / 50.4 / 51.5 (tear_herald 48.5 at seed 11, 1.5 over its band) |
| **b+** | 61.6 / 61.7 / 61.7 | pass | 40.6 / 40.0 / 37.9 | 49.6 / 50.2 / 50.1 |
| a+ | 60.7 / 58.1 / 58.9 | fail by 1.9 | not run | 51.2 / 50.9 / 47.9 |

Champions at seed 23 sit under 0.38 for base (37.7) and b+ (37.9); the
test runs seed 7 only, where every option passes.

### Reading it

- **a** passes the gap with room (worst 0.066, mean 0.033) but costs the
  player most: chapter 6 to 8 lose 3-4 more points than the base, and the
  floor fails by 5.3 (warrior 54.7) with a 10.3 spread at seed 7. It
  can't meet the floor: `boss_balance` measures clash-rule play, and every
  clash-only lever that closes the gap makes clash play harder, so it
  moves the professions down, never up. The floor already failed on the
  base because the pack rules cost chapters 3-5 8-10 points.
- **b** fails the gap (mean 0.130, chapter 2 0.168, chapter 6 0.182): the
  cut makes pack fights easier on both sides (plain chapter 2 +9.9,
  clash +1.7 vs main), so it moves the gap only from 0.151 to 0.130.
  The player gains 2-11 points a chapter on main.
- **b+** passes the floor (61.6 lowest) and the mean (0.039) but chapter
  6 is 0.122, over 0.10: chapter 6's gap is mostly lone foes, which
  neither the cut nor the pack rules touch.
- **Confirmed: the cut makes pack fights easier in both rule sets, and
  chapters 3-5's drop comes from the clash pack rules.** Chapters 3/4/5,
  clash: main 67.0 / 57.4 / 66.2, cut alone (b) 70.6 / 62.3 / 70.5 (+3.6
  / +4.9 / +4.3), pack rules alone (base) 57.7 / 49.0 / 59.5 (-9.3 / -8.4
  / -6.7), both (b+) 60.0 / 53.3 / 62.0. Plain: 52.5 / 45.4 / 54.6 at
  0.8/0.7, 57.4 / 49.0 / 57.9 at 0.7/0.6.
- **c**: with the pack rules (base) the current limits pass, at 0.099 for
  chapter 6 (limit 0.10) and a mean of 0.046 (0.08); a chapter moves 0.02
  to 0.05 with any change to the seeded stream, so a safe limit is about
  0.12 a chapter. Without the pack rules (main) the test needs 0.24 a
  chapter (chapter 2 is 0.230) and 0.16 for the mean (0.151).
- Seed noise: the lone-foe lever with 0.7/0.6 (a+) put chapter 6 at
  0.096, where on 0.8/0.7 it gave 0.066. Chapter 6 is the chapter to
  watch whatever is chosen.

### Side by side

| | a | b | b+ | c (base / main) |
|---|---|---|---|---|
| Rules | pack rules + lone foes not executed (clash), 0.8/0.7 | 0.7/0.6 both, no pack rules | 0.7/0.6 both + pack rules | none |
| Worst gap ch2-8 | 0.066 (ch6) | 0.182 (ch6) | 0.122 (ch6) | 0.099 / 0.230 |
| Mean gap 2-8 | 0.033 | 0.130 | 0.039 | 0.046 / 0.151 |
| Real-walk test (0.10, 0.08) | pass | fail | fail (ch6) | pass by 0.001 / fail |
| Professions floor 60 | fail (54.7) | pass (68.6) | pass (61.6) | fail (56.6) / pass (63.2) |
| Champions, seeds 7/11/23 | 44.0 / 41.3 / 42.3 | 42.0 / 44.1 / 44.5 | 40.6 / 40.0 / 37.9 | 39.8 / 43.3 / 37.7 ; 39.9 / 42.3 / 46.7 |
| Boss mean | 46.6-50.3 | 50.4-53.0 | 49.6-50.2 | 48.4-50.9 / 50.2-51.6 |
| Ch 3-5 vs main (clash) | -9.4 / -8.6 / -7.7 | +3.6 / +4.9 / +4.3 | -7.0 / -4.1 / -4.2 | -9.3 / -8.4 / -6.7 ; 0 |
| Limit needed for the test | none | 0.19 a chapter | 0.13 a chapter | none (0.12 for margin) / 0.24 and mean 0.16 |
