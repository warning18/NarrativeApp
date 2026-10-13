# UX: the next PR, and the version it needs

For the manager (read here because UX has no `send_message`). #203 (1.277) is merged; this note replaces the one for it.

The next UX PR is v1.282.0+318 (the version the manager gave), merged with `main` at v1.281. It merges on green CI, no QA review (manager's rule until the weekly reset).

What it holds, all in UX's area but for two lines in shared screens:

- **Stat points:** "1 Stat Point" in English, and "1 Point de statistique" (and 0) in French (`stat_point_label_one`, `statPointsText`).
- **Journey, 320 px:** the weather chip is an icon on a screen narrower than 340 px (a tap reads the line), so it no longer covers the lowest step's name in French.
- **Help pattern, the rest of B:** the guide's ⓘ in the header of the Skills, Inventory, Level Up, Journal, Achievements, World map, Skill challenge, Harbor, Port and Shop pages (it replays that page's tour).
- **Dice loadout:** the "Choose this face's skill" button of the die card stays in sight (a regression of #203: the fixed-height card hid it under the scrolling text).
- **The full-screen map (board 8, approved by the user):** `FullMapScreen` is the Journey's own chart (sphere or flat as set, layers, weather) on its own page. Opened from a **Full map** button among the Journey chart's controls, and from each known place on the camp's Road tab (**On the map**: the chart opens on that place with its sheet up). A tap on a reached place opens a sheet: where the party stands, **Travel here** (the camp's own `travelToPlace`; disabled during a fight or an expedition), or why it cannot. Under the chart: **Legend** (marks as the chart draws them), **The story** (opens the Journal's "story so far" page) and **Journeys** (roads walked by chapter; a tap turns the chart to where it ends). The layers sheet is now shared (`widgets/calques_sheet.dart`). The flat travel page (`TravelMapScreen`, `TravelMapView`, the compass button) is removed; the map no longer uses `MapShape.story`.
- **docs/proposals/side-view-ux.md** (+ images): the written record of the voyage (I) and land walk (L) mock-ups you asked for.

Touches another session's area: the deleted QA test `test/qa_travel_map_test.dart` (it guarded the retired travel page; QA to write a guard of the full map), `lib/screens/journey_screen.dart` (the chip's `compact` flag; the layers sheet and the shop/camp lookups moved to shared helpers; the Full map button; the compass button removed), `lib/widgets/camp_travel.dart` (an "On the map" button on `PlaceCard`), `lib/l10n/app_strings.dart` (new `map_*` keys, four `travel_*` keys removed with the page) and the AppBars of the pages above (`actions:` only).

Not in it, waiting on the user: **C** (the skill choice sheet with before → after: board 9 of the design file), the walking sprite for L.

**Left of the full map (board 8), next PR, and what I need:**
- **Core:** the rule for a place the party has only heard of. Board 8 proposes: an open road to it → "Set out" (with a warning), no road → "Mark as goal". Which unvisited places a road opens, and what "set out" does to the story (travel to a place with no settlement scene), is Core's. Today the sheet only offers travel to reached places the camp lists (`travelHistoryProvider.travelTargets`).
- **UX, once the above lands:** the home bar's map icon opens the full map; for that the old `WorldMapPage` must give up what only it has: the look and shape pickers (to move into the layers sheet), the chapter chips, the replay of the walked road (board 8's "Replay all"), and its tutorial topic. Until then the home icon stays on `WorldMapPage`; nothing is lost.
