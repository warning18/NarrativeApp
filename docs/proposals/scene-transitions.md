# Scene transitions: what plays today, and the user's idea of one continuous world

The user said: "Review the scene transitions, for now they do not make sense.
Maybe it would be better to have a single big parallax and adapt the camera
start on it?" Docs and pictures only: no `lib/` change, no version. Pictures in
`docs/ux-shots/transitions/`.

## 1. The transitions that exist today

`transitions-today.png`: one row per hop, the durations read from the code
(`journey_screen.dart`, `stitched_ink.dart`, `arrival_sheet.dart`,
`fight_entrance.dart`, `creation_fade_route.dart`, `land_crossing_screen.dart`,
`scene_versions.dart`). Real pictures where the view could be rendered, boxes
marked "schematic" where I did not render it.

| # | Hop | What plays now |
|---|---|---|
| 1 | story page > map (Continue) | text swaps with a 320 ms fade + 4 % rise (`_nodeTransition`); the map arrives scaled 0.55 > 1 in 360 ms (`_arrive`); chart/place switcher 280 ms |
| 2 | map: district > town > land | town level 320 ms (`_town`), the land by a zoom glide (`_enterZoom`), the door tab 520 ms |
| 3 | map > place view of a site | the same screen redrawn with another painter; no transition of its own found |
| 4 | place/map > land crossing | route push: 180 ms fade + 12 px rise (`InkPageTransitions`); inside, a Bayer dissolve of about 1 s between "versions" |
| 5 | map step > fight | map **jolt** 380 ms (shake + red edges), then the route push 180 ms, then the foe's entrance card 1200 ms |
| 6 | crossing > fight | the route push and the entrance card; no jolt |
| 7 | town chart > street | a side-view scene; versions dissolve into each other |
| 8 | story > detour band | text swap 320 ms; the band is a side-view scene |
| 9 | arrival at a place | the sheet slides up and fades in, 260 ms |
| 10 | road between two places | a flight along the chart road, 1900 ms (the crossing is the same trip on its own screen) |
| 11 | Story tab > Camp | the Camp takes the Story tab's place: a swap |
| 12 | creation > first scene | fade 300 ms in, 1500 ms out |
| 13 | a choice that stays in the place (69 % of them) | page > Continue > map > page, nothing moves (row 13 of the picture, with the count) |

**Where they contradict each other** (red letters on the picture):
- **A. Five ways to "arrive"**: scale-in (360 ms), rise + fade (180 ms), slide +
  fade (260 ms), Bayer dissolve (about 1 s), plain fade (300 / 1500 ms).
- **B. A fight starts two ways**: from the map with a red jolt, from the
  crossing with none.
- **C. The "versions" are shuffled**: `sceneVersionAt` deals the four versions
  of a scene in a seeded order, and `SceneVersions._salt` is random per
  launch. The versions are windows of one scrolling world (version k+1 is the
  land right after version k), but they are shown out of order, so the same place
  does not look the same twice and two neighbours do not look like neighbours.
- **D. Same place, still through the map**: Core's `scene-vs-map-flow.md`
  counts 729 of the story's 1,061 choices (69 %) staying in the place, yet each
  goes story page > Continue > map > story page.
- **E. Two ways to travel**: a long road is a crossing screen of its own, a
  short one is a flight on the map.

**For the user, to choose** (I cannot tell which one bothers them most): which
of A to E, and which hops of the 12, feel wrong? My guess is D and C (the same
place reached by Continue > map > page, and a place that looks different each
visit), then A.

## 2. The user's idea, drawn

`world-parallax-panorama.png`: **one continuous world per region** (land, sea).
It is the app's own side-view kits (`desert_kit`, `ruins_kit`, `fen_kit`,
`frost_kit`), real layers rendered from code, laid end to end with a 160 px
horizon blend at each border (desert > ruins > fen > frost). The camera window
is the phone's 320 px, shown at three positions: settled at a place, travelling
between two biomes, settled at the far place. Each place or stop of a route has an
x on the strip.

`world-parallax-storyboard.png`: **one transition in six frames** (desert place
A > ruins place B). The kit layers are real (near ground fast, far mesas slow,
the blend painted by a column mask); the cards and the sheet are drawn over.

