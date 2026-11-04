# UX's part of the code cleanup: waves 3b, 4 and 5 (a plan, no code)

From UX-2 to the Manager, for `docs/qa/code-cleanup-plan.md` (waves are defined there; this is
only what UX owns, with today's numbers from `tool/qa_size.py`, `qa_unused.py`, `qa_duplicates.py`
at main v1.696). **One PR per step, one file at a time, no behaviour change** (the plan's rules
1 to 11), pictures before/after only where a look could move (it should not: each step is
checked by the existing tests and, for a screen, a screenshot test or a run-through).

**Not mine:** the world map and its files (`chart_map_painter.dart` 2,422 lines, `journey_world_map.dart`,
`world_map_screen.dart`, `journey_place.dart`, `city_chart/*`, `city_chart_screen.dart`) belong to the main UX
session, who is waiting on the user for the map build. `journey_screen.dart` is shared: its map half is theirs, its
scene layer is mine (v1.686/687/696); I only split it when they confirm no map PR is open on it.

## Wave 3b: UI duplicates (about -300 lines, ~14 files, **risk low**)

| Step | What | Files | Proof |
|---|---|---|---|
| 3b-1 | One tag/badge widget for the four private ones: `_Tag` in `harbor_screen.dart:1017`, `origin_stories_screen.dart:702`, `offer_dialog.dart:1221`, and `_Badge` in `companion_remark_bubble.dart:270` (and `_TagChip`, `choice_card.dart:158`, only if the look is identical) → `lib/widgets/ink_tag.dart` (there is already an `InkTag` in the theme to reuse first) | 5 | widget tests of each screen; the picture: they should be pixel-identical (`ux_*` shots), anything that moves is left alone |
| 3b-2 | The two die badges: `DieBadge` (`fight_markers.dart:9`) and `CharacterDieBadge` (`character_die_badge.dart:21`) → one badge with two constructors | 3 | `fight_markers_test`, `character_die_badge` tests |
| 3b-3 | The six cross-file blocks of the plan (2.3): `feature_unlock.dart:356` / `return_notice.dart:94` (a shared card shell), `weather_chip.dart:141` / `ward_mark.dart:79`, `title_detail_view.dart:187` / `item_detail_view.dart:498`; the `journey_screen.dart` / `story_player_screen.dart` / `main_menu_screen.dart` ones go with wave 4 | 6 | the widget tests; no picture if identical |
| 3b-4 | UX's leftover dead code from the plan: `ShipCutaway.roomRect`, `deckCrewHeight`, `hasWalkSprite` (test-only today), `projectileStyles` (shared), `SuitorCard`/`TitlesSection`/`ClansSection` if their tests are decided with them; then 2b for `lib/widgets`, `lib/utils`, `lib/theme` (~120 file-only names private) | ~25 | analyzer + the tests that name them; one PR for dead code, one for 2b, 2b right after a merge of all open PRs |

Order: 3b-1, 3b-2, 3b-3, 3b-4. Each ~10 minutes to read. Versions: one each (they touch `lib/`).

## Wave 4: the files UX owns, one per PR, never two at once

Pattern (the fight screen's, already in the repo): a `part` file of extensions per view, the state class stays,
**no logic moves**, so a split is a pure cut and paste proven by the compiler, the analyzer and the tests that import
the file.

| Order | File (lines) | Cut | Risk | Proof |
|---|---|---|---|---|
| 1 | `lib/screens/story_player_screen.dart` (4,467; `build` 829 at :243) | parts for the choice flow, the sheets, the excursion, the fight/expedition launches; the 2 duplicated blocks inside it (`:3015`/`:3229`) merged on the way | medium: Core's `story_flow` code lives here; check open PRs first | `story_*`, `choice_*`, `qa_smoke_*`; CI; a play-through of chapter 1 (the simulator's smoke) |
| 2 | `lib/screens/journey_screen.dart` (6,860; `build` 1,690 at :1533, 792 at :4442, 579 at :6279) | **scene layer first** (my half: `_ScenePanel`, `_choicePanel`, `_cardFor`, vignette/stage glue, the reading page) into `journey_scene.dart`; the map half only with the main UX session's yes | high, the biggest file; a conflict magnet: only in a window with no map PR | `journey_*`, `scene_*`, `prologue_*`, `reading_flow`; screenshot shots at 320/412 |
| 3 | `lib/screens/ship_battle_panel.dart` (3,983; shared with Core) | panel, log, orders | medium | `ship_battle_*` tests; a voyage run-through |
| 4 | `lib/screens/voyage_screen.dart` (1,923), `lib/widgets/sea_battlefield.dart` (1,830), `lib/widgets/combat_vfx.dart` (1,888) | one each, by class | low (painters) | their widget tests, the VFX gallery |
| 5 | the 600-line `build`s: `shop_detail_screen.dart:55` (653), `settings_screen.dart:61` (607), `race_profession_screen.dart` (421, 1,290 lines), `inventory_screen.dart` (411), `clans_politics_screen.dart` (1,706) | extract sections into widgets, same file first | low | their screen tests |
| later | `app_strings.dart` (13,946): the plan's own wave 4 first item; only when **every** session has merged; keys unchanged, one `const` map per feature | no behaviour; conflict magnet | the strings tests (`qa_strings_test`, `qa_data_refs_test`) | not mine to start: the Manager picks the window |

