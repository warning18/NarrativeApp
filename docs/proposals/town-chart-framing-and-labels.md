# The town chart: framing the way-out banners and keeping the names apart (UX-2)

From QA's renders of main 1.851 (`docs/qa/village-hubs-1.851/`, 412 x 860, EN). Pictures only; nothing is built on main.

Both pictures are real renders of a prototype (a patch, not committed): left is 1.851 today, right is the proposal.

## 1. White Wells (1200): the "pool at night" banner is cut by the frame

`docs/ux-shots/chart/white-wells-frame-before-after.png`

**Why**: a district opens framed on its own box (`city_chart_view.dart`: `_fit`, `_showDistrict`, the camera's shot), but a way's banner hangs 35 px above its building, so a building near the box's top has its banner past the frame.

**Proposal**: frame the district's box with room for what hangs over it: 48 px at the top (a banner is 38 px tall, 16 px above the building), 30 px at the foot (the names), 16 px at the sides. All three places that frame a district use one helper. The district reads a little smaller (about 12 % less zoom here) and every banner is whole.

## 2. Rimewell (6100): names run over each other

`docs/ux-shots/chart/rimewell-labels-before-after.png`

**Why**: a building's name is drawn straight under its building (`city_chart_painter.dart`, "Building names"), with no look at the other names, the banners, the service pins or the view's edge; six banners in one district stack their names on each other and on the edge ("milestone", "nger a name to sing").

**Proposal**: place the names one after another, each in the first spot that is clear of the names already placed, the banners, the service pins and the edges: under the building, then beside it on the right, on the left, then a row further down. A long name wraps to two lines at 124 px. **A name with no clear spot is left off**: every way is also in the "Places here" list under the chart, and the banner is tapped as before. In Rimewell 3 of 6 names stay; the others are in the list.

## What it costs

About 60 lines in `city_chart_painter.dart` and `city_chart_view.dart` (both UX's), no data, no strings. The names' placement runs in the paint (a few rects per building), the framing once per view. Tests: a painter test for "no two names overlap" on the village hubs' charts, and the existing town-chart tests.

## Open question

Leave names off when there is no room (what the pictures show), or show the name of the way picked (selected) over the others? I would add the second: the picked way always gets its name, taking the spot that covers least, as the Journey's place map does (`journeyLabelSpots`, `keep`).
