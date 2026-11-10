# Skill animations: a proposal (picture first, nothing wired)

Sheet: `docs/art/boards/skill-effects-pilot.png` (each style: today's strip, the new strip, the new strip re-tinted). Files: `art/pixellab-vfx/staged/vfx_<style>.png` (9 frames of 48x48 = 432x48, PNG8), `art/pixellab-vfx/gif/<style>.gif` (to watch them move, 90 ms a frame), raw frames in `raw/`. Pilot: 6 of the 29 styles (flame, frost, lightning, heal, void_rift, shield), **13 generations** (balance 1159.5 to 1146.5).

## How skill effects work today
`skills.json` gives each skill a `vfx` style (29 styles; radiance 12 skills, heal 10, stone_shield 10, void_rift 9, shout 9, flame 9, shadow 8, pierce 8, heavy_slash 8, shield 7...). `lib/combat/skill_vfx.dart` maps style to a strip in `assets/visuals/pixel_fx/` (`vfx_<style>.png`, 384x48 = 8 frames of 48x48, **grey masks**), and the element decides the colours in code ("a Fire heal glows warm and a Void heal dark from the same `heal` style"). The grey masks are clean but thin: one outline of white pixels, a dither fill, no hot core.

## The proposal
**Redraw the 29 strips as full-colour, outlined, hot-core animations in the hero's Stitched Ink style**, keeping the mechanism: the code re-tints a strip by element through a 4-step luminance ramp (shadow, mid, light, core), so one drawn style still serves every element (bottom rows of the sheet: the flame as a teal Water flame, the void rift as a Fire rift).
- **Pipeline (PixelLab):** a first frame (`create_image_pixen` 48x48, 1 generation) animated into 9 frames (`animate_image`, 8 frames + the input, 1 generation). 2 generations a style.
- **Tint:** luminance quantised to 4 levels and mapped to the element's ramp (done in the sheet by script; UX does it in code, or ships pre-tinted strips per element).
- **Size:** 9 frames x 48 = 432x48 PNG8, transparent, 90 ms a frame (about 0.8 s, close to today's).

## What the pilot shows (honest)
- **Frost, lightning, void rift, shield** have a real life cycle: they appear, peak and fade; they read far better than today's masks.
- **Flame and heal** came out as loops: they flicker or glow but do not dissolve. Two fixes: the code fades and shrinks the strip out (it already does for the masks), or one retry each pinned to a faded last frame (`animate_image` has a last-frame option): 1 generation each.
- **Re-tinting works**, with some loss of fine colour detail; Fire, Water, Void and Light ramps are in the sheet's script.
- These are **centred effects**; travel (a slash, an arrow, a meteor, a bolt) stays code motion over the strip, as today.

## Cost of the whole set
- **Tier 1, all 29 styles redrawn:** 29 x 2 = 58 generations, about 70 with retries (flame/heal-type fixes, rejects). Pilot 6 are done (13 spent, 2 re-do needed at most).
- **Tier 2 (optional, new): signature animations** for the 9 legendary and 43 epic skills, each in its own colours (not a shared style), 64x64, about 3 generations each: about 150. Only if the user wants them; Tier 1 alone already changes every skill.
- Ids, numbers and which skill uses which style do not change (`vfx` in `skills.json` is Core's).

## Next (needs the user's pick)
Approve the direction and the tint mechanism, then Tier 1 in batches of 10 styles (about 20 generations each), a sheet per batch before UX-2 wires it.
