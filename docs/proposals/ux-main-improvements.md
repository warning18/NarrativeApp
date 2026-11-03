# UX (main): improvements within my scope

For the manager. Scope: `lib/widgets`, `lib/theme`, pixel icons, `face_style`,
the art generators (`tool/gen_*.py`, `tools/`), `assets/visuals`,
`assets/icons`, the world map and its code. **No new features, no code yet.**
Each item says what, why (the evidence I found), risk, effort, and what the
player would notice. Ranked by value over effort. "Measured" means I ran it
here; "read" means I read the code and did not run it on a device.

What I looked for and did **not** find: unused art. The 686 PNGs are all
reached (by id, by `$name` paths, or by pubspec folders); `tool/qa_unused_assets.py`
lists 5 (the chest `_open.png` icons) and `spoils_chest_dialog.dart:72` builds
that name at run time. The dead-code scan (`tool/qa_unused.py`) lists no unused
widget file in my scope: its "file_only" classes (`ThroneRoom`, `SaveSlotsSheet`,
`ForgeMoment`, `HostSheet` ...) are opened by a `show...()` function in their
own file that other screens call. The Cleanup round already took the four
dead members (`sign_pending`, `ShipCutaway.roomRect`, `deckCrewHeight`;
`hasWalkSprite` kept).

## Ranked list

| # | Item | Removes / smaller / faster | Value | Effort | Risk |
|---|---|---|---|---|---|
| 1 | Sea beast sprites to 64 colours | smaller (-1 MB) | high | S | low |
| 2 | Retire the mock tests of designs already built or dropped | removes | high | S | low |
| 3 | Map: the still-map and fog steps from the performance note | faster | high | M each | medium |
| 4 | Pictures in `docs/`: quantize, stop committing GIFs | smaller repo | medium | S | low |
| 5 | Art generators: one README, delete what cannot reproduce its art | removes | medium | S-M | low |
| 6 | Drop `Spectral-Medium.ttf` | smaller (-171 KB) | low | S | low-medium |
| 7 | Dog sprites shipped but never read | smaller (about -60 KB) | low | S | low |
| 8 | One radar painter instead of two | removes | low | S-M | low |
| 9 | Die widgets: one pass looking for overlap | removes (to check) | unknown | M | medium |

### 1. Sea beast sprites: 1.07 MB to about 0.11 MB (smaller)

- **What.** `assets/visuals/sea_beasts/` holds three PNGs, 840 px wide, true
  colour with alpha: `mother_of_wrecks.png` 523 KB, `deep_leviathan.png`
  379 KB, `drowned_wyrm.png` 198 KB.
- **Why.** They are **62% of all PNG bytes in the app** (1.07 MB of 1.73 MB;
  the other 683 PNGs together are 0.66 MB). They are shaded pixel art with
  13 to 33 thousand colours each, which is what makes them big. Measured with
  ImageMagick `-colors 64 PNG8`: 378,868 to 37,373 B, 197,760 to 22,386 B,
  523,220 to 50,734 B (total 1,099,848 to 110,493 B). I have not looked at the
  pictures after quantizing.
- **Risk.** Banding in the soft shading. I check the three at 64 and, if
  needed, 128 colours next to the originals in a picture before anything
  merges. No generator for them is in the repo, so the originals stay in git
  history only.
- **Effort.** Small: one command per file plus a picture.
- **Player notices.** Nothing, if the check passes. The APK is about 1 MB
  smaller, and the sprites decode faster (they are kept decoded in
  memory, `SeaBeastSprites`).

### 2. Retire the mock tests of designs that are built or dropped (removes)

- **What.** `test/ux_*` is 52 files; the mock, parts and shots files are 48
  of them and about 24,900 lines. The mocks were the pictures shown to the
  user; the designs have since been built (dice, forge, inventory, race and
  profession, companion, star chart, epilogue map, places, intro, journey
  pins) or dropped. Each mock test returns at once unless `UX_SHOTS` is set
  (`ux_dice_mock_test.dart:1861`; the others carry the same guard), so in CI
  they run nothing, but each file is still formatted, analysed and compiled
  in its shard, and each is a place a future change has to keep compiling
  (the Wave 3b merge of the shared mock blocks is that cost already).
