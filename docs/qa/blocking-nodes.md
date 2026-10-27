# Blocking nodes and detours in the story graph

Read from the graph, not played: `assets/Cleaned_Narrative_DAG.json` (472 nodes, 1,141 choices) with the quests, zones, coast events and companions around it, at v1.564.0 (2026-10-27). Nothing was run in the simulator. The analysis is [`blocking_nodes.py`](blocking_nodes.py) (about 40 s, no dependencies); the fast part of it is a guard, `test/qa_story_blocking_test.dart` (about 1 s, five tests, passes today).

## Result

**Nothing blocks the player.** By the severities of the brief:

| Severity | Findings |
|---|---|
| stuck forever | **0** |
| stuck until something (a requirement nothing can supply, a gate whose opener comes later, a flag only set on a path not taken) | **0** |
| longer path (a failed test or fight that sends the player the long way round) | **1** by design (`400`, the Black Hold), **1** quest that can only be handed in after the chapter's finale (`q_ch3_inquisition_ledger`) |
| dead ends, unreachable nodes, broken references | **0** |
| combat or reward referencing something missing | **0** |

One more class is listed for the owners, not a block: **38 forced fights have no defeat branch** (80 choices, tables below). A lost fight there is retried, with no cost (`StoryChoice.loseNextId` doc: "Null keeps today's behavior, the fight can be retried"), so the player is stuck only if the fight cannot be won at the level they have; the simulator's L3 on v1.501 reached the ending in 900 runs of 900 and the eleven bosses are banded in `boss_balance_test`. Two forced fights that look like bosses have no band: `inquisition_high_warden` (the chapter 3 finale) and `void_manifestation` (`6003b`).

No GitHub issue was opened: there is no "stuck" finding.

## What is modelled

- A choice is **open** when all its `showIfFlags` are set and none of its `hideIfFlags` is, and its target's `reqFlags` are set. `reqGold`, `reqAlignment*` and the `pays` choices are checked apart (rule 6).
- A **fight** won goes to `next_id`; lost, to `loseNextId`, else the fight is retried. A **check** passed goes to `next_id`; failed, to `failNextId`, else on to `next_id` without the choice's effects. Flags are added only by the choice taken (so nothing from a lost fight or a failed check).
- A place's hub always offers the way back to the camp (`canReturnToCampFrom`, once the camp stands, from chapter 3), a camp offers its errands and the places of its chapters. So a place with every hub item done is not a trap.
- Flags that only the game sets (an expedition cleared, `ally_*`, `devoted_*`, `host_*`, `found_*`, the coast's events, the quests' `flagToAdd`) are taken as obtainable wherever they are waited for; each does have a setter in the data.

## What was checked

| # | Rule | Result |
|---|---|---|
| 1 | Every node can be entered: a may-set / must-set dataflow over the flag gates (so a gate whose opener comes later, or a flag set only on a path not taken, shows as an unreachable node) | 472 of 472 |
| 2 | Every flag a choice or a node waits for is set by something | 0 missing (some flags only a game system sets: the companions' `ally_*` and `devoted_*`, the Host's `host_*`, four expedition clears, `hull_patched`, `sail_mended`, `throne_filled`) |
| 3 | A node where every choice can be closed at once, checked exactly over the flags that gate it | 25 candidates; 17 cannot be closed at all (exact search over the flags that gate them); 7 can, and are place hubs or camps (the way back to the camp, the errands); 1 (`6010_gate`) is an arrival scene, a first visit only (`Settlement.arrivalNodeId`), so its closed state cannot happen |
| 4 | Every defeat and failure branch meets the way the win or success takes (a detour) | 87 branches: all meet it; 86 within 3 nodes, 1 four longer (`400`); no skill challenge without a failure branch (12 of 12 have one) |
| 5 | A fight with no defeat branch and no non-fight choice at its node (retry only) | 38 nodes, in the tables |
| 6 | A choice that costs gold has a free way beside it; a node that waits for gold (`261`, `3040`, `3005_grosh`, `2015_sable_bought`, `2040_paid`, `6010_chart_bought`, `3200_blade`) or for an alignment (`1002`, `2015_kelda`, `2015_sable`, `5010_tobin`, `6010_malrik`, `7002_pact`, `7005_dawn`, `7005_crown`) has a free way round at each way into it | 27 `pays` choices, all with a free way; 15 gated nodes, all with one. The endings `7005_dawn` (alignment 15 or more) and `7005_crown` (-15 or less) have `7005` and `7005_seeker` for the rest |
| 7 | The quests: every objective's enemy, item and flag exists and can be had; each open chapter has more quests than its `questGoal` (chapters 3 to 6: 9, 4 besides the six nemesis quests, 5, 3 against 2, 1, 1, 1) | 0 broken; `q_ch3_inquisition_ledger` as in the table of chapter 3 |
| 8 | Every node can reach an ending | 472 of 472 |
| 9 | A choice that waits for the coast (`politicsIf`) | 28 nodes have one; at 26 there is a free way too; at `7500` and `7515_rest` every way waits and one always holds (the claim `none` has the grey hand; the throne event, fired by every `7510_*` choice, sets a leader) |

## Findings per chapter

