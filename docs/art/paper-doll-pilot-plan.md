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

## Pilot done (25 November): 15 generations, balance 1751
Base: Starter_basic_hero east idle, 48 x 48 (`art/pixellab-paperdoll/raw/base.png`). Three layers, each one `inpaint_image_pro_flash` call (5 generations) on the base with a rectangle mask, output "New layer with changes", seed 1: **helm** (iron cap with a nose guard; mask x 8, y 0, 18 x 15), **chest** (studded dark leather jerkin; x 6, y 14, 24 x 18), **boots** (tall dark brown leather boots; x 8, y 34, 20 x 14). Each layer is cut as the pixels that differ from the base (208, 174 and 110 pixels) and staged as a transparent PNG8: `art/pixellab-paperdoll/final/layer_{helm,chest,boots}.png`, with `composite.png` (the base with the three layers). Board `docs/art/boards/paper-doll-pilot.png` (base | helm | chest | boots | all three | mirrored for west).
**Result:** the layers line up on the base and read as gear: the helm and boots are clean, the chest jerkin is the weakest (a few stray dark outline pixels at its back edge and a gap at the front, where the shirt shows through), and the helm sits over the hair so that the hair under it turns grey-tinted. West is the east layers mirrored in code, which works. Not yet tested: other poses (each pose is a new inpaint), tints by tier in code, and a walk strip as one sheet (6 more generations).

## Gear, further (25 November): 16 generations, balance 1718
- **Chest redone** (5): mask x 4, y 14, 28 x 19, "a complete studded dark leather jerkin covering the whole torso down to the belt", seed 2: `art/pixellab-paperdoll/final/layer_chest_v2.png` (220 px): now a closed jerkin, no gap at the front and no stray outline strands.
- **Helm redone** (5): the mask only on top of the head (x 8, y 0, 22 x 10), "a plain iron cap helmet sitting on top of the head only, the black hair below it stays black", seed 2: `layer_helm_v2.png` (145 px): the hair under it stays black.
- **Boots**: unchanged (`layer_boots.png`). `composite_v2.png` is the base with the three v2 layers.
- **Walk strip** (6): the 8 east walking frames of Starter_basic_hero cropped to 48 x 48 in a 4 x 2 sheet (192 x 96, `art/pixellab-paperdoll/walk/sheet_base.png`), one `inpaint_image_pro_flash` call with a mask over the helm, torso and boots of every cell (`walk/mask.png`), "the same hero walking ... iron cap helmet, studded dark leather jerkin, tall dark brown leather boots, the same gear in every frame", seed 3. **The gear is consistent across all 8 frames**: the same cap, the same jerkin, the same boots, the walk pose kept. The per-frame layers (the pixels that differ from the base frame, transparent elsewhere) are `walk_gear_frame0.png` to `walk_gear_frame7.png` (48 x 48). One call gives all three layers together for the whole strip: 6 generations instead of 5 per layer per frame.
- Board `docs/art/boards/paper-doll-pilot2.png` (base | helm | chest | boots | all three; below the base walk frames and the same frames with gear).
- Caveat: the three layers of the walk strip come from one call, so they are cut from the masked regions together (a layer boundary is the mask edge); the cut is by region, so a jerkin sleeve crossing the boots region would belong to the wrong layer, which does not happen in these frames. Not tested: tier tints in code, a west walk (mirror), other armour looks (each is one more call of 6 for a strip).
