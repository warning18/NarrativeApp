# Chapter 1 review: UX's part (v1.606)

Read-only review of main at v1.606.0 (56df5feb) of the screens UX owns, as a
player meets them in chapter 1 (Alster to the White Wells). Nothing here is
fixed; the user ranks first. The Journey correction (v1.607, #586) is not in
this note: its before/after pictures are in `docs/ux-shots/journey-fix/`.

**How it was done.** A static audit of `lib/widgets`, `lib/theme`,
`lib/screens` and `assets/` (greps for unused classes, unbundled folders,
dead taps, animations, image decoding), plus the phone-width pictures and
tests that already exist: UX's (`docs/ux-shots/`, 320 and 412 px, English and
French, the app's own fonts) and QA's (`docs/qa/smoke/`,
`test/qa_smoke_ch1_test.dart`: intro, race and profession, Vica's page, the
Party formation, the inventory with its Dice tab, at 412, 360 and 320 px, both
languages, no overflow). **Not done:** no new screen-by-screen walk was run for
this note; where a screen has no picture at a size, the line says so.

**Severity:** *blocks play* · *confusing* · *cosmetic* · *cleanup*.
**Size:** lines a fix takes.

## 1. Findings

| # | Where | What | Sev. | Size |
|---|---|---|---|---|
| 1 | `pubspec.yaml:105-141`, `lib/widgets/reward_cards.dart:32,108,256` | `assets/visuals/chapters/` (8 art strips, 36 KB) is **not listed in pubspec**, so it is not in the build. The quest reward card (card B, `banner: true` is the default, `quest_turn_in.dart:217`) asks for `chapter_N.png`, fails, and its `errorBuilder` paints a flat tinted block. `reward_card_test` checks the files exist on disk, which passes, so nothing noticed. Every quest-complete card in chapter 1 shows no art. | cosmetic | 1 |
| 2 | `lib/widgets/clan_widgets.dart:702`, `title_widgets.dart:25`, `offer_dialog.dart:1221`, `journey_fx.dart:661` | `ClansSection` (used only by `throne_widgets_test`), `TitlesSection`, `SuitorCard`, `InkReveal`: no use in `lib/`. About 400 lines. Delete with their test lines. | cleanup | ~400 deleted |
| 3 | `lib/widgets/fight_markers.dart:136` and `character_die_badge.dart:21` | Two classes both called a die badge (`DieBadge`, `CharacterDieBadge`) with different looks; plus four private tag/badge widgets that draw the same rounded label (`offer_dialog.dart:1407 _Tag`, `harbor_screen.dart:1017 _Tag`, `choice_card.dart:158 _TagChip`, `companion_remark_bubble.dart:270 _Badge`). One small `LabelTag` in `sheet_kit.dart` would serve all. | cleanup | ~80 |
| 4 | `lib/widgets/companion_remark_bubble.dart:149`, `lib/tutorial/guide_tour.dart:423` | The typewriter calls `setState` every 16 ms for the whole bubble/tour card, one char per tick (about 60 rebuilds a second while a line writes). Fine on a phone today; it is the first thing to jank if a bubble ever holds a big child. Step by 2 chars, or repaint only the text with a `ValueNotifier`. | cleanup | 15 |
| 5 | `lib/widgets/city_chart/city_chart_view.dart:226`, `lib/widgets/fight_figure.dart:117` | `.repeat()` starts when the caller's `animate` is true; only `journey_screen.dart` (10 sites), `pixel_sprite.dart`, `feature_unlock.dart` and `ship_yard.dart` read `MediaQuery.disableAnimations` themselves. I did not trace whether every caller passes it; if one does not, a player with reduced motion still sees the breathing chart and the idle fighters. Needs a 10-minute check, then one line each. | confusing | 2-4 |
| 6 | `lib/screens/companion_page.dart:166`, `app_strings.dart:4814` | Vica's page subtitle reads "Guide dog" / "Chien guide" for `isGuideDog`. It is true (Vica is the dog) and the only "dog" label left; the old trot strip, its Settings toggle and strings are gone (grep for `walk_companion`, `trot`: nothing). Decide with Narrative whether the subtitle should name her role instead. | cosmetic | 2 strings |
| 7 | Inventory, 320 px, French (QA's picture) | The equipment slot "Dé porte-bo…" is cut with an ellipsis and the tab row scrolls, so the **Dice tab is off-screen until dragged**. Readable, but the tab that holds the dice is the one hidden. Shorter tab labels at 320 (icon + word only for the selected tab) or an end fade on the row. | confusing | 20 |
| 8 | Race and profession, French (#582, QA) | The granted skill is shown as "Resolve" / "Shield Bash" under Humain and Guerrier: the name is built from the id, not read from `skills.json` (`name_fr`). Core's helper `grantedSkillName`; the widget only needs to call the localized table. | confusing | 5 |
| 9 | Fight screen, 320 px | The fight is **not** fixed-size yet: hero, allies and enemy boxes grow with their art and cards. The proposal `docs/proposals/fight-fixed-sizes.md` (merged #571) waits for three answers (do bosses get a bigger box, do allies stand in a back row, slim cards?). Not measured at 320 px here. | confusing | 120-200 after the answers |
| 10 | Intro, `docs/ux-shots/intro-anim.gif` (3.9 MB) and `docs/ux-shots/intro-build/` (1.5 MB) | The "4 MB intro frames" are in **docs only**, not in the app: the intro is drawn in code (`intro_art.dart`, `street_view.dart`), nothing is decoded. `assets/` is 2.5 MB of art in all (the biggest file is 523 KB). The git weight is `docs/ux-shots` at 39 MB, most of it pictures of old mock-ups. | cleanup | prune old pictures |
| 11 | 14 `Image.asset` sites, none with `cacheWidth`/`cacheHeight` | All art is small pixel art (largest `sea_beasts/mother_of_wrecks.png` 840 x 672, chapter 7 only), so no image is decoded much larger than it is drawn. Nothing to fix now; add a `cacheWidth` if bigger art is ever added. | cleanup | 0 |
| 12 | `lib/widgets/forge_sheet.dart:489` | The only `onPressed: null` in `lib/` is the forge button when something is missing; its label names what (`lacking`). Not a dead control. | none | 0 |
| 13 | `lib/screens/journey_screen.dart` (6,709 lines), `story_player_screen.dart` (4,365), `playthrough_simulator_screen.dart` (4,664) | Three files above 4,000 lines. The Journey one starts an idle-glyph controller (line 4061). Splitting would help reading; no jank was measured. | cleanup | large, no hurry |

## 2. Screen by screen

What was looked at, and where the picture is. "Pic" = a picture at 320 and a
wider size exists; "audit" = read only.

- **Intro** (`intro_screen.dart`): pic (QA, UX storyboard). No overflow; a tap
  skips; reduced motion shows the still. Nothing found.
- **Race and profession**: pic, both languages (UX `docs/ux-shots/`, QA). One
  finding, #8.
- **Journey map and list**: v1.607 correction (#586) removed the pop-in text and
  the collapsible list. Pictures at 320 and 412 in the PR.
- **Page, street, room, map scenes**: audit plus `qa_story_text_real_font_test`
  (longest scenes, both languages). No finding.
- **Fight**: finding #9; the tips and anomaly chip have real-font tests.
- **Camp Party tab, Vica's page**: pic at 320 and 412, both languages (UX
  `companion-interface.md`, QA). Findings #6.
- **Character** (with the die badge), **inventory and Dice tab**: pic (UX,
  QA). Finding #7.
- **Level-up**: `qa_real_font_layout_test` (320 and 360, both languages). Nothing.
- **Shops**: none in chapter 1 (`chapter1-core.md`); audit only.
- **Settings**: audit only (`smoke-coverage.md` lists it as unpictured). The
  intro "play again" row and the removed dog toggle are the changes since the
  last read.

## 3. Taps, contrast, tap targets

No finding was measured here. `GestureDetector` is used 45 times in
`widgets/` and `screens/`; 35 files set an explicit hit-test behaviour. A
sweep with `tester.getSize` on every tappable at 320 px (target 44 px) would
turn this into numbers; it is a QA-sized job and is not done.

## 4. Suggested order

1. #1 (one pubspec line; quest cards get their art).
2. #7 and #5 (the two that a player can hit in chapter 1).
3. #2, #3 (cleanup, one PR, no change to the screen).
4. #9 when the user answers the three fight questions.
