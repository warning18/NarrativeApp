# PixelLab backgrounds, first proposal

Raw output of `create_image_pixen`, two seeds (11 and 12) per background, for UX's
side-by-side with the current renders (`docs/ux-shots/backdrops-current/`). Not
bundled, no code change. 12 generations in total (plan balance 1349.53 to 1337.53).
No `reduce_colors` pass yet (it costs 0.1 a call; UX can quantize locally or ask).

Style suffix on every prompt: "16-bit pixel art, flat colour with a dark ink outline,
muted warm palette, no text, no characters, no UI". view/detail: `side` or `high
top-down` (sea), `medium detail`.

| File | Size | Prompt (before the style suffix) |
|---|---|---|
| `fields_s11/s12` | 180 x 320 | pixel art, side-on horizon view, flat green farmland field in the foreground, low rolling hills and a few round trees on the horizon, pale overcast morning sky with dithered gradient, empty open ground in the lower half for fighters to stand on |
| `dunes_s11/s12` | 180 x 320 | pixel art, desert horizon view, warm tan dunes, low sun glow in a hazy orange sky, flat sandy ground in the lower half with a few pebbles, empty |
| `sea_s11/s12` | 180 x 320 | pixel art, top-down bird's-eye view of open sea water, deep blue with long slow swell lines and a few white foam flecks, no ships, no land, seamless-looking |
| `street_s11/s12` | 208 x 128 | pixel art, narrow medieval harbour town street at dusk, facade of a tavern with a warm lit window on the right, cobblestones in the foreground, a faint sky between roofs, no people, no readable signs |
| `scene_s11/s12` | 200 x 100 | pixel art, side view of a frozen coast at twilight, pale snowy ground, dark jagged ice cliffs far away, cold violet sky |
| `tower_s11/s12` | 180 x 320 | pixel art, interior of a round stone tower room, dark blue-grey masonry, a tall narrow arched window with pale moonlight, a few wall torches, empty stone floor in front, mostly dark so UI text stays legible |

Findings:
- Sizes came out exactly as asked (PixelLab accepts any multiple of 4 up to 512 x 512 in area).
- The sea does NOT tile vertically: the seam row differs 2.0 to 2.6 times more than
  two ordinary adjacent rows. It would need a crossfade or a mirrored repeat, or
  stay a code painter.
- The prompts gave no characters, text or signs. The sea, tower and street read
  well; the fields seed 11 is dark and flat; the dunes seed 12 has hard black ridge
  lines.
- The tower seed 12 is cooler and lighter, seed 11 is warmer and darker; UI text
  legibility in the middle needs a check with the real tower screen.
