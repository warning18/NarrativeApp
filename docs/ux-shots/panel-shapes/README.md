# Tower fight: shape variations for the two fighter panels (picture only)

Same fight, 412 wide, top half. `panel-shapes-sheet.png` has all six; one file per variation beside it.

1. today: slanted top edge on the foe panel, slanted bottom on You.
2. cut corners: foe panel cut top-left, You cut bottom-right.
3. slanted gutter: the line between the panels runs on a diagonal.
4. offset: panels stagger, the foe panel's art sits over its border.
5. burst: zigzag edge on the foe panel (shown on a warden floor, 5).
6. brush-ink: jittered ink strokes and speed lines instead of the straight line.

Names, Heat chip, HP bars and info buttons stay in place in all six.

Rule idea: shape tells the floor's danger. Plain (today) on ordinary floors,
slanted gutter for Elites, burst for wardens and bosses. Cut corners, offset and
brush stay as spare looks for events or the Heat levels.

Code: `towerPanelShape` (default `today`) in `ink_kit.dart` is a proposal switch; no behaviour change shipped. Clan reward cards are untouched.
