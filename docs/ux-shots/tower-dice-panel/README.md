# The Tower's "Your dice" panel (picture first, no code merged)

The user's mechanics fix #3, Core's rule: a gained die goes to the bag, and the player swaps dice on the floor screen between fights. This is the panel on the **real** floor screen (floor 3, "The Wet Steps"), in the frame look: `s-412.png` (wood: 1 die; 3 dice with Flame Die new and Gambler's Die resonating; a die opened; iron: a die opened), `s-360.png` (360, wood and iron). The Tower is always the night theme, so there is no light variant. The data is a mock; the pictures come from a throw-away prototype (`prototype.patch`, which needs the iron-frame prototype of `docs/ux-shots/iron-frames/` for the frames).

## The panel
- **A row of die tiles** under "Your dice" (in the Tower's small-caps label), between "Your health" and the Fight button. Each tile: the die as drawn everywhere else (its skin and art, the shape from its face count), its name, and tags.
- **The die in play** has a gold pixel-step tile and the tag "In play". A die of the main clan has the green tag "Resonates". A die just gained has a red "new" dot on its corner until it has been opened.
- **A tap on a tile** opens it (gold border): its faces as pixel-step chips (the face's icon and value) and a **"Roll this die"** button under them (disabled and reading "In play" on the die already in play). A second tap closes it. After "Roll this die" the tile takes the "In play" mark and the run is saved by Core's `TowerController.chooseDie`.
- One die: a single tile at its own width, left. Three dice at 360: the tiles share the row (about 96 px each); "Resonates" scales down to stay on one line.
- All the frames in the pictures (the oath, foe and health panels, the buttons) are the frame prototype, which this panel does not depend on: it is an `InkPanel`, so it wears whatever the Tower's panels wear.

## Placement and the hook
I own the panel widget and put it on `tower_floor_screen.dart` myself (one `if` and the widget in `_FloorIntro`, after the health panel): Core does not need to add an opener. What I use from Core: `towerDiceOf(run, data)` for the tiles and `towerChooseDie` through `TowerController.chooseDie(dieId)`; the strings `tower_dice_title`, `tower_dice_in_play`, `tower_dice_roll`, `tower_dice_resonates` (the pictures use the English text). The "new" dot needs a "looked at" flag in the run (Core: the dot goes when the die is opened; it can live in the run's saved state).

## Found
The wood primary button's grain lines run through its label ("Fight", "Roll this die"): the art has horizontal planks under the text. Iron's reads fine. For the build: a flat inner plate or a text shadow for the wood button (or Art redraws the wood button's face).

Version slot: after Core's v1.916 logic; with or after the iron frames.
