# The epilogue map (UX picture, nothing built)

Wave 18, step 2, item 4 (`docs/proposals/wave18-step2.md` on `claude/core-wave18-step2`): at the ending, the
map shows each big town and district tinted by its holder, with the clans' roads between them. Per the
user's rule this is a **picture first**: nothing is built until the user says yes, no version.
Picture: [`docs/ux-shots/epilogue-map.png`](../ux-shots/epilogue-map.png) at 412 and 320 px. Mock test:
`test/ux_epilogue_map_mock_test.dart` (the screen is in `test/ux_epilogue_map_parts.dart`).

## What the picture shows
One screen, "The realm, at the end", from the top:
1. **The map**: the world's coast cropped to where the 16 towns are, each town a disc in its holder's colour
   with a darker rim (the tint the world chart and the town views already use). The **seven big towns**
   (Alster, Saltmouth, the Ashen Quarter, the Drowned Cloister, the Black Reliquary, the White Anchorage,
   Candlehold) are larger and numbered; the nine villages and the camp are small dots.
2. **The roads**: a road joining two towns of **one holder** is drawn in that clan's colour (wave 18 item 5,
   "clan roads"); a road between towns of different holders is a thin grey dashed line.
3. **The holders**: one chip per clan with its flag and how many towns it holds.
4. **One line for each big town**: its number, name, the holder's flag and name, and **how it was taken**
   ("since the start", "by war, chapter 5", "by influence, chapter 4", "by the seat, chapter 7"). A town whose
   districts are held by others says so ("3 districts differ"); a tap on it would open the districts' list
   (not drawn).

At 320 px the map is the same, the chips wrap to three lines and a name that does not fit puts its "districts
differ" tag on the next line.

## What is real and what is a sample
- **Real:** the geography (16 towns, 59 districts), the factions' colours, the chart's coast and town
  positions, the tints: `townRulers(geography, politics, factions)` run on a sample politics state.
- **Sample:** the holdings themselves (who took what) and the "how it was taken" lines, until Core's
  `epilogueHoldings(politics, geography)` (v1.618) gives each town and district its holder, source, chapter
  and cause from the clan log `givePlace` keeps. The roads are each town joined to its two nearest
  neighbours, standing in for the land routes Core's item 5 will define.

## Where it would sit
At the ending, after the last scene, as its own screen opened from the ending (and later from the camp's "On
the map" for a game already finished). It is **not** the world chart itself: the chart is a painting with
labels that collide at phone width when 16 towns each carry a holder line, so the epilogue draws a
simplified map of the same coast with numbers, and the list carries the words.

## Costs
- One new screen: the map painter (about 120 lines), the row and chip widgets (about 150), strings.
- It reuses `townRulers` and the factions' colours, so the tint cannot drift from the rest of the game.
- The roads need Core's item 5 (clan roads) to be real; until then they would be hidden or drawn as above.

## Needs from other sessions
- **Core:** `epilogueHoldings(politics, geography)` with, for each town and district: holder, source (own,
  war, influence, seat), the chapter and the day it was taken; and, for the roads, which pairs of towns a
  land route joins.
- **Narrative:** the "how it was taken" wording in English and French (the picture says "by war, chapter 5"),
  and a line for the screen's title and subtitle.

## Questions for the user
1. A dedicated end screen with a simplified map (as drawn), or the real world chart with the same tints and
   a list under it?
2. One line for each of the seven big towns (as drawn), or for all sixteen?
3. Should the districts that differ be listed under their town (a tap), or only counted ("3 districts differ")?
