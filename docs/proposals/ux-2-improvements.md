# UX-2: improvements within my scope (removals, simplifications, speed-ups)

For the Manager. Scope: what I built or touched since v1.651 (the fight view, cards, board and top strip,
"Qui combat ?", the scene panel and stage, the reading page, the dice and clan-dice screens, the inventory
dice rows, settings, the effect icons and heads). **No code yet.** Measured on main v1.701+ with
`tool/qa_*.py`, `flutter test --reporter json` and the code itself; where I have no evidence I say so.
This list is **in addition to** the approved 12-step plan `docs/proposals/ux-waves-3b-4-5.md` (tag/badge
widgets, die badges, shell blocks, dead code + 2b, typewriter, reduced-motion audit, const sites, the big
file splits); numbers 1 to 12 there, A to J here. Same rules: one PR open at a time, no step changes a
look, a number or a string, no check weakened, versions from you.

## Ranked by value over effort

| # | Item | Kind | Value | Effort | Risk |
|---|---|---|---|---|---|
| A | The fight's ground layer repaints every frame for nothing | speeds up | high (every fight frame) | tiny (about 10 lines) | low |
| B | The slow fight tests wait in real time: run them at dice speed 4× | speeds up (tests) | high | tiny (a pref in the harnesses) | none |
| C | Move or delete the 38 picture-generator tests gated by `UX_SHOTS` | removes | high | medium, mechanical | low |
| D | One status-tile widget instead of two in `fight_effect_icons.dart` | removes | medium | small | low |
| E | One log UI: delete the edit-mode ticker or show the history button everywhere | removes | medium | small | **needs your call** |
| F | Drop the weather tile from the top strip (the subtitle already says it) | removes | low | small | **needs your call** |
| G | A 320 px / French overflow sweep of what I built (a guard, not a feature) | verifies | medium | small | none |
| H | `FightAimLine` measures after every build | speeds up | low | tiny | low |
| I | Settings and shop `build` of 600 lines into section widgets | simplifies | medium | medium | low |
| J | A frame-time capture of the fight and the Journey (needs a device) | measures | decides the rest | the user's 10 minutes | none |

## A. The fight's ground layer repaints every frame for nothing (speeds up)

- **What**: `FightBackdrop` (`lib/widgets/fight_backdrop.dart:270-330`) starts a `Ticker` whenever motion is on and
  repaints its painter on every tick. Since v1.671 the fight stacks three of them (ground, weather, board events);
  the **ground** one has no weather and no anomaly to draw, yet it still ticks at 60 fps and repaints the whole pixel
  stage (`paintPixelStage`, the night veil and the lamps) every frame behind the whole fight.
- **Why**: evidence is the code (`didChangeDependencies` starts the ticker; `_Frame.tick` notifies each frame; the
  painter listens to it). I have not measured the frame cost (no device); a full-screen pixel scene per frame during
  the whole fight is the obvious waste.
- **Do**: start the ticker only when this layer has something that moves (`weather && sky != null`, or `events` with an
  anomaly, or lights that flicker); a still ground paints once and again only when the stage, light or size changes.
- **Player notices**: nothing, except a cooler phone. **Risk** low: `fight_backdrop_test`, `pixel_stage_test`, `fight_ground_test`.

## B. The slow fight tests wait in real time (speeds up the suite)

- **Evidence** (`flutter test --reporter json`, this machine): my fight tests are the slowest of what I added:
  "a keep is final once a new roll is made" 21 s, "slots, pop-in, pick, keep and put back" 15 s,
  "a heal die aims at the ally…" 14 s, "no log block in play mode…" 13 s; the reading and scene tests 6 to 8 s each.
  Since v1.679 the dice throw is 1.4 s + 0.45 s rest and these tests wait it out with real `Future.delayed`.
- **Do**: the harnesses (`skill_fight_harness.dart`, the helpers in `fight_board_*_test.dart`) set `combat_dice_speed`
  to `quad` in their `SharedPreferences` mock: the throw and the rest are a quarter (350 ms + 112 ms). The
  `dice_speed_test` already proves 4× is the default divided by 4, so no check is lost.
- **Gain**: about 35 to 45 s of the four slowest files; likely more across the other 60 fight test files (I only measured mine).
  **Player notices**: nothing. **Risk** none (test setup only); QA to report the suite time before/after.

## C. The picture-generator tests (removes)

- **Evidence**: `test/ux_*.dart` is **52 files, 23,566 lines**; **38** of them are gated by the `UX_SHOTS` environment
  variable (they draw storyboards and write PNGs; with the variable unset they assert almost nothing). Running just those
  38 files takes **55 s wall** here, nearly all of it compiling and loading, and the CI shards pay it on every PR.
  Some also hold real assertions (`ux_story_room_test` runs 18 s), so each needs a look.
