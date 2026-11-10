# Final panels and buttons (user's choice: A panels + C buttons)

Panels: direction A, the double ink line. Buttons: direction C, the flat pixel frame with a bevel. Free pixel drawing (no PixelLab generation), palette PNG8, no text.

Files: `dark/` (surface `#1F1C23`) and `parchment/` (surface `#EAE0C9`), each with `panel_<state>.png` (48x32) and `button_<state>.png` (40x16), states `normal`, `pressed`, `disabled`, `lit`.

Tokens kept: 1 art px = 2 dp. Panel corner 10 dp = radius 5 px; button corner 4 dp = radius 2 px. Layouts, sizes and text unchanged.

Nine-slice insets (`nine_slice.json`): panel 6 px on every side, button 4 px on every side. Corners stay fixed, edges and centre stretch (nearest neighbour, whole-number scale).

`spec.json` has the exact hex of every part per theme and state, and the geometry (line widths, the inner line 3 px inside the edge, corner stitches, bevel rows), so the same look can be painted in code instead of using the images. A code painter must draw without antialiasing.
