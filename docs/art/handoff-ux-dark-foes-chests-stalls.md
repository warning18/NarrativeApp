# Hand-off to UX: dark foe icons, dark chests, shop stalls (Art, 25 November 2026)

The user chose the dark chibi look (`docs/art/style-brut.md` "The DARK chibi look"). Files only; nothing in the game was changed. These **replace** the lighter wave 4 foe icons and the wave 5a chests; the old 5a shopfronts are retired.

## 1. Foes: 64 icons, 32 x 32
`art/pixellab-icons-v2/handoff_wave4d/<enemy id>.png` -> `assets/icons/enemies/<enemy id>.png` (names = enemies.json keys; today's are 16 px, so a 32 px slot is needed). Chibi bust or whole creature, muted, one rim light by faction (cold blue Dominion/angels/giants, ember gold Crows/Compact/Vigil/demons/beasts, sickly green Mire/undead, void violet Penitents/void). The 7 foes with a new full character (horn_taker, frost_kept_giant, smuggler_captain, strand_colossus, void_wisp, void_stalker, void_manifestation) were redrawn from the darkened characters; plague_hound from its sprite. Sheet `docs/art/boards/icons-wave4d-all.png`; the five redrawn weak ones `icons-wave4d-fixes.png`.
The 7 darkened characters themselves (48 px, west/east/south/north) are in `art/pixellab-chars7/final_dark/<id>/`; their head crops (lighter version, to be darkened if wanted) in `art/pixellab-heads-crops/handoff/`.

## 2. Chests: 10 icons, 32 x 32
`art/pixellab-icons-v2/handoff_chests_dark/<tier>_<closed|open>.png` -> `assets/icons/chests/` (same names). Sheet `docs/art/boards/icons-chests-dark.png` (current | dark). Moody but murky; the open ones show a glow and a small spill.

## 3. Shops as stall elements: 14 stalls + 14 list icons
`art/pixellab-icons-v2/handoff_stalls/<shop id>.png` (96 x 64, transparent) and `<shop id>_icon32.png` (32 x 32, for lists); shop ids = shops.json keys. Suggested paths: `assets/visuals/shops/<id>.png` and `assets/icons/shops/<id>.png`.
- Layer order: background -> shopkeeper NPC -> stall. The space between the posts above the counter is transparent.
- Anchors (stall coordinates): opening about x 14..82, y 8..40; counter top about y 40; put a 48 px NPC centred at x 48, feet at about y 52 (hidden by the counter); the stall's bottom edge on the ground line of the plate; scale 2x on a 180 px wide plate.
- The NPC and the background change freely; one stall per shop.
Sheets `docs/art/boards/stalls-all.png` (14 stalls and icons), `stalls-composites.png` (6 stalls on a Tower plate and a street plate with different NPCs).

## Known weak spots
Foes: a few are murky or very similar (hollow_reflection, tear_spawn). Chests: the open ones are busy. Stall list icons: small and alike (the trade sign is not readable at 32 px); 12 proper 32 px icons would cost 12 generations.
