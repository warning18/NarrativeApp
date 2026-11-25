# Hand-off to UX: the Tower icons, wave 2 (Art, 25 November 2026)

Approved by the user: V2 chibi colour. Files only; nothing in the game was changed.

## What and where
`art/pixellab-icons-v2/handoff_wave2/<item id>.png` -> `assets/icons/items/<item id>.png` (replace; the names are the item ids in `assets/gamedata/items.json`). **93 files, all 32 x 32 PNG with a transparent ground.**
- **7 consumables and marks:** potion_minor, potion_major, antidote, salve, potion_bundle, marks, fate_coin. `salve`, `potion_bundle` and `marks` are the merchant's stock and the Tower's currency; they are not item ids in items.json, so the Tower screen picks them up under those names (a new asset path if needed, UX's call).
- **50 tiered weapons** (sword, spear, dagger, shield, staff x t1 to t10): five looks per type, copied under every tier id so no code mapping is needed: t1 and t2 share the t1 look, t3 and t4 the t3 look, t5 to t7 the t5 look, t8 and t9 the t8 look, t10 its own. The rarity colour in the UI tells tiers apart.
- **28 armour pieces** (every `Armor` item) and **8 relics** (void_banner, artifact_moon_shard, wisp_ember, saint_reliquary, sovereign_crown, harborwatch_lantern, hollow_court_seal, phoenix_sigil).

Note: the icons in `assets/icons/items/` today are 16 x 16; these are 32 x 32, so the item widgets need a 32 px slot (or show them at 2x of a 16 px box).

## The look
A thick near-black outline (010000), chunky rounded shapes, a small flat palette in smooth shadow/base/light ramps, one highlight. Palette: the Starter_basic_hero ramps plus muted red, ochre, green, teal, blue, violet (`docs/art/boards/chibi-palette-extended.png`, hex in `art/pixellab-icons-v2/palette.py`). Snapped in code: no region under 2 px.

## Known weak spots
warden_signet is a gold blob rather than a clear ring; coat_last_watch reads as a round armour bundle; hood_gravecloth is a pale cloth lump. They are placeholders until the user wants them redone.

## Sheets
`docs/art/boards/icons-wave2-all.png` (all 68 looks at 3x), `icons-wave2-cards.png` (on cards, beside a Tower plate), `icons-wave2-fixes.png` (the five redraws and the antidote), `chibi-palette-test.png` (before and after the extended palette).
