# World map: what costs frames, and what to change

UX proposal, read from the code (`lib/widgets/chart_map_painter.dart`,
`lib/widgets/journey_world_map.dart`). **Nothing here is measured on a
device yet.** The list is ordered by what I expect to cost most; the first
step of the work is a timeline capture on the phone the user plays on, so the
order can be corrected before anything is built.

## What the painter does on every frame

`ChartMapPainter` repaints on `frame`, `walk`, the skin's `_ready` counter and
the `view` notifier (turning or pinching the sphere), and
`shouldRepaint` is `true` (line 2412). So a drag on the sphere repaints
everything below, 60 times a second:

1. **The sphere's skin** (`_paintGlobeSkinned`). The flat chart is rendered
   once into an image (cached by look and detail, good), then drawn as a
   mesh of textured triangles, each vertex lifted by its height, then the
   graticule and three radial-gradient discs for the light. The mesh is
   rebuilt and re-drawn per frame. This is the likely floor of the cost, and
   it scales with the ball's size in pixels.
2. **The fog** (lines ~2134-2170). While the story has not reached the whole
   world: a `saveLayer` over the whole chart, then one `dstOut` blurred path
   per reached land (`MaskFilter.blur` 3.5) and one blurred corridor stroke
   per walked leg (blur 4). `saveLayer` plus blur masks are the costliest
   operations the canvas has, and they are redone every frame even when the
   fog has not changed. The early game (few lands, little fog cleared) is
   cheap; the middle game (many lands cleared, all legs walked) is the worst
   case.
3. **The names** (`_names`, `_layout`, ~line 1626-1900). Every reached
   place gets a fresh `TextPainter`, laid out and painted every frame, and a
   rectangle collision test against every name already placed (quadratic in
   the number of names). Region names and the standing caption are laid out
   the same way. Text layout is the main CPU cost of the painter once the
   world is charted.
4. **The calque** (Clans, chapters, and before this change the climate
   layers). The climate layers are cached as a picture on the flat chart but
   repainted from scratch on the sphere (`_paintClimate`). The Clans tint
   (now whole regions) is a path fill per region per frame, with a hatch for
   contested regions.
5. **The weather** (`chart_weather.dart`), a separate animated layer over the
   map with its own ticker, repainting every frame while on.
6. **Repaint areas.** The controls, the chapter chips, the legend and the
   map share one tree; only the chart is under a `RepaintBoundary`
   through its custom paint. A blinking marker or the walking party repaints
   the whole chart, not just the marker.

## Changes, by expected gain

1. **Keep the sphere's picture while nothing moves.** Hold the painted
   ball in a `ui.Picture`/`RepaintBoundary` and redraw it only when the view,
   the discovered set, the selection or the calque changes; the party's
   walk, the weather and the pulse go on a separate painter above it.
   Gain: a still map costs nothing; the walk costs only its own layer.
2. **Turn the fog into an image.** Render the fog once per discovered-set
   (and per detail) to a `ui.Image`, as the skin already is, and draw it as
   one image on the flat chart and as part of the skin on the sphere (so it
   also turns with the ball). That removes the `saveLayer` and every blurred
   path from the per-frame cost. It rebuilds only when a place is reached,
   and the reveal animation can cross-fade two images.
3. **Cache the labels.** Lay the names out once per (language, detail level,
   discovered set) into `TextPainter`s kept in a map, and keep the placement
   result (which names fit, and where) until the zoom or the discovered
   set changes. On the sphere, recompute placement only when the turn
   stops (a name appearing or vanishing while the ball spins is also
   noise to the eye).
4. **Thin the names by zoom.** At the world zoom show the big places and
   region names only; at a land zoom add the towns; at close zoom add the
   rest. The `lod` value already exists in the painter; the rule is "rank 4
   names wait for the close zoom". Fewer names means fewer layouts and
   fewer collisions, which is also the first visibility gain.
5. **Cap the mesh by size.** Pick the mesh's rows and columns from the ball's
   pixel size (a ball at 0.5 of today's size does not need today's mesh).
   The size mock (1, 0.8, 0.5) shows the ball cut down; if the user keeps a
   smaller ball, this is free speed.

If only two: **1 and 2.** Both remove work from every frame rather than make
it cheaper.

## Visibility gains to take with it

- **Label collisions.** Names now fall back to "left off if no clear spot",
  which hides places the player has reached. With the thinning in (4) and
  one cached placement (3), names can be placed in rank order once, with
  a leader line for the few that must move; no name is dropped without
  being listed in the Légende.
- **Label contrast over the lands.** The names are drawn over bright
  land and dark sea with the same shadow. Give each name a thin halo in the
  chart's ground colour (a stroke pass under the fill, cached with the
  painter in (3)), or a soft plate for names over a Clans tint, so a name is
  readable on a red or blue region as it is on the sea.
- **The Clans tint.** The whole-region tint is at 0.5 alpha of the clan colour
  (`regionHolders`, Core's `chartZoneHolders`); on dark lands the red and
  the blue read well, on a pale parchment look they would need a different
  alpha. The parchment and shroud looks are dropped from the map's menu in
  this proposal, so only the night look needs tuning.

## What I need from Core

- `chartZoneHolders` and `regionHoldersProvider` to stay cheap and stable:
  the painter calls them with the same inputs every frame, so they must
  return an identical `Map` until the politics change (not a new map each
  read), so I can cache the tint picture on the map's identity.
- A `discoveredRevision` (an int that changes when the discovered set does,
  or a stable hash) on the journey state, so the fog image and the label
  placement have a key that is not "compare the set each frame".
- Confirm the holders' result does not depend on the player's position or
  the walk, only on politics and geography; if it does, say which, because
  that decides which layer the tint belongs to.
- Nothing is needed from Core for changes 1, 3, 4 and 5.

## Order

Measure first (a Flutter timeline of a drag on the sphere and of the walk,
at the middle game); then 1 and 2; then 3 and 4 together with the label
visibility; then 5. Each is a separate small PR in UX's files
(`chart_map_painter.dart`, `journey_world_map.dart`), and none changes a
number or a rule.
