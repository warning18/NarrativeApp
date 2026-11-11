# Chibi dark-medieval UI: three style directions, and A by environment (pictures only, no code)

The user: "propose again different UI elements styling: chibi dark medieval fantasy,
ideally changing lightly depending on the environment". Built from Art's three
hand-drawn kits (PR #932, `art/pixellab-chibi-frames/`: 9-slice panel, buttons
normal/pressed, corner, texture, six environment corners and stitch tints). The
mock-ups are real Flutter renders of the elements (panel, primary and secondary
button in normal/pressed/disabled, chips and tabs, header and nav bar, a dialog,
a list row), painted from those PNGs at 1 art pixel = 2 dp (edges tiled, not
stretched), with the real texts, real item icons, the harmonised look and the
real scene band. Two screens per direction: the inventory and a story node.
Not the real widgets re-skinned (that is the build): the layout is a faithful
copy, not a screenshot.

| Picture | What |
|---|---|
| `direction-A.png` | A, **stitched leather** (recommended): dark plum leather, 2 px ink outline, gold stitch line, rust buttons that drop when pressed |
| `direction-B.png` | B, **forged iron and candle**: riveted steel plates, brown buttons, candle-gold accents |
| `direction-C.png` | C, **carved bone**: parchment plates with a double border, green buttons, light plates on the dark ground |
| `environments-A.png` | A in six environments (city, wilds, coast, ash, frost, sacred/void): only the stitch tint, the accent bar and the corner change |
| `art-kits-and-env-pieces.png` | the raw Art pieces used |

## Why A
Closest to the hero's chunky ink-outlined look; the dark plum reads as the game's
night palette; the stitch line is the one thing an environment can recolour, so a
screen changes lightly while the dark base stays one design. B is colder and
heavier (good for a fighting or forge screen), C is the book-like option (good for
the story reader and the dialogs) and could coexist with A as "paper on leather".

## How the environment change would work in code
- A `ThemeExtension<EnvAccent>` (stitch colour, accent colour, corner image, optional
  vignette tint) set by one widget near the top of the game route from the current
  zone: the biome pattern the fights already use (`FightStage` / `BiomePattern`),
  the town or road the party stands in. Nothing in a screen's layout reads it.
- The frame painters (panel, button, bars) read the extension; no screen changes.
- Cost, honestly: the frame widgets (a tiled-edge nine-patch painter, panel, button,
  chip, bars, dialog, list row, an asset cache) about 700 lines plus theme wiring for
  Card, Dialog, buttons, chips, AppBar and the nav bar about 300 lines, and the
  environment extension about 150 lines; tests for each; the 320 and 360 widths
  need a pass because the frame margins (8 art px = 16 dp) eat padding; every
  `Card`, `Material` and `Container` with a hand-made border has to move to the
  frame widgets (hundreds of sites, scripted where the shape is plain). Risk:
  medium-high, like item 8 (this replaces it). 
- Edges must repeat, not stretch: Flutter's `drawImageNine` stretches the edge
  slices, which turns the stitch into long dashes; the mock-ups use a painter that
  tiles them (as I would build it).

## What I would need from Art (polish pass on the chosen kit)
1. A thicker outline on panels (the "chibi" weight), more ornament variety on the corners.
2. Panel variants: a flat list-row panel (one stitch line, thin), a dialog panel with a top ornament, a slot panel (inventory) and a plaque for headers.
3. Button: secondary (ghost) normal/pressed/disabled, and a small button for rows (16 px high); chip and tab frames (selected/unselected); the nav bar's selected pill.
4. Header and nav bar caps (a left and right end, tileable middle), a divider.
5. The six environment corners x 4 (all four corners) and a stitch tint swatch per environment; optional faint texture per environment.
6. All of it on the 16 px pixel grid, harmonised palette (the shared 63 colours + ink `#0A0807`).

## Interaction with the plan
This replaces item 8 (panels A + buttons C from `claude/ux-2-panels`, code-painted
frames): item 8 stays held until the user picks a direction. Items 1 to 7 and the
glyph and icon work are independent of the choice.
