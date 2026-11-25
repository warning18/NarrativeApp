# Icons wave 3: the other items (V2 chibi colour, extended palette; Art, 25 November 2026)

44 ids = every item of `assets/gamedata/items.json` not in wave 2: 11 other equippables (sword_001, rat_king_tooth, thug_knuckle_wrap, blackened_fang, dawnward_shield, halo_lance, tear_glass_blade, harborwatch_cutlass, hollow_court_blade, bloodthorn_blade, siphon_wand), 13 spellbooks, 11 materials and trophies, 4 charms, 2 tomes, scroll_fireball, quest_sealed_letter, elite_trophy. Prompts and wording ("the object alone, no body, no head, no face, no person") in `art/pixellab-icons-v2/wave3_ids.py`; extended palette forced; code pass `post.py` (snap, ink edge, no region under 2 px).

Cost: 44 generations, no retries (cap 80). Balance 1483 -> 1483 - 5 (wave-2 redraws) - 44 = 1434.
Files `art/pixellab-icons-v2/final_wave3/<id>32.png`; sheets `docs/art/boards/icons-wave3-all.png` and `icons-wave3-cards.png`.
Weak: thug_knuckle_wrap (two blobs), halo_lance (a blob), material_white_fleet_oak (a round ball, not a plank), charm_fourth_roll (reads as a skull), tome_of_insight (a ghost shape), dawnward_shield and elite_trophy (small, unclear).

## Round 2 (25 November): 7 redraws, 7 generations (cap 10)
thug_knuckle_wrap, halo_lance, material_white_fleet_oak, charm_fourth_roll, tome_of_insight, dawnward_shield, elite_trophy redrawn (`RETRY` in `wave3_ids.py`, seed 5). Sheet `docs/art/boards/icons-wave3-fixes.png`. halo_lance (a lance now), the oak plank, the bone die, the tome, the round shield and the medal are good; thug_knuckle_wrap is still a dark bundle. Wave 3 total 51 generations. Balance 1427. Hand-off: `docs/art/handoff-ux-icons-wave3.md`, files `art/pixellab-icons-v2/handoff_wave3/`.
