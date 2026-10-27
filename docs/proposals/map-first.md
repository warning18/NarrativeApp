# The district view, map first (wave 19 "What opens where", UX mock, nothing built)

> **Built in v1.583** (see `district-places.md`). The pins carry no words on the map where places are listed (the story's building names are off too), a tap on a pin shows its card (name, count, Go; a second tap folds it), the "Places · N" handle zooms the map to its full zoom and the list rises (the handle reads "Map" and folds it), a pinch to full zoom does the same, and an arrival eases the camera in 25% on the party's mark in 0.6 s (a jump with reduced motion; not on the Town view a move frames). Not built: the gold ring on the pin where the story goes on (the main banner already says it) and the padlock on a shut one beyond the banner's own; the Town view is unchanged. Core's `CityChartCamera` got a `pending` flag so a chart built later does not replay an old shot.

Picture: `docs/ux-shots/map-first-mock.png`. Mock test: `test/ux_map_first_mock_test.dart`.
The map is the app's own `CityChartView` on Saltmouth's stored plan with Smugglers' Quay's
real ways (scene 2015, the user's screenshot); the real screen today is a capture
(`docs/ux-shots/map-first-today.png`); the rest is drawn with the app's own widgets.

## The user's call
"A version where, once on the journey map, you remove the list and make the list below appear
when completely zoomed on district level; also remove the names on the journey map and only
add them when the user clicks, like the actual way of work. Each time you arrive on a
district, zoom a bit and center on yourself."

## What the picture shows
- **Today:** the map labels each pin with the way's own text, the labels overlap each other and
  the pins, and the list under the map repeats them as long rows. (The map's labels come from
  the way text, not a place name: `CityChartWay.name`.)
- **A, default zoom:** the map and nothing else (it takes the room the list had). No label on
  any pin; the chart's own shapes say the kind (diamond: a thing to do, cross: a fight, square:
  a check, chevron: a way out). A tap on a pin shows a small card with the place's name, a
  count and Go. A "Places · 10" handle at the foot of the map tells there is a list.
- **The arrival:** on arriving in a district the camera eases in 25% from the district fit and
  centers on the party's mark: 0.6 s, ease in and out, a tap anywhere skips it, a jump with
  reduced motion. Moving between places inside the district does not repeat it.
- **B, fully zoomed:** the map shrinks to make room and the list of places rises under it: the
  real places of the quay (five named by Narrative, five with no name yet), a count, a flag
  where the story goes on, and the shut doors under WAYS OUT. The handle reads "Map" and folds
  the list back. Pinching to full zoom does the same as the handle.

## Questions answered
- **How the player knows the zoom that shows the list:** the "Places · N" handle at every
  district zoom. Tapped, it zooms the map to the full district view and the list rises; at
  that zoom it reads "Map". The list follows the zoom, and the handle is the way there.
- **Town and World:** unchanged. Town: the districts with their names on the plan (and the
  crest or the padlock), no per-way pins and no list, the district card at the foot when one is
  tapped. World: as today. The list belongs to the district view only.
- **A pin with no name:** the shape carries the kind. Proposed additions: a gold ring on the pin
  where the story goes on and a grey padlock on a shut one, as the shut districts already wear
  (wave 18). A tap shows the name and count; the way texts appear only on arrival.

## What it needs
- **Core (owns the camera state):** a trigger on arriving in a district
  (`partyDistrictProvider` changing); a way to set the camera's zoom and center (`CityChartView`
  has only `focus` today); a signal when the map reaches full zoom, or leaves it, so the list
  can follow; the place for each way and its count (as in `district-places.md`).
- **Narrative:** names for the five quay buildings that have none (Vane's three spots, the
  crane, Liora's skiff) and for the door to the footbridge.
- **UX (the build, if approved):** the labels off the map and the card on a tap, the handle,
  the list under the zoomed map, the arrival ease. About two days after Core's camera state.

Consistent with `presentation-contract.md` (Core), `ux-presentation-answers.md` and
`district-places.md` (UX).
