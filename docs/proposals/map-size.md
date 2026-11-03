# World map: "map size" at 1 / 0.8 / 0.5

UX, pictures only. The user's answer (via the manager): the size is **of the
map itself, not the real size of the ball**. The first M2 shrank only the
sphere inside an unchanged panel, which was the wrong picture. Two readings of
"the map" fit, so both are drawn on the real full-map screen (412 px phone,
French, the sphere):

- **A. The panel's size on screen.** The map takes 1 / 0.8 / 0.5 of today's
  height; the rest of the screen is free (on the Journey screen it would hold
  the list). `M2-map-size-A-{mid,early}.png`.
- **B. The map's drawing detail.** The panel keeps its place but is drawn at
  1 / 0.8 / 0.5 of today's resolution and stretched back. Simulated here by
  drawing the map at that resolution and enlarging it; the buttons and the
  chips stay sharp, the map does not. `M2-map-size-B-{mid,early}.png`.

## What each size means

| | A: panel height | B: drawing detail |
|---|---|---|
| **1** | today | today |
| **0.8** | the map takes 80% of its height; the ball does **not** shrink (it is 0.9 of the panel's short side, and at 0.8 the panel is still taller than it is wide, 586 against 412 px), so only the empty bands above and below go | 64% of today's pixels; text and coastlines are slightly soft, hardly seen on a phone |
| **0.5** | the map takes half its height; the ball does shrink, to about 0.9 of today's (the panel is now 366 px high, less than its width), and the page below gains half a map of room | 25% of today's pixels; names and the graticule are visibly soft (see the picture) |

**Speed (read from the code, not measured on a device).** The cost that grows
with pixels is the sphere's textured mesh, the glow discs and the fog's
`saveLayer`. B cuts those with the area it draws (about 0.64 and 0.25 of
today), whatever the screen. A cuts them only once the ball itself gets
smaller, which at 0.8 it does not; at 0.5 the ball loses about a fifth of its
area. The names' text layout (the CPU cost named in `map-performance.md`) does
not depend on either size; it falls with fewer names, which is a different
step. So if the point is speed, B 0.8 or 0.5 is where the gain is; if the
point is visibility (a bigger map, or more room for the list), A is the
reading.

**What I would build.** The user's words ("size of the map itself", "for
performance and visibility") fit A best, a panel that takes less of the
screen; B is the cheaper way to speed and changes no layout. If the user
cannot choose between them, one question settles it: "Should the map take
less room on the screen (A), or the same room drawn with less detail (B)?"

## A correction to the earlier pictures

The first M2 to M5 pictures "early" and "mid" were the same picture: the
screen reads how far the party has come from the story's play state, and my
shot tool set only the travel history. Fixed in `test/ux_map_shots_test.dart`
(the new M2 pictures differ: early is mostly fog). The earlier M4 and M5
(clans on the sphere and close in) are drawn again with the build, not
before.
