# Perf, second pass (no visible change)

Measured the same way as the review: a test build on a server, to compare before with after, not a phone.

## The ball's own drawing

One paint of the ball, timed step by step (60 paints, the ball turned a little each time):

| Zoom | Before | After |
|---|---|---|
| whole ball | 5.3 to 6.4 ms | 3.3 to 3.7 ms |
| opening view | 6.5 to 8.1 ms | 3.8 to 4.5 ms |
| closest | 6.1 to 7.6 ms | 3.4 to 3.8 ms |

Where it went: the ground (the skin stretched over the ball) took 2.2 to 3.0 ms and now takes about 1.1;
the names took 1.9 to 4.4 ms and now take 0.7 to 1.8. What was done, all in
`lib/widgets/chart_map_painter.dart`:

- each point of the ball's mesh had its height looked up again on every paint (5,220 points); heights and
  the points' places in the skin are now worked out once;
- every name was laid out again on every paint, and its halo too; they are kept by their text and style
  (the store empties itself when it grows, so a long zoom does not fill memory);
- every road's bends were worked out again on every paint; they are kept.

Checked that nothing the player sees changed: six screens (Alster and mid game: opening view, one "+" in,
the full map) are the same pixel for pixel before and after.

## A drag of the town plan

| What | Before | After |
|---|---|---|
| Town on the Journey, drag of the plan, pieces repainted a frame | 512 | 9 |

(Counted after Core's split of the Journey screen, v2.1.1; ten moves.)

The cause, found with Core's probe: the plan's view rebuilt itself once per move with an ordinary
`setState`. A widget rebuilt under a layout builder makes that layout builder lay out again and repaint
its layer, and the view sits under the page's layout builder: so each move repainted the whole page.
Now the view has its own layer, and what a pan, a zoom or a pick rebuilds is a builder inside the view's
own layout builder (`lib/widgets/city_chart/city_chart_view.dart`): the plan's layer is repainted, not
the screen round it. This is the same trap as the party's ring and the ball in wave 1.

Checked that nothing the player sees changed: six more screens (Alster and Saltmouth: the Town, the city
plan page, the page one "+" in) are the same pixel for pixel.

## Left, and whose

- **A room keeps asking for frames**: the idle glyph animation of the Journey's chart
  (`lib/screens/journey_screen.dart`, `_idleGlyphs`). Not a map painter; for Core or UX after the split.
- The marks under the fog (towns' houses, trade roads, villages) still take about 2 ms of a paint of the
  ball; they could be kept between paints like the names. Not done: more code than the gain is worth
  before a phone says the ball is slow.
