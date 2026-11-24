# Maps review, November 2026

Every map the player sees, from the room plan to the globe, on v1.992. Three passes (find, verify, fresh
eyes), the map tests three times, then a self-review. Nothing in the app changed: docs and pictures only.

**How it was checked.** Real screens of the app rendered by a throw-away test from four places (Alster,
Saltmouth, the Ashen Quarter, and a mid-game save at the Spire of Judgment), 412 dark, 412 light and
360 in French. The same test measured tap sizes, what is redrawn while nothing is touched, and frame
times. `measures.txt` holds the raw lines. Frame times are from this container's processor in a test
build: they compare one map with another and do not say how smooth a phone is.

**Not covered:** a real phone, the camp's cliff town, Edit Mode's world map page, a move along a road.

## Tests, three times

The 14 map test files (`chart_*`, `city_chart_*`, `room_plan_*`, `map_*`, `full_map_*`), 101 tests:
**78 s, 41 s, 39 s** wall time (the first run compiles); 53 s, 54 s, 52 s of test time summed.
All 101 pass all three times: **no flaky test**. The slowest: `map_ladder_test` "four rungs a tap apart"
(12 s) and `chart_weather_test` "the Layers sheet turns the calques and the weather on" (10 s).

## Findings, ranked by what the player gains against the work

Each is marked **quick win**, **needs the user's choice** or **needs pictures first**. Size S, M or L.

### 1. Turning the ball redraws the whole screen (M; the first half is a quick win, S)
Evidence: during a drag of the ball a frame takes **18 ms** (median, worst 31; 22 and 54 in mid game),
against **4.8 ms** when only the ball is redrawn. Each drag frame rebuilds about 89 widgets (the five
buttons, their tooltips) and repaints about 480 pieces of the screen: there is no paint boundary round
the ball (`lib/widgets/journey_world_map.dart:714`, the `CustomPaint` at :724), and each move is a
`setState` of the whole map widget. The weather layer is redrawn with it.
Build brief: put the ball and its weather behind a paint boundary; keep the ball's view in a notifier the
painter listens to, so a drag repaints the ball only and the buttons are not rebuilt. No change the player
sees except smoother turning. Check on a phone before and after.

### 2. "Town" is offered on the World where the place has no town plan (S, quick win)
Evidence: at the Spire of Judgment the strip shows Town dim on the District and Room, but lit on the World
(`04`, last screen). A tap on it lands on the District (`measures.txt`, "MID after Town tap").
Cause: `lib/screens/journey_screen.dart:2376` opens the rung whenever the level is not the place.
Build brief: open Town on the World only where the place has a town plan, as on the full map page.

### 3. The city plan page is a second Town view with its own rules (needs the user's choice)
Evidence (`01` last screen, `02` first): same map as the Town rung, but its buttons are top right (bottom
right on the Journey), it has no level strip and no list, the plan is drawn smaller than the page allows,
and "Whole city" is 34 px high. Its "+" now goes to the party's district.
Choice: (a) make it a true "enlarge" of the Town rung: same buttons in the same place, the strip, the plan
filling the page (M, pictures first); or (b) remove the page and its icon, since the Town rung shows the
same (S). I would do (a).

### 4. Things to tap that are under 44 px (S, needs pictures first)
Measured: the level strip 36 px high (kept at 36 so the Journey fits a 360 x 640 phone); the city plan icon
40 x 40; "Whole city" 108 x 34; a district's row in the list under the Town 37 px high when it has one line;
the map's own buttons are 44 x 44, the full map's tabs 46 high.
Build brief: "Whole city" to 44 (Maps). The district rows and the plan icon are in the Journey screen:
with UX. The strip stays unless the user wants it taller on tall phones only.

### 5. Names of lands not yet reached are too faint (S, needs pictures first)
Evidence: they are drawn at 60 % strength (`lib/widgets/chart_map_painter.dart:1826`). Contrast against
the ground behind them, computed from the palettes: Night 3.5 on fog and 2.8 on land, Parchment **2.3**,
Shroud 3.3. Readable text wants 4.5; 3 is the floor for large text. On Parchment they almost vanish (`06`).
Build brief: 75 to 85 % strength (Night 4.8 to 5.8, Parchment 2.9 to 3.5), and a darker ink for Parchment's
names (a palette colour: with UX). Reached names stay stronger so the difference still reads.

### 6. The phone's back button leaves the Journey from any map level (needs the user's choice; with UX)
Evidence: from inside a building, back goes to the title page (`measures.txt`, "BACK room after: no strip").
There is no back handling in the Journey or the map pages; only the two pushed pages (full map, city plan)
close on back.
Choice: back climbs one rung first (Room, District, Town, World) and leaves from the World; or stays as it
is. It is an app-wide habit, so it belongs with UX's audit of transitions; the map side is one handler (S).

