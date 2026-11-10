# Intro, Version A "Alster in ashes": the final plates (the user's choice)

Four plates, 180x320, palette PNG8 (32 colours), from `../raw` (PixelLab pixen, seeds in `../index.json`). 0 new generations.

| File | Beats | Plate |
|---|---|---|
| `plate1_shroud_burns.png` | 1 and 2 (0 to 4.5 s) | the Great Shroud burning over the ash-sky city (seed 5) |
| `plate2_city_on_alert.png` | 3 (4.5 to 6.5 s) | the city on alert, calm streets, ships far off (seed 6) |
| `plate3_blind_beggar.png` | 4 (6.5 to 8.5 s) | Tallow Street and the Blind Beggar (seed 5, the sign text painted out by hand: the board is blank) |
| `plate4_tavern_room.png` | 5 to 7 (8.5 to 13.5 s) | the tavern room for the die and the title (seed 5) |

## For UX-2 (wiring, later)
- Replaces the four code scenes in `lib/widgets/intro_art.dart` (the banner, the city, the street, the room); the timing (`introBeatStarts`), Narrative's four lines, the `Die3D` bone die, the title, the fade, tap to skip and reduced motion do not change.
- Draw each plate cover-fit on the 70x124-ratio screen, nearest neighbour; zoom slowly and pan down between beats 3 and 4 (the plate's lower third meets the next plate's top); embers, smoke and the shell's flash stay code particles over the still plate.
- The Blind Beggar's sign is blank: the shop name can be a code-drawn sign if wanted (no text in the art, French build). The chalk marks on the doors are marks, not words.
- Plate 4: the floor in the foreground is empty for the die; nothing in the light pool is baked.
- The plates are finer than the 70x124 grid art (2.6x more pixels across): that is expected, all four plates change together.
