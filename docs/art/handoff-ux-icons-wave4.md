# Hand-off to UX: the 64 foe icons, wave 4 (Art, 25 November 2026)

V2 chibi colour, extended palette. Files only; nothing in the game was changed.

## What and where
`art/pixellab-icons-v2/handoff_wave4/<enemy id>.png` -> `assets/icons/enemies/<enemy id>.png` (replace; names are the keys of `assets/gamedata/enemies.json`). **64 files, 32 x 32 PNG, transparent ground.** The icons there today are 16 x 16, so the foe widgets need a 32 px slot (as for the item icons).

Each is a chibi bust (head and shoulders) or, for beasts and creatures, a whole small creature, with the clan hue on the clothes (Dominion blue-white, Crows pink and dark red, Compact ochre, Mire green, Vigil yellow, Penitents violet, Void purple). Near-black outline 010000, smooth shadow/base/light ramps; palette `docs/art/boards/chibi-palette-extended.png`, hex in `art/pixellab-icons-v2/palette.py`; no region under 2 px.

## The seven foes that have a full chibi character
inquisition_warden, iron_golem, plague_hound, rat_matriarch, street_bandit, void_sovereign, white_soldier were redrawn **from their character** (the sprite's bust or whole body as the starting image), so the head, colours and gear follow the character. White_soldier is faceless like the character.

## Known weak spots
kraken_arm reads as a curled teal tentacle (a little like a wisp); hollow_reflection is a hooded blue-grey figure; void_manifestation is a purple cloud without clear faces. All are placeholders until the user wants them redone.

## Sheets
`docs/art/boards/icons-wave4-all.png` (all 64 at 3x, the 11 fixed ones marked with a red star), `icons-wave4-fixes2.png` (the fixes: sprite, previous, new), `icons-wave4-cards.png`, `icons-wave4-fixes.png` (first redraw round).
