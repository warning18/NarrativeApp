# Catalogue of generated assets

One row per PixelLab generation made by the Art session: prompt, seed, model, size, cost, date, and the app element it is for.
Style suffix for backgrounds: "16-bit pixel art, flat colour with a dark ink outline, muted warm palette, no text, no characters, no UI"; view `side`, `medium detail`.

| File | For | Model | Size | Seed | Cost | Date | Prompt (before the suffix) |
|---|---|---|---|---|---|---|---|
| `art/pixellab-backgrounds/tower_band2.png` (raw: `raw2/b2`) | Tower floor background, floors 11 to 20 | pixen | 180x320 | 11 | 1 | 2026-11-10 | pixel art, interior of a round stone tower room higher up, cold blue-violet masonry, two narrow arched windows with pale moonlight, iron brackets with a single guttering torch, a stair curving up the wall, empty stone floor in front, mostly dark so UI text stays legible |
| `art/pixellab-backgrounds/tower_band3.png` (raw: `raw2/b3`) | Tower floor background, floors 21 to 30 | pixen | 180x320 | 11 | 1 | 2026-11-10 | pixel art, top of a ruined round stone tower, cracked dark masonry, a broad broken opening onto a night sky with a few stars and drifting ash, embers glowing in an iron brazier, empty stone floor in front, mostly dark so UI text stays legible |
| `art/pixellab-backgrounds/tower_band1.png` | floors 1 to 10 | pixen | 180x320 | 11 | 1 (earlier, Manager) | earlier | the earlier `tower_s11`, quantized |

Quantized with PIL median cut to 24 colours, no dither, saved as 8-bit palette PNG. Balance 1331.5 before, 1329.5 after.
