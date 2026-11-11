# Art direction: chibi dark medieval fantasy (one page)
Reference sheet: `docs/art/boards/art-direction-reference.png`. Palette: `art/pixellab-icons/shared_palette.json` (63 colours, one ink `#0A0807`). Owner: the Art session; UX wires, never restyles.

## The look
**Chibi dark medieval fantasy, in "Stitched Ink".** Chunky, readable shapes with big heads (head about 40% of a person's height, the ronin hero is the source), a thick clean 1 px ink outline (`#0A0807`) around every shape, flat colour in 3 to 4 tones per material, **light from the top-left** (shade falls right and down), a muted warm palette with **one accent colour per picture** (a faction colour, an ember, a lantern). **Rawer pixel clusters**: hard stepped edges, few colours, whole-pixel scaling, **no soft glow, no anti-aliasing, no gradients, no tiny confetti sparkles**. A world that is dim and worn, never grim-photoreal and never cute-bright. **Environments change the accent, not the base**: city amber, wilds green, coast teal, ash ember red, frost ice blue, sacred gold or void violet.

## What each category follows
| Category | Must follow | Reference files |
|---|---|---|
| **Characters and enemies** | side view, west for enemies (hero east), 60 px creatures and bosses, 48 px people, feet 1 to 2 px above the bottom, the hero's outline, proportions and shading, one accent colour | `assets/visuals/walker/ronin_idle_west.png` and the pro + style-reference test `art/pixellab-enemies2/style/white_admiral_pro_style_ronin_60.png` (sheet `style-test.png`). **The v3 enemies currently in `art/pixellab-enemies2/staged/` are NOT style references**: their realistic 3.5-head proportions drift from the hero; they are placeholders until the hero-style pass (`docs/art/enemy-hero-style-draft.md`) |
| **Icons** (16 px skills, items, HUD; 24 px UI) | one ink, shared palette, 1 px outline, gem or plate container, cream glyph, light top-left; harmonise, don't redraw | `art/pixellab-icons/harmonised/`, `art/pixellab-hud16/`, `art/pixellab-ui24/` |
| **Effects** (48 px strips, 40 px die landings) | 9 or 8 frames, appear / peak / fade, 5 colours plus ink, hard edges, re-tinted by element through a 4-step luminance ramp, no glow | `art/pixellab-vfx/final/`, `art/pixellab-attackfx/strips/` |
| **Backgrounds and scene bands** | 240x100 bands (story) and 180x320 plates (intro, fights), ink-outlined buildings, muted warm palette, one light source, no text, no figures unless asked | `art/pixellab-scenes/final/`, `art/pixellab-intro/final/`, `art/pixellab-backgrounds/fight/` |
| **UI frames** | 9-slice, 2 px ink with chamfered corners, 1 px light top-left and shade bottom-right, stitch or rivet detail, environment accent in the stitch tint and one corner ornament | `art/pixellab-chibi-frames/A_leather/` (PR #932), `art/pixellab-pilots/final/panels/` |
| **Maps** (town and room plans) | top-down painted plates, same ink and palette, the code's layout kept readable (places, doors, paths where the code expects them), no text baked in | the Ashen and casino proposals (next) |

## Do / don't
- **Do** start from an approved file; match its outline, palette and light; state the cost before a PixelLab call; stage palette-reduced PNG8 and hand off with a short brief.
- **Do** keep icons and effects hand-drawn or scripted when a shape is simple (0 generations); use PixelLab for characters, scenes and painted plates.
- **Don't** add a glow, a gradient, soft shadows, outer outlines in a second colour, or text in any picture; don't use more than about 6 colours per effect or more than the shared 63 per icon.
- **Don't** restyle an approved set; banners and icons are harmonised, never redrawn. **Don't** put a different face, outfit or proportion on a returning character.

## PixelLab prompt blocks (PixelLab has no negative-prompt field: the negatives go into the description as "no ...")
Common suffix **S**: `16-bit pixel art, chibi dark medieval fantasy, flat colour with a dark ink outline, muted warm palette, light from the top-left, no glow, no gradient, no text, no UI`.
- **Character or enemy** (`create_character`, mode `pro`, `style_character_id` `3cd4c1e2-a9b9-4b5b-945a-a219c084b7bd`, size 60 creatures / 48 people, view side, 10 generations; v3 at 2 generations is the cheaper, looser option): `<who, one accent colour, one prop>, chibi proportions with a big head, thick clean outline, S`. Then `animate_character` template `fight-stance-idle-8-frames`, west only, 1 generation.
- **Object, prop, creature image** (`create_image_pixen`, 1 generation, `no_background` true up to 256x256, `outline` "single color black outline", `detail` "medium detail", view side, direction west): `<thing>, S`.
- **Effect first frame, then strip** (`create_image_pixen` 48x48 `no_background` true, seed fixed per batch; then `animate_image`, `frame_count` 8, 1 generation): first frame `<effect>, hot bright core, centred, S`; action `<it> appears, peaks, then fades away until nothing is left`. Post-process with `art/pixellab-vfx/rawer_gen.py` (24 grid x2, 5 colours + ink).
- **Scene band** (`create_image_pixen` 240x100, `no_background` false, 1 generation a seed, two seeds): `pixel art, <place and hour>, <three concrete props>, wide low scene, no characters, S`.
- **Tall plate** (180x320, same call): `<place>, tall composition, S`.
- **Top-down map plate** (`create_image_pixen`, view `high top-down`, size by the plan, 1 generation a seed): `top-down painted plan of <place>, <layout words>, ink-outlined walls and floor planks, chibi dark medieval fantasy, no text, no figures, S`.
- **Settings summary:** outline "single color black outline"; detail "medium detail"; shading ignored by pro and v3; seeds pinned per batch; always check for baked text and odd details before staging.
