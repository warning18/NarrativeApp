# Quest progress tracking — feature scope

Not implemented. Written up per a request to scope this as follow-up work,
after a 40-playthrough simulation found that quest completion currently
gates on nothing: the "Complete" button in the Quests tab is enabled the
moment a quest becomes active, regardless of whether its described
objective (a kill, a fetch, a conversation) has actually happened. This
inflates the in-game economy — ~30% of simulated end-game gold was quest
rewards — but may be an intentional lightweight design. This doc exists so
that question can be answered with a concrete plan in hand, not a guess.

## What already exists

The data foundation is already there and doesn't need to change. Every
quest in `quests.json` already carries a structured `objectives` array
(`db_schema.dart`'s `questsSchema`, field `objectives`):

```json
"q_first_blood": {
  "objectives": [
    {"description": "Defeat the slum thug", "type": "Kill",
     "targetEnemyID": "slum_thug", "targetItemID": "", "targetNPCName": "",
     "locationID": "", "requiredAmount": 1}
  ]
}
```

All 15 current quests have exactly one objective each, of three real types
in practice (the schema's label comment also lists `Gather`/`Reach`, but
nothing currently uses them):

| Type  | Count | Shape |
|-------|------:|-------|
| Kill  | 9     | `targetEnemyID` + `requiredAmount` (always 1 today) |
| Fetch | 4     | `targetItemID` + `requiredAmount` (always 1 today) |
| Talk  | 2     | no target fields set at all — currently unenforceable even in principle without a new signal (see below) |

None of this is read anywhere in gameplay code today — `objectives` is
display-only, surfaced in the Quests tab as flavor text.

## Proposed tracking model

Add one new field to `PlayerSession`: `Map<String, int> questKillCounts`
(questId → kills logged toward its objective since being made active),
persisted and serialized the same way every other session map field is.
Fetch and Talk objectives don't need their own counters — they're
satisfied by state that already exists or by a new one-shot signal (below).

### Enforcement per type

- **Kill** — `applyCombatResult`'s win path (and the equivalent in
  `autoplay_engine.dart`'s `_simulateFight`) already knows the enemy that
  was just beaten. On a win, for every quest in `activeQuestIds` whose
  objective's `targetEnemyID` matches, increment
  `questKillCounts[questId]`. Objective met when the count reaches
  `requiredAmount`.
- **Fetch** — no counter needed: met whenever
  `inventoryItemIds.contains(targetItemID)` is true while the quest is
  active. Simpler than Kill, but raises a design question worth deciding
  up front: does turning the quest in *consume* the item (it's currently
  never removed), and can the same fetched item satisfy two different
  fetch quests at once if both target it? Neither has a wrong answer, but
  today's "keep everything, always" model means picking one changes
  player-facing behavior.
- **Talk** — the two current Talk objectives (`q_ch3_alsters_dawn`,
  `q_ch3_marens_penance`) have no target fields at all, so there's
  currently no data signal that distinguishes "talked to them" from
  "haven't." This type needs either: (a) a new `flagsToAdd`-driven
  convention — the specific story choice that represents the conversation
  sets a flag named after the quest (e.g. `talked_$questId`), checked the
  same way Kill/Fetch are; or (b) repurposing `questIDToProgress` itself
  as the "talked" signal for Talk-type quests specifically, since it's
  already the mechanism that puts a quest into `activeQuestIds` from a
  story choice — meaning a Talk quest would need a *second*,
  later-in-the-conversation choice to actually fire completion-readiness,
  not the same one that started it. (a) is more general and works for
  quests picked up outside the main story (an excursion), so it's the
  better default; (b) is less data-entry work if Talk quests stay rare and
  always story-node-triggered.

### Where this plugs in

- `PlayerSessionNotifier`: a new `_logKill(String enemyId)` called from
  `applyCombatResult`'s and `_simulateFight`'s win paths; a computed
  `bool isQuestObjectiveMet(String questId, Map questRecord)` helper the
  UI and the Complete button both call.
- `play_screen.dart`'s Quests tab: swap the unconditional `ElevatedButton`
  for one disabled until `isQuestObjectiveMet`, and show live progress
  next to the objective description ("Slum Thugs defeated: 0/1").
- `autoplay_engine.dart`: already resolves real fights and already knows
  the enemy, so wiring in `_logKill` there is a small addition — autoplay
  should earn quest completions the same honest way live play would,
  consistent with its own stated design goal.

## Migration concern

Flipping this on isn't purely additive: existing quests already sitting in
a player's `activeQuestIds` (from a save made before this feature ships)
would suddenly become uncompletable if their objective was never logged
retroactively. Simplest safe handling: on first load after the update, for
every already-active quest, treat its objective as pre-satisfied (log
`requiredAmount` kills, or don't gate Fetch/Talk at all) so no existing
save gets stuck — only quests picked up *after* the update are enforced
from a clean state.

## Suggested phasing

1. Kill-objective enforcement only (9 of 15 quests, the most common and
   simplest case — a pure counter with no new data-entry or design
   decision needed).
2. Fetch-objective enforcement, once the consume-on-turn-in question above
   is settled.
3. Talk-objective enforcement, once convention (a) or (b) above is picked
   and the two existing Talk quests are updated to match.

Each phase is independently shippable and testable via the existing
Python playthrough simulator (extend it to only "complete" a quest once
its objective is actually met under the same rules, and confirm completion
rates/timing don't regress).

## Explicitly out of scope here

- `requiredAmount > 1` multi-kill objectives — no current quest needs it,
  though the counter model above already supports it for free.
- Gather/Reach objective types — unused by any current quest; would need
  their own design pass if content using them is ever authored.
- Retroactively adding objectives to quests that don't need this (e.g.
  ones with no real combat/fetch beat) — not every quest needs to be
  objective-gated just because the system now supports it.
