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

## Result (25 November)
68 first tries + 22 retries = **90 generations (the cap)**; balance 1573 -> 1483. Round 1: 22 of the 68 came out as tiny characters wearing the piece (worn armour, "knight's", "sovereign") or the wrong colour; round 2 redrew exactly those, with "the piece alone, empty inside, no body, no head, no face, no person" (`RETRY` in `wave2_ids.py`), seed 7. Code pass `art/pixellab-icons-v2/post.py` (hero palette + red/heal/tide tokens, ink silhouette edge, no region under 2 px). Files `art/pixellab-icons-v2/final_wave2/<id>32.png` (32x32 PNG), raw in `raw_wave2/`. Sheets: `docs/art/boards/icons-wave2-all.png` (all 68 at 3x), `icons-wave2-cards.png` (6 icons on cards at 3x, 2x, 1x beside a Tower plate).
- Good: weapons (all five types), potions, marks, fate coin, boots, helms, relics, shields, the capes.
- Weak (no retry budget left): antidote reads beige, not green (the model ignored "green"; the palette has no green, needs the heal token or one more go); warden_signet (a pig-faced round helmet), hood_gravecloth and coat_last_watch (still small figures), dagger_t8 (a shard, not a dagger), greaves_hide (unclear shape).
