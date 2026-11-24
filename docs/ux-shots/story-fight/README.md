# The story fight, today and in the Tower's ink (pictures only)

`story-fight-compare.png` (start here): the same fight, drawn by the real fight screen: the hero and Sister Maren against two Harbour Rats, at 360, English. `story-360-en-{before,after}.png` are today's story look; `ink-360-en-{before,after}.png` are the same screen under the Tower's look (`TowerNight`), which needs no new layout code. `test/ux_story_fight_shots_test.dart` takes them (`UX_SHOTS=<dir>`).

## What the ink variant shows
- Each side is one painted panel with a thin bar and the name over it (the numbers are in the sheet), instead of a cream plate per fighter: lighter, and the scene breathes.
- The Tower's dice plate, spark row of six faces and Reroll / Confirm buttons come with it.

## What it needs for the story
1. **The ladder strip** (30 rungs) is the Tower's: on a story fight it should go. It also takes the height the dice board needs: here the board is about 80 dp tall and the dice are cut (the same short-board problem as #1141).
2. A party of three could not be shown: the Fight Lab adds one companion only, so the picture holds two.
3. The story colours (cream, teal for the party, ember for the foes) are the screen's today; a version of the ink layout in those colours is not drawn: say which of the two directions the user wants, or whether the ink one is the answer for the story as it is for the Tower.
