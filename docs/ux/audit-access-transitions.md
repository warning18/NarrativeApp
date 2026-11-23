# UX audit: access and transitions (UX-2, November 2026, main v1.993)

Docs only: nothing in the app changed. Nothing here is built until the user picks.

**How it was checked.** Three passes: (1) a survey of `lib/` by search (routes, back handling,
durations, curves, dialogs, tap sizes, rebuild breadth, duplicated widgets); (2) a read of each
hit in context to drop false alarms; (3) a fresh read of the ranked list against the code, plus
Maps' review items that sit in UX's area. The 37 `test/ux_*_test.dart` files (160 tests, 3 skipped
picture tests) were run three times: **94 s, 75 s, 76 s** (the first run compiles), all
`+157 ~3`, so **no flaky test**.

**Not covered:** a real phone (no frame times, no TalkBack), the camp cliff town, a full screen
reader pass. Every number below is a count in the code, not a measurement on a device.

## What is already right

- One page transition for the whole app (`InkPageTransitions`, 180 ms fade + 12 px rise, reduced
  motion respected). 90 places read the reduce-motion setting.
- Motion tokens exist (`Motion.fast/base/slow` = 160/240/400 ms) and curves are few: easeInOut 24,
  easeOutCubic 23, easeOut 22, easeIn 11, easeOutBack 8.
- Fight, death, voyage, expedition, land crossing and origin stories guard back with `PopScope`.

## Findings, ranked by what the player gains against the work

### 1. Android back leaves the Journey from any map level (needs the user's choice; M)
Maps' item 6. From a room or district, back goes to the title; only the pushed map pages close.
`journey_screen.dart` has no `PopScope`. Proposal: back climbs one rung (Room, District, Town,
World) and leaves from the World. One shared handler, no new screen. Same rule for any screen
with an inner level (Skills tabs, Inventory tabs): check each when built.
Before/after picture: a short sequence strip at 360 wide, to be made with the build.

### 2. A dim or busy control says nothing when tapped (quick win; S)
`level_ladder.dart:83`: a closed rung has `onTap: null`, so nothing moves and nothing is said.
Proposal: a closed rung shows a one-line snackbar or tooltip naming why ("No town plan here").
Same pattern wherever `onTap: null` is used on an `InkWell` the player can see (to list when
built). Needs a string key per reason (Narrative may word them).

### 3. Tap targets under 44 dp in the Journey screen (S; needs pictures)
Maps' item 4: the district row is 37 dp high, the city-plan icon 40, the level strip 36 (kept for
a 360 x 640 phone). Fix: pad the hit area to 44 without changing the drawn size (an invisible
extension), so no layout moves. Also in the code: 57 `visualDensity.compact` or `shrinkWrap`
tap-size overrides, to check one by one (a shrinkWrap on a 24 dp icon is a 24 dp target).

### 4. The weather line covers the foot of the plan (S, needs pictures)
Maps' item 7. In `journey_screen.dart` the line takes two rows and sits on the plan; the building
name shows through it. Proposal: one row, shorter text, or move it under the map beside the strip.

### 5. The path above the map is cut on the left (S)
Maps' item 13. Make the breadcrumb scroll to its end, or ellipsise the middle and keep the last two
names. No layout change.

### 6. Parchment ink for unreached land names (S; colour is UX's)
Maps' item 5: contrast 2.3 on Parchment (floor for large text is 3, readable text 4.5). Proposal:
a darker Parchment ink for names (one palette token); Maps raises the strength to 75-85 %.

### 7. 171 raw `Duration(...)` against 35 `Motion.*` uses (M, no visible change at first)
A second motion system has grown beside the tokens: odd values (120, 420, 520, 550, 700, 900, 950,
1400, 1500 ms) repeated in `screens/` and `widgets/`. Proposal, the **motion system**: add
`Motion.instant` (80), `Motion.pulse` (900, looping effects) and `Motion.story` (1400, story
beats); move the repeated values onto the tokens; leave one-off effect timings (VFX, fight)
alone. Curves: keep three (easeOutCubic in, easeInCubic out, easeInOut for loops) and retire
easeOutBack/elasticOut outside the dice and the gift reveal.

