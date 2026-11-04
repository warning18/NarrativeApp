# Art catalog findings: two proposals (UX-2)

## 1. Skill icons: one glyph per skill (picture first, nothing built)

Finding: 157 skill icons are 85 drawings; the 16 px ones (the older skills) are
**blank gems**, the same diamond (or the Earth shield) in the element's colour.
17 martial skills share one grey gem, 8 fire skills one orange gem, etc. Only
the 32 px icons (added in 1.245) carry a pictogram.

Proposal: **the frame keeps carrying the school** (colour and shape, as today)
and **the glyph carries the skill**: a 7x7 cream pictogram in the gem's middle
(the area a diamond leaves free), drawn for each of the blank-gem skills.

Pictures (rows: today above, proposal below, for 12 skills across the martial
school, fire, wind and earth):
- `docs/ux-shots/art/skill-glyphs-proposal-16px.png` (the real size, x3)
- `docs/ux-shots/art/skill-glyphs-proposal-x8.png` (enlarged)
- `docs/ux-shots/art/skill_glyphs_sample.py` (the 12 bitmaps)

Costs: about 70 skills draw a new 7x7 glyph (the 16 px blank ones); the 32 px
icons stay. A generator `tool/gen_skill_glyphs.py` would hold the bitmaps and
paint them on the existing gems (no hand editing of PNGs).
Limits: at 16 px a 7x7 glyph is a hint, not a drawing; the Earth shield has
less room (5x5 reads best). Some glyphs (focus_mind, warcry) need a second look
on a phone.

## 2. Effect strips off palette (picture, branch `claude/ux-2-art-pictures`)

The 25 dice, element and keyword strips in `tool/gen_pixel_fx.py` used Material
Design colours. They now draw from one table (`PAL`, from `InkColors.dark`),
with `FROM_MATERIAL` saying what each old colour became; assets regenerated and
run through `tool/png8.py`.
Picture: `docs/ux-shots/art/fx-recolour-before-after.png` (die_bloom, el_water,
kw_pain; each pair is before above, after below).
Not done: the shared palette file and the PixelLab imports (later).
