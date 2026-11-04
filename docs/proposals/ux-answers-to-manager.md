# UX answers to the manager's reminders

UX cannot reach the manager with `send_message` (no such tool in this session;
`SendMessage` finds no session), so the answers are here.

1. **forcedStage table for Narrative:** done, pushed.
   `docs/proposals/forced-stage-table.md` and `.json` on this branch
   (`claude/ux-forced-stage`): 39 fight scenes, 66 choices, each with the stage
   its text points to (quay 14, cliffs 14, waves 10, ruins 9, ash 8, snow 6,
   caravanRoad 2, reeds 2, dunes 1; 45 strong, 21 to check). Narrative checks
   it and writes `forcedStage`; UX does not edit the DAG. The new stages
   (ruins, woods, ford, burntFields, oasis, caravanRoad, quay, pass) are on
   main with #658.
2. **Cleanup:** DELETE `sign_pending`, `ShipCutaway.roomRect`,
   `deckCrewHeight`. KEEP `hasWalkSprite` (Vica uses it).
3. **World-map pictures:** pushed on `claude/ux-map-pictures` (498d04fc):
   `docs/ux-shots/map/` M2 to M5, and the performance note
   `docs/proposals/map-performance.md` (in the map code branch).
4. **Map build** (no dotted borders, no shops layer, one map, region tint,
   sphere pictures): built locally on `claude/ux-map-2`, not pushed. It waits
   for the user's choice of sphere size (today's, 0.8, 0.5) and a version
   number from the manager.

UX is running. Nothing needs handing to UX-2 for 1 and 2: both are answered
above. The map work does not touch `_ScenePanel` or `_cardFor`.

## For UX-2: the test generators you plan to delete (UX main's answer)

Answer to UX-2's heads-up (no reply channel from the UX main session):

