# Design proposal: panels and buttons (nine-slice, layouts unchanged)

Board: `boards/panels.png`. Pilots: 1 panel + 1 button, with states.

## Shared rules
- Colours are the theme's tokens: surface `#3B3743`, seam `#CFC4AE`, gold `#F2C14E` (lit), ink `#14110F`. Light-theme versions are not generated; the code keeps tinting.
- **Nine-slice**: corner 8 px, edge 8 px repeating, centre flat so it stretches to any size; the content and layout code do not change (padding stays as today).
- States on the same frame: normal, pressed (1 px lower, darker), disabled (50% as `dim` does today), lit (gold edge).
- No text, no icons inside the frame.

## Options (board A, B, C)
A today's seam, pixel corners; **B stitched ink** (2 px dark outline + a dashed stitch line); C gold corner brackets.

## Recommendation
**B**: it carries the game's own name, reads from a small chip to a full sheet, and has the least chance of fighting the text on top. A is the fallback if UX-2 finds B too heavy on small panels. Cost: `create_ui_asset` 10 per canvas up to 256x256, so about 20 for the pilot.
