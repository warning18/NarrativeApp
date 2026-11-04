# Code health, second round: new proposals (Cleanup session)

Written at v1.751.0 (main `97c772ca`, after the story_player split, the page break and the other splits). Proposals only, no code. It does not repeat `cleanup-improvements.md`, `cleanup-visible-for-testing.md` or `cleanup-unawaited-futures.md`, nor anything merged or held (#700 lints, #710 Gemini). Every item keeps behaviour unchanged. Ranked by value over effort.

| # | Item | Size | Risk | Files of |
|---|---|---|---|---|
| 1 | Leftovers batch: one dead function, a stale `ignore`, an orphan test helper, a stale package description, two needless `.gitkeep` | S | none | Core, QA, Manager (pubspec) |
| 2 | Privatise 7 names that became file-only | S | none | Core, UX, Narrative |
| 3 | Five more lints at about 29 sites | S | low | Core, UX, QA |
| 4 | Two repeated blocks the splits left in the story player and the notices | M | low | UX |
| 5 | Two `class` that are really `enum`s (owner's call) | S | low | UX |

## 1. Leftovers batch (one PR, about 130 lines out)

**What.**
- `joinedNarration` (`lib/data/narration_pages.dart:39`, one function and its doc comment): nothing calls it, in `lib/`, `test/` or `tool/`. It was written for the page break (v1.750) and left unused by v1.751 when the recording scripts dropped `[PAGE]`. `qa_unused.py` lists it as `dead`; it is the only new one since my last list (the other, `regionHoldersProvider`, stays KEEP for UX).
- `// ignore: unused_element` at `lib/screens/fight/fight_dice_rules.dart:112`: `_setHealTarget` is called by `fight_board_view.dart:258` (a part of the same library), so the ignore hides nothing and says the method is unused, which is false.
- `test/fight_hero_harness.dart` (104 lines): no test imports it (`grep -r fight_hero_harness test lib`). Its last change was the shared-helpers move of QA's wave 3a (`a9553708`); QA to confirm it is not kept for a test in progress.
- `pubspec.yaml` line 2: `description: "... and AI-assisted generation."` is false since the Gemini library went (#710). One word of metadata. Manager's file.
- `.gitkeep` in `assets/visuals/companion/dog_companion_animations/walking_angel/east/` and `walking_evil/east/`: the folders hold 8 frames each, so the placeholder is useless (the two `west` ones are empty, undeclared in `pubspec.yaml` and read by nothing: also candidates, with their folders).

**Why.** Each is a line a reader has to understand and discard. **Evidence.** `python3 tool/qa_unused.py | grep dead`; the greps above. **Risk** none: no call, no import, no shipped file changes (the east `.gitkeep` is not a declared asset). **Size** S. **Touches** Core (`narration_pages.dart`, `fight_dice_rules.dart`), QA/Core (`fight_hero_harness.dart`), Manager (`pubspec.yaml`).

## 2. Privatise 7 names that became file-only

**What.** `tool/qa_unused.py` lists, as `file_only`, names that the splits and the page break left used by one file: `resonanceTier` (`lib/combat/clan_dice.dart`), `pageOpeningMarkers` (`lib/data/narration_pages.dart`), `resonanceLineFor` (`lib/widgets/clan_die_gift.dart`), `streetOverlay` and `streetParty` (`lib/widgets/street_view/street_view.dart`), `StorySoFarPage` (`lib/screens/journal_screen.dart`), `ChapterGridAlgorithm` (`lib/screens/story_graph_screen.dart`). I tried the rename on a scratch tree with my tools: after reverting the names the analyzer objects to, `flutter analyze` is clean with these 7 (6 files, 18 lines).

**Why.** Same as wave 2b: a name that cannot be used elsewhere should say so. **Not included:** the other 95 classes, 12 typedefs, 5 enums on that list; the analyzer rejects privatising them (`library_private_types_in_public_api` when a public member exposes the type, `unused_element_parameter`), so they stay public. **Risk** none (the compiler proves it). **Size** S. **Touches** Core (`clan_dice`, `narration_pages`), UX (`clan_die_gift`, `street_view`), Narrative-adjacent screens (`journal_screen`, `story_graph_screen`).

## 3. Five more lints (about 29 sites)

Same method as #700: turn on, fix, keep at zero. Counts from `flutter analyze` with the rule added:

| Lint | Sites | Fix |
|---|---|---|
| `combinators_ordering` | 14 (2 in `lib/`, 12 in `test/`; one of them is the orphan helper of item 1) | sort the names after `show` / `hide`; order only |
| `use_is_even_rather_than_modulo` | 11 (all drawing code: `fight_pixel_stage`, the side-view kits, `chart_map_painter`) | `x % 2 == 0` becomes `x.isEven`; same value for an `int`, negatives included |
| `use_colored_box` | 2 (`ship_battle_panel.dart:2999`, `test/feature_unlock_test.dart:69`) | `Container(color:, child:)` becomes `ColoredBox`; both have a `child:`, so the size is the same (I checked, as for `use_decorated_box`); the first has a `key:`, which `ColoredBox` takes too |
| `join_return_with_assignment` | 1 (`lib/data/nemesis.dart:213`) | return the expression |
| `use_late_for_private_fields_and_variables` | 1 (`lib/screens/expedition_screen.dart:116`) | `late` for a field set once |

**Risk** low (analyzer-proven; the `ship_battle_panel.dart` site waits for UX-2's #727 split). **Size** S: one PR, about 25 files. **Touches** UX (drawing and widgets), Core (`nemesis.dart`), QA (the test combinators).

## 4. Repeated blocks the splits left

`qa_duplicates.py --dir lib` finds two blocks repeated **across** files (all other repeats are tables inside one file, listed in `cleanup-improvements.md` item 6):
- `lib/screens/story_player/story_hub.dart:685-715` and `story_choice_widgets.dart:66-97` (29 to 31 lines). Both cut from `story_player_screen.dart` in #724, so the copy was already there; now it is in two files that can share one private-to-the-library helper.
- `lib/widgets/feature_unlock.dart:356-378` and `lib/widgets/return_notice.dart:94-116` (20 lines): the same card frame.

**Why.** The two copies will drift apart (they are the first thing a restyle of the cards touches). **Risk** low (a shared builder with the same arguments; the story-player and notice tests cover them). **Size** M. **Touches** UX only.

## 5. Two `class` that are `enum`s

`use_enums` flags `lib/screens/world_map_screen.dart:40` and `lib/widgets/ship_cutaway.dart:11`: classes made of constants that an `enum` expresses in fewer lines and with exhaustive `switch`es. **Risk** low but not zero (any code that compares by `==` on a value built twice, or stores them, needs a look), so this one is for the owner to read, not a mechanical fix. **Size** S. **Touches** UX.

## Checked and not worth doing (this round)

| Idea | Finding |
|---|---|
| Unused strings | 0 read nowhere, 2 read only by tests (`journey_level_place`, `stat_pick_rare`, already on `cleanup-visible-for-testing.md`). |
| Unused images and pubspec entries | Only the 5 `chests/*_open.png` (loaded at run time). No pubspec entry matches nothing. The undeclared `Fight_-_Attack` folders (160 KB) feed `tool/gen_fight_heads.py`: read, not shipped, documented in `tool/README.md`. |
| New test-only symbols | None: all 50 listed are in `cleanup-visible-for-testing.md` (46 rows) or are the known entry points. |
| Unused gamedata fields | One: `boon` (6 rows of `factions.json` `_newKinds`). It is a design note beside `value` and `engine` (about 2.4 KB of briefing text that ships in the data). Core's call whether the notes belong in the shipped file or in `docs/`; too small to ask for a change. |
| Empty or orphan part files | None: the 24 `part of` files are 72 to 1,373 lines; no `lib/` file lacks an importer. |
| `no_adjacent_strings_in_list` | 135 sites, all deliberate wrapped long strings (`combat_aftermath.dart` 44, `check_outcomes.dart` 37, `alignment_events.dart` 24): fixing them means rewrapping prose. Not a bug finder here (no missing comma found in a read of the first files). |
| `prefer_int_literals` (175), `avoid_redundant_argument_values` (267), `prefer_expression_function_bodies` (170), `prefer_if_elements_to_conditional_expressions` (45), `avoid_positional_boolean_parameters` (108) | Style churn above the value, as in round 1. |
| `unnecessary_async` (26) | Removing `async` changes when an error is thrown and what a caller can `catch`: not no-behaviour. |
| The 7 `ignore: deprecated_member_use` on `DropdownButtonFormField.value` | The fix (`initialValue`) stops the field following its provider: a behaviour change. Keep. |
| Committed junk | No `__pycache__`, `.pyc`, `.orig`, `.log`; the biggest tracked files are UX screenshots and GIFs (round 1, item 8). |
| Fonts | All 5 `.ttf` files are declared and used. |

## Order

1 (a quarter hour, touches the fewest files), then 2, then 3 (the three can ship as one PR if the Manager prefers: all analyzer-proven, about 40 files). 4 and 5 go to UX after #727 merges. Nothing here needs a test deleted except the orphan helper in item 1, which no test uses.
