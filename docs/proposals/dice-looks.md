# More dice: sizes, styles and their animations (UX mock, for the user to approve)

Pictures: `docs/ux-shots/dice-family-mock.png`, `dice-roll-mock.png`, `dice-ui-mock.png`.
Mock test: `test/ux_dice_mock_test.dart`. Nothing is built. Core writes the sizes and rules
(`docs/proposals/dice-sizes.md`); this is how they look and move.

## 1. The family, and what a style adds (`dice-family-mock.png`)
- **Shapes**: d4 (tetrahedron), d6 (the cube, today), d8 (octahedron), d10 (kite), d12
  (dodecahedron), d20 (the forge's, an icosahedron) and a coin, drawn as flat-shaded polygons
  (3 to 10 faces visible, at most 20 polygons for a die), side by side at the same scale and
  at the fight's 44 px size. The number stays readable down to about 34 px; below that the
  shape alone says the size.
- **Styles are the skins the game already has** (`die_skins.dart`: 34 of them, each a stone
  colour, an edge colour, a mark cut into the faces and sometimes a glow, drawn by
  `DiePatternPainter`). Today they paint only the cube; the same data paints any shape.
  Shown: Bone (every die today), Worn wood (`pilgrim_die`), Brass (`tobin_die`), Obsidian
  (`shadow_die`), Tear-glass (`tearglass_die`, glows), Ember (`flame_die`, glows), and a
  **clan-marked** die (the clan's banner on its front face, new). A style changes how a die
  looks, not what it does; the size changes the face count and how it is read (Core's rule).

## 2. The roll (`dice-roll-mock.png`): about 1 s, tap to skip
Seven beats: **the throw** (small, up, a ghost trail), **the tumble** (turning, foreshortened),
**the bounce** (a squash on first touch, a small bounce), **the settle** (a rock), **the read**
(the face lit). A tap shows the result at once; with reduced motion only the last frame.
- **Polyhedra (d4, d8, d10, d12, d20): new**, but cheap: one flat polygon set, a rotation, a
  scale for the tumble and a squash; no real 3D.
- **The d6: existing** (`Die3D`, the cube tumbling in perspective, landing on the face
  rolled with a burst fitted to the face: `DieFx`).
- **The coin: new**, cheaper still: a disc scaled across its width, edge-on twice, a wobble.
- **How the read is staged** (the last 0.2 s; the d20 shown): a **critical** is a white
  flash, then a held beat (0.15 s) with a gold ring (existing: the surge ring and the burst);
  a **fumble** is a shudder sideways, then it dims and a grey puff rises (existing: the
  blank's shudder and dust); a **skill face** makes the die glow and its icon rise (existing:
  the bigger burst of a skill face; the die's own glow is new).
- **Reused**: `Die3D` and `DieFx`, the surge ring, the shudder, the skins and patterns, the
  d20 forge cast (`d20_roll.dart`) when a d20 is shown large (the forge, a check), the sparks
  (`pixel_vfx`). **New**: the flat polyhedron painter and its tumble, the coin flip, the
  held beat at a critical, the die's glow on a skill face, the clan mark.
- **Budget**: one `CustomPaint` of at most 20 polygons for a die, one controller, nothing
  rasterised. To be measured with six dice at once on a phone when built.

## 3. Where the dice show (`dice-ui-mock.png`)
- **In the fight**, the party's dice row: each die a small tile in its shape and style with
  the shape's name under it ("d8 · a skill face"); a die that landed on a skill face glows, a
  kept die wears a gold lock, one not yet rolled is pale.
- **On the character's Dice slot** (today "starter_die" on the Inventory screen, a raw id):
  the die's name ("Lucky Die") with its shape drawn, "d6 · bone" under it; the sheet it opens
  lists the dice by look, name, faces and material (the same rows as the inventory proposal).
  The name already exists (`dieDisplayName`); this is the one-line bug fix of the inventory
  review, with a picture.

## Questions for the user
1. Which sizes first (my guess: d8 and d20, since the forge already has a d20)?
2. Should a clan-marked die be a reward (a clan's gift) or a style the player picks?
3. Is the 1 s roll too short for a d20, which a check shows large (the forge's cast is 1 s)?

## Update: a slot for every face, and art for every die (the user's words)
"The 12-faced die should have 12 faces to equip and a dedicated art."

### Equipping the faces (`docs/ux-shots/dice-equip-mock.png`)
Every die has as many face slots as its size: **d4 four, d6 six, d8 eight, d10 ten, d12 twelve,
d20 twenty, the coin two**. The die sits in the middle of a **ring** of round slots (a face
is its skill's icon and its number; a "+" is a face with nothing on it yet); a tap on a slot
chooses that face, and a small panel under the ring says what it does with one **Change**
button. At the d20 the ring would be too tight at 320 px, so it becomes a **grid five across**.
Nothing is a form: no fields, no labels per slot, the slot is the thing. The big picture is
the legendary d12 (12 slots, "9 of 12 faces set"); the others are one die of each size.
Needs from Core: a die's face list (`faces` in dice.json already is one, of any length) and
a skill for each face; the equip screen draws what is there.

### Dedicated art (`docs/ux-shots/dice-art-mock.png`)
A die gets pieces of its own drawn over and round its shape, on top of its skin (a handful of
paths, no new image files):
- **The four six-faced dice that share a cube today**: Dwarven stone (chipped corners, a cut
  rune), Stormcast (a crackle of lightning over the faces), Liora's (vines and leaves),
  Grosh's tusk (tusk spikes at the corners, notches).
- **One die for each other size**: d4 Twin-fang (curved fangs for its tips), d8 Rune crystal
  (a sparkle, inner facets), d10 Antler and oak (tines from its top), d20 Sky-glass eye (an eye
  on its front face).
- **The legendary d12, the Sovereign's Die**: a crown, a gold edge, a halo of rays.
- **The coin, the Sovereign's coin**: a ring of beads and a crown.
The art ids are keyed to the existing skins (`stone_die`, `storm_die`, `liora_die`,
`grosh_die`, `twinfang_die`, `arcane_die`, `huntsman_die`, `sage_die`, `holy_die`,
`tobin_die`), so a die's dedicated art is a field next to its skin in the same table.
The roll storyboard (`dice-roll-mock.png`) stays as drawn.
