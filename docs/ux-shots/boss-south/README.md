# Boss facing the player (picture only)

A warden fight (Brine Jack, floor 5) at 412 and 360 wide, laid out so it reads as
one scene from top to bottom: the boss FACES THE VIEWER (south sprite), standing
big in its taller panel; "You" is a slim strip under it with the hero seen FROM
BEHIND (north sprite), his head and shoulders over the seam, looking up at it.

**Stand-in frames, labelled in the pictures**: the boss is the Inquisition High
Warden's south frame and the hero is a coated figure's north frame (both from
`art/`), tinted grey. Brine Jack's own south frames and the warrior's north frames
come from Art. The real ones drop in at the same place.

Names, HP bars, the Heat chip and the info buttons stay readable and in place: the
hero's plate (name, HP bar) takes the left half of the strip and the hero stands
in the right half, so he never covers the bar. At 360 it is the same.

Built behind a picture-only switch (`towerBossFacingMock` in
`fight_tower_panels.dart`, null in the game); no version until the user approves.
