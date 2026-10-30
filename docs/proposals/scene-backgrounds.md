# Scene backgrounds: more variety, chosen by where the scene is

UX proposal, **approved by the user and built in v1.665.0**: all eight new stages, the choosing ladder and the pools for the temperate country. The fights' backdrops are now in the scenes' pixel style (`lib/widgets/fight_pixel_stage.dart`), and every scene has four versions (`lib/widgets/side_view/scene_versions.dart`) shown one after the other in a seeded order, with a pixel dissolve between them. Still to do: Core's mapping table and the road crossing passing its stage (the ladder's steps 2 to 4), Narrative's `forcedStage` table (step 1), the anomalies redrawn in pixels.
The user's words: the backgrounds behind the fight setup, the fight and the
scenes (green hills, trees, a road) are too uniform; add diversity matching the
texts and situations of detours, expeditions and so on, for example more
desert.

Pictures (all drawn by the app's own painter recipe, phone shape):

- `docs/ux-shots/backgrounds/today-stages.png`: the 11 stages the app draws today.
- `docs/ux-shots/backgrounds/new-stages.png`: 8 proposed new stages.
- `docs/ux-shots/backgrounds/examples.png`: three scenes, today on the left,
  the proposal on the right.

## What is there today

`lib/widgets/fight_backdrop.dart` already draws **11 stages**: fields, dunes
(desert), salt flats, waves, ash, terraces, cliffs, reeds (marsh), snow, glass
and hall. Over any of them it can lay the sky (cloud, fog, rain, snow, dust,
ash) and the light (dusk, night, dark), and the anomalies. So desert, salt
flats, marsh, frost, cliffs, night and rain **already exist as pictures**.

## Why it still looks like green hills

The screenshot's "Open country" is the `fields` stage. It comes up because the
stage is picked only from the place the *story* stands at, and most fights do
not ask anything more specific:

1. **Road fights never ask.** `land_crossing_screen.dart:351` opens the fight
   with no stage at all, so a fight on the desert road (or the fen, or the
   frost) is drawn on the hills of wherever the story happens to be. The routes
   know better: `land_routes.json` writes a `biome` and a `terrain` on each
   (`desert`, `ashlands` / `ruins`, `fen`, `frost`, `sea_cliffs`).
2. **No story choice names a stage.** The `forcedStage` field on a choice
   exists (`story_node.dart`) and is written **0 times** in the narrative DAG.
3. **The pool is thin where the story spends its time.** Of 95 story fights,
   a loose keyword count on the scene text finds ash in about 15, cliffs in 12,
   ruins in 11, a quay or dock in 11, dunes in 9, snow in 7 (54 of the 95 name
   some terrain; some are only a name or a figure of speech). Ruins and quays have no stage of their own;
   the temperate country has one picture (fields) for every hill, wood, ford
   and burnt farm of the Crusade's first fires.
4. **Detours and expeditions** do carry the information (`detour_scenes.json`
   `where` is a biome or a place; each zone has a `location` and a `mapTheme`),
   but only the expedition's `location` is used.

So the fix is two things: **choose better** and **draw a few more**.

## Eight new stages (`new-stages.png`)

| Stage | For | Why |
|---|---|---|
| ruins | the gutted town, burnt quarters, ruin routes | 11 fight texts, the `ruins` route terrain, the Ashen Streets zones |
| woods | the hill woods (oak), the temperate country | breaks up fields; the biome text names oaks and hill woods |
| ford | rivers and the Stone Bridge | the temperate biome's quick rivers |
| burnt fields | the country the Crusade burned first | same biome, a sadder face |
| oasis | the White Wells, wells and pools in the dunes | the desert text's date palms |
| caravan road | the salt roads and the desert routes | the Salt Roads zones, the desert routes |
| quay | harbours and docks (Saltmouth, the Cove) | 11 fight texts name a quay |
| pass | mountain passes and the road to the court | a land with rock and a road |

Night, dusk and rain are **not** stages: they are the light and the sky laid
over any of them (see the ruins at night and the cliffs in the rain in
`examples.png`), and they are already wired.

## How a scene gets its stage (most specific first)

1. **The scene says so.** A choice's `forcedStage` (exists; Narrative writes it
   where the text names a terrain, for example the ruined quarter).
2. **The road being crossed.** The route's `terrain`, then its `biome` (exists
   in `land_routes.json`). *Needs the crossing to pass it to the fight.*
3. **The detour's `where`.** A `biome` or a `place` (exists).
4. **The expedition.** The zone's `location` (used today), then its `mapTheme`
   (`saltRoads` is the caravan road, `ashenStreets` the ruins, and so on).
5. **The place the story stands at.** The place's `stage`, then its biome's
   pattern (today's rule, kept).
6. **Fields**, as now.

To keep one biome from always looking the same, a biome may have a **pool**:
the temperate country draws from fields, woods, ford and burnt fields, picked
by the node or place id so that the same place always looks the same (no flicker
between visits).

## Needs

- **Core:**
  - The road crossing passes `forcedStage` (the route's terrain or biome) to its
    fight (`land_crossing_screen.dart`, a few lines; I can do them if you prefer,
    it is a shared screen).
  - A mapping table from route terrain and zone `mapTheme` to a stage, next to
    `fightStageOf` in `lib/combat/field_anomaly.dart`.
  - New stages need rows in the anomaly table (`FieldAnomaly.stages` lists which
    stages an anomaly can come on); which anomalies fit a ruin or a quay is your
    call.
- **Narrative:** optionally write `forcedStage` on the fight choices whose text
  names a terrain (a loose count finds 54 of the 95 fight scenes with a terrain
  word, so the real list needs a read). I can hand over the node ids with the
  stage the text suggests, as a table to check; I do not edit the DAG.
- **UX (me):** the new stage painters in `fight_backdrop.dart`, the pool, tests,
  and pictures of the real screens.

## What to choose

1. **Which new stages:** all eight, or which? (Ruins and quay have the most
   texts waiting.)
2. **The ladder** above as it stands, or with a step left out?
3. **Pools** for the temperate country, yes or no?

## Sources

The pictures come from `test/ux_stage_sheet_test.dart` (today's stages, the real
painter) and `test/ux_stage_variants_shots_test.dart` with
`test/ux_stage_variants_parts.dart` (the new ones, mock painters in the same
recipe). Run with `UX_SHOTS=<folder>`. The mock painters ship nothing.
