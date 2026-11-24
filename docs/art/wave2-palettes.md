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
