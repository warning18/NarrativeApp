# The Tower in ink-wash version A (UX-2, pictures only, no version)

Every screen the player meets in the Tower, drawn at 360 wide (720x1560) by
`test/ux_tower_ink_test.dart` (`UX_SHOTS=<folder> flutter test ...`). The
original chibi sprites recoloured only (`docs/ux-shots/fight-ink/make_ink_assets.py`),
the real 3D skill dice (`Die3D`) with a face strip, the ink palette with red kept to
health, your turn, the aimed foe, a x3, the lit die and the one button that goes on.
Texts are the game's own strings (`app_strings.dart`); numbers are samples.

**Placeholders (marked in the pictures):** the 14 Tower plates are the existing
colour PixelLab plates recoloured into the ink greys by
`make_tower_ink.py` (`assets/`); item pictures are boxes marked "item art"; the
race and profession cards use the chibi and Art's ink ground, not new portraits.

**Art's pieces (art/ in this folder):** `ink_wideframe` (paper inside) frames the text panels of the
menu, start, end and marks screens, dark ink text on the paper, the one button that goes on red; the frame is
drawn at half size, its red splashes sit in two corners so the text keeps clear of them. `alt_ink_wideframe`
(black inside) was not used: on the Tower's black ground its black brush edge cannot be seen.
`17-band1-compare.png` puts my recolour of tower_band1 beside Art's painted ink sample.

**Held back:** slanted comic panels only where there is a picture to frame (the foes,
the hero, the calling cards, the dice tray, the end plate). The text-heavy screens
(start, event cards, stall, bargain, spoils, offer, level up, marks) keep upright panels
with a slanted title tab and skewed buttons: a slant under a paragraph slows reading,
and the tap boxes stay rectangles.

| File | Screen | Against today |
|---|---|---|
| 01-menu | main menu with the Tower entry | each button a paper wide frame, the Tower's with a tower mark and a red bar; the menu gets an ink ground |
| 02-start | the door: marks, best floor, continue, new climb | paper wide frames; skewed chips for people, calling and clan (locked ones greyed with a lock), one red Climb |
| 03-calling | the calling pick (the main game's screen, reused) | three slanted picture cards with the chibi, one red "Chosen" |
| 04-floor | floor 7: foes, you, oaths, your dice | the vertical ladder stays; foes and you in slanted plate panels; the dice are real 3D with the face strip |
| 05-shortcut | a choice before the fight (the stair or the door) | the event card is a red-ringed panel; the fight waits (dim) |
| 06-parley | a guardian bars the stair | upright card on the faint plate; the odds in red; Talk is the one red button |
| 07-stall | the Stair-Chandler | two item rows in brush frames with Buy; Leave below |
| 08-bargain | the Tally-Clerk | Gain in paper, Cost in red; Sign red, Refuse plain |
| 09-boss | floor 10 boss | red FLOOR 10 BOSS tab on the boss panel, its rule line below |
| 10-fight, 10-fight-320 | the fight (version A), 360 and 320 | the ladder becomes a 30-tick climb strip; the aimed foe has the splash and speed lines; the matching Fire die lit |
| 11-spoils | the silver chest | three item rows in brush frames, the worn one marked red |
| 12-offer | choose one reward | three brush-framed cards, the one in hand ringed red |
| 13-levelup | level up (the main game's screen) | a slanted hero panel, four stat rows in brush frames |
| 14-death, 15-victory | the end of a run | the plate of the room (lose, win) with the sentence on it, the marks table, the way on |
| 17-band1-compare | tower_band1: the recolour beside Art's painted ink sample (1440x1280) | not a screen: the choice of how the plates are made |
| 16-marks | marks and unlocks | three groups in upright panels, Buy in red only for the one affordable now |
