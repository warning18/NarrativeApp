# The city chart (UX, board 15, model A)

**What it is.** A city drawn as a real old city, seen from above, in the Map look's chart colours (night, parchment, shroud): crooked blocks cut into house lots, a river with an island and bridges, canals, a star of avenues, a ring road, squares, an arena, the wall. One page: it opens on the whole city, pinch and wheel zoom in and out (and + / - buttons), a tap on a district zooms to it, its houses grow roofs, its buildings their names and its ways their pins; a pin opens a card with the way and "Go". Districts the party has not found lie under fog (dashed outline, "?"; a tap says "Not explored yet" and does not open). The party's mark breathes on the building it stands at. The "Whole city" chip is the way back. No separate hub screen and no automatic goal star: only the goal the player sets is flagged.

**Where the code is.** `lib/widgets/city_chart/` (UX): `city_chart.dart` reads the record, `city_chart_painter.dart` draws it, `city_chart_view.dart` is the page's body. `lib/screens/city_chart_screen.dart` shows it on Saltmouth's stub plan, opened from the fight lab ("City chart (preview)").

**The record (what Core's per-city record has to give, or UX's reader adapts to).** Plain JSON, one per city, plan units (Saltmouth is 880 x 980). Rings are flat `[x0,y0,x1,y1,...]` lists; shapes are lists of rings, filled even-odd (an island is a ring inside the river's).

| field | what |
|---|---|
| `w`, `h`, `name`, `seed` | the plan's size and the city's name |
| `sea`, `ground`, `avenues`, `squares`, `water`, `bridges` | shapes |
| `wall`, `towers` | the wall's ring; tower points |
| `arena` | outer ring, inner ring (or `[]`) |
| `districts[]` | `id`, `name`, `colour` (`#RRGGBB`), `blocks` (the district's region, a shape, closed up over the avenues between its blocks), `seed` (where its name sits) |
| `lots[]` | `d` (district index), `r` (the lot's ring), `g` (its roof ridge `x0,y0,x1,y1`) |
| `buildings[]` | the buildings the story stands at: `key`, `d`, `name`, `r`, `round`, `quiet` (a spot, not a house: a notice board, a slip), `at` (its middle, where the pin and the party stand), `g` (ridge) |
| `ways[]` | `id`, `d`, `kind` (`quest`, `fight`, `check`, `shop`, `road`), `name`, `at` (a building's `key`) |
| `marks` | quiet decoration: `lanterns`, `stalls`, `boats` (x, y, angle), `trees`, `piers` (x, y, width, thickness) |

`assets/visuals/city/saltmouth_stub.json` is a full example (about 190 KB: the 1,500 lots are most of it; a record can drop `lots` for a city that is far from the party and the painter would draw the blocks alone). UX generated it offline; Core can take it as Saltmouth's first record, or generate its own to this shape.

**What the Journey needs from Core for the next step.** Per city: the record above; which district each way belongs to and which building it is pinned on (here `ways[].d` and `.at`); the districts the party has found; the party's district and building. UX then opens this page from the Journey's city level, with the way card's "Go" taking the way. **Narrative:** the districts' and buildings' names (and ambiance lines), in EN and FR (the stub is English only).
