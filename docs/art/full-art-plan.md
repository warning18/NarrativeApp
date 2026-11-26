# Full art plan: every visual element of the game (Art, 25 November 2026)

Nothing here is generated yet. Counts marked "~" are estimates until I list the ids per category (the first step of each wave). Balance today: **1573 generations** (reset 16 December). Every wave is at most 70 pieces and waits for the user's OK; each ends with a sheet and stops before anything goes to UX.

## What PixelLab makes and what stays code

PixelLab: every drawn picture (characters, heads, icons, plates, scenes, vignettes, banners, dice shapes, frames, panels, buttons, chips, seals, stamps). Code: all text and numbers, live bars and meters, layout, the pips and numerals on dice, the 9-slice stretching, the palette snap and the speck merge. Skill icons (157, Apollo palette) and effects stay as they are: they are the skill language, UX owns the effects.

## The elements, Tower first, then the story

| # | Element | Where | Count | Size | By | Status | Gens (with retries) | Order |
|---|---|---|---|---|---|---|---|---|
| 1 | Tower plates (bands, wards, bosses, shop, bargain, parley, win, lose) | Tower screen | 14 | 180x320 | PixelLab | approved, handed to UX | 0 | done |
| 2 | Tarot vignettes (elements, die, spells) | Tower cards | 14 | 96x64 | PixelLab | approved, handed to UX | 0 | done |
| 3 | Seals 1 to 5 dots, tarot frame, "new" stamp | Tower cards | 7 | 32 / 112x160 / 48 | PixelLab | done (ink set), check against the icon look | 0 | done |
| 4 | Clan banners | clan cards, Tower offers | 6 | 64x128 | PixelLab | approved | 0 | done |
| 5 | Dice shapes (blank faces; pips and numerals are code) | every roll | 6 (d4, d6, d8, d10, d12, d20) | 44 | PixelLab + code | approved; d10 made in code | 0 | done |
| 6 | **Card frame**: the rounded card only (user's decision, 25 Nov; the other 5 manga frame shapes are dropped) | cards | 1 (+ dim version in code) | ~112x160, 9-slice | PixelLab (1 gen, text only) + code slice | to make | ~4 | wave 1 |
| 7 | **Ink kit**: panel, button (normal, pressed, disabled), chip, tab, bar frame, seal button | every screen | ~8 pieces | 24 to 48 px, 9-slice | PixelLab + code slice | to make (code-drawn kits exist) | ~22 | wave 1 |
| 8 | **Icons: Tower items, coins, perks, stall** | Tower, shops | ~70 | 32 | PixelLab | to make, V2 chibi colour | ~90 | wave 2 |
| 9 | Icons: the other items (equipment, consumables, keys) | inventory | ~62 | 32 | PixelLab | to make | ~80 | wave 3 |
| 10 | Icons: foes | bestiary, fight | 64 | 32 | PixelLab | to make | ~83 | wave 4 |
| 11 | Icons: shops and chests | city | 24 | 32 | PixelLab | to make | ~31 | wave 5 |
| 12 | Foe heads | fight, cards | 18 | 13 to 28 px wide | crops of full chibi characters | 11 done (crops), 7 to make | 7 characters x 10 = 70 (+14 retries) | wave 5 |
| 13 | Fight plates | fights | 30 | 180x320 | PixelLab | to make (cut paper, text only) | ~39 | wave 6 |
| 14 | Scenes (chapters, life art, bands) | story | 73 | 240x100 | PixelLab | to make | ~95 | waves 7 and 8 |
| 15 | Heroes, races, NPCs, fighters (full characters) | everywhere | existing | 48 | PixelLab | done; paper doll on hold | 0 | none |
| 16 | Map pieces (painted plates, ground, props) | Maps session | not counted | n/a | PixelLab, asked through the Manager | none asked | 0 | on request |

## Icons: the user picked V2 chibi colour (25 November)

- **Look:** chibi shapes (chunky, rounded, squat, oversized parts), the Starter_basic_hero palette forced, a thick dark outline, one highlight, one inner shadow, a material read (glass, steel, leather, wood, cloth).
- **Cost:** 1 generation per icon, text only, about 1.3 with retries; the code pass is free. About 220 icons, about 290 generations in 4 waves, as in the table.
- **Fixes noted from the test:** the key's bow came out busy (prompt: "a plain round ring bow, one simple shape"), the shield came out as a round badge (prompt: "a heater shield, pointed bottom"); the antidote's liquid takes the heal green only when the item is a healing one (the hero palette has plum and copper, so other liquids use those).
- **Recipe:** `docs/art/style-brut.md`, section "Icon recipe: V2 chibi colour". The ink version (V1) stays available in code from the same files (`inkify.py`) if a screen needs a one-colour icon.

## Consistency method

1. **One style reference**: the Starter_basic_hero sprite palette forced on every icon and character-scale piece (the user's V2 pick); ink, paper and the red token on the ink pieces (Tower, tarot, plates).
2. **Palette snap** after every call (free, in code): ink 090A14, paper E7E1CD, paper shadow C9C2A6, deep red A53030, heal 7DBE6A, tide 4FB0B0 and the clan hues, nothing else.
3. **The detail rule from Ashen Ink**, with the relaxation for icons: no isolated specks, 2 px minimum region; silhouette edge always ink; plates keep 60 px minimum regions on new plates.
4. **A sheet before any hand-off**, at 1x and 3x next to a Tower plate and a card, then the user picks.
5. Known weak spots and the way round them:
   - Dice: PixelLab draws black cubes. Text-only gave cubes for every shape, so the shapes come from init strength about 100 on bone dice, d10 in code, pips and numerals in code.
   - 16 px: the style does not hold; icons are 32 px, heads are crops of full characters (a generated head gets a face in profile).
   - The word "chibi": it draws characters. Say "chunky, rounded, squat, oversized parts" in the prompt, or force the hero palette and derive ink in code.
   - High init strength copies texture: text only for scenes and icons, init only with strength about 80 and a clear emblem to keep (banners).
   - Pixen needs a square canvas below 32 px; pixflux caps the size, so plates use pixen.
   - Specks in generated icons: the code merge handles them; the helm and the key are the worst.

## Waves and totals

| Wave | Content | Pieces | Gens with retries | Running total | Balance left |
|---|---|---|---|---|---|
| 1 | Card frames + ink kit (rows 6, 7) | ~14 | ~40 | 40 | ~1530 |
| 2 | Icons: Tower items, coins, perks, stall (row 8) | ~70 | ~90 | 130 | ~1440 |
| 3 | Icons: other items (row 9) | ~62 | ~80 | 210 | ~1360 |
| 4 | Icons: foes (row 10) | 64 | ~83 | 293 | ~1280 |
| 5 | Icons: shops, chests (row 11) + 7 foe characters (row 12) | 24 + 7 | ~31 + ~84 | 408 | ~1165 |
| 6 | Fight plates (row 13) | 30 | ~39 | 447 | ~1125 |
| 7 | Scenes, first half (row 14) | ~37 | ~48 | 495 | ~1075 |
| 8 | Scenes, second half (row 14) | ~36 | ~47 | 542 | ~1030 |

Total about **542 generations** of the 1573 left, about a third of the cycle's allowance. Wave 5 is above 70 generations (the 7 characters are 10 each): I split it into two calls, shops and chests first, then the characters.

## Rules for each wave

- I state the cost before every call and ask the user's OK before each wave.
- Each wave begins by listing the exact ids and the final count from the gamedata.
- Hand-off to UX goes only through the Manager and only after the user picks; I change no layout, number or id.


## Updates (25 November, later)
- Row 6 (card frames) shrank to the rounded card alone; nothing to generate for the other five. Wave 1 is now the rounded frame (about 4 generations) plus the ink kit (row 7, still waiting for the user).
- Waves 2 to 5 are done (see `docs/art/icons-wave2.md` to `icons-wave5a.md`, `chars7.md`, `dark-redo.md`, `dark-batch2.md`). Looks: items stay in the lighter chibi colour look; foes, shop stalls, keepers and shop scenes are dark; chests keep the lighter ones (`docs/art/style-brut.md`, "Which look for what"). Balance 1083.
- Still to do: wave 1 (rounded frame, ink kit), wave 6 (fight plates, ~39), waves 7 and 8 (scenes, ~95), each on the user's OK.

- Fight plates (row 13, wave 6): **cancelled** by the user on 26 November ("the actual backgrounds were better"). 27 generations were spent on a 22-plate cut-paper test batch (kept, not handed off: `docs/art/handoff-ux-fightplates.md`). Nothing more is planned for fight plates.
