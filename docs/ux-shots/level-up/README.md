# Level Up, three proposals (picture only)

Drawn with the real numbers of the user's screenshot (Level 4: STR 1, DEX 10, CON -2,
INT 3, WIS -1, PER 1, LUCK 2, CHA 0; base damage 8, armour 0, health 32). They are
mock screens in the Ink palette (`test/ux_level_up_shots_test.dart`), not the app's
screen: nothing in the game changed. At 412 wide: `level-up-three-412.png` (A, B, C side by
side) and each alone; at 360: `level-up-A-360.png` and `level-up-B-360.png` (B with the
STR card picked, to show a pick that changes nothing in a fight).

What they fix, against the screenshot:
- **Overlap**: the radar sits in a box that keeps its labels (STR, WIS) clear of the
  cards above and the Take button below.
- **Radar**: -2 sits on the first ring and 10 on the rim, so a negative stat is a dent
  you can read, not a point at the centre; the shape is filled and the pick is ghosted
  in a dashed red line with its corner dotted. (C drops the radar for a bar per stat,
  the pick's +1 in red on the bar.)
- **Gain icons**: one glyph per stat (book INT, runner DEX, dumbbell STR, here Material
  icons as stand-ins). Proposed for Art: eight 24 px stat glyphs (STR, DEX, CON, INT,
  WIS, PER, LUCK, CHA) in the Apollo palette, so the same glyph marks the card, the radar
  corner and the bar.
- **Unpicked cards**: 90% opacity, not greyed down; the picked one has the paper ring, the
  red glyph and a check.
- **Effects**: each card lists what the pick does for this hero ("+1 damage, +2% dodge").
  A, B: as the real card text today. B also shows the stat's before to after on the card
  (10 → 11) and, under the derived numbers, "Damage 8 → 9", "Dodge 25% → 27%".
- **Digits**: XP and every number in Spectral lining figures (the 0 of Base Armour is a
  true zero), the pixel face only for the stat abbreviations and the button.
- **Space**: the derived numbers (base damage, armour, health) show the picked pick's
  change in red (8 → 9) right under the button.

Open question for Core: what STR and INT do in the Tower. Today's cards say "story
checks" for a hero whose damage is not that stat. If they truly do nothing in a fight,
the card should say so plainly ("no effect in the Tower"); if they do something, the
numbers have to be exposed. Needed from Core: `statPickEffects` for the Tower's fights.
