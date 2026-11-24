# Paper-doll pilot plan (Art, 24 November 2026; cost first, nothing called)

The user prefers the paper doll: one neutral base body plus gear layers that line up. Plan, with costs.

## Facts the plan rests on
- **Inpainting freezes everything outside the mask**, so a layer can be cut exactly as the difference from the base (the changed pixels inside the mask). `inpaint_image_pro_flash`: 5 generations for a canvas up to 96 px (6 up to 208 px), one image per call. `inpaint_image` (the older tool): 10 per image. Both need the layer's rectangle as the mask.
- The game's fight shows **a single idle still** per figure (`assets/visuals/fighters/<sprite>_idle_west.png`, one 48 px frame; the hero's idle is one 42x47 frame). The walk strips are used on the road only.
- **The data has 97 equippable items out of 134, not 132**, and only **36 of them are body armour**: Head 11, Top 14, Bottom 6, Foot 5. The other 61 are Weapons (sword, spear, dagger, staff and shield, 10 tiers each, plus 11 single weapons). So the layer slots the items need today are head, chest (Top), legs (Bottom) and feet (Foot) as body layers, and weapon (with the shield as the same kind of held piece). Hands, cloak and offhand are not in the data (the cloak and the circlet are armour pieces inside Top and Head).

## Pilot: base, 3 layers, idle pose
1. **Base**: Starter_basic_hero, east idle, 48 x 48, side view, plain clothes, bare head and feet (the hero already is: no new generation).
2. **Three layers** by inpainting the base with a rectangle mask each, `inpaint_image_pro_flash` at 48 px: **helm** (rows 0 to 16), **chest piece** (rows 14 to 32), **boots** (rows 34 to 48): 3 x 5 = **15 generations**. A retry per layer is another 5 (cap 25 for the pilot).
3. **Cut**: each layer is the pixels that differ from the base inside its mask, saved as a transparent PNG; the base plus the layers in any order must reproduce the inpainted picture (a check in code).
4. West is the east layers mirrored in code: 0 generations.
5. **Output**: a board with the base, each layer, and the base with all three, at 1x and 4x.

## The fight animation: what it costs, and whether a still is enough
- **A still idle is enough for the fight today**: the fight uses one standing frame per figure (hits and flinches are drawn by code effects). So the pilot's idle layers serve the fight without more art.
- If the fight later wants motion: a walk or attack is one inpaint per layer per frame, **5 generations per layer per frame**, or a whole strip in one call as a sheet (6 frames of 48 px fit one 144 x 96 sheet = 6 generations per layer, 18 for three layers), if the model keeps the layer identical across the cells. That is untested; the pilot can test it with one layer for 6 more generations. If the cells drift, it falls back to 5 per frame per layer (30 per layer for a 6-frame walk).

## Slots and total cost for the equippable items
| Plan | Layers | Cost (idle still, 5 generations a layer) |
|---|---|---|
| Each body item gets its own layer | 36 (head 11, chest 14, legs 6, feet 5) | 180 |
| Layers shared by material, tier by tint in code | about 20 (5 materials: cloth, leather, mail, plate, robe or cloak, x head, chest, legs, feet) | 100 |
| Weapons and shields (61) | held pieces: the 16 px item icons rotated at a hand anchor per frame (anchor table by UX or Core) | 0, or 5 families x 1 generation for in-hand art |
For the 97 equippable items: about **180 generations for own-layer armour** or **about 100 for shared looks**, plus 0 to 5 for the held pieces. With a walk strip per layer (6 more per layer if the sheet trick works): add 120 to 216. Recommended: shared layers by material, tint by tier in code, held pieces by overlay.

## Risks
- A layer made for the idle pose does not fit another pose; each pose is a new inpaint.
- A helm that changes the silhouette (a plume, horns) needs a mask larger than the head; the cut then includes background, fine as a transparent layer.
- The model may redraw the masked area in the base's colours, giving a layer that differs only a little: the pilot shows whether layers read.
