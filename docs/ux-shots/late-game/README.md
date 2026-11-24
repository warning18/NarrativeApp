# Late game (Core's v2.5.0): the Void Banner slot, the chapter goals, the chapter chest

Proposal, pictures only, at 360 and 320 wide, English and French. Samples: the goals' lines (Narrative writes the real ones) and the numbers; the tiles, the cards and the chests are the app's own pieces (`InventorySlotTile`, `InkPanel`, `assets/icons/chests/`).

- `banner-<w>-<lang>.png`: the Void Banner's own slot, the sixth after Foot. **A** (my pick) a full-width tile under the five slots and the dice: a banner is wide and the slot is rare, so it takes its own row and the grid above is untouched. **B** a seventh tile alone on its row: same size as the others, a lonely corner. **C** no tile until the banner is found, so the 99 % of the game that never meets it sees nothing. The last grid is the slot lit (found, not worn). My pick is A with C's rule (shown once a banner is owned). The slot glyph is a placeholder flag; Art can draw a banner glyph (`inventory_parts.dart`'s `inventorySlotGlyph`, a new `PixelGlyphs` entry).
- `goals-<w>-<lang>.png`: the chapter goals. The home is the **chapter page** (a card with the 3 goals and their ticks, the four chests under it with the one the count gives lit). At a **fight's setup** only the goals that fight can settle show, as one line. After a fight, a **toast** ("Goal met: no potion · 2/3"). The card is also shown at 0, 2 and 3 of 3.
- `chest-<0|2|3>-goals-<w>-<lang>.png`: the chapter-end screen: the goals ticked, the chest the count earns (Wooden 0, Iron 1, Silver 2, Gold 3), "Open the chest" (into the usual loot sheet), and a line saying the boss chest stays apart.

## Notes
- The silver and void chest icons (`assets/icons/chests/silver_*.png`, `void_*.png`) are 16 x 16 while the wooden, iron and gold are 32 x 32: at the chapter chest's size the silver one is visibly coarser than its neighbours. Art would need to redraw them at 32 x 32 if the chapter chest ships.
- No code is built. The slot needs `equipSlotOptions` to gain "Banner", a glyph, and the grid row in `inventory_screen.dart`; the goals need a card widget and a place on the chapter page.

## Updated to Core's final shapes (v2.5.0)
- The Void Banner is one item (Relic, attack 2, armour 2, +1 every element), gained from the chapter 1 quest reward; only it uses the Banner slot.
- The goals are a tick list without counts per goal (the "best so far" lines are gone; the x/3 in the card's corner is the count that sets the chest). Kinds: rounds(n), weakness, no_potion (now a close fight won without a potion: ending under half health) and first_try (only chapter 7's claimant and chapter 8's Sovereign), so the chapter 5 card has rounds, weakness and no_potion.
- The chest is given once, when the story enters the next chapter, right after its chapter card (chapter 8's at the ending), through the usual spoils sheet: the chest pictures are titled that way.
