# UI catalogue: elements with variants (pictures only, nothing ships)

Four sheets at 360 wide (`catalogue-1..4.png`), made by `test/ux_ui_catalogue_test.dart`
(`UX_SHOTS=<dir> flutter test test/ux_ui_catalogue_test.dart`). Every tile says where the
variant belongs. **Built** = exists in the app today. **Code** = can be built from code and
the existing kit (Apollo palette, frame kit, Art's ink pieces) in a UX PR, no new art.
**Art** = a PixelLab piece would make it right; cost is a relative size for Art to price:
S = one small asset (an icon or a 9-slice), M = a small set (3 to 6 pieces), L = a family
(by clan, rarity or material).

| Element | Variant | Where it belongs | Status | Art cost |
|---|---|---|---|---|
| Button, primary | Gilt block | story: the one that goes on | Built | none |
| | Ink skew | Tower, home menu | Built | none |
| | Wax seal | oaths, vows, clan gifts | Art | M: round wax in 3 colours, a stamp mark |
| | Iron plate | forge, ship, smithing | Art | S: a 9-slice plate with rivets (the iron frame kit has the border) |
| Button, secondary / quiet | Outlined | story: Not now, Back | Built | none |
| | Paper frame | menus, ink screens | Built | none |
| | Text only | dialogs, inline Skip | Built | none |
| | Black + paper line | Tower secondary | Built | none |
| Button, destructive | Blood outline | story: Abandon, Delete | Code | none |
| | Blood block | story: final confirm | Code | none |
| | Red skew + hold | Tower: leave the run | Code | none (a hold-to-confirm gesture) |
| | Two-step plate | ironman, permadeath | Art | S: the plate, shared with the iron one |
| Button, icon-only | Round gilt | story: close, map, log | Built | none |
| | Square ink | Tower: potion, log | Built | none |
| | Wax round | clan and oath marks | Art | shares the wax seal set |
| | Bare icon | toolbars, app bar | Built | none |
| Button, themed | Banner tab | chapter / section headers | Built (InkTab) | none |
| | Die-shaped roll | fight: Roll Dice | Code | none (a rotated die frame); S if Art draws the die button |
| | Clan-coloured | clan pages, gift offers | Code | none (the clan's colour on the block); L for clan emblems on the button |
| | Rarity glow | loot: Take, Equip | Code | none |
| Chips and tags | Pixel chip | story status, Sworn | Built | none |
| | Rarity chip | loot: Rare / Epic / Heroic | Built | none |
| | Ink tag | Tower: Armoured, Elite | Built | none |
| | Weakness mark | fight: x3 / x1/2 | Built | none |
| Badges and counters | Round count | inventory, log, potions | Built | none |
| | Pixel counter | story: new quest, unread | Built | none |
| | Square ink | Tower: dice, tiles | Built | none |
| | Wax dot | clan standing, gifts | Art | shares the wax seal set |
| Tooltips and popovers | Cream card | story: icon help | Built | none |
| | Ink popover | Tower: hero / foe sheet | Built (sheet) | none |
| | Scroll note | lore, codex, letters | Art | S: a torn-paper 9-slice |
| Digits | Pixel font today | everywhere | Built | the 5 reads as S |
| | Spectral digits | numbers in the prose face | Code | none: set numbers in Spectral (a one-line change per widget, or a digit-safe text style) |
| | A repaired 5 | the pixel font itself | Art | S: redraw the 5 glyph in PixelifySans (font file edit, not PixelLab) |
| Cards and frames | Cream card | story: events, offers | Built | none |
| | Clan-tinted | clan pages, sworn gifts | Code | none; L if each clan gets its own frame art |
| | Rarity frame | items, dice, skills | Code | none; M for painted rarity frames |
| | Ink panel | Tower: all panels | Built | none |
| Dividers | Hairline | lists, sheets | Built | none |
| | Stitched | story cards | Built | none |
| | Ink slash | Tower sections | Code | none |
| | Flourish | chapter breaks, lore | Art | S: 2 or 3 flourishes |
| List rows | Story row | inventory, journal | Built | none |
| | Rarity row | loot, shop | Code | none |
| | Ink row | Tower: stall, marks | Built | none |
| Empty states | Quiet line | story lists: no saves | Built | none |
| | Illustrated | journal, codex, bag | Art | M: one small picture per list (about 5) |
| | Ink empty | Tower: Unsworn, no dice | Built | none |
| Progress and health bars | Round green | story: health, XP | Built | none |
| | Segmented | quests, tide, mana | Code | none |
| | Ink thin | Tower: plates | Built | none |
| | Blood warning | low health, danger | Code | none |
| Toggles and switches | Pill | settings (today) | Built | none |
| | Plate | ink screens | Code | none |
| | Lever | ironman, permadeath | Art | S: a lever sprite in two positions |
| Tabs | Underline | story: inventory, map | Built | none |
| | Banner tabs | chapters, clans | Built | none |
| | Skewed ink | Tower: marks, calling | Code | none |
| | Folder tabs | journal, codex | Art | S: a folder-tab 9-slice |
| Dialog headers | Cream header | story dialogs, sheets | Built | none |
| | Banner header | clan, oath, boss | Art | M: a banner strip per clan (L) or one neutral |
| | Ink title | Tower: floor, end | Built | none |

New art in total: wax seal set (M), iron plate (S), scroll note (S), flourishes (S),
folder tabs (S), lever (S), illustrated empty states (M), banner headers (M to L),
plus the pixel font's 5 (a font edit). Everything else is code on the kit that exists.
