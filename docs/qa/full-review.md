# Full review of the app

Read-only review by QA, 2026-11-03, on `main` at v1.702.0 (L3 figures from v1.696.0). Nothing in `lib/` or the data was edited. Findings are ranked **blocks the player / wrong / rough / nit**; each non-nit finding has a GitHub issue labelled `qa` and an owner.

**Method and its limit.** `lib/` was read by area (five readers), and every finding listed below as verified was then re-read in the code by QA. Findings are from reading, not from a reproduction on a device, except where it says otherwise. Nits are listed but have no issue.

## Summary

| rank | count | issues |
|---|---|---|
| blocks the player | 1 | #693 |
| wrong | 3 | #694, #695, #697 |
| rough | 4 | #696, #698, #688, #582 (older) |
| nit | 5 | none |

The data is clean (the cross-reference and quest audits find nothing, the story graph has no blocking node), the screens fit at 320, 360 and 412 px in English and French, and the suite and simulator pass. The risks are in how saves and fights fail, not in the content.

## 1. Blocks the player

- **#693 (Core): a corrupt save, legacy save, autosave or new-game default can leave the player on the loading screen.** `player_session_provider.dart` `_load` (~1928-1946, ~1955-1961, ~2033-2039), `save_game_provider.dart` (~76-99), `story_providers.dart` `_loadAutosave` (151-179). Decodes are unguarded. This is the only finding that can lose a save.

## 2. Wrong

- **#694 (Core): fights.** A skipped fight with no `else` moves on as won (`story_player_screen.dart` ~1476-1485); a missing enemy table is a free win and Hold rewards are paid from it (`fight_rewards.dart` ~26-28, 61, 445); `_finishFight` has no try/finally so an error can stick the screen (`fight_rounds.dart` ~672-678); the Long Vigil mend is not clamped; Flurry can resolve a die twice; rolling is possible during the round pause (`fight_dice_rules.dart` 847-848, 1152-1155; `fight_rounds.dart` ~1641).
- **#695 (Core): `startExcursion` does not persist** (`story_providers.dart` ~305-323), so quitting just after starting one resumes at the previous node.
- **#697 (Core, and the user): balance from the L3.** Regular fights are 8.7 points easier than at 1.501; the mage leads by 5 to 8 points; the simulator skips 21 camp errands.

## 3. Rough

- **#696 (Core, UX): data loaders swallow errors** (`game_db_providers.dart` 44-47, 71-85, 128-154; `story_repository.dart` 25, 34-39): a broken file shows up as missing content far away.
- **#698 (UX, Core): reduced motion** is ignored by `city_chart_view.dart` (~226) and `pixel_sprite.dart` (~148-160); `tutorial_launcher.dart` (~37-41) reads `ref` before checking `mounted`.
- **#688 (UX-2): the dice board is a 20 px strip at 320 x 568** (open since the L3 on 1.696).
- **#582 (Core, Narrative): English skill names on the race screen in French** (older; guarded by `qa_user_feedback_test`).
- **#598 (UX): two guide-dog frames are not in the build** (older).

## 4. Nits (no issue)

- The camp screen at 320 px shows the title twice (app bar and body) and the gold chip in the app bar sits under the debug banner in debug builds only (UX).
- Settings and the main menu at 320 px are readable but tight; nothing clips (UX).
- `docs/qa/code-cleanup-plan.md`, the assets READMEs and `CLAUDE.md` still name removed files or placeholders (`tool/qa_docs_stale.py` lists them; Cleanup).
- `lib/` has many `catch (_) {}` blocks that hide errors (see #696); a lint rule would count them (Cleanup).
- Per-file duplicates in tests (see [qa-improvements.md](qa-improvements.md)) (QA, Cleanup).

## Data (gamedata and the story)

- `tool/qa_xref_audit.py`: all gamedata references resolve, **0 problems**. `tool/qa_quests_audit.py`: 51 quests, every step reachable and every reward valid, **0 problems** (it allows the engine's own nemesis, temptation, champion/angel/demon and ship-repair cases).
- Story graph: 479 scenes, 1,156 ways, **no blocking node** (`qa_story_blocking_test`); scene 270 is parked by design.
- Coverage: simulated runs reach 92.5% of scenes; the 21 unvisited are camp errands the simulator does not take (#697), not unreachable scenes.
- EN/FR: the L3 read-through found no new gaps beyond #582; the smoke tests now run every player screen in both languages.

## Tests and CI

- Coverage holes: 45 of 54 screens had no real-font phone check; `qa_smoke_l3_test` and the new `qa_smoke_screens_test` (12 screens x 3 sizes x 2 languages, no overflow) close the player's own screens. The editor screens remain (low value).
- Slow or fragile: the stale `Round 2` polls (about 180 s) are fixed; shard weights were stale (slowest shard 753 s, now about 651 s). `_pumpUntil` copies can still time out silently ([qa-improvements.md](qa-improvements.md), item 3).
- Not run on CI today: the cross-reference and quest audits (item 8 there).

## Screens at 320 and 412 px, English and French

Read at 412, 360 and 320 px in both languages: main menu, settings, achievements, journal, character, camp, clans and politics, harbor, ship, main story, NPC detail, shop detail (this review), plus the 21 cases of the L3 and every screen changed since 1.654. No overflow in any; the only layout finding is the 20 px dice strip (#688) and the nits above.

## Docs

`tool/qa_docs_stale.py` finds stale paths and links in the assets READMEs, the old cleanup plan and CLAUDE.md placeholders (nits, Cleanup). `docs/qa/README.md` points to the last L3.

## The L3 report

Folded in: the full report is [l3-1.696.0.md](l3-1.696.0.md) (PR #690). Pass: suite green (3,852 tests), format and analyze clean, 900 of 900 simulated runs reach an ending, data audit clean, bosses within 6 points of their targets.

## What this review did not cover

No run on a physical device; no timing or memory profile of the app itself; `lib/` was read, not exercised, so the findings in sections 1 and 2 should be confirmed by the owner with a failing test before the fix (QA will write the `qa_` guard on request).