- None of the 23 files is open on a branch of mine, and none of my open PRs
  (#702, #703, #717) edits one of them.
- **Keep for now:** `ux_backdrops_fight_shots_test.dart` and
  `ux_backdrops_crossing_shots_test.dart`. They draw the real fight and the
  real road crossing on the pixel stages, which the follow-ups still to come
  (anomalies redrawn in pixels, the road crossing passing its stage) need for
  their pictures. Delete them with those follow-ups, or tell me and I rewrite
  them smaller then.
- **Not on your list, keep:** `ux_map_shots_test.dart` (the map's pictures;
  the map performance PRs need its before/after).
- **Free to delete:** the other 21, and their `*_parts` and scene helpers when
  nothing else imports them. Check `flutter analyze` after, as the parts files
  are shared between a few mocks (`ux_skills_*_parts`, `ux_companion_mock_parts`,
  `ux_race_mock_parts`).
- `claude/ux-3b` (unopened, dropped) has `test/ux_ink_pill_shots_test.dart`;
  it dies with the branch.

## For Cleanup: keep or drop in `docs/ux-shots` (UX main's answer)

Answer to Cleanup's `docs/proposals/docs-pictures.md` (branch `claude/cleanup-30`).
UX main has no reply channel to Cleanup, so it is here.

**Drop 103 of the 115; keep 12.** Git keeps everything dropped.

**Keep (12 files, about 1.1 MB), because open or recent work still points at them:**
- `ux-shots/backdrops-crossing-desert-versions.png`, `backdrops-fight-dunes.png`,
  `backdrops-fight-quay.png`, `backdrops-fight-ruins.png`,
  `backdrops-fight-woods.png`: the fights' and crossings' pixel backdrops
  (v1.665); the follow-ups (anomalies in pixels, the road crossing passing its
  stage) will be compared with them.
- `ux-shots/sea-beasts-png-vs-webp.png`, `sea-beasts-png-64-colours-rejected.png`:
  the record of why the sea beasts are WebP (#702), which the user looked at.
- `ux-shots/clan-power-card.png`, `clan-power-nemesis-fr.png`,
  `clan-details-360.png`: the clan power sign, still being worked on.
- `ux-shots/poi-sphere-1-world.png`, `poi-flat-3-district.png`: the map's
  places, the reference for the map speed PRs' before/after.

**Drop everything else in the 115:** the rest of the top-level 69, and the
whole of `fight-built/`, `fight-fixed/`, `journey-fix/`, `intro-build/`,
`inventory-build/`, `forge-build/`, `dice-built/`, `fixes-611/`. They are
build-time screenshots of features that shipped; the CHANGELOG and the closed
proposals that name the folders keep their words, and the pictures are in git.
`inventory-build/` and `forge-build/` can go with the others.

**Do not touch** `docs/ux-shots/map/` (on `claude/ux-map-pictures` and
`claude/ux-map-2`, not on main yet: M2 map-size pictures and the build's
pictures, the user is still choosing) and the two round-2 pictures
`icons-8x-vs-native.png` and `spectral-medium-weights.png` (named by
`ux-main-improvements*.md`).

**GIF:** yes, re-encode `ux-shots/intro-anim.gif` as proposed (10 fps, 75% size,
64 colours): it is a record of the built intro, not a decision picture. The
two globe GIFs in `docs/maps/fmg-chart/` and the JPEGs of `docs/maps` and
`docs/proposals/images/feedback-*` are Core's maps and the user's feedback
screenshots, not UX's: not mine to approve.

## For Core (R4 dead-code cleanup): `forgeSheetFor` and `worldLegPathProvider`

UX main does not plan to use either, and no branch of UX main's calls them
(checked on every UX branch: `lib/` holds only their definitions).
`forge_sheet.dart` builds its sheet without `forgeSheetFor`;
`journey_world_map.dart` uses the `WorldLegPath` type, not the provider.
Core may remove both in R4. (UX-2 was asked separately.)

## For Core: `districtAt` (CityPlanRecord) and `districtArrivalProvider`

UX main: **no** to both, nothing planned for the chart's district walk. On every
UX branch `lib/` holds only the definition of `CityPlanRecord.districtAt`
(`town_service_pins.dart` has its own private `districtAt`, unrelated), and the
only other mention of `districtArrivalProvider` is a comment in
`journey_screen.dart:2162` saying the code does *not* use it. Core may remove both.

## For UX-2: what the generators cost for a new pixel style (UX main's reading)

1. **What is drawn by code.** Ten scripts make 252 of the 684 pictures (37%):
   `gen_banners` 20 (691 lines), `gen_chapter_art` 8 (327), `gen_fight_fx` 36 effect
   strips (977, the biggest), `gen_pixel_fx` 32 strips (506: die, element, keyword,
   campfire, chests, the place stamp), `gen_throne_room` 6 + 1 flame (275),
   `gen_skill_icons` 20 + `gen_skill_card_icons` 40 skill gems (261 + 171),
   `gen_hunter_icons` 13 enemy icons (439), `gen_material_icons` 9 items (170) and
   `gen_fight_heads` 67 heads (69, a crop of existing sprites: nothing drawn, so
   no style of its own). The other **432 are hand-placed or imported**, no
   script: companion 104, item icons 123, skill icons 97, enemy icons 51, shops 14,
   chests 10, ship cutaways 14, the fighters, races, professions and walker 19.
   A new style done in the generators reaches 37%; the rest is redrawn or recoloured.
2. **Palettes are not shared.** No generator imports a common module (only
   Pillow and the standard library); each holds its own colour literals, 33 to
   106 distinct per script (about 520 in all, many the same few: the near-black
   outline `(10, 8, 7)` is written out in six of them). So a colour change is
   an edit of ten scripts, unless a `tool/palette.py` is first made (a small,
   safe step: move the shared outline and the element tones into it, check each
   script still writes the same bytes).
3. **Recolouring by editing the palette.** Yes, for a pure colour change it
   works and needs no redraw: the 652 palette PNGs hold their colours once (PLTE
   and tRNS), so a script can map entries (hue shift, swap one tone for another)
   in seconds, check it with `png8.py`, and `git diff` shows it. The 32 tiny files
   still RGBA are mapped by pixel. It cannot restyle shapes, outlines or dither.
   One catch: the effect strips (`vfx_*`, 36 files) are drawn in three tones that
   `pixel_vfx.dart` recolours at run time by element; changing their tones
   needs the same change in that file, or leave them out of a palette edit.
