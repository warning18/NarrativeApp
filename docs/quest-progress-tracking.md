# Quest progress tracking — how it works

Shipped. This file used to be the scope for the feature (written when
completion gated on nothing and the quests' `objectives` were display-only).
It now describes what the game does, so that a new quest can be written
against it. The code is `lib/data/quest_objectives.dart` (the rules) and
`lib/data/quest_tracking.dart` (what a play-mode list shows); the tests are
`test/quest_objectives_test.dart` and `test/quest_tracking_test.dart`.

## What a quest looks like

Every quest in `assets/gamedata/quests.json` carries an `objectives`
array (the schema is `questsSchema` in `lib/gamedata/db_schema.dart`).
There are 39 quests and 41 objectives: one quest has three
(`q_ch2_leave_saltmouth`), the rest one. Each objective has a `type`:

| Type | Count | Met when |
|---|---:|---|
| `Kill` | 24 | the party has beaten `requiredAmount` of the foe in `targetEnemyID` (or of any foe in `targetEnemyIDs`; two objectives use the list). With `countFromAccept: true` (16 objectives, the bounties) only kills made since the quest was taken count; otherwise the lifetime count does. |
| `Flag` | 13 | a story choice has set `targetFlag`. For beats the story grants directly (taking the heirloom at the hovel) rather than through an item, a kill or a person. |
| `Fetch` | 2 | `targetItemID` is in the party's inventory. The turn-in does not remove it. |
| `Talk` | 2 | the party has spoken to the person named by `targetNPCID` (`talkedToNpcIds`). A Talk objective without a `targetNPCID` is treated as flavour text and is always met. |

An objective with no target data (an empty enemy, item or flag) is always
met; it is flavour text, not an obligation. Any other `type` is ungated
until it is given its own rule.

The Quests tab shows each objective as its own checklist line with its
progress ("2/3") and keeps the Complete button disabled until every one
is met. A quest written with several objectives is, in effect, split
into sub-quests; no separate "quest group" exists.

## Older saves

A save made before tracking was added has its already-active quests in
`PlayerSession.grandfatheredQuestIds`: their objectives count as met, so
no older save is stranded. A quest picked up afterwards is checked
normally.

## How a quest starts and ends

- A story choice with `unlockQuestId` offers the quest; one with
  `questIDToProgress` starts it (only `q_first_blood`, from node `260`, does
  this). A quest's `nextQuestID` chains the next one in.
- The quest's own `questChoices` accept it (`flagToAdd` records that);
  `turnInChoices`, where a quest has them (12 do), are the ways to hand it
  in, each with its own reward, alignment change, result text and `flag`
  (the flag is what later scenes and NPC `states` read).
- Rewards (`rewardGold`, `rewardXP`, `rewardItemID`, `alignmentChange`,
  `rewardAllyId`, `grantsBannerPieceId`) are Core's numbers; the words
  are Narrative's.

## Writing a new quest

1. Pick the objective type that matches what the story does: a fight
   (`Kill`), a thing carried (`Fetch`), a conversation (`Talk`, and give
   it `targetNPCID`) or a scene (`Flag`, and make a choice in that scene add
   the flag).
2. Make sure the thing can actually happen: the enemy is in a pack or a
   zone the party will meet, the item drops or is handed over, the flag is
   set by a choice that can be reached.
3. Give every player-facing text its `_fr` twin (`questName_fr`,
   `npcDialogueText_fr`, each objective's `description_fr`, each choice's
   `buttonText_fr` / `choiceText_fr` / `resultText_fr`).
4. Offer it from a scene (`unlockQuestId`) and give the quest an `id`
   in the shape `q_ch<chapter>_<name>`. Its `chapter` decides which chapter
   counts it toward the camp's quest goal (see `chapter-flow-roadmap.md`).

## Open

- `requiredAmount` above 1 is supported but only the bounties use it.
- Gather and Reach objectives are not built; no quest needs them.
- `Fetch` does not consume the item, so one item can satisfy two quests.
  No two current quests share an item.
- A quest's `chapter` is what the camp's quest goal counts
  (`chapterQuestCount`) and what the detour pool draws from
  (`filterQuestPool`); a quest id keeps its original chapter prefix once it
  is in saves, so `q_ch6_beyond_the_tear` is a chapter 8 quest
  (`"chapter": 8`) with a chapter 6 id. Each chapter has exactly one start
  and one end among its Main quests (`test/quest_validation_test.dart`).
- The playthrough simulator plays quests the same way the game does; see
  `docs/simulation/report-quests.md`.
