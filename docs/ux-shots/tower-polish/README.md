# Tower polish: four items (picture first; one PR when the user says)

All on the real app at 360 (`test/ux_tower_polish_shots_test.dart`, run on main for "before" and on the branch for "after").

1. **Fight dice cut off: the 30-rung strip is gone from fights** (`fightroll-before-after.png`). The floor is already in the title's subtitle ("The Ashen Tower · Floor 1"), so the strip was a second copy of it; its 26 dp go to the board. (`fight_tower_panels.dart`, `_buildClimbStrip` removed.)
2. **Numerals in the prose face** (`numerals-specimen.png`, `numerals-before-after.png`). The pixel face's 5 reads as an S, its 6 as a G, its 0 as an O. The digits of `PixelifySans` (Regular and SemiBold) are replaced by Spectral's, scaled to the same cap height and kept at their original advances, so no line moves; every other glyph is untouched. It applies wherever the pixel face writes a number, the story and the maps included (Maps raised the same on the epilogue chart). The two font files are renamed inside ("Pixelify Sans Num") as the OFL asks of a modified font; both fonts are OFL (licences already bundled).
3. **The start screen's zone rows in ink** (`start-before-after.png`): the three bands are slanted ink panels with their painted plates and the display face, as the run to go on is drawn, instead of grey rounded Material cards.
4. **The rail on stalls** (`stall-before-after.png`): offers already gave the rail's room to their cards once the head had walked; a merchant's stall, a bargain and a parley now do too (`tower_floor_screen.dart`, `_railFor`). The earlier clan-card pictures that showed the rail were taken in the first half second, before it left.

Touches another session's area: `lib/screens/fight/fight_tower_panels.dart` (the fight's Tower panels); the two font files in `assets/fonts/` (every screen's digits).
