# PixelLab backgrounds vs the code painters (UX-2 proposal)

Pictures only. `compare-<name>-<412|360>.png`: left = today's real render (code painter), middle and right = PixelLab seeds 11 and 12 (raw files in `art/pixellab-backgrounds/` on the Manager's branch ccr-76229db7-131ulj), scaled to cover with nearest-neighbour, no quantizing yet. The tower picture puts each seed behind today's real Tower screen by compositing (today's screen is the light page, so the text edges are rough; it only shows legibility).

Cost: 12 generations used 12.0 plan credits (1 per generation). Each raw PNG is 8 to 60 KB.

| Background | Pick | Recommendation |
|---|---|---|
| Fight ground, fields / dunes | fields s12, dunes s11 | Good-looking statics, but a fight stage must also take 8+ stages, the day's light, night with lamps, weather and anomalies; the painters tint and animate. Ship PixelLab only if we accept one static still per stage and tint it in code. Keep the painters for now. |
| Sea battle (top-down) | none | Keep the code painter: the sea scrolls and the PixelLab image does not tile vertically (seam 2 to 2.6x ordinary). |
| Town street | s11 or s12 | Reads very well, but the street is parametric (building kind, name, 4 day phases, weather, pins). One image per combination is dozens of generations and APK weight. Keep the painter; use PixelLab for a few set pieces (Candlehold gate) at most. |
| Scene stage (side view) | s12 | The stage is parallax layers that move; a still loses that. Keep the painter. |
| Tower floor | s11 (warm, dark) behind a 55 % dark scrim | The one real win: today the Tower has no backdrop, so this is new, static and one image per band (3 in all). The middle needs a scrim for text; s12 is too light for that. |

Shipping notes: static PNG per background at the native size, shown with `FilterQuality.none` and cover-fit; `reduce_colors` to about 24 colours (0.1 a call) or quantize locally so it fits our palette; dark theme only (the light page would need its own). Full set at 2 tries each: about 65 generations (10 fight stages, 3 tower bands, 8 streets x phases, 8 scenes), roughly 65 credits.

Recommendation: ship the Tower floor from PixelLab (3 images), keep the code painters everywhere else.
