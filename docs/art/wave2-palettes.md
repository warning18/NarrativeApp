# Wave 2: palette and head pictures for the user's choice (24 November, 0 generations)

Everything here is a nearest-colour remap or a code crop (`art/pixellab-wave2/remap.py`); nothing was generated and nothing in the game changes. Sheets are in `docs/art/boards/`.

## 1. Apollo remap of the 39 off-palette `pixel_fx` files
Sheets `wave2-fx-apollo-1.png` to `-4.png` (10 files each: the original above, the Apollo + cores version below). The remapped files are in `art/pixellab-wave2/fx_apollo/` (same names, PNG8) for UX to copy if the user says yes. The colours move only a little (the strips already used near-Apollo hues), so the change is small but exact.

## 2. One palette for the item, foe, shop and chest icons (220 files)
Two options, each a before | Apollo | ink triple per icon: `wave2-icons-items-1.png` to `-4.png` (132 items), `wave2-icons-enemies-1.png`, `-2.png` (64 foes), `wave2-icons-shops-chests-1.png` (14 shops and 10 chests).
- **Apollo** keeps every hue, snapped to the 46 colours: items stay readable by colour (potions, metals, gems).
- **Ink** (ten Apollo greys and three deep reds): hues are lost; red is kept only where the icon is already red (blades, the Compact shield, some gems). Items that differ only by colour (potions, tier variants of daggers) become hard to tell apart, so ink needs a spot of colour by hand for those, or the rarity frame to carry the meaning.

## 3. The hat-only heads (18): which need new art
`wave2-heads-hats.png`: each head, the icon it was cropped from, a code crop that looks for the face, and the full sprite where one exists. Finding: the sources are 16 px top-down blobs (a hat seen from above); most of them have **no face to crop**.
- **4 fixable by a better crop (0 generations)**: `inquisition_warden`, `iron_golem`, `street_bandit`, `void_sovereign` have a 48 px fighter sprite in `assets/visuals/fighters`; cropping its top 34 % gives a real face or helm. Sheet `wave2-heads-recrop.png`; the crops are in `art/pixellab-wave2/heads/`.
- **14 need new art or another picture**: `cultist_acolyte`, `dock_overseer`, `frost_kept_giant`, `hollow_reflection`, `horn_taker`, `inquisition_auxiliary`, `inquisition_soldier`, `smuggler_captain`, `slum_thug`, `strand_colossus`, `void_wisp`, `void_stalker`, `void_manifestation`, `hollow_court_zealot`. About 1 to 2 generations each (14 to 28), or UX's portrait card alone.

## 4. Ink versions for UX's part 4
Interpreted as: the 14 shop icons (the stall icons), the 3 Tower figures (`assets/visuals/tower/npc`: chandler, clerk, guardian) and the 8 shop keepers (`assets/visuals/keepers`, the stall NPCs). Sheet `wave2-ink-npcs-icons.png` (before | ink); files in `art/pixellab-wave2/ink/<folder>_<name>.png` (RGBA, ink palette). If UX meant other icons, tell me which and I redo it.

## 5. Icons in ink with one spot colour (the user's choice, 24 November, 0 generations)
Sheets `docs/art/boards/wave2-icons-inkspot-{items-1..3,enemies-1..2,shops-chests-1}.png` (before | ink + spot, 220 icons); files in `art/pixellab-wave2/ink_spot/{items,enemies,shops,chests}/` (same names, RGBA). Code: `ink_spot` in `art/pixellab-wave2/remap.py`.

**The accent rule.** Everything is the ten ink greys (090A14 to EBEDE9) except one hue per icon: the hue family with most saturated pixels (saturation over 0.4, value over 0.3, at least 3 pixels), drawn in a three-step ramp from Apollo:
| family | ramp (dark, mid, light) | carries |
|---|---|---|
| red | 411D31 752438 A53030 | blood, health potions, red gems, red blades |
| orange | 884B2B BE772B DE9E41 | fire, bronze, embers |
| gold | BE772B DE9E41 E8C170 | coins, gilt, holy light |
| green | 25562E 468232 75A743 | antidotes, poison, nature |
| blue | 253A5E 3C5E8B 4F8FBA | water, frost, steel-blue gems |
| purple | 402751 7A367B A23E8C | void, arcane, voidsteel |
Browns (wood, leather) and low-saturation colours stay grey, so the spot never lands on the material by accident. Counts over the 220 icons: no spot 60, gold 52, purple 30, red 22, blue 21, orange 20, green 15. The tier sets t1 to t10 of the dagger, shield, spear and sword stay distinguishable (checked: no two are identical); in the staff set t1/t6, t2/t7 and t3/t8 collapsed to the same picture (the originals differ only in the shaft's shade), so t6, t7 and t8 got their greys one step lighter by hand. Rarity is not encoded: where the frame does not show it, the hue carries it only when the original icon already had that hue.

## 6. The head test (8 generations, 24 November): it did not work
Board `docs/art/boards/wave2-heads-test.png`: Renn (`dock_overseer`), the exorcist (`horn_taker`), the captain (`smuggler_captain`) and the zealot (`hollow_court_zealot`), each current hat blob above and the two new tries below (`create_image_pixflux`, 32 x 32, img2img from Starter_basic_hero's head mirrored to face left, init strength 300; raw in `art/pixellab-heads/raw/`). All eight tries came out as Starter_basic_hero's own head with a slight variation: at that strength the model keeps the reference's face, hair and collar and ignores the hat, hood, cowl and scar. They are not usable as the four characters. Cost 8 generations (balance 1822). A retry at a lower strength (about 120, which lets the model change the head) would be another 8 generations for the same four: not spent.
