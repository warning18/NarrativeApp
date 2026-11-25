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
