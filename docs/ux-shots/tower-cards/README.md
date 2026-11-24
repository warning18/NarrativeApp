# The Tower's cards in the latest ink design (proposal, pictures only)

Three directions, each a pick of 3 cards. Existing art only (the ink kit, the Tower plates, the skill and die icons); no PixelLab call. The cards are the real floor-5 offer of a seeded run (Steady Aim, Chorus Die, Rally the Line); rarity and the "new synergy" tag are mock (see "Notes").

| Direction | What it is |
|---|---|
| **A** | ink paper cards in the kit's seeded variations (tint, tilt, torn edge, pin, stains); rarity is a spot of colour (grey, blue, gold) with its word |
| **B** | tall tarot-like cards: a vignette cropped from the Tower's ink plates, a red seal whose dots count the rarity |
| **C** | a black card, a paper title band, a big icon in a frame ringed in the rarity colour, a rarity stripe on the left edge |

Files (360 and 320 wide, `<dir>-<kind>-<width>.png`; `_compare-*` put A, B and C side by side):
- `*-pick-*`: the pick of three (middle card selected, with Take) and the reroll / banish control under it
- `*-states-*`: common, rare, epic, selected, hovered, disabled (can't afford, with its price) and new synergy
- `*-french-1.3x-*`: a long French name ("Résonance de l'Ordre des Sentinelles Vigilantes") at 1.3x text
- `today-*`: the real app today (the spoils sheet, then the cards, then the third card held), the shot part 4 missed; floor 5 is a boon floor, so it offers a skill, a die and a spell

Code: `test/ux_tower_cards_proposal_test.dart` (the three directions) and `test/ux_tower_cards_real_shot_test.dart` (the real shots); `UX_SHOTS=<folder> flutter test <file>`.

## Notes
- **Fit.** A and C fit at 320 wide, French, 1.3x (names take up to 3 lines). B fits only by scaling: the card grows with the text setting and the name and the words scale down, so at 320 / 1.3x with a long French text the body is about 7 px. If B is chosen, below about 340 wide or above 1.15x text it should fall back to C's rows.
- **Data.** Only skills carry a rarity today (`towerRarityStep`); dice and spells have none, and "new synergy" and the price on a card do not exist. Rerolls and banish are Core's proposal, so those controls are drawn only. Core would need to say what rarity a die or a spell has, what makes a card a synergy, and whether a card can cost marks.
- **Tap behaviour kept.** Tap holds a card, Take takes it, "Leave them all (+1 mark)" stays; the oath card keeps its clan disc (not drawn here).
- **What Art would need for B** (A and C need nothing new): a painted vignette of about 96 x 64 (cropped from a 160 x 96 plate) for each kind of card, in the Apollo palette: one per skill school (about 8 to 10), one for dice, one per spell family (4 to 6), and one for the clan oath (the clan banner on a plate); the three rarity seals redrawn as pixel art (1, 2 and 3 notches); a tarot frame with corner ornaments; a "new" stamp. The drawings here borrow four existing plates (ward, shop, parley, bargain) as stand-ins.
