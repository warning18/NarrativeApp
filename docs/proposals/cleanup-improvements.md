# Code health beyond waves 1, 2 and 2b: proposals (Cleanup session)

Written at v1.696.0 (main `0d5f71e5`, 560 test files). Proposals only, no code: each item says what, why (the evidence and how to reproduce it), risk and effort, and the list is ranked by value over effort. None changes behaviour. Waves 1, 2 and 2b are done (`docs/qa/code-cleanup-plan.md`, section 6).

| # | Item | Value | Effort | Risk | Owner |
|---|---|---|---|---|---|
| 1 | Seven more mechanical lints | M | S | low | Cleanup |
| 2 | Drop the unused `cupertino_icons` dependency | S | XS | low | Manager (pubspec) |
| 3 | `@visibleForTesting` on the test-only symbols | M | S | none | each owner, Cleanup does it |
| 4 | One `mockFlutterTts()` helper for 142 test files | M | S | none | QA |
| 5 | Review the 47 `unawaited_futures` sites | M to H | M | low to medium | UX (screens, widgets), Core |
| 6 | Same-file copy-paste in `lib/` | M | M | low to medium | Core, UX |
| 7 | Near-identical UX mock tests, and a fresh suite profile | M | M | none | QA, UX |
| 8 | 50 MB of screenshots in `docs/` | S | S | none | UX |
| 9 | Ask: `google_generative_ai` in every APK | ? | S | low | Manager |
| 10 | Const-ize the generated chart tables | S | M | medium | Core |

## 1. Seven more mechanical lints (about 100 sites)

**What.** Turn on, fix with `dart fix` or by hand, and keep at zero: `use_if_null_to_convert_nulls_to_bools` (39 sites: `x ?? false` as `x == true`), `noop_primitive_operations` (19: a `.toString()` on a String, a `.toDouble()` on a double), `use_named_constants` (17: `Duration(...)` or `EdgeInsets` with a named equivalent), `prefer_foreach` (16, mostly tests), `unnecessary_raw_strings` (10), `use_decorated_box` (8), `sort_pub_dependencies` (2), `avoid_bool_literals_in_conditional_expressions` (2), `prefer_const_literals_to_create_immutables` (1), `avoid_unused_constructor_parameters` (1: `form` in `lib/widgets/side_view/side_ship.dart:191`).

**Why.** Same logic as wave 1: the analyzer proves each fix, and the lint keeps the next one out. Evidence: `flutter analyze` with these added to `analysis_options.yaml` (counts above, taken at v1.696).

**Not included on purpose.** `avoid_slow_async_io` (4 sites in `elevenlabs_tts_provider.dart`): its fix swaps an async file check for a blocking one, which is a behaviour change. `unawaited_futures` is item 5.

**Risk** low (the tests and CI). **Effort** S: one PR, about 40 files.

## 2. Drop `cupertino_icons`

**What.** Remove `cupertino_icons: ^1.0.8` from `pubspec.yaml` (and its lock entry).

**Why.** Zero imports of `package:cupertino_icons` and zero uses of `CupertinoIcons` in `lib/`, `test/` and `tool/` (grep). It is the project template's default; its icon font is bundled with every build (tree-shaking trims unused glyphs, so the gain is small).

**Risk** low (`flutter pub get`, analyze, the APK job). **Effort** XS. Needs a version, so it is the Manager's call.

## 3. `@visibleForTesting` on the test-only symbols

**What.** `tool/qa_unused.py` lists 52 symbols that only a test uses (`docs/qa/code-cleanup/test-only-symbols.md`). Of them: 4 are name collisions the scanner cannot tell apart (`shots`, `shows`, `peek`, `classic`: nothing to do), 2 are test entry points by design (`simulatePlaythroughs`, `debugEditorRoundTrip`), the other 46 are helpers and constants. Mark those 46 `@visibleForTesting` (import `package:flutter/foundation.dart show visibleForTesting`).

**Why.** Today a helper that exists for a test looks like game code, and nothing stops a screen from starting to call it. With the annotation the analyzer's default warning `invalid_use_of_visible_for_testing_member` does: any use from `lib/` is flagged, any use from a test is fine. It turns the "delete both, or keep because a feature is waiting" question into something visible in the code. Where a helper is only a lens on live data (`isMainSpec`, `duosOf`, `fightStageOf`, `fightGoalFromName`), moving it into the test is the other clean option. Each owner decides delete, move or annotate; the annotation is the default.

**Risk** none (no runtime effect). **Effort** S: one line per symbol, one PR per area.

## 4. A `mockFlutterTts()` helper

**What.** `test/support/` has fonts, pump, open_game and sim_world, but not the text-to-speech mock. 142 test files repeat the same 3 to 4 lines (`TestDefaultBinaryMessengerBinding... setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1)`); `grep -l "MethodChannel('flutter_tts')" test/*.dart | wc -l`.