### 7. The weather line covers the foot of the plan (needs another session: UX)
Evidence: at Alster the line takes two rows and sits on the plan; a building's name shows through under it
(`01`, second screen: "...ind Beggar"). In a room it covers the lower wall.
Proposal: one row always (shorter text), or under the map beside the strip. The line is drawn in the Journey
screen, not by a map painter.

### 8. The epilogue map cannot be read on a phone (M, needs pictures first)
Evidence (`07`): the lands' names are about 4 px high, the numbered marks 3 and 5 sit on each other, small
unnumbered dots have no name, the map cannot be zoomed, and it is the dark Night chart on a light page.
Build brief: no land names at this size, numbered marks pushed apart, the page's own light look, a tap on a
number scrolls to its line.

### 9. Names run across marks, roads and rivers (M, needs pictures first)
Evidence: names keep clear of other names (`chart_map_painter.dart:1676`), not of the drawing under them:
"THE SALT COAST" on the river and the marks at Alster (`02`), "THE RED HILLS" on Emberwick's mark (`04`),
"LES PLAINES DE CENDRE" against "Le Quartier des Cendres" at 360 (`05`).
Build brief: land names also avoid place marks and the party's road, and step aside further before
giving up.

### 10. The ball's ground pictures are never let go (S to M, quick win once tried on a phone)
Evidence: `chart_map_painter.dart:746`, a static store with no eviction. One look with one layer holds
three pictures (1.6, 2.9 and 6.5 MB, about 11 MB); each other look or the Clans layer adds as much, kept
until the app closes.
Build brief: keep the current look's pictures only, and let them go when no map is on screen.

### 11. The town and district screens never rest (S, quick win)
Evidence: the party's ring is redrawn on each of 30 idle frames, with 3 or 4 button outlines beside it
(`measures.txt`, "IDLE ... district"). The plan itself is drawn once since release 3; a frame costs about
2.5 ms. The World is still when untouched. A room also keeps asking for frames, from something that is not
a map painter (not traced).
Build brief: a paint boundary round the ring so the buttons are left alone. Small gain; battery, not speed.

### 12. Small print on the ball (S, needs pictures first)
Names of ranges, woods and works are 10 px at the least, lands 10 px, places 12.5 px (`:209`, `:1905`).
10 px italic is hard on a phone. Raising them to 11 or 12 drops a few more names where it is crowded.

### 13. Smaller things
- The whole ball uses half of its box (`03`); "−" could stop at the ball filling the box's width.
- A dim rung does nothing when tapped and does not say why (`lib/widgets/level_ladder.dart:83`). With UX.
- The path above the map is cut on the left ("er › Alster ›", every picture). With UX.
- A place with no plan shows a dotted field with posts (`04`, second screen): the open question on the land
  texture round a plan.
- The ground now mixes pixel-drawn trees and peaks with soft blurred coasts: the open question of one look
  for all the maps.
- `assets/visuals/city/saltmouth_stub.json` (190 KB) ships for a preview page and four tests only.

## How the maps link today (the map side of the transitions)

| From → to | How | What moves |
|---|---|---|
| Room → District | "−", pinch out, the District rung | a door veil clears the map |
| District ↔ Town | "−" / "+", a tap on a district, the rungs | the plan's camera glides |
| Town or District → World | "−", pinch out, the World rung | the plan fades over the ball, which pulls back (0.2 s) |
| World → Town | "+" at the closest view, a pinch in, a tap on the party's place, the Town rung | the ball closes in, the plan grows (0.36 s) |
| World → full map page | the square button | a page slides in; back closes it; its strip returns to a rung |
| Town → city plan page | the map icon in the top row | a page slides in; only the back arrow leaves it |
| Full map → a place | a tap | a sheet; "Set out" or "Travel" where allowed |
| Any level → out | the phone's back button | leaves the Journey (finding 6) |

All of these stand still with "reduce motion".

## Self-review

- Finding 1's times come from a test build on a server; the counts (widgets rebuilt, pieces repainted) are
  facts of the code, the milliseconds are not a phone's.
- Finding 5 keeps "dim until reached" on purpose; only how dim changes.
- Findings 6, 7 and three of the smaller ones are in the shared Journey screen or UX's widgets: listed, not
  mine to build alone.
- Dropped after checking: "the plan is redrawn every frame" (no longer true since release 3) and "names
  overlap names" (they do not; they cross marks and roads).