- **Why.** The largest: `ux_dice_mock_test.dart` 2,025 lines,
  `ux_journey_pins_mockups_test.dart` 1,739, `ux_companion_mock_parts.dart`
  1,460, `ux_inplace_refined_parts.dart` 1,067, `ux_skills_*` (five mocks plus
  parts, about 3,300 lines), `ux_race_mock_parts.dart` 923,
  `ux_intro_d_mock_test.dart` 921. The pictures they made are already in
  `docs/ux-shots` and in the PRs that built the designs, which is the
  record; the source of a mock adds nothing once its design ships.
- **Keep.** The three tests that run for real (`ux_polish_test`,
  `ux_folds_test`, `ux_sweep_test`) and the shot tools I still use on
  features in progress (`ux_backdrops_*_shots_test`, `ux_map_shots_test`);
  the other `ux_*_shots_test` files go when their feature's build is
  settled.
- **Not measured.** The CI time they cost. QA can measure it with
  `flutter test --reporter json` before and after; I did not.
- **Risk.** Low; they are mine (`ux_*`) and nothing imports them except each
  other (I check with `flutter analyze`). A design that returns later is
  redrawn from the build, not the mock.
- **Effort.** Small: delete files, check `flutter analyze` and the other
  `ux_` tests still compile.
- **Player notices.** Nothing.

### 3. World map performance (faster)

The full list is in `docs/proposals/map-performance.md` (on the map branch,
`claude/ux-map-2`). **Read, not measured on a device.** The order I expect,
each a separate PR as you proposed:

1. Keep the painted sphere while nothing moves (a still map costs nothing,
   the party's walk and the weather go on a small layer above).
2. Turn the fog into one cached image (removes a `saveLayer` plus one blurred
   path per reached land and per walked leg from every frame).
3. Cache the place-name layout and the placement result.
4. Thin the names by zoom (the `lod` value exists).
5. Cap the sphere's mesh by its pixel size (free if the user keeps a smaller
   ball).

Step 0 of the work is a timeline capture on the user's phone, so the order
is corrected before anything is built. `ChartMapPainter.shouldRepaint` returns
`true` (line 2412), so today a drag repaints everything 60 times a second.
Risk: medium (fog and labels are the map's look, so each step gets before and
after pictures). Player notices: a smoother sphere, less battery, and a
quieter map at world zoom.

### 4. Pictures in `docs/` (smaller repo)

