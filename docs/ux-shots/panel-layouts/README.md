# Tower fight: layouts of the two fighter panels (picture only)

The look of each panel stays as it is (slanted edges, ink border). Only the
layout changes with the kind of fight. Same Tower fight, 412 wide, top 62%.

- `sheet-boss.png`: boss floor (warden Brine Jack, floor 5): today, then
  (a) foe panel 1.5x taller and "You" slim under it, (b) foe fills the whole
  area with "You" as a strip on its bottom edge, (c) "You" slim on top and the
  boss big below, nearer the dice.
- `sheet-rival.png`: ordinary (today), then rival (a) two equal tall panels,
  foe left and "You" right, both turned to face each other, (b) the same with
  a slanted gutter, (c) the names and HP bars in a row above the two pictures.
- `sheet-elite-360.png`: elite as a small step (foe panel 1.2x), then the boss
  (a) and the rival (b) at 360 wide.
- `layout-*.png`: each picture alone.

Reading at 360: in the rival layouts the foe's name gets half the width. Long
names ("Armoured Sentinel of the Choir") shrink or cut; HP bars, Heat chip and
info buttons stay. The boss and elite layouts are fine at 360.

Flags in the game: boss = `isBossEnemy` (the enemy has phases, or is solo-only);
elite = `_isElite` in the fight screen; rival = the Tower floor event
`TowerEventKind.rival` (a floor won within 3 rounds), not a foe flag. The rival
picture here is the ordinary floor-1 fight forced into the layout; for the real
thing the fight screen needs that event passed to it (Core's `tower_events`).

Code: `towerPanelLayout` (ink_kit.dart), null by default = today's layout.
