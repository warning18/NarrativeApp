# Tower: stair-climb and 30-floor board (pictures only, no PR code)

Concept pictures, 412/360 dark, drawn in code (no art files yet). Both are one idea: **the hero token moves up**.

## Stair-climb after a WON Tower fight (1-1.5 s, tap to skip, off with reduced motion, nothing on defeat)
- **A. Rail step** (`stair-a-rail-strip.png`, `.gif`): the hero token steps up one notch on the existing left floor rail (floor just won to the next). Cheapest, always visible, no new screen time. Needs no art.
- **B. Full stair** (`stair-b-full-strip.png`, `.gif`): a full-width stair fills the page for about a second, the hero hops up it, then the next floor appears. More ceremony; stair drawn in code from the iron/stone palette, hero token = the hero's head crop (already have `HeadAvatar`). Optional small hand-drawn piece from Art: a stone step tile (tileable) per band (night/stone/void).

## The 30 floors as a snakes-and-ladders board (`board-412.png`, `board-360.png`)
5 columns x 6 rows, floor 1 bottom-left, the path winds (boustrophedon). Bands 1-10 night, 11-20 stone, 21-30 void; wardens 5/15/25 carry a shield, bosses 10/20/30 are ringed in blood with a mark; floors climbed are ringed gold; the hero token stands on the current floor. One ladder (3 to 8) and one snake (17 to 12) as examples. Cells use the iron-frame look (rivets) so the frames session (1.919) can swap the 2px stroke for the real 9-slice frame.

Where it could live (my pick first):
1. **A "board" button on the floor screen** opening the board as a sheet; the left rail stays. Keeps today's screen, the board is a map you check.
2. Replace the left rail by the board (loses the floor-screen width, board needs a full page).
3. The floor screen itself shown as the board, the floor's content under it (largest change).

Ladders and snakes are a rules question (shortcuts and falls) for Core; the picture only shows how they would look.

`shot_test.dart.txt` is the scratch picture test (rename to `test/..._test.dart`, `UX_SHOTS=<dir>`).
