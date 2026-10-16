# Fighters: enemies that stand in the fight

`<sprite>_idle_west.png`: one 48 x 48 standing frame of an enemy facing west (toward the hero, who faces east), cropped from the user's PixelLab exports (`art/pixellab/dominion/<sprite>/rotations/west.png`, low top-down view; the feet are two pixels above the bottom edge).

Used by `lib/widgets/fight_sprites.dart` (`enemyFightSprite`: which enemy gets which sprite is a data table there) and drawn by `lib/widgets/fight_figure.dart`. To add one: put `<name>_idle_west.png` here, add a `FightSpriteSet` for it and the enemy ids that wear it to the table; an enemy with no sprite keeps its portrait card alone.

| Sprite | PixelLab name | Worn by |
|---|---|---|
| `aurel_vane` | Inquisitor-General Aurel Vane | `aurel_vane` |
| `inquisition_warden` | Inquisition Warden | `inquisition_warden` |
| `white_soldier` | White Soldier | `white_soldier` |
| `inquisition_soldier_02` | Inquisition Soldier_02 | `inquisition_soldier` |
| `inquisition_soldier_03` | Inquisition Soldier_03 | `inquisition_auxiliary` |
