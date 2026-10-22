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

The rewritten test is kept as a patch (not committed) until the user picks.
