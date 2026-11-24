# UI catalogue in ink: elements with variants (pictures only, nothing ships)

Four sheets at 360 wide, drawn in the ink look (near-black ground, paper white, cold greys,
deep red only for what matters, Art's brush frames, skewed and torn edges):
`catalogue-ink-1..4.png`, made by `test/ux_ui_catalogue_ink_test.dart`
(`UX_SHOTS=<dir> flutter test test/ux_ui_catalogue_ink_test.dart`). Every tile says where
the variant belongs. **Built** = exists in the app today. **Code** = can be built from
code and the existing kit (ink_kit, ink_menu, Art's frames) in a UX PR, no new art.
**Art** = a PixelLab piece in the ink palette would make it right; cost is a relative size
for Art to price: S = one small asset (an icon or a 9-slice), M = a small set (3 to 6
pieces), L = a family (by clan, rarity or material).

| Sheet | Element | Variant | Where it belongs | Status | Art cost |
|---|---|---|---|---|---|
| 1 | Button, primary | Red skew | Tower, home menu: the one that goes on | Built | none |
| 1 | | Wax seal, deep red on black | oaths, vows, clan gifts | Art | M: round wax in 2 to 3 reds, a stamp mark |
| 1 | | Iron plate, cold grey, rivets | forge, ship, smithing | Art | S: a 9-slice plate with rivets |
| 1 | | Paper frame | menus: Load, Settings | Built | none |
| 1 | Button, secondary / quiet | Black + paper line | Tower secondary | Built | none |
| 1 | | Paper slip | inline choices on paper screens | Code | none |
| 1 | | Text only | dialogs, inline Skip | Code | none |
| 1 | | Grey plate | disabled, locked | Code | none |
| 1 | Button, destructive | Blood ink | Abandon, Delete | Code | none |
| 1 | | Hold to leave | Tower: leave the run | Art | S: a brush fill for the hold (code works as is) |
| 1 | | Red outline | secondary danger | Code | none |
| 1 | | Two-step plate | ironman, permadeath | Art | shares the iron plate |
| 1 | Button, icon-only | Square ink | Tower: potion, log | Built | none |
| 1 | | Wax round | clan, oath marks | Art | shares the wax seal set |
| 1 | | Skewed square | map, journal | Code | none |
| 1 | | Paper seal | close, back on paper | Code | none |
| 1 | Button, themed | Banner tab, torn | chapter / section headers | Art | S: a torn-edge strip (code clip is the stand-in) |
| 1 | | 3D ink die | fight: Roll Dice | Code | none (Die3D with the ink skin) |
| 1 | | Clan brush edge | clan pages, gift offers | Code | none; L if each clan gets its own brush |
| 1 | | Rarity brush corner | loot: Take, Equip | Code | none; M for painted corners |
| 2 | Chips and tags | Paper on red | Tower: Armoured, affixes | Built | none |
| 2 | | Red on black | danger, curse, bleed | Code | none |
| 2 | | Paper line | Elite, plain marks | Built | none |
| 2 | | Rarity and clan outlines | loot, standing | Code | none |
| 2 | Badges and counters | Red round | inventory, log, potions | Code | none |
| 2 | | Skewed red | new quest, unread | Code | none |
| 2 | | Square paper | Tower: tiles, dice | Built | none |
| 2 | | Wax dot | clan standing, gifts | Art | shares the wax seal set |
| 2 | Tooltips and popovers | Ink popover | Tower: hero / foe sheet | Built | none |
| 2 | | Paper note | help, hints on paper | Built (paper frame) | none |
| 2 | | Torn scrap | lore, codex, letters | Art | S: a torn-paper edge |
| 2 | Digits | Pixel font today | everywhere | Built | the 5 reads as S |
| 2 | | Spectral digits | numbers in the prose face | Code | none |
| 2 | | A repaired 5 | the pixel font itself | Font edit | redraw the 5 glyph in PixelifySans (not PixelLab) |
| 3 | Cards and frames | Ink panel | Tower: all panels | Built | none |
| 3 | | Wide paper frame | text screens, offers | Built | none |
| 3 | | Brush frame (ink_frame) | sheets, dialogs | Art | M: the frame in 3 sizes (the 9-slice here stretches) |
| 3 | | Clan brush edge | clan pages, sworn gifts | Code | none; L for clan art |
| 3 | | Rarity brush corner | items, dice, skills | Code | none; M for painted corners |
| 3 | Dividers | Ink slash | sections | Code | none |
| 3 | | Brush stroke | chapter breaks | Art | S: 2 or 3 strokes |
| 3 | | Red ticks | lists, stalls | Code | none |
| 3 | | Hairline | dense lists | Code | none |
| 3 | List rows | Ink row | Tower: stall, marks | Built | none |
| 3 | | Rarity row | loot, shop, inventory | Code | none |
| 3 | | Paper row | journal, saves | Code | none |
| 3 | Empty states | Ink-wash vignette | journal, codex, bag | Art | M: one wash per list (about 5); the dice-plate texture is the stand-in |
| 3 | | Red slash + line | Tower: Unsworn, no dice | Code | none |
| 3 | | Quiet line | lists: no saves | Code | none |
| 4 | Bars | Thin ink | Tower: plates, health, XP | Built | none |
| 4 | | Blood bar | low health, danger | Code | none |
| 4 | | Segmented | quests, tide, mana | Code | none |
| 4 | | Skewed bar | boss, banner headers | Code | none |
| 4 | Toggles | Ink plate | settings | Code | none |
| 4 | | Lever | ironman, permadeath | Art | S: a lever sprite in two positions |
| 4 | | Skewed switch | on / off pairs | Code | none |
| 4 | | Square check | lists, options | Code | none |
| 4 | Tabs | Skewed ink | Tower: marks, calling | Code | none |
| 4 | | Banner tabs | chapters, clans | Built | none |
| 4 | | Underline slash | inventory, map | Code | none |
| 4 | | Paper folder tabs | journal, codex | Art | S: a folder-tab 9-slice |
| 4 | Dialog headers | Ink title + red tab | Tower: floor, end | Built | none |
| 4 | | Paper header strip | story dialogs, sheets | Built (paper frame title) | none |
| 4 | | Torn banner header | clan, oath, boss | Art | M to L: one neutral, or one per clan |

New art in total: wax seal set (M), iron plate (S), torn strip (S), torn scrap (S), brush
frames (M), brush strokes (S), ink-wash vignettes (M), lever (S), folder tabs (S), banner
headers (M to L), plus the pixel font's 5 (a font edit). Everything else is code on the
kit that exists.
