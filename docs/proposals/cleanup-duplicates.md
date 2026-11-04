# Copy-paste inside one file: what was merged, what stays (Cleanup session)

Released by the user ("fix copy-pasted blocks within a single file"). Re-measured on main `055a7529` (v1.760) with `tool/qa_duplicates.py --dir lib`: 80 blocks of 15 or more repeated lines, 41 of them inside one file. Rule: a block that is **textually identical** and needs only a shared private helper is merged by Cleanup; a block that is only similar (the numbers or the words differ) goes to its owner.

## Merged (this PR, no behaviour change)

| File | Blocks | Helper |
|---|---|---|
| `lib/screens/story_player_screen.dart` | the `_StoryText(...)` card built twice (centred layout and plain layout), 31 lines each | one local `storyText`, used by both |
| `lib/screens/playthrough_simulator/sim_batch_card.dart` | the "by location" and "by mood" `ExpansionTile`s, 22 lines each | `_distributionTile(context, titleKey, groups)` |
| `lib/data/sim_combat.dart` | the spellbook-buying loop and the shop-stock list, in both `visitShop` and `_visitShopCompetent` | `_buySpellbooks(stock, spells, purse)` and `_shopItems(shop, items)` |
| `lib/data/autoplay_engine.dart` | the 27 lines after a step's fights (land crossed, effects, unlocks, politics, hazard, next node) in `autoplayToNode` and `_playTowardChapter` | `_finishAutoplayStep(ref, story, choice, fromNodeId, firstEnemyId, random)` |

## Stays, and why

| Where | Lines | Why not merged here |
|---|---|---|
| `lib/data/origin_stories.dart` (about 25 pairs and triples of 18 to 33 lines) | | Data: the same `OriginAnswer(...)` shape with different words (`diff` shows every text line differing). A table is not copy-paste. |
| `lib/gamedata/db_schema.dart` (about 12 blocks of 18 to 21 lines) | | Data: field lists of editor tables with the same columns. Same reason. |
| `lib/providers/player_session_provider.dart:981` and `:5737` | 18 | The parameter list of `copyWith` and of `debugSetStats` is identical, and Dart has no way to share a parameter list. |
| `lib/data/expedition_kinds.dart:322` / `:341`, `lib/data/world_map.dart:332` / `:597`, `lib/data/alignment_events.dart:430` / `:448` | 20 to 30 | Similar, not identical: 11, 12 and 15 of the lines differ. A shared helper needs a design choice (what the parameters are): Core's call. |
