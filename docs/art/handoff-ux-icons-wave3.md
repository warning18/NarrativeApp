# Hand-off to UX: the other item icons, wave 3 (Art, 25 November 2026)

Approved by the user: V2 chibi colour, extended palette. Files only; nothing in the game was changed.

## What and where
`art/pixellab-icons-v2/handoff_wave3/<item id>.png` -> `assets/icons/items/<item id>.png` (replace; names are the item ids in `assets/gamedata/items.json`). **44 files, 32 x 32 PNG, transparent ground.** Together with wave 2 (93 files) every item of items.json has an icon except the merchant extras `salve`, `potion_bundle`, `marks` (in wave 2, not item ids).
- 11 other equippables: sword_001, rat_king_tooth, thug_knuckle_wrap, blackened_fang, dawnward_shield, halo_lance, tear_glass_blade, harborwatch_cutlass, hollow_court_blade, bloodthorn_blade, siphon_wand.
- 13 spellbooks (closed book, a cover colour and one emblem each), 11 materials and trophies, 4 charms, 2 tomes, scroll_fireball, quest_sealed_letter, elite_trophy.

The existing icons in `assets/icons/items/` are 16 x 16; these are 32 x 32 (a 32 px slot is needed, as for wave 2).

## The look and the palette
Same as wave 2: near-black outline 010000, chunky rounded shapes, smooth shadow/base/light ramps, one highlight; the extended palette `docs/art/boards/chibi-palette-extended.png` (hex in `art/pixellab-icons-v2/palette.py`). No region under 2 px.

## Known weak spots
thug_knuckle_wrap reads as a dark bundle (knuckle dusters); the rest were redrawn and are fine.

## Sheets
`docs/art/boards/icons-wave3-all.png` (44 at 3x, first try), `icons-wave3-cards.png`, `icons-wave3-fixes.png` (the 7 redraws before and after).
