# The Forge sheet with tabs (UX mock, nothing built)

Picture: `docs/ux-shots/forge-mock.png`. Mock test: `test/ux_forge_mock_test.dart`.
The left phone is the real sheet today (a capture of `showForgeSheet` at the Hammersmith's
forge with three iron ore and 180 gold in the pack); the others are drawn with the app's own
widgets (`ItemPixelIcon`, `ItemStatChips`) on the game's real items.

## What the data says
The forge has **four recipes, all Armor, one for each slot**: Iron Cap (head), Iron Scale
Coat (body), Iron Greaves (legs), Iron-Shod Boots (feet), all Uncommon, all at
`hammersmith_forge` (`craftedAt` in `items.json`). Tabs by *item type* would be a single
tab. So the tabs are the **slots** (`equipSlot`: Head, Top, Bottom, Foot), and a slot has a
tab only when a recipe for it exists.

## What the picture shows
1. **Today:** one list of four cards in the order of the file, the same card for every piece;
   the ore hint under the title.
2. **A slot's tab (Feet):** a line says what is worn in that slot, so the stat chips show the
   gain or loss against it (the compare the shop and the pack already use); a bigger card with
   what it needs (a tick or a cross), and the roll line ("Rolls a d20 · dwarf +2 · Fine at 13,
   Masterwork at 18": the tiers of `forge_roll.dart` with the modifiers `forgeModifiersProvider`
   gives), so the odds are readable before pressing Forge. The ore hint moves to the foot of a
   tab that lacks ore.
3. **The All tab:** rows as today in two groups, what can be forged now first and what needs
   more after (the missing part in red), each row with its slot and rarity.

Tabs: All, then Head, Body, Legs, Feet; a count on each and a gold dot where something can
be forged now. The tab you left on is the one the sheet opens on next time (kept per game,
not saved). When Core gives the forge weapons or charms they come in as Weapon and Charm
tabs by item type: slots for armour, types for the rest.

## What it needs
- **Core:** nothing. The recipes, `equipSlot` and the roll's modifiers exist. More recipes
  (weapons, charms) make the tab row longer and are Core's and Narrative's to add.
- **UX (the build, if approved):** about a day: the tab row, the worn line and the compare, the
  roll line, the two groups; a test. The forging moment (the d20, the tier, before and after)
  is the next picture.
