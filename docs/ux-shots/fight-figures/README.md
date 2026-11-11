# Fighters standing on the fight board (proposal, pictures only)

Real fight screens (Rat Matriarch, "Open country · Rain", dark-free default theme),
rendered from a throw-away prototype (`prototype.patch`, never merged; the scratch
test that renders it is `shot_test.dart.txt`).

| Sheet | Shows |
|---|---|
| `one-412.png` | today / A / B, one foe, 412 |
| `pack-412.png` | today / A / B, 3 foes (Frenzied Rat Matriarch, Harbour Rat, Plague Hound) + hero and 2 allies (Kelda, Sable), 412 |
| `A-360-320.png` | A at 360 and 320, one foe and the pack |
| `B-360-320.png` | B at 360 and 320 |

(The allies' figures are forced for the picture; their cards are not shown because a
companion seat needs a recruited ally. The real build uses the party list.)

## The two layouts
- **A, figures on the stage edge (recommended).** The fighters stand along the top of the
  dice stage, on the ground it already draws: hero and allies left, foes right, drawn from
  `FightSpriteSet` (the idle frame, foot inset and `drawScale` already in
  `fight_sprites.dart`), allies mirrored east. Costs no height: the dice sit below them
  (seats start under the figures), the figures take no touches (IgnorePointer). 62 dp tall at
  412, 54 at 360, 46 at 320; with 6 figures they scale down to fit (FittedBox).
- **B, a band between the cards and the stage.** Same row, 56 dp, above the stage: the stage
  loses that height, which is tight at 320 x 568; the figures stand on the backdrop
  but not on the stage's ground.

## What I'd also do
1. Enemy card portrait cropped from the new sprite where one exists (the head of the 48/60 px
   frame, fallback to today's `tool/gen_fight_heads.py` head).
2. Hit / lunge / hurt strips later (Art): the figures are idle frames only today.
3. At 320 x 568 (`_shortPhone`) keep the row at 46 dp (fits).

## Touches
`lib/screens/fight/fight_board_view.dart` (one `Positioned` in the board stack and the row
widget, new file `lib/screens/fight/fight_figures.dart` would hold the widget),
`fight_view.dart` untouched for A. No logic: Core's fight files unchanged. Shared files
(`fight_view.dart`, `fight_board_view.dart`): I check for open PRs on them before building.
Version slot: 1.911 (Manager's renumbering).
