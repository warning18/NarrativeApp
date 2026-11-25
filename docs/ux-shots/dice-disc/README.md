# The disc behind the die (v2.10.14), real Tower fight at 412

The disc is the die's landing burst. In the Tower it was drawn from the pixel strips,
then flattened to one colour (red for an attack, paper for the rest), so the strip's
big flash became a solid disc over and behind the die for a few frames, and a die
picked soon after it landed showed it. Now the Tower's burst is rings and sparks only
(outlines, no fill), in the same colours.

- `dice-disc-before-after-412.png`: the landing, frame by frame, before and after.
- `dice-picked-before-412.png`, `dice-picked-after-412.png`: the die picked just after
  it landed.

The pick's gold glow (a blurred box under the die) is removed too: the die keeps its
gold outline. States checked by the test: not rolled, rolling, rolled, picked (the burst
is the outline painter at every frame of the landing).

## The state of the user's screenshot (added)

Overseer Renn (floor 5), rolled, one die tapped once (its target shown), on a short
board (412 x 700): `dice-tapped-once-before-after-412.png` (before, v2.10.13, and after).

Three things painted a solid dark or light mass behind or over the die in that state; all
three are gone:
1. the landing burst, flattened to one colour (above);
2. the picked die's gold glow, a blurred box under the die (the die keeps its gold outline);
3. **the plate's dark archway**: Art's dice plate has a dark arch between two pillars at
   its top, and on a short board the plate is scaled up so that the arch sits right behind
   the die, a round black shape with a maroon rim (the "black ball" of the screenshot, which
   is round, dark, with a violet-looking rim, and behind the upper half of the die). The
   plate is now drawn a third larger from its foot, so the arch is cut off and only the stone
   floor is left.

`dice-archway-before-after-412.png`: the same state (floor 5, Overseer Renn, rolled), on
boards 412 x 740 and 412 x 700 high, before and after. Before, the dark archway between
the two pillars at the top of Art's plate sits right behind the die; after, only the stone
floor. (The faces differ between the pictures: the die rolls at random.)

The aim bubble's shield: the block's label was drawn with a "⛨" character that is missing in
some fonts (an empty box before the number); it is now an icon.
