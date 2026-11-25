# Icons wave 2: Tower items, coins and stall (V2 chibi colour; Art, 25 November 2026)

User approved wave 2 (via the Manager): about 70 pieces, 90 generations max with retries. Style and recipe: `docs/art/style-brut.md` "Icon recipe: V2 chibi colour". Prompts per id: `art/pixellab-icons-v2/wave2_ids.py`. Generator `art/pixellab-icons-v2/gen.py`.

## The 68 ids (from `assets/gamedata/items.json` and `lib/data/tower/`)
The Tower drops the story's gear and potions (`towerSpoilsFor`), sells a salve and a potion bundle for marks (the run's coin), and has no perks (nothing in `lib/data/tower/` is a perk). So:
- **7 consumables, stall and marks:** potion_minor, potion_major, antidote, salve (merchant), potion bundle (merchant), marks, fate_coin.
- **25 tiered weapon looks:** sword, spear, dagger, shield, staff x t1, t3, t5, t8, t10. The 50 tiered weapons (t1 to t10) reuse the nearest look: t1-2 = t1, t3-4 = t3, t5-7 = t5, t8-9 = t8, t10 = t10; the rarity colour in the UI tells tiers apart.
- **28 armour pieces:** every `Armor` item (10 tops and cloaks, 7 heads, 6 legs, 5 boots).
- **8 relics:** void_banner, artifact_moon_shard, wisp_ember, saint_reliquary, sovereign_crown, harborwatch_lantern, hollow_court_seal, phoenix_sigil.
Left for wave 3: the 11 other equippables (unique weapons and charms), the 13 spellbooks, materials, tomes, scrolls, quest items.

## Cost
68 generations at 1 each, about 88 with retries (cap 90). Balance before: 1573.
