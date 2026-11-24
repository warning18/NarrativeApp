# The clan accent, second round (pictures only): Art's flat hues

Redrawn with the user's approved hues (Art, cut-paper direction): Dominion #2F6FE0, Crows #E0479E, Compact #E8782A, Mire #3FB06A, Vigil #E8C21A, Penitents #9B5DE5. No leader is **ink and paper**, not red: red only ever means a warning. One flat colour per clan: no gradient, no second value. `gen2.py` (in the folder above) draws them from `base-*.png`; `test/ux_clan_accent_shots_test.dart` takes the bases.

- `sheet-home.png`, `sheet-floor.png`, `sheet-fight.png`: the three screens at 360, neutral and the six clans. The primary button takes the fill (its label turns to ink on a light fill), the held card's frame and the current rung take the colour, the home menu's paint edges take it too. Health, damage, boss rungs, the danger band and weakness marks stay red.
- `contrast.png`: each hue on ink black and on paper; the best text on the fill; the line on ink black. A fill is darkened only when neither paper nor ink text reaches 4.5.
- `change-fade.png` / `.gif`: neutral to Dominion, a 400 ms fade when the toast fires.

## Findings
1. **Text on fills:** with these hues the label is **ink** on Vigil, Compact, Mire and Crows' fills and on the neutral paper, and **paper** on Dominion and Penitents. Dominion #2F6FE0 reaches 4.4 with paper text, so its fill is darkened one notch to #2264D9 (the frame keeps #2F6FE0). Every other hue passes as given.
2. **Frames on ink black** all read 3+ with no adjustment (Dominion 4.1 is the lowest).
3. **Semantic red is alone again:** Crows' pink is far enough from the warning red, and nothing else is red. Two reds remain in the pictures that are not warnings: the wax seals on the cards (their rarity pips) and the banner's emblem. With this rule the seals should be paper or ink, not red wax; a decision for Art and the user.
4. **Neutral** (no leader) reads as a paper button with ink text, and an ink-and-paper frame; the home menu's paint edges turn grey, which is quieter than today's red.
