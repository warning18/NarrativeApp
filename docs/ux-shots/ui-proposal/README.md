# UI proposal: one pixel game (pictures first, no code)

The user's focus: skills, event-interface icons and the UI. Today the game is
pixel art (377 PNG icons, sprites, banners) inside a Material shell (378
Material glyphs, thin outlines, rounded pills and cards). Inventory of the
families: `docs/ux-shots/icons-inventory/` (on `claude/ux-2-icons-inventory`).

All "before" pictures are the real screens at 412 (the real widgets, the app's
fonts, a level-6 human warrior). "After" pictures are mock-ups: placeholder
16x16 sprites drawn by me (`placeholder-sprites.png`) stand in for Art's set;
item and skill icons are the real PNGs at an exact scale.

## The rules the mock-ups follow

1. **One grid.** Icons are 16x16 art pixels; 1 art pixel = 1 or 2 dp, so an icon
   is 16 dp (chips, rows, strip) or 32 dp (nav, slots, nodes, headers), and 48 or
   64 dp for big ones. No more 18, 20, 14, 13, 26 dp icons (today 18 dp is the
   most used size: 108 uses; 16 dp 52; 20 dp 49; 14 dp 39).
2. **Pixel icons for things, Material only for pure chrome** (chevrons, close,
   back arrows may stay vector for now: they are the 6 most reused glyphs and
   must stay legible at 14 to 18 dp).
3. **Square pixel corners** on chips and frames (no pills, no circles).
4. **Locked = the same icon faded, with a pixel lock on it**, not an empty ring.

## The pictures

| # | Picture | What changes |
|---|---|---|
| 1 | `1-header-stats-nav.png` | header home/scales, the stats strip (level, day, health, mana, gold, journal, map) and the 4 nav tabs become pixel icons: 16 dp in the strip, 32 dp in the nav and header |
| 2 | `2-inventory.png` | empty-slot glyphs (Head, Legs, Feet) become pixel silhouettes; item icons at an exact 2x (32 dp; today 28 dp smears); filter chips with square pixel corners |
| 3 | `3-skills-tree.png` | skill icons at an exact 4x (64 px; today about 1.6x, it smears), chamfered square frames instead of thin circles, pixel lock and star |
| 4 | `4-fight-hud.png` | the 4 condition chips and the round flag: 16 dp pixel icons in square-cornered chips at the same 32 dp size |
| opt | `option-panels-a-buttons-c-*.png` | ON HOLD, the user's call: code-painted pixel frames for panels (A) and buttons (C), from `claude/ux-2-panels` |

Not drawn here, same rules apply: Journey and road events (the way pins' glyphs,
33 Material glyphs, become pixel; the banner pins already are), character
screen (stat icons), camp/other lists (chevrons, lock icons), shops.

## Ranked: impact vs cost

| Rank | Change | Impact | Cost | Needs |
|---|---|---|---|---|
| 1 | Skill and item icons at exact scales (32 / 64 dp) everywhere they are drawn (skills tree, rows, rewards, die facets) | high: the best art in the game stops smearing | small: a size table in `lib/theme` and about 30 call sites with `size:` literals | nothing from Art |
| 2 | Missing icons: 14 enemies, 5 skills, 2 items; elements Lightning, Ice, Holy, Dark (today the same empty circle) | high: visible holes in fights and the bestiary | small in code, Art draws 25 icons | Art |
| 3 | Header, stats strip and nav bar as pixel icons (picture 1) | high: on every screen, all day | small: 3 files, 25 glyphs | Art's set |
| 4 | Fight HUD chips, die face kinds, rule words, spell effects, elements (about 30 glyphs) | high in the fight (the screen played most) | small to medium: `face_style.dart`, `game_icons.dart`, chips | Art's set |
| 5 | Locked / empty states as faded pixel + pixel lock/star (pictures 2, 3) | medium | small | Art: lock, star, 6 slot silhouettes |
| 6 | Square pixel chips and tabs (pictures 2, 4) | medium | medium: the theme's chip, tab and filter styles, 360 and 320 checks | none |
| 7 | Journey way glyphs (33) and road-event cards | medium: it is the game's main screen but they are small | medium: the idle motions (sway, flicker) must be kept as sprite transforms | Art |
| 8 | Panels A + buttons C (code-painted frames) | high for the "one game" feel | medium to large, touches every card and button, risk at 320/360 | ON HOLD |
| 9 | Replace the six vector chrome glyphs (chevron, lock, check, close, add, arrow) with pixel ones | low to medium | small, but must read at 14 to 18 dp | last |

My order if the user says go: 1 (needs nothing), then 2 + 3 + 4 with Art's set,
then 5 and 6, then 7; 8 stays the user's call.

## Honest limits

- The sprites in the "after" pictures are placeholders I drew in minutes, not a
  style proposal. Art's guide sets the look; these show only where icons go,
  which sizes, and how frames sit.
- Pictures 2 and 3 are edits over real screenshots (the items in picture 2 use
  made-up ids, so two rows show the generic box); no layout was changed.
- 360 and 320 widths are not drawn yet; the 16 / 32 dp scale does not change
  any layout width, so they should not shift, but I would picture them before
  any code.
