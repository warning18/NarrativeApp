# Chapter 1 review (QA, v1.606.0, 2026-10-28)

L3 for chapter 1 only, as the user asked: the intro and the race screen, Alster (scenes 100 to 960, the Black Hold, the quay, Weaver's Alley), the Lark, the Waste, `1150_vica`, the White Wells (`1200`, `1210`) and the origin endings `1000` to `1002`: 49 graph nodes. Nothing was run in the simulator: the graph was read by [`chapter1_audit.py`](chapter1_audit.py) (a second, quick script, no dependencies), the screens were pictured at 412, 360 and 320 px in English and French, and the existing chapter 1 tests were run.

The other sessions' notes: Narrative's `docs/qa/chapter1-narrative.md` is merged into the list below (its numbers in brackets, "N1"...). The Core and UX notes were not on any branch when this was written; their findings go into the list when they land.

## The short version

- **Nothing blocks the player** and nothing is unreachable. 0 broken references (nodes, enemies, items, quests, routes, banner pieces), 0 flags set and never read, 0 flags read and never set, FR present on every scene, choice, callback and persona variant.
- **Two things a player meets** are wrong today: the guide on the first Alster page is called Vica a scene before the story names her, and the race screen shows the starting skills' names in English in French mode.
- Eight more are small: a missing callback, a codex line, a payment the purse cannot refuse, pacing and wording.
- Chapter 1's boss is on target: Aurel Vane 83% (target 75%) at the last L3 (v1.501, 800 runs), banded in `boss_balance_test`.

## Findings, worst first

"Fix" is who owns it (CLAUDE.md). Severity: **P** the player sees a contradiction or a wrong text; **W** wording or pacing; **K** cleanup.

| # | Where | Sev | What the player sees | Fix |
|---|---|---|---|---|
| 1 | The tutorial guide (`tut_story_1`, `tut_guide_default_name`) against `1150_vica` (N6) | P | On the first Alster page a small dog guide says "Woof! I'm Vica." The story names her Vica for the first time at `1150_vica`, in the dunes, as if for the first time ("I called her **Vica**..."). A player who renamed the guide meets a different name later. | decision for the user, then **Narrative** (the wording) and **Core** (`lib/tutorial/`) |
| 2 | Race and profession screen, French (new finding, #582) | P | "Resolve" and "Shield Bash" under Humain and Guerrier: the granted skill's name is built from its id (`grantedSkillName` in `lib/data/character_start.dart`: "human_resolve" becomes "Resolve") and never read from `skills.json`, which has `name_fr` ("Détermination", "Coup de bouclier") for all 162 skills. English players see the same words, so only French shows it. | **UX** (the screen), **Core** (the helper) |
| 3 | `1150_vica` (N4) | C | Lysa walks with the hero through 1100 to 1130 and is at the Wells in `1200`, but `1150_vica` has no `lysa_survived` line: she is gone for one scene. | **Narrative** |
| 4 | Codex, `biomes.json`, temperate fauna "Warhound / Chien de guerre" (N9) | C | "Bred by Inquisition dog-handlers; since the burning, a few run loose in the alleys." The dog is Vica's alone in chapter 1; this says they run loose in the alleys. Text only. | **Narrative** (wording of Core's file) |
| 5 | `896_failed` (-40) and `897_failed` (-25) (#583) | W | "The price was a good part of what I had left" and "Pay the bribe and board": the choice has no `pays` flag and the next scene no `reqGold`, so a player with 10 gold pays 10 (the purse stops at 0, `player_session_provider.dart`) and boards. The price in the text is not enforced. Not a block: a forced page after a failed check; it only makes a poor player's failure free. | **Core** (mark it `pays`, or leave it as a soft price) |
| 6 | `260` / `261` (N8) | W | "Pay the toll (30 gold)" has no `goldMod`; the 30 is taken on the next card, "Cross the bridge". **By design, not a bug**: the gate is `reqGold: 30` on `261` and the locked line "Thirty gold. I did not have it." covers the poor player. The label and the wallet move one card apart; Narrative may prefer to put it on one card. | **Narrative**, optional |
| 7 | `0` → `100_dice`; `896_failed`, `897_failed`, `898_failed` → `960_lift` (N1, N2, N7) | W | Two lone "Continue" pages in a row, twice: the prologue then the dice page; a failed boarding then the Lark's lift. The pacing drags before the first real choice and before the quay's end. | **Narrative** |
| 8 | `1150_vica` (N5) | W | `ui_theme: docks` where the other desert scenes use `desert`. | **Narrative** |
| 9 | `0` choice (N3) | W | "Choose who you are..." with three dots; the game uses "…". | **Narrative** |
| 10 | `1150_vica`, the coin | W | "Count some coins into the sand for her (10 gold)" is shut to a purse under 10 (`pays`, locked line shows the gold) in both languages: correct. It is the one choice that lowers her approval (-8), which a player cannot know. By design ("the coin is all very well, but where is the bread?"); worth a line in the choice or the remark. | **Narrative**, optional |
| 11 | flags `hound_*` (N10) | K | Ids that name a dog that is now Vica (`vica_follow`, `vica_shared`, `vica_paid` exist). Ids only, no player impact; renaming costs a save migration. Leave. | **Core**, probably never |

Checked and clean (the user's list): no text in chapter 1 mentions a dog or a hound before `1150_vica` (guarded, see below); no caravan-day Vica: `1200`'s caravan is the salt caravan Lysa and the player take south, not a Vica scene, and the companion's join nodes are `1150_vica` and `1200`; the dogs in `detours.json` are in the cove camp and the frost biome (chapters 7 and later), not chapter 1; Vica's coin is 10 gold, locked under 10; Vess is in chapter 2 only and no scene offers more than four choices (both from Narrative's note).

## Chapter 1's fights and tests (26 choices, 49 nodes)

| Kind | Where | Note |
|---|---|---|
| fights with a defeat branch (`loseNextId`) | `105` (x3), `110` (x3), `120` (x3), `400` (Aurel Vane to `400_lost`, the Black Hold) | the den is walked on, the Hold is the only long path (4 nodes, by design) |
| forced fights, a loss retries at no cost | `260`, `820`, `822`, `850`, `855`, `1140`, `1140_spotted` | the clash and boss bands catch an unwinnable one; `rat_matriarch`, `inquisition_warden`, `wreck_scavenger` are ordinary enemies |
| skill tests, a fail branch each | `820`, `822`, `840`, `850`, `895` (x3), `1100`, `1120`, `1140` | every one has a `failNextId`; every fail branch meets the path again |

Aurel Vane, 83% against a target of 75 at v1.501 (79 at v1.489): the early boss sits a little above its curve, as the L3 said for all the early bosses. Not re-measured here (no broad batch, the user's rule); the guard `boss_balance_test` holds the band.

## The screens, on a phone

Pictured at 412 x 892, 360 x 740 and 320 x 568, English and French, the app's own fonts, no overflow error: the intro, the race and profession screen, Vica's page, the Party formation with Vica and Kelda, the inventory with its Dice tab (`test/qa_smoke_ch1_test.dart`, new). All five pass at all three sizes in both languages. What the pictures show:

- Race screen, FR: the English skill names (finding 2). The rest fits at 320 px.
- Party formation, FR, 320 px: the locked seat reads "Une place de plus Barracks Annex" in the test only: the test hands the raw table, the app hands the localized one (`houseName_fr` is "L’Annexe de la caserne"). Not a bug.
- Inventory, 320 px, FR: the equipment slot's "Dé porte-bo…" is cut with an ellipsis and the tab row scrolls (the Dice tab is off-screen until it is dragged). Readable, not a defect; a candidate for UX if the Dice tab matters to the player.
- Not pictured, not covered by a real-font check yet: the Journey's map and list, the page scenes (`100_dice`, `400_hold`, `960_lift`: the longest scenes are in `qa_story_text_real_font_test`), the fight screen beyond its tips, and the camp's Party tab as a whole page (only the formation widget). Listed in `smoke-coverage.md`.

## The simulator and the tests, as they are

No new batch. The chapter 1 tests ran together (65 tests in 39 s on this machine): `chapter_one_test`, `chapter_one_flight_test`, `alster_one_place_test`, `first_journey_test`, `new_game_start_test`, `vica_test`, `doorstep_scenes_test`: all pass. The last reports are `docs/qa/l3-1.501.0.md` (bosses, every goal reaches an ending) and `docs/simulation/report-100-runs.md`.

## Code and test smells seen from the data (lib/ untouched)

- `grantedSkillName` (finding 2): the table is already passed to the widget (`skills`), the name is rebuilt from the id; one call to the localized table would do.
- `StoryChoice.pays` is opt-in: a price in a choice (`goldMod < 0`) is shut to a poor purse only when the author marks it `pays` (or the next scene has `reqGold`). 12 chapter 1 choices cost gold: 3 are gated (`261`, `1130`, `1150_vica`), 7 are the casino and the den (`115`, `125`: the cost is what the player lost there) and 2 are the forced boarding prices (finding 5). A default of "a negative `goldMod` outside a forced page pays" would be safer; Core's call.
- The slowest chapter 1 files by their shard weight: `story_layout_test` (18 s), `ux_story_room_test` (17.5 s), `journey_moves_test` (15.7 s), `qa_story_text_real_font_test` (10 s). No duplicate fixture was looked for in them here (no profile run: the user's rule); a profile pass is the way to find one.
- Seven chapter 1 test files have no shard weight, so the default 0.6 s is used; together they ran 39 s. Adding their weights would balance the shards a little better; not worth a PR alone.

## What was added

- `docs/qa/chapter1_audit.py`: the cross-reference audit above (about 1 s).
- `test/qa_chapter1_test.dart`: no dog before Vica is met; every join node is a scene and Vica joins at the Wells; a story payment in chapter 1 shows its price in both languages. About 1 s.
- `test/qa_smoke_ch1_test.dart`: the five chapter 1 screens at three phone sizes, EN and FR. About 10 s.
- Not guarded: finding 2 (a guard would fail today; it goes in with the fix: the race screen in French must read "Détermination"), findings 1, 3 to 9 (they are text and design choices).

## Issues

Opened with the label `qa`: #582 (finding 2, UX and Core) and #583 (finding 5, Core). The other findings are Narrative's and stay in this list.