Severity "retry only" means: a forced fight whose loss retries it; stuck only if it cannot be won. Owners as in CLAUDE.md: Core for fights and rules, Narrative for the story and text (a defeat branch is a graph edit, so Narrative's, asked for by Core).

### Prologue

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| | | nothing found | | | |

### Chapter 1

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `822_lie_failed` | inquisition_warden | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `850_fed_failed` | rat_matriarch | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `855` | rat_matriarch | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `400` | Charge him (a fight) | Defeat goes to `400_lost` then `800` (the Black Hold) and rejoins at `470`, 4 nodes longer than the win | rule 4 | longer path (by design) | Narrative |

### Chapter 2

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `2010_liora` | smuggler_captain | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2011_roof_fall` | harbor_rat | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_dockside` | harbor_rat | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_informant_caught` | street_bandit | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_informant_trap` | inquisition_warden, street_bandit | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_kelda` | inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_scaffold_clerk_fight` | inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015_ternrow_fight` | dock_overseer | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `2015` | Force the loading crane's winch (Strength 13) | A failed check goes to `2011` (the shove past Vane), which meets `2010_crane` at `2900`: same road, no loss | rule 4 | none | n/a |

### Chapter 3 (the Spire)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `3005_clan_vigil_1_breach` | void_stalker | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: void_stalker | rule 5 | retry only | Core (numbers) |
| `3005_glass_fire_fight` | cultist_acolyte | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `3005_grosh` | hollow_court_zealot | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `3005_oath` | cultist_acolyte | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `3005_relic` | void_wisp | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `3005_wall_fight` | inquisition_auxiliary | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `3030` | inquisition_high_warden | Forced fight, no defeat branch (a loss retries it); the chapter's finale, three ways to it; no boss band for this enemy | rule 5 | retry only | Core (numbers) |
| `3040` | inquisition_high_warden | Forced fight, no defeat branch (a loss retries it); the chapter's finale, three ways to it; no boss band for this enemy | rule 5 | retry only | Core (numbers) |
| `3050` | inquisition_high_warden | Forced fight, no defeat branch (a loss retries it); the chapter's finale, three ways to it; no boss band for this enemy | rule 5 | retry only | Core (numbers) |
| `q_ch3_inquisition_ledger` | Fetch the sealed letter (a quest, not a node) | The letter drops only from the High Warden of `3030`/`3040`/`3050`, the chapter's finale (100%), so the quest can be handed in only after it; the chapter's quest goal (2 of 9) is met by the others | rule 7 | longer path (one quest) | Narrative / Core |

### Chapter 4 (the Drowned Stair)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `5006_cornered` | bone_sexton, cultist_acolyte | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `5010_bark_cache_fight` | street_bandit | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `5010_tobin` | catacomb_ghoul | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |

### Chapter 5 (the Reliquary)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `6002_siege_breach` | void_hound | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `6003b` | void_manifestation | Forced fight, no defeat branch (a loss retries it); no boss band for this enemy | rule 5 | retry only | Core (numbers) |
| `6010_candle_walk_fight` | tear_spawn | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `6010_clan_compact_3_seen` | inquisition_penitent, inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `6010_malrik` | void_hound | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `6100_clan_penitents_2_heard` | inquisition_penitent, inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `6100_clan_vigil_2` | void_hound, void_stalker | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: void_stalker | rule 5 | retry only | Core (numbers) |
| `6200_quarry_face_fight` | rime_bailiff | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |

### Chapter 6 (the White Fleet)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `7100_impound_fight` | inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |

### Chapter 7 (Candlehold)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `7510_seen` | inquisition_auxiliary, inquisition_soldier | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `7520_morrow` | claimant_morrow | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: claimant_morrow | rule 5 | retry only | Core (numbers) |
| `7520_tallis` | claimant_tallis | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: claimant_tallis | rule 5 | retry only | Core (numbers) |
| `7520_vane` | claimant_vane | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: claimant_vane | rule 5 | retry only | Core (numbers) |
| `7500`, `7515_rest` | The gate and the dawn (every way waits for the coast) | Every way on waits for the claim, a standing or a leader flag; the claim `none` always has the grey hand, and the throne event sets a leader on every route to `7515_rest` | rule 3 | none | n/a |

### Chapter 8 (the finale)

| Node | The fight or test | What blocks or detours | How found | Severity | Owner |
|---|---|---|---|---|---|
| `7002_alarm` | hollow_reflection, unmade_knight | Forced fight, no defeat branch (a loss retries it) | rule 5 | retry only | Core (numbers) |
| `7810` | hollow_reflection, tear_herald | Forced fight, no defeat branch (a loss retries it); boss band in boss_balance: tear_herald; on the story spine: the last fight | rule 5 | retry only | Core (numbers) |


## Limits (what this does not say)

- **Fight winnability** is not read from the graph: whether `inquisition_high_warden` at the end of chapter 3, `void_manifestation`, or the chapter 7 claimants can be won at the level a player has by then is the simulator's and `boss_balance_test`'s to say (the claimants and the last bosses are banded; the High Warden and the Void Manifestation are not).
- **The chapter loop is not in the graph.** From chapter 3 the open chapters advance by the engine (`chapter_loop.dart`: `activityGoal`, `questGoal`, `mainQuestNeedsPlaceIds`), not by node edges, so "a path bypasses a main-story node" is only meaningful for the straight road (the prologue, chapters 1 and 2, the finale); the graph model joins every camp to every place of a lower chapter, which makes the camp-to-camp main quests look skippable. The supply side is checked (rule 7: places, quests per chapter), not the engine.
- **Alignment and gold are optimistic** (a gate on either is taken as passable); rule 6 checks that a way round exists at each one instead.
- **First-visit scenes** (`arrivalNodeId`) are entered each time in the model.
- Detours by the generated road events (`detours.json`, `detour_scenes.json`) are not graph nodes and were not read.

## Re-running

`python3 docs/qa/blocking_nodes.py > blocking.json` prints every list above; `flutter test test/qa_story_blocking_test.dart` runs the five fast checks (flags set, nodes enterable, branches meeting, a cost with a free way, an ending reachable). A mutation check was made on the guard: a typo in a gate flag fails the first two tests.