### 8. Sheets and dialogs: three scaffolds for one idea (M)
47 `showDialog`, 38 `AlertDialog`, 8 `showModalBottomSheet` (6 with a drag handle or a draggable
sheet). The story-plate dialogs (`StoryPlate`, `StoryFrame`) and plain `AlertDialog`s coexist:
a few dialogs look like the Ink kit, most do not. Proposal: one `InkDialog` and one `InkSheet`
wrapper with the kit's frame, title row, close icon and 44 dp actions; convert by screen in the
batches below, not in one sweep. No behaviour change.

### 9. Accessibility labels (S per screen)
163 `Semantics`/`semanticLabel`/`tooltip` uses in `screens/` and `widgets/`; 77 `IconButton`s, nearly
all with a tooltip nearby (a rough count): icon buttons are mostly covered. The gap is the 52
`GestureDetector`/`InkWell` tiles (cards, chips, plates): to be labelled as they are touched,
screen by screen. Check TalkBack on a real phone (not possible in this container).

### 10. Performance: where a screen rebuilds more than it needs (M each; measure first)
- `journey_screen.dart` is 6146 lines with 36 `setState` calls; `journey_world_map.dart` 10.
  Maps' item 1 (turning the ball redraws the whole screen, 18 ms against 4.8 ms) and items 10 and
  11 (ground pictures kept for ever; the idle ring redraws) are the measured part of this. They are
  Maps' to build; the Journey screen's own `setState` breadth is Core's/UX's, to split after.
- 88 `ref.watch(playerSessionProvider)` whole-session watches (character screen 7, play 5, journey
  4, offer dialog 3, journal 3). Each rebuilds on any change to the session. Proposal: `select`
  the fields used. Check with a rebuild counter before and after; likely a small gain except in
  the character screen and the Journey.

### 11. Duplicated widgets (S each; picked up with the batches)
The `_SectionHeader`, `_SectionTitle` and `_CollapsibleSection` classes exist as private copies;
`_ZoneChip`, `_BiomeChip`, `_BonusChip`, `_CostChip`, `_ElementChip`, `_HolderChip`, `_SkillChip`,
`_StatusEffectChip`, `_SceneChip`, `_RungChip` and `_PixelChip` are private chip variants in 11
files. Proposal: one `InkChip` (icon, label, tone, optional 44 dp hit area) in `lib/widgets/`; move
the chips whose look already matches, leave the rest. Cleanup may privatise or delete the unused
ones meanwhile (their wave 2).

## Smaller things (not ranked)

- A place with no plan shows a dotted field (Maps' open question); the ground mixes pixel trees
  with soft coasts (Maps' open question of one look for all maps): both Maps' with the user.
- The epilogue map is not readable on a phone (Maps' item 8): Maps'.
- "Town" offered on the World where the place has no town plan (Maps' item 2): Maps'.

## PR-sized batches, if the user says go

| Batch | Contents | Needs | Touches another area |
|---|---|---|---|
| A. Reach (1.5 days) | 2 (dim rung says why), 3 (44 dp hit areas), 5 (breadcrumb), 6 (Parchment ink) | pictures | `level_ladder.dart`, Maps' strings (Narrative) |
| B. Back (1 day) | 1, one `PopScope` handler for the Journey and inner-level screens | the user's choice | Journey is Core's/Maps': a few lines |
| C. Motion (1.5 days) | 7 tokens and curves, 4 weather line | none | none |
| D. Kit (3 days, in steps) | 8 `InkDialog`/`InkSheet`, 11 `InkChip`, 9 labels | pictures for the first of each | none |

Performance (10) goes to the owners: the ball to Maps, the Journey `setState` split to Core, the
`select` pass to UX in batch D.

## Pictures

Before/after pictures at 360 wide for the top ten are drawn with each batch's picture-first step
(the user picks which batches first); drawing them now, before the choices, would be pictures of
changes nobody has asked for.
