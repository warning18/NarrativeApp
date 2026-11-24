# The Tower's tarot cards (Art's set, claude/art-npc-export 7d7db2ef)

`skill_<element>.png` (Fire, Earth, Wind, Water, Ice, Light, Electricity, Void, None), `die.png`, `spell_{damage,ward,heal,hex}.png`: 96 x 64 vignettes. `seal_1dots.png` to `seal_5dots.png`: 32 x 32 wax seals (the dots read faintly at 1x), `frame_tarot.png`: 112 x 160, an 11 px border, `stamp_new.png`: 48 x 48 (for the "new synergy" slot, unused until Core defines it).

`seal_blank.png` is `seal_2dots.png` with the inner disc flattened (UX): the cards draw the rarity's pips over it in paper colour, so they read at 24 px. The lookup is `lib/screens/tower/tower_card_art.dart`.