1. story text is a card over the camera at A; the choice is tapped;
2. the card fades (today's 320 ms text fade) and the camera starts to scroll;
3. travelling: parallax, a "route" chip names where it goes;
4. the horizon blend: sky first, over the 160 px, instead of a random cut;
5. the camera eases to B's x (like the map's 360 ms arrival);
6. the arrival sheet slides up 260 ms, over a world that is already there.

**What happens to**
- **The story page text**: a card over the camera, as in frame 1 (the scene *is*
  the world). A page with no scene behind it (the prologue, an ending) keeps
  today's plain page.
- **The map**: stays for moving and for towns. From the camera, the map is a
  pull-out (the camera zooms out into the chart, the same glide as `_enterZoom`)
  rather than a swap. A city chart is still a town's inside: the camera settles
  at the town's x, and the chart opens as today's arrival.
- **Fights**: keep their own stage (`fight_pixel_stage.dart`) but dressed with
  the kit of the camera's x, frozen, and one entrance for all (the same short
  camera shake whether the fight comes from the map or the road; today's red jolt
  and the none are contradiction B).
- **Reduced motion**: a cut. The camera is at the destination's x, no scroll,
  no blend (a one-frame swap), the arrival sheet appears without sliding.
- **The versions** become fixed x windows of the strip: window 1, 2, 3, 4 are
  four places along the way, in order, the same on every launch.

## 3. What it would cost, and what it breaks

- **Art**: none. The layers are painted by code as a function of scroll, so the
  world is seamless and needs no big textures; four kits already exist (and
  `cliffs_kit`, `sea_kit`). New: a blend layer between two kits (the picture is
  that, as a column mask) and a camera object that holds x.
- **From Core**: a map from each place or route stop to an x on its region's
  strip, from the geography (places have chart positions; routes have a `biome`
  and a `terrain`, `land_routes.json`) plus an order of the biomes along the
  strip, and the sea as a second strip. A data table of a few dozen rows, not
  logic.
- **From Narrative**: nothing, no text changes.
- **Breaks**: `scene_versions.dart` and its test (random order and salt go);
  every side-view scene gets a camera x instead of a version; the land
  crossing's own dissolve; the five "arrive" idioms are replaced by two (the
  camera settling, the sheet). Tests that look for the Continue page > map
  steps change only if the flow changes (contradiction D is Core's rule from
  `scene-vs-map-flow.md`, not decided by this idea).
- **Perf**: the user's slow-frames numbers are still pending. What I can say is
  what the extra layers would cost, measured only as the time Dart takes to
  record one frame of a kit (debug VM on the build machine, 360 x 216, 300
  frames, not a phone and not the GPU): desert 6.0 ms (7 layers), ruins 4.8 ms
  (6), fen 3.6 ms (6), frost 3.7 ms (6). A blend between two kits paints both,
  so the border costs the sum of the two (about 8 to 11 ms in the same units),
  which is what today's dissolve already costs; away from a border the camera
  paints one kit, as a scene does today. Those are relative numbers only: the real
  cost is the slow-frames meter's on a phone.

## 4. Open questions for the user

1. Which hops (1 to 12) and which contradictions (A to E) bother you most?
2. Do you want the crossing and the map's flight to become one thing (the camera
   travelling), or only the same look?
3. Should a town keep its chart (a town is where the camera stops and the chart
   opens), or should towns also be a scene on the strip?

## 5. Update: what a run of scenes in one place should look like (for Core's v1.809)

Core read the code against main 1.808
(`docs/proposals/scene-flow-status-and-strip.md`, branch `claude/core-flow-note`):
the rule "a choice that stays in the place keeps you in the scene" was built as
a classification (`StoryStops`, `FlowStay` / `FlowMap` / `FlowTripThenArrive` /
`FlowReturnToHub`) but `_take` still opens the next scene and brings the map
back with Continue after every choice that moves the story. The user told Core
to finish that rule (logic only); this is the look it lands on, so I add it.

`same-place-run.png` (real pages of scenes 2005 and 2020, both at the Landward
Gate; the beat frame and the echo line are drawn over real pictures):