Core's files stay Core's (`player_session_provider.dart`, `sim_combat.dart`, `db_schema.dart`, `factions.dart`, ...).

## Wave 5: performance, UX's items

| Step | What | Where | Proof |
|---|---|---|---|
| 5-1 | Typewriter without a `setState` per 16 ms for the whole bubble: type into a `ValueNotifier<int>` and rebuild only the `Text` (`companion_remark_bubble.dart:149`; `StoryText` already repaints through an `AnimatedBuilder`, leave it); the tour's one is Core's (`guide_tour.dart:423`) | 1 (+1) | `companion_remark_*` tests; behaviour identical |
| 5-2 | Reduced motion and `.repeat()`: audit the 10 callers (`city_chart_view.dart:226`, `pixel_sprite.dart:158`, `wind_banner.dart:57`, `throne_room.dart:250`, `ship_yard.dart:95`, `feature_unlock.dart:202`, `ship_battle_panel.dart:551/810`, `journey_screen.dart:4211`, `guide_tour.dart:321`); each must stop under `disableAnimations` and when its ticker is not enabled; the list of the ones that do not, as a small PR with a test per widget | ~6 | a widget test per fix (`disableAnimations: true`, `tester.hasRunningAnimations` false) |
| 5-3 | The ~40 `prefer_const_constructors` sites in widgets (wave 1 already enabled the lint) | ~15 | analyzer |
| 5-4 | A profile timeline of the Journey (reading page + stage), the fight (board with weather) and the Camp, **before touching anything else**: a frame-time capture is the only way to know whether any of it matters. I cannot run a device here: I need the user's or QA's capture; otherwise 5-1/5-2 only | none | the capture |

I already did the performance-relevant parts of my own recent work: the weather and event layers are separate
`RepaintBoundary`s driven by one ticker each (v1.671), the fight's top strip is one row instead of three (v1.685).

## Risks and the rule that keeps them small

- **Conflicts**: `journey_screen.dart` and `story_player_screen.dart` are edited by Core (behaviour) and UX (look). Before each
  step I run `git diff --stat origin/main...origin/<branch>` on every open branch, skip the file if any touches it, and ask you
  for a window for 4-1/4-2 (no other PR on them).
- **No weakened tests**: a test that fails because a widget was merged is updated to the new name, never loosened.
- **Pictures**: only 3b-1/3b-2 could move a pixel; they are done only if the result is identical (checked with the existing
  `ux_*` screenshot tests), otherwise the widget is left alone and listed.

## Order and versions (starting v1.703, one per PR)

1. 3b-1 tag/badge widget, 2. 3b-2 die badges, 3. 3b-3 shell blocks, 4. 3b-4 dead code + 2b widgets,
5. 5-1 typewriter, 6. 5-2 reduced-motion audit, 7. 5-3 const sites,
8. 4-1 `story_player_screen.dart`, 9. 4-2 `journey_screen.dart` scene layer, 10. 4-3 `ship_battle_panel.dart`,
11. 4-4 the painters, 12. 4-5 the long `build`s.
Steps 1 to 7 are small and can overlap with other sessions' work; 8 to 12 each need a quiet window you grant.

## Status (2026-11-04, UX-2)

**Done**: 4-1 `story_player_screen.dart` cut into four part files (#724, v1.749; pure cut, the sorted lines before and after
are identical). Related work outside this plan: the list in `ux-2-improvements.md` (D one tile widget #708, G the 320 px /
French sweep #709, C the `ux_*` generators #718 and #720: 38 files / about 22,000 lines of picture mocks removed, the 8 that
assert real behaviour kept).

**Not done, and why**
- **3b-1, 3b-2, 3b-3**: not duplicates once read. The tag/badge and die-badge blocks have different looks and roles (merging them
  would change a pixel or add a parameter list longer than the code it saves); the shell block is a 25-line mixin that costs
  more than it saves. Manager agreed.
- **3b-4** (dead code, 2b for `lib/widgets`, `lib/utils`, `lib/theme`): the Cleanup session owns it (CLAUDE.md: waves 1, 2, 2b).
- **H (the aim line measuring only on a change)**: `_measure` already calls `setState` only when a point moved; measuring only
  when the widget's fields change would leave the line stale when a card moves with the same keys (for example the slot count
  of #704). The saving is a post-frame callback and two transforms. Manager agreed.

**Options left for a later PR (not started)**
- Merge the two duplicated blocks inside the story view (`story_player_screen.dart` near the old `:3015` and `:3229`, now in
  `story_player/story_hub.dart`: the settlement arrival card and the hub choice card). That is a code change, not a cut, so it
  needs its own PR and a picture check.
- 4-2 the Journey's scene layer, 4-3 `ship_battle_panel.dart`, 4-4 the painters, 4-5 the long `build`s, 5-1 to 5-3: still as
  planned above, each when no other PR touches the file.
