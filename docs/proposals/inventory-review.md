# Inventory & Equipment: a review and a mock (UX, for the user to approve)

Picture: `docs/ux-shots/inventory-mock.png` (today and the proposal, at 320 and 412 px;
the bag is the user's own screenshot). Mock test: `test/ux_inventory_mock_test.dart`.
Nothing is built.

## What is wrong today (read from the screen and from the data)
1. **The Dice slot shows the raw id "starter_die".** The die's name already exists
   (`dieDisplayName`: "Lucky Die" / « Dé porte-bonheur »); the slot passes the id.
   This is a bug, a one-line fix.
2. **Every empty slot is the same box icon** (`ItemPixelIcon(null)`), so an empty slot does
   not say what it takes.
3. **The Warden's Signet is "Armor · ARM +1", and nothing says where it goes.** There is no
   Ring slot: items.json puts it in the **Head** slot (like the Sovereign's Crown and the
   Phoenix Sigil, which are `Artifact` pieces of Head/Top). So the "+" equips it to Head, and
   the screen never says so.
4. **A "+" with no word**, and a **swap icon at the top right** that is the manual compare
   mode (tap two items, a dialog of 18 rows). Unexplained, and almost every row it compares
   is empty.
5. **A type word where the numbers should be**: the row says "Armor · ARM +1" in grey. The
   stat chips (`ItemStatChips`) and the change against what is worn (which `_ItemTile`
   computes as `comparisonItem` but shows as a text "vs equipped: Name") are not used.
6. **One flat list** of 4 to 60 items: items.json has 10 item types.
7. Other: the slots are two columns of wide boxes (6 slots take a third of the screen, 3
   rows of "(empty)"), the tutorial text "Tap a slot to choose what goes there" is always
   shown, the title is long ("Inventory & Equipment", cut at 320 px).

## The proposal (less on each row, not more)
- **Tabs above the items**, only for the kinds the bag has, each with a count, the last one
  remembered (a small preference): **All · Gear · Charms · Potions · Materials · Books ·
  Quest**. From the item types of items.json: *Gear* = Weapon, Armor, Artifact (the
  equippables); *Books* = Spellbook, Tome, Scroll; the others are their own type. Dice are in
  their slot, not in the bag. (The test checks that all 10 types fall in exactly one tab.)
- **The six slots as small tiles**, three by two: the slot's own icon (faded when empty:
  helmet, shirt, weapon, legs, boot), the name of what is in it under it, **the die by its
  name**, and the slot the open row would go to lit gold. Half the height of today's.
- **Each row**: the piece's picture, its name, **one quiet line** ("Rare · goes on the
  Head" with the slot's icon), the **numbers as chips with the change against what is worn**
  (ARM 1 → +1; with Iron Cap worn: ARM 1 · Earth resist 0 −1), and **one labelled "Equip"
  button** (a worn piece shows "Take off"). Non-gear rows are just name and one line.
- **A gold dot for what is new** (looted since the last visit).
- **A quiet sort** at the right of the tabs: Newest (default), Rarity, Name.
- **The swap icon is gone**: a row compares by itself against what is worn. A tap on a row
  opens the piece with a small before → after against the worn one (the third picture);
  the existing details sheet already has the data.
- The title is shortened to "Inventory" (the EN/FR strings can keep the long form for the
  tutorial).

## Cost, and what it needs
All in UX's files except the screen itself (Core's `inventory_screen.dart`: the slot tiles,
the tab row and the row widget would replace `_ItemTile` and the slot boxes; the equip and
unequip logic, the requirement checks, the ally mode and the tutorial targets are kept).
The dice name and the empty-slot icons can ship first, alone, as a small fix. New strings:
the tab names (and "Newest / Rarity / Name", "Take off", "goes on the {slot}", "New").
No new data.

## Questions for the user
1. Are six tabs right, or fewer (Gear, Items, Books)?
2. Remove the manual compare mode entirely, or keep it behind a long press on a row?
3. Should "Equip" replace the worn piece at once (as the "+" does today)?