- **Today** (also row 13 of `transitions-today.png`): scene 2005, tap the card,
  scene 2020 full screen with Continue, the map, the page again: 4 views and 3
  hops for one tap, while the party has not moved (729 of 1,061 choices).
- **Proposed**: the scene view holds the run. The tap lights the card; a **200 ms
  beat** cross-fades the text and the cards (the stage with its figures stays,
  the crumbs stay, the top bar's map button stays); a **one-line echo** of the
  choice just taken ("Vous vous cachez dans un chariot de sel.") rides the beat
  and fades, so the thread is not lost. The map comes only when a card *moves*
  the party (a pin, as "Entrer avec la caravane"), then the arrival sheet.
- **Replace or append**: replace with the echo (shown). Appending (a log that
  grows) keeps the thread by itself but makes the page grow; it suits a long
  hub, not a short run.
- **Reduced motion**: a cut, no beat, the echo line shows still for a second.
- **Decision for the user**: the 200 ms beat and the echo line are my proposal;
  "no beat, no echo" (a straight swap) is the cheaper alternative.

## 6. Core's strip data, read (in case the parallax goes ahead)

The user has said **not yet** to the position strip. I read Core's note for it
anyway: a pure file (`lib/data/region_strip.dart`, 200 to 300 lines, a test, low
risk, changes no existing code) derived from `StoryStops`,
`Geography.placeOfNode`, `ancestorAt(zone|country)`, the landmarks' chart
positions, `world_roads` and `world_leg_path`: a region is a strip of stops
placed by road distance, districts spread around their town. What it settles for
my side: the camera's x for "arriving" is a stop's `at`, and for "travelling" the
projection of `world_leg_path` on the strip (`pathOn`). Three choices it leaves
to the user (zone or country as the region; true road distances or even steps;
districts in plan order or story order): for the camera, **road distances** feel
right (the scroll is proportional to the walk), **zone** is the region (a
country is too long for four kits), and **districts in story order** (the camera
visits them in the order the player does). Nothing to build now.

## 7. After #789 (v1.809): what the look still lacks, and the smallest PR

Read from the diff of #789 and `journey_panels.dart` on main: same-place
choices are now cards on the page and keep the page or the sheet
(`arrivalViewOf(..., current:)`, `onCard` for `FlowStay`); no map in between.
Core built no look. Against my `same-place-run.png`:

| In my picture | State on main |
|---|---|
| **the 200 ms beat** (cross-fade of text and cards) | **mostly there already**: a new scene's words "come out of the ink, top to bottom" (`StoryText(revealKey)` in `journey_panels.dart`), so the text has its own beat. What is not covered: the stage and the card list swap with no beat (a cut). Optional. |
| **the one-line echo of the choice taken** | **missing**. (`EchoLine` in the same file is something else: the consequences of earlier choices, "because ...". I would not reuse the word "echo": call it the "taken" line.) |
| **a "still in <place>" line** | **missing**. The crumbs name the place, and a one-tap return to a hub has its "You came back to ..." notice, but nothing says "nothing moved" after a same-place card. |

`same-place-look-v1810.png`: scene 2005 (the card is tapped); 2020 as v1.809
shows it; and 2020 with the two lines drawn over the real page.

**Smallest UX PR (v1.810 provisional, not built, the user decides after
hand-testing 1.809):**
1. A **taken line** above the new scene's words when the step was a same-place
   card: the choice's own text in a small italic gold line with a "›" (no new
   string: the choice text is already in the language read). It stays until the
   next step (no timer) and scrolls with the text.
2. A **still-in line** under it: "Toujours : {place}" / "Still at {place}": **2
   new strings** (Narrative to word), the place being the crumbs' last name.
   Shown only after a same-place step, never after a move or a hub return (that
   has its own notice).
3. Optional, separate: a 200 ms cross-fade of the stage and the cards
   (`AnimatedSwitcher` keyed by the node), a cut under reduced motion.

Files: `lib/screens/journey/journey_panels.dart` (the two lines, about 30
lines), `journey_screen.dart` (remember the taken choice and the flow in `_take`,
clear it on a map or hub move: about 10 lines, shared file, Core's `_take`),
`app_strings.dart` (2 strings). Test: the lines show after a same-place card
and not after a move, at 320 px French. No data, no assets.
