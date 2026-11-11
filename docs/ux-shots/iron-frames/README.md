# Frame design system (old iron): proposal, pictures first

The user: "more medieval, with OLD IRON on the edges, and some elements like plants or sand or snow added depending on the environment (separate elements)", and "going on in the story, your interface becomes less cheap: first wood, then iron, then silver...". Art's kit: #939 (iron + environment decorations + `anchors.json`), #950 (wood, silver, gilt in the same shape).

Nothing here is wired in the game: the pictures come from a prototype (`prototype.patch`, never merged) that drives the real fight screen with frames.

## Tokens (one place: `lib/theme/frame_style.dart`)

| Token | What | Where it comes from |
|---|---|---|
| `FrameMaterial` | wood, iron, silver, gilt: the frame's material | one value read from the player's progress (the rule waits for the user's OK; Manager suggests the chapter for the story, the floor band for the Tower) |
| `EnvDecor` | none, wilds, dunes, frost, coast, ash, city, sacredVoid: the place's decorations | the zone or biome (a map from the fight's stage / zone to a set; Tower: its own) |
| `FramePiece` | panel dark / parchment, HUD panel, dialog, chip, buttons (normal, pressed, disabled) with the file, size and 9-slice margin of `anchors.json` | fixed by Art's kit |
| `pixel` | logical pixels per art pixel: **2** for HUD panels, cards, dialogs and buttons (the materials only read at 2: at 1 an iron frame is a thin black line), 1 for the smallest chips | token, 16/32 scale of the icons |
| `envPixel` | the decorations' own scale, always **1**: at the frame's 2 they cover the text (see the pictures) | token |
| `FrameStyle` | a `ThemeExtension` holding material, env and the two scales | `ThemeData.extensions`; override it for a subtree with `Theme` (a Tower page, a zone) |

## Components
- **`FrameBorder`** (an `OutlinedBorder`): paints the piece's 9-slice around the box. Corners as drawn; **edges tiled, never stretched** (`drawImageNine` would stretch); `fillCenter` for buttons (their fill is in the art). Then the environment's decorations: the top edge (32 x 10 sprites, 4 px overlap, variant cycled by a **seed**, so a panel never changes between frames), and the four corners (the top-left sprite mirrored). No animation, no hit area, never over text (envPixel 1).
- One primitive, three ways to wear it: `Card.shape` and `Dialog.shape` and the button styles by the theme (every `Card`, dialog and filled button, no screen changes), `ShapeDecoration(shape: FrameBorder(...))` for the ad-hoc `Container`s (the fight's slots, the Tower's bands), and a `FramePanel` widget for new screens.
- Images load once (`FrameImages.preload(material, env)`, at start and when the material or the place changes); a frame whose image has not arrived paints nothing and its fill shows.

## What the pictures show
`fight-before-after-412.png` (today and old iron + wilds, dark and light), `materials-wood-iron-silver.png`, `environments-iron.png` (dunes, frost, coast, ash, city, sacred/void), `fight-360.png`: the real fight screen. The prototype also paints the HUD slots and the cards/dialog/buttons through the theme; the "Roll Dice" button was not restyled in these pictures.

## Found while doing it (for Art)
1. The frost corner (and the silver/frost combination) shows **white square blocks** at the corners: the sprite is opaque there. Needs transparent corners.
2. The wood / iron / silver frames only differ at pixel 2; at pixel 1 they are hard to tell apart.
3. The art's parchment panel has a dark outer line that reads heavy on the light theme's page; a lighter outline for the parchment pieces would sit better.

## Costs and order (Tower first)
- `frame_style.dart` + theme wiring: about 350 lines (done in the prototype), tests for the painter (tiles do not stretch, a missing image paints nothing, the seed is stable).
- Wiring the surfaces: the cards/dialogs/buttons by the theme (free), the fight's slots and the Tower's bands/oath cards by `ShapeDecoration` (about 20 sites in the Tower and fight), HUD panel for the fight's HUD.
- Decorations as a second step (1.913) if the first (1.912) is large.
- What I need from you: the OK for the tier rule, and Art's fix for the corners.
