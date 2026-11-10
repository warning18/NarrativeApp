# Tower interface design: two options (UX-2, proposal, not for merge)

Real screens, drawn by a throwaway prototype on this branch (`lib/screens/tower/tower_look.dart` plus a few `towerLook` switches); the code on this branch is a record, not a PR.
Pictures, EN 412 and FR 360: `board-today-*` (1.899, the baseline), `board-option-a-*`, `board-option-b-*`, `compare-key-screens-*` (start, floor, boss floor, spoils: today | A | B).

## Option A, conservative (same layout, same text)
- Panels: A+C, a double ink line with a bevel, for every Tower panel (InkPanel in a Tower look).
- Ladder: courses of stone in the colour of the band (warm, violet-grey, ash), the climbed floors gold, the floor stood on a lit stone with a glow, boss floors ringed in blood.
- The backdrop (band 1) also sits behind the start screen, a touch lighter (veil 72 %).
- Layout change: none.

## Option B, bolder
- The whole Tower in the night theme (dark scheme), the backdrop under a 58 % dark veil, A+C panels, gold buttons.
- Ladder: a stair of arched windows, lit up to the floor climbed to; the current floor glows; bosses ringed.
- Floor screen: a large gold floor numeral; the foe stands in its panel as its figure when it has art.
- Start screen: the three bands as panes of their pictures with their names and floors (new element, under the Climb button).
- Spoils: the chest at 96 px (the title may wrap to two lines in French).
- Layout changes to flag: the foe figure in the foe panel, the band panes on the start screen, the larger chest.

Recommendation: A as the default, with B's night theme as the Tower's dark variant (the user's A+C default).