**Why.** About 450 lines out, one place to change if the plugin changes, and wave 3a's pattern (QA) applies as it is.

**Risk** none (same call, same value). **Effort** S for the helper, then a mechanical replace. QA's files; Cleanup can do it if QA asks.

## 5. The 47 `unawaited_futures` sites

**What.** The lint reports a Future started and dropped without `await` or `unawaited()`: 25 in `lib/screens`, 13 in `lib/widgets`, 1 in `lib/providers`, 8 in tests. Each is either deliberate fire-and-forget (wrap in `unawaited()`, no behaviour change) or a missing `await` (a latent bug: an error is lost, an order assumed).

**Why.** It is the one rule of the set that can find a real defect. Evidence: the analyzer output (`flutter analyze` with the rule on).

**Risk** low for `unawaited()`, medium for adding an `await` (it changes timing: do it only when the owner confirms the intent, with the test). **Effort** M: the owners read 47 lines. Cleanup can produce the list (file:line, the call) and the owners tick them.

## 6. Same-file copy-paste in `lib/`

**What.** `tool/qa_duplicates.py --dir lib` (237 blocks, 7,140 repeated lines; most are data tables). The code ones, all inside one file:
- `lib/data/origin_stories.dart`: lines 387-419, 612-644, 667-697 (31 to 33 lines, three copies) and 711-743 / 767-799, 224-252 / 737-765.
- `lib/data/expedition_kinds.dart` 322-351 / 341-370.
- `lib/screens/story_player_screen.dart` 3102-3132 / 3317-3348.

**Why.** A helper function per block removes about 250 lines and the copies that drift apart. **Risk** low to medium (a shared helper changes nothing if the parameters are right; the stories and expedition tests cover it). **Effort** M, one file per PR, by the file's owner (Core for `data`, UX for the screen).

## 7. UX mock tests, and a fresh suite profile (for QA, not edited by Cleanup)

**What.** 36 test files named `ux_*mock*` or `ux_*shot*` hold 14,667 lines. Four of them (`ux_skills_mock`, `_styles_mock`, `_combined_mock`, `_ideas_mock`) repeat 102 to 111 lines of the same scaffold (`qa_duplicates.py --dir test`: 235 blocks, 9,421 lines in all). QA's last profile is `docs/qa/suite-time-1.499.0.md` (425 files, 839 s); there are 560 now.

**Why.** A shared scaffold removes about 400 lines; a new `flutter test --reporter json` profile finds which of the 135 added files cost the most (the screenshot tests pump many frames). **Risk** none (assertions untouched). **Effort** M. List for QA.

## 8. Screenshots in `docs/`

**What.** `docs/ux-shots` is 50 MB and 310 PNG files in all of `docs/`; `.git` is 182 MB; `docs/proposals` 17 MB, `docs/maps` 11 MB (`du -sh docs/*`).

**Why.** Every clone and every cloud session pays for it. The shots of proposals that have shipped could be dropped (the history keeps them) or kept as the latest set only. **Risk** none for the app. **Effort** S. UX's files.

## 9. Ask: `google_generative_ai`

Used by two developer screens (`ai_generator_screen.dart`, `playthrough_simulator_screen.dart`) and compiled into every release APK. If those screens are only for the developer, the package could sit behind a debug-only path or flavor. I cannot measure the size effect without a build; the Manager decides whether to ask for it.

## 10. Const-ize the generated chart tables (Core)

The three generated tables (`chart_story.dart`, `chart_worlds.dart`, `tool/fmg_chart/chart_fmg.dart`: 2,747 `prefer_const_constructors` sites) carry an `ignore_for_file` today because const lists are unmodifiable. If Core confirms nothing mutates them, making them const moves them out of startup allocation. Measure first (a startup timeline); risk medium until then.

## Checked and not worth doing

| Idea | Finding |
|---|---|
| Unused images | None left. The `chests/*_open.png` icons are loaded at run time. |
| Duplicate images | 26 groups of identical PNGs, 38 KB in total: not worth a change. |
| Leftover `TODO` / `FIXME` | 0 in `lib/` and `tool/`. |
| Unused imports, locals, parameters | 0 (the default warnings). |
| Style lints | `always_use_package_imports` (3,223 sites), `cascade_invocations` (764), `directives_ordering` (667), `avoid_redundant_argument_values` (303), `prefer_single_quotes` (258), `prefer_expression_function_bodies` (211): churn far above the value, and an explicit default documents intent. |
| Stale docs | 13 dead path references in 9 of 169 docs, all in dated proposals (`travel-map-ux`, `scene-backgrounds`, `intro-animation*`, `fight-fixed-sizes`...): history, leave. |
| Big files | Already tracked as wave 4 with their owners: `journey_screen.dart` 6,860 lines (a `build` of 1,690), `player_session_provider.dart` 6,232, `sim_combat.dart` (a function of 1,492 lines), `story_player_screen.dart` 4,467 (a `build` of 829). 21 files are over 1,500 lines. |
