# Icons wave 4: the 64 foe icons (V2 chibi colour, extended palette; Art, 25 November 2026)

The 64 foes that have an icon in `assets/icons/enemies/` (ids = enemies.json keys). Each is a chibi bust (head and shoulders) or a whole small creature at 32 px; looks come from each foe's description and faction hue (Dominion blue-white, Crows pink-dark red, Compact ochre, Mire green, Vigil yellow, Penitents violet, Void purple). Prompts: `art/pixellab-icons-v2/wave4_ids.py` (no "no person" wording: foes are creatures). Extended palette forced; code pass `post.py`.

Cost: 64 first tries + 8 redraws (kraken_arm, strand_colossus, iron_golem, hollow_reflection, void_manifestation, bone_sexton, bone_warden, void_stalker) = **72 generations** (cap 83). Balance 1427 -> 1355.
Files `art/pixellab-icons-v2/final_wave4/<id>32.png`; sheets `docs/art/boards/icons-wave4-all.png` (64 at 3x), `icons-wave4-cards.png`, `icons-wave4-fixes.png`.
Good: nearly every person, angel, demon, undead, beast, the golem. Weakest: kraken_arm (a small octopus, not an arm), strand_colossus (a ship-creature), void_manifestation (a purple cloud), hollow_reflection. Foes with a full chibi character (inquisition_warden, iron_golem, plague_hound, rat_matriarch, street_bandit, void_sovereign, white_soldier) were generated from text only, not from the character; they match its look only roughly.