- **What.** `docs/ux-shots` is 50 MB on disk (the repo's pack is 107 MB);
  `docs` holds 310 PNGs adding up to 66 MB, plus GIFs of 4.1 MB
  (`docs/ux-shots/intro-anim.gif`) and 1.7 MB each (two in
  `docs/maps/fmg-chart/`).
- **Why.** None of it ships in the APK, but every clone and every CI checkout
  pays for it. The shots are screenshots with flat pixel-art colour, which
  quantize well (item 1 went 10 to 1; screenshots will gain less, I have not
  measured them).
- **Proposal.** Quantize the existing ones in a docs-only PR, and from now on
  keep only the pictures a decision needs, as PNG8, no new GIFs (an
  artifact page or the PR description carries an animation). This does not
  shrink git history unless it is rewritten, and I do not propose that.
- **Risk.** Low; docs link by path, and I keep names. **Effort:** small.
  **Player notices:** nothing.

### 5. Art generators (removes; what to keep)

- **What.** Ten scripts, about 3,900 lines: `tool/gen_banners.py`,
  `gen_chapter_art.py`, `gen_fight_fx.py` (977), `gen_fight_heads.py`,
  `gen_hunter_icons.py`, `gen_material_icons.py`, `gen_pixel_fx.py`,
  `gen_skill_icons.py`, `gen_throne_room.py`, `tools/gen_skill_card_icons.py`.
  One of them is named in the docs (`gen_material_icons.py`), none in
  CLAUDE.md, and `git log` shows the same date (2026-10-21) for nine, the day
  they arrived in the repo, so history does not tell which still match their
  output.
- **Overlap I can see.** `gen_fight_fx.py` and `gen_pixel_fx.py` both write
  `assets/visuals/pixel_fx/`, and `gen_throne_room.py` also writes into it.
- **Proposal.** (a) One `tool/README.md`: script, output folder, how to run.
  (b) For each, run it into a temporary folder and compare with the
  checked-in PNGs: identical means keep; different or crashing means the
  checked-in file is the source, and the script goes (the art stays).
  (c) Fold `gen_pixel_fx` into `gen_fight_fx` if the check shows they are
  the same recipe.
- **Risk.** Low: nothing in the app reads a script. **Effort:** S to M
  (ten runs). **Player notices:** nothing. It makes the next person's
  "regenerate the art" a known command.

### 6. `Spectral-Medium.ttf` (smaller, 171 KB)

- **What.** `Spectral` ships Regular, Medium (weight 500) and Italic. Only 10
  places in `lib` ask for `FontWeight.w500`.
- **Why.** Dropping Medium makes those 10 spots Regular; Spectral has no
  bold file, so bold prose is already synthesised from a shipped weight.
- **Risk.** Low-medium: ten texts get slightly lighter, and I would check
  them in pictures before the change. If you prefer no visible change on
  prose, skip this one: it is the smallest gain here.
- **Effort.** Small. **Player notices:** a slightly lighter text in 10 spots.

### 7. Dog sprites that ship but are never read (about 60 KB)

- **What.** `pubspec.yaml` declares whole folders. Of
  `Make_it_with_angel_w/rotations`, `Make_it_with_demon_w/rotations` and
  `Sitting_down/rotations`, the code reads only `south.png`
  (`guide_tour.dart`, `companion_parts.dart`, `empty_state.dart`), so 21 of
  24 files ship unread (about 52 KB). `Fight_-_Attack/animations/Bark/south`
  (6 frames) is declared and read nowhere.
- **Fix.** Declare the one file, or delete the unread ones (I would check
  `tool/gen_fight_heads.py`, which names the dog's attack folder, does not
  need them).
- **Risk.** Low (`test/qa_assets_declared_test.dart` guards the declared
  list). **Effort:** small. **Player notices:** nothing.
- Plus, not shipped but in the repo: the undeclared `Fight_-_Attack`
  rotations and the Bark east/west/north frames, about 58 KB.

### 8. Two radar painters (removes)

`radar_chart.dart` (477 lines) has `RadarChart` and a private
`_RadarPainter`; `clan_radar_chart.dart` (140 lines) has its own private
`_RadarPainter`. `ability_radar.dart` (449 lines) is a third reader. I have
**not** compared them line by line; the proposal is to read the three, and if
the clan one only draws a polygon on axes, build it on `RadarChart` and delete
its painter. **Risk:** low if the pictures match. **Effort:** S to M.
**Player notices:** nothing.

### 9. Die widgets: one look for overlap (to check, not a finding)

`die_3d.dart` 988, `poly_die.dart` 597, `die_art.dart` 552, `d20_roll.dart` 307,
`die_skins.dart` 262, `station_die.dart` 142, `rolling_die.dart` 127: about
3,000 lines for dice, built in several rounds (v1.595 to v1.636). The Wave 3b
`DieBadge`/`CharacterDieBadge` merge is the first slice. I have not looked for
more. I would read them for dead branches and shapes drawn twice and report
before proposing a cut; if you would rather not spend the effort, drop this
item. **Player notices:** nothing, if it is done right.

## Already in hand (for your list)

- **Wave 3b**: `InkPill` replaces the four tag widgets (branch `claude/ux-3b`,
  3f3b0b45, with `test/ink_pill_test.dart`). Needs a version; and your call on
  deleting the four `ux_skills_*_mock` tests (item 2 would cover it: I
  recommend deleting).
- **Map build** (`claude/ux-map-2`, v1.704.0+740 reserved): removes the look
  and shape selectors, the shops layer and the dashed contours. Waiting for
  the user's choice of sphere size.
- **Backdrops** (#658): deleted the old smooth stage painters from
  `fight_backdrop.dart`; anomalies are still drawn the old way (a later
  redraw in pixels, not an improvement item).

## What I would do first

1 and 2 (small each, nothing visible, the largest numbers), then 4, then the
map steps of 3 once the user has chosen the sphere, then 5. 6, 7 and 8 are
small and can ride along with a PR that already touches the same files. 9
only if you want it.
