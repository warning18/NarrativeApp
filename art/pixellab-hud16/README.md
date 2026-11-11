# UI item 4: fight HUD set, 58 glyphs at 16 px
`png/<family>_<key>.png`, 16x16 RGBA (14 drawn + 1 px ink `#0A0807`), the originals' outlined two-tone style, light from the top-left. `index.json` lists them. Sheet: `docs/art/boards/hud16-fight-set.png`. Generator `hud16_gen.py` (repo root). 0 generations. Not wired.
- **die (8):** attack, defend, heal, mana, skill (the five face types in `dice.json`) plus curse, drain, blank (the states of the existing `die_*` strips).
- **rule (6):** cleave, echo, pierce, growth, pain, steady (the `kw_*` words).
- **spell (5):** damage, block, sheal (heal), status, cleanse (the `effect` types in `spells.json`).
- **element (9):** fire, water, earth, wind, lightning, ice, light, void, none.
- **chip (30):** statuses (poison, stun, weaken, braced, broken), battlefield conditions (ambush, dark, cramped, high_ground, shrine), element reactions (conduct, shatter, firestorm, freeze, sandblast, eclipse), enemy affixes (venomous, armored, skittish, frenzied, pack_leader), anomaly families (anomaly_storm, ground, cold, heat, water, light), and boon, hazard, omen.
Fixed colours (no theme tint). Native 16 px: draw at 16, 32 or 48 dp. UX-2 maps each id in code; the set follows what the code has today, not a new vocabulary.
