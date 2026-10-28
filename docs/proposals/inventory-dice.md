# The dice on the main Inventory page (UX mock, nothing built)

Picture: `docs/ux-shots/inventory-dice-mock.png`. Mock test: `test/ux_inventory_dice_mock_test.dart`.
The user: "propose updates to add the dice accessible on the main inventory page". The two
left pictures and the right one are the real screens (captures with a warrior's real dice);
the middle one is drawn with the app's own data (`dice.json`, the skins in `die_skins.dart`,
`dieDisplayName`).

## Today
- The Dice slot tile shows the die's raw id ("starter_die"), not its name.
- A tap on it opens a plain sheet: one row per owned die, all text (the faces in a sentence,
  "Made for mage"), no look, no way to see or change the faces.
- The real dice screen (the die in a ring of face slots, Core's v1.573) is reached from the
  Character tab, not from the Inventory; opened, it shows the first die of the list, which
  can be one the hero cannot use.

## The proposal (the middle picture)
- The Dice slot tile says the die's name and its drawn look ("Lucky Die", d6 · Bone), lit
  like the die in hand; a tap goes to the Dice tab.
- A **Dice** tab among the inventory's tabs (count of the dice owned; shown only when the bag
  holds more than the one in hand).
- **In your hand:** the die lit in gold: its look (its own skin: stone, mark, edge, glow),
  name, "d6 · 6 faces · Bone", a chevron.
- **In the bag:** the other dice, same line, one labelled **Equip**. A die made for another
  class keeps its row, greyed, with a padlock and who it is for ("Made for the Mage").
- **Equip** swaps the die in hand at once (the old one goes to the bag).
- A tap on a die (in hand or in the bag) opens the dice screen **on that die**: the ring of
  face slots, a skill on each face, Change (the right picture, as it is). "Equip this die"
  sits there too.

The shapes of the dice-family picture (d4 to d20 as polyhedra) come with the dice art; until
then the rows draw each die as a tile in its skin with its size on it.

## What it needs
- **Core:** the dice screen takes an optional die to open on (`initialDieId`; its
  `_selectedDiceId` already exists): a two-line change. The one-line name fix
  (`dieDisplayName`) is in the inventory review.
- **UX (the build):** the tab, with the inventory build (v1.594): about half a day more.
