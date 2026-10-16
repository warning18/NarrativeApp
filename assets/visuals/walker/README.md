# The walker: the hero in side view

`ronin_walk_{east,west}.png`: the walk cycle, 8 frames in a strip (42 x 47 each, the feet on the last row).
`ronin_idle_{east,west}.png`: one frame, standing (the walk's third frame, the legs together), on the same canvas.

Supplied by the user ("Idle-Walking", a ronin samurai vagabond, 8 directions, side view); cropped to one common box so the frames keep their anchor. Used by `lib/widgets/side_view/side_sprite.dart`.

To add a hero sprite for the fight: draw it facing east, save `<name>_idle_east.png` (one frame, or a strip whose first frame stands) and optionally `<name>_walk_east.png` (a strip of equal frames) here, and add a `FightSpriteSet` for it in `lib/widgets/fight_sprites.dart` (the files' names and the size of one frame), then return it from `heroFightSprite` for the profession or race it belongs to; the fight sizes and places the figure from the frame size, and a missing file falls back to the ronin.
