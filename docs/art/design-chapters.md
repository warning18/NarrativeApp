# Design proposal: chapter strips

Board: `boards/chapters.png`. Pilots: chapters 1 and 4.

## Shared rules
- Canvas **160x56**, palette PNG8 of at most 24 colours; wide, low horizon, one light source per strip, a dithered sky as today.
- Chapter palettes are read from today's strips: night `#1E1032 #2C1746 #0C1A16`, teal `#2A3D4A #46607E #527EA9 #6AA0C8`, dusk `#5A2822 #92502F #3A2A1A`, light `#E8F2FA`, windows `#F2C14E`.
- Lit windows or lamps are the only warm points; no characters, no text, nothing in the bottom 8 px (the card overlays it).
- Each chapter keeps its mood and place (chapter 1 the roofs at dusk, chapter 4 the flooded arches); PixelLab redraws the same scene with more depth.

## Options (board)
Today (code-generated) vs PixelLab at 160x56 (recommended, same slot), or a 320x112 version scaled 2x (finer but off the pixel grid).

## Recommendation
**160x56**, pixen at 1 generation each, then reduce colours. Cost: about 3 per strip with retries; 6 for the pilot. The 6 other strips follow only if the user likes these.
