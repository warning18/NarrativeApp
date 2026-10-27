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
