# Shops as layers: a proposal (picture first, no build)
`shops-en.png` (412 wide, four shops side by side) and `shops-fr.png` (360): the shop screen built as background plate -> shopkeeper NPC -> stall, then the keeper's line, then the wares. Art's two test stalls (forge, apothecary) are used; the Ossuary and the Last Lantern borrow one of them. `test/ux_shop_layers_shots_test.dart` draws them (`STALLS=<folder of stall_*.png> UX_SHOTS=<dir>`).

## Layout (top to bottom)
App bar with the shop's name; the layered strip, full width, height 0.52 of the width: the plate (the shop's place, a darkened 0.28 ink wash so the stall reads), the NPC standing behind the counter, the stall 2/3 of the width, centred, its bottom 6% above the strip's bottom; the keeper's line (italic, the tier line as today); the wares list (rows as today, 4 px corners, item icon 32 px, name, price); the buy/sell tabs and the faction price line where they are now.
Anchors from Art: stall 96x64; the NPC's 64 px frame is placed so its feet (frame y 56) stand at stall y 52, under the counter top (y 40); the NPC is horizontally centred (x 48).

## Which plate (existing `assets/visuals/scenes/`, 240x100, drawn cover, bottom-aligned)
| Shop | Plate |
|---|---|
| blind_beggar_stall | blind_beggar |
| weaponsmith_forge | saltmouth_yard |
| shieldwrights_hall | saltmouth_landward_warehouse |
| apothecary_row | saltmouth_tern_row |
| black_market_docks (Tide Cellar) | saltmouth_tide_cellar |
| smugglers_vault | white_anchorage_vault |
| sharpweave_den (Needle House) | saltmouth_green_door |
| arcane_bazaar | ashen_quarter_ash_market |
| arcane_academy | spire_hall_of_records |
| hammersmith_forge | emberwick_cold_forge |
| ossuary_relics | drowned_cloister_ossuary |
| last_lantern | reliquary_quarter |
| anchorage_chandlery | white_anchorage_chandlery |
| wayfarer_caravan | the_crossing |
(A guess where a shop's place is not in `ports.json`; Maps/Core may correct the plate per shop.)

## Which NPC
The eight keepers that have a figure today (`assets/visuals/keepers/<shop id>.png`) keep it, drawn at 64 px instead of cropped. For the six without (blind beggar's cellar-boy, shieldwright, smugglers' vault, Needle House, hammersmith, wayfarer caravan): the Tower's chibi NPCs (`assets/visuals/tower/npc/`: chandler, clerk, guardian) as stand-ins until Art draws them, or Art draws six more keepers.

## Which stall
One stall per trade, 14 asked of Art. Until they exist a shop falls back to today's strip (keeper figure and sign), so the screen works shop by shop.

## Guesses / open
- The plate is only the place's picture, darkened; no parallax or motion.
- The wares list stays a list (rows with 32 px icons); no wares drawn on the stall as buttons.
- The 14 stalls are drawn in Art's dark palette; the plates are today's lighter ones: a darkening wash is used here to bridge. Art may want to darken the 14 plates.