- **Do**: for each gated file, either (1) keep its real assertions in a small test and move the drawing to
  `tool/ux_shots/` (not part of `flutter test`), or (2) delete it when its pictures are already archived in
  `docs/ux-shots/` and it asserts nothing. The ones I wrote (`ux_inplace_refined_*`, the fight shot tests) first.
  Shared mock parts (`ux_*_parts.dart`, 5,900 lines) follow their only users.
- **Player notices**: nothing. **Lost**: the ability to redraw an old picture by one command (it moves to `tool/`).
  **Risk** low. Effort: mechanical, but 38 files: split in 3 PRs by owner (mine, then UX main's, then the rest).

## D. Two status-tile widgets in one file (removes)

- `FightEffectChip` (the 9×9 pixel icons) and `FightStatusTile` (the top strip's Material icons) in
  `lib/widgets/fight_effect_icons.dart` draw the same tinted tile and the same corner badge twice (about 60 lines of
  decoration and badge code); the pop-in is already shared. **Do**: one `FightTile` with an `icon` (pixel or Material)
  parameter. **Player notices**: nothing (pixel-identical, checked by the existing icon and chip tests).
  **Risk** low. Goes with step 3b-1 of the plan.

## E. Two log UIs (removes), needs a decision

- In play mode the log is behind a history icon (v1.685); in edit mode the old two-line ticker (`_buildLogTicker`,
  `fight_controls.dart:62-118`, ~55 lines) stays. Two UIs for one log to keep working. **Option 1**: show the history
  button in both modes and delete the ticker (edit mode loses a glanceable two lines). **Option 2**: leave it. I would
  take option 1 if edit mode is only for authoring, but the user asked for the change "in play mode" only, so I do not
  without your word.

## F. The weather tile (removes), needs a decision

- The app bar subtitle already says "Within walls · Rain"; the top strip's weather tile repeats it and only adds the
  tip text. **Option**: make the subtitle tappable (same pop-in) and remove the tile, one tile less on the row (32 px).
  Tiny value; I only list it because you called the chip redundant.

## G. Does it fit at 320 px and in French? (verifies)

- **Evidence**: none yet, which is the point. I checked 412 and 420 px in tests, and French on the scene panel and the
  Stone Bridge; I did **not** sweep the top strip's tiles and pop-ins, the "Qui combat ?" card, the vignette's folded
  line, the stage's balloon and door tab, the gift line in the dice bag, or the Settings dice-speed control at 320 px in
  French. **Do**: one test per widget that pumps it at 320 px in French with the longest real strings (the longest
  clan names, the longest `reply_fr`) and fails on an overflow or an ellipsis in a place that must not cut. It
  becomes a guard (`qa_`-style); anything it finds is a bug I fix with the string's owner.

## H. `FightAimLine` measures after every build (speeds up, small)

- `lib/widgets/fight_board.dart:539` schedules `_measure()` in every `build`, even when nothing moved; `_measure` only
  calls `setState` when a point changed, so it is correct but does a layout walk per frame while a die is picked.
  **Do**: measure on size changes (a `LayoutBuilder` key) and when the picked die changes. Value low; effort tiny.

## I. Long builds in screens I touched (simplifies; part of plan step 4-5)

- `settings_screen.dart` `build` 607 lines (my dice-speed control is one of ~25 tiles), `shop_detail_screen.dart` 653,
  `inventory_screen.dart` 411, `race_profession_screen.dart` 421. Sections as private widgets in the same file first (no
  logic moves); this is what makes the next feature a 10-line change instead of a hunt. Plan step 4-5.

## J. A frame-time capture (needs a device)

- Nothing here was profiled; I cannot run a device. Before any speed-up beyond A, H and B, **ask the user for one
  `flutter run --profile` timeline** of: a fight with rain and an anomaly (the three layers and the throw), the Journey's
  reading page and stage, and the Camp. If you want it, say so and I write the three-line instructions for the user.

## What I looked at and am NOT proposing

- **Heads**: 67 images, none unused (every head belongs to an enemy, the hero, Vica or Aurel Vane); `HeadAvatar`
  (v1.701) already merged three copies of the head code.
- **Old fight stage files** (`fight_figure`, `fight_stage_parts`) are already gone; `fight_markers.dart` is down to the
  `DieBadge` (87 lines), which the plan's step 3b-2 merges.
- **Clan-dice art, gift line, balloon, door tab**: small widgets, used once each, nothing to remove.
- **Animations that add nothing**: none found among mine; the reduced-motion audit of the 10 `.repeat()` callers is
  already plan step 6.

## Order I would take

A, B (a day's work together, biggest return), then the plan's 1 to 4 with D folded into step 1, then G, C in its
three PRs, H, then 5 to 7 and the splits 8 to 12 when you grant the windows; E and F only on your answer; J when you want
the user's capture. One PR at a time; I ask you for each version when I open it.
