# Boss facing the player (picture only)

A floor-20 boss fight (Claimant Morrow) at 412 and 360 wide, laid out so it reads as
one scene from top to bottom: the boss FACES THE VIEWER (south frame), standing big
in its taller panel; "You" is a slim strip under it with the hero seen FROM BEHIND
(north frame), his head and shoulders over the seam, looking up at it.

**Art's own frames**, from the hand-off (`art/pixellab-boss-rotations/handoff/` on
`claude/art-npc-export`): `claimant_morrow_south.png` (60 px) and `warrior_north.png`
(48 px), tinted grey like the game's figures. Brine Jack, the floor-5 warden, has no
south frame yet, so the floor-20 boss stands in (Art's note: `docs/art/boss-rotations.md`).
The frames are read from a folder given to the picture test (`ART_HANDOFF`), not
copied into the repo, since Art's branch is not merged.

Names, HP bars, the Heat chip and the info buttons stay readable and in place: the
hero's plate (name, HP bar) takes the left half of the strip and the hero stands in
the right half, so he never covers the bar. At 360 it is the same.

Built behind a picture-only switch (`towerBossFacingMock` in
`fight_tower_panels.dart`, null in the game); no version until the user approves.
