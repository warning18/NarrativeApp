# The simulator reaches the shops a player reaches (v1.766)

The user asked for this after the starter-die investigation
(`starter-die.md` §3, §6.2). The simulated player only ever met the shops a
scene unlocks, and each of them once. A real player also shops at the ports,
at the houses they build and at the caravan on the road.

## What changed in the walk

- **Port shops:** at a settlement with a port, its shops (`ports.json`
  `shopIds`) are visited.
- **House shops:** a house that opens a shop (`houses.json`
  `unlocksShopId`) is visited once built.
- **The Wayfarer's Caravan:** when the road holds it (`road_events.dart`),
  its stall is visited.
- **Visiting again:** a shop can be visited again, at most once a chapter.
  That happens when the walk comes back to its port in a later chapter.
- **Chapter gate:** a shop reached any of these ways waits for its
  `minChapter`. A scene's own shop opens when the scene unlocks it, as
  before.

**Not shipped: the camp revisit.** The walk could also go back to every
shop it knows from the camp. That version is kept on the branch
`claude/core-sim-revisit`. It made the late bosses much harder, so it waits
for the late-boss question.

## The one game change: void_stalker

With the reach, the chapter-3 boss became too easy (88.3% in the boss
test, target 65 ± 12). Its health goes from 44 to 54 and its damage from 4
to 5, which brings it back to 62.5%.

## The new naive baseline

QA's method: 800 naive runs (seeds 11 and 23, four goals, 400 runs each).
Main is v1.762; the second column is this change with the void_stalker
fix.

| | Main | With the reach |
|---|---|---|
| Encounters won | 71.0% | 75.3% |
| Ordinary (non-boss) fights won | 74.4% | 79.3% |
| Won at the first attempt | 40.0% | 44.4% |
| Level at the end | 21.6 | 22.1 |
| Gold at the end | 4,976 | 4,110 |
| Runs that reach an ending | 800 / 800 | 800 / 800 |

Encounters won by chapter:

| Ch1 | Ch2 | Ch3 | Ch4 | Ch5 | Ch6 | Ch7 | Ch8 |
|---|---|---|---|---|---|---|---|
| 94 → 94 | 93 → 98 | 71 → 83 | 62 → 72 | 70 → 72 | 64 → 62 | 55 → 51 | 52 → 50 |

By profession: cleric 69.7 → 72.0, mage 74.3 → 80.2, ranger 72.2 → 72.8,
rogue 70.7 → 76.3, warrior 68.2 → 74.9. The spread grows from 6.1 to 8.2
points.

The bosses, in the boss test (the test's own runs, `boss_balance_test`):

| Boss (chapter) | Target | Main | With the reach |
|---|---|---|---|
| aurel_vane (1) | 75 | 75.9 | 75.9 |
| void_stalker (3) | 65 | 60.3 | 62.5 (was 88.3 before the fix) |
| hollow_court_inquisitor (4) | 55 | 59.2 | 63.3 |
| bone_warden (4) | 55 | 57.4 | 65.8 |
| void_archon (5) | 50 | 50.7 | 43.8 |
| white_admiral (6) | 45 | 56.3 | 40.3 |
| claimant_vane (7) | 40 | 44.0 | 36.4 |
| claimant_tallis (7) | 40 | 40.8 | 33.9 |
| claimant_morrow (7) | 40 | 44.8 | 33.3 |
| tear_herald (8) | 35 | 35.3 | 29.0 |
| void_sovereign (8) | 35 | 34.2 | 28.0 |

Every boss is inside its band (±12 points, or wider for the claimants
held together).

## The guards

All pass:
- the boss curve (`boss_balance`);
- the class spread;
- the competent player (`sim_competent`);
- the naive walk (`sim_playthroughs`, `sim_coverage`);
- the houses, quests, companions and tamper tests;
- `clash_balance`, `fight_length`, `foe_kind`, `patron_stats`,
  `profession_cores`, `claimant_rules`;
- QA's `qa_sim_tables`.

## What it means

The early and middle game reads easier than the old simulator said: chapter
3 is 83% won instead of 71%, because a player who shops is better armed.
The late game reads slightly harder (chapters 6–8 lose 1–4 points), because
the extra shopping leaves less gold. That late-game slope is the question
the manager holds for later.
