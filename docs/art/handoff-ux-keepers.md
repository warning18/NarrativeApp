# Hand-off to UX: the 6 new shop keepers (Art, 25 November 2026)

Dark chibi recipe (`docs/art/style-brut.md`), 64 x 64 PNG, transparent ground, standing straight, seen from the front, hands low (they rest on the counter). Made as one picture each (1 generation, text plus the Starter_basic_hero south sprite at low strength for the proportions, dark palette forced, then snapped; `art/pixellab-keepers/gen.py`): 6 generations, no retries.

## Files
`art/pixellab-keepers/handoff/<id>.png` (bottom-aligned, so the feet are at the canvas bottom): `beggars_cellar_boy` (blind_beggar_stall), `shieldwright` (shieldwrights_hall), `vault_keeper` (smugglers_vault), `needle_house_keeper` (sharpweave_den), `hammersmith` (hammersmith_forge), `caravan_master` (wayfarer_caravan). The other shops keep an existing NPC.

## How to layer (stall coordinates, 96 x 64)
Background -> keeper -> stall. Centre the keeper at x 48 with its **top at stall y 2** and clip the keeper layer to the stall's 96 x 64 box: the head and chest then show in the opening (y 8 to 40) and the counter hides the rest. A 48 px NPC (existing chibi NPCs) still goes feet at y 52.
Sheet `docs/art/boards/keepers-composites.png` (each keeper behind its stall, on a Tower plate and a street plate). A bit more of the beggar boy's feet show under the counter than the others; clipping at y 60 cleans it.
