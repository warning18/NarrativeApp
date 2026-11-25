# Hand-off to UX: dark shop scenes and the final stall icons (Art, 25 November 2026)

## 1. The 14 dark shop scenes (NEW files; the originals stay for the story scenes)
`art/pixellab-shopscenes/handoff/<scene id>_shop_dark.png` (240 x 100 PNG, no alpha) -> `assets/visuals/scenes/<scene id>_shop_dark.png`, for the shop strip only. Mapping: weaponsmith -> saltmouth_yard, apothecary -> saltmouth_tern_row, ossuary -> drowned_cloister_ossuary, last lantern -> reliquary_quarter, chandlery -> white_anchorage_chandlery, black market -> saltmouth_tide_cellar, shieldwright -> saltmouth_landward_warehouse, vault -> white_anchorage_vault, needle house -> saltmouth_green_door, bazaar -> ashen_quarter_ash_market, academy -> spire_hall_of_records, hammersmith -> emberwick_cold_forge, beggar -> blind_beggar, caravan -> the_crossing.
Each is a new night or dusk scene of the same place (made with the original as a loose start at strength 110, so the layout is not always the same; the beggar's corner is now an alley wall, the crossing a tent on a night road), graded darker in code (value x0.7, a darkening toward the sky) and snapped to the dark palette. No characters (the keeper stands in front: see the keepers brief).
Sheet `docs/art/boards/shop-scenes-dark.png` (original | dark). 14 generations. Code: `art/pixellab-shopscenes/gen.py`, `post.py`.

## 2. Stall icons (final)
`art/pixellab-icons-v2/handoff_stalls/<shop id>_icon32.png` are the sign-first icons (see `handoff-ux-dark-foes-chests-stalls.md` update). Stalls, keepers and the layer order are unchanged.

## 3. Foes
`hollow_reflection` and `tear_spawn` in `art/pixellab-icons-v2/handoff_wave4d/` were redrawn (less murky, no longer alike): replace the two files if the other 62 are already copied. Sheet `docs/art/boards/icons-wave4d-fixes2.png`.
