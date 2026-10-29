# The fight with fixed sizes (built in v1.612)

> **Built (v1.612),** approved as drawn: bigger box for bosses only, allies in a back row, slim ally cards. Pictures of the build: `docs/ux-shots/fight-built/`. Still to follow: the damage numbers and effects anchor to the boxes (they still rise from the cards), and pack foes' cards are not yet slimmer.


The user: "update the Fight interface so that the size of enemy or player are fixed." Pictures only:
no build, no version. Mock test: `test/ux_fight_fixed_mock_test.dart`; the captures of the real fight
come from `test/ux_fight_size_shots_test.dart` (one scene per run, see its header) and are kept in
`docs/ux-shots/fight-fixed/` so the board can be redrawn.

| Picture | What it is |
|---|---|
| `docs/ux-shots/fight-sizes-today.png` | The real fight with different parties and foes, at 412 and 320 px: what changes in size. |
| `docs/ux-shots/fight-sizes-fixed.png` | The stage with fixed boxes: alone, three allies, three foes, a boss, and 320 px. |

## What changes in size today (from the captures)
`fight_effects.dart` draws the hero and the foes on the ground below the cards, "as big as the room the
cards leave allows": a sprite pixel of 3, 2 or 1 screen pixels, picked by the room left under the cards
(each party card is estimated at 112 px, each foe card at 124 px).
- Alone against one warden: hero and warden both **×3** (the picture people expect).
- **Three allies:** four party cards eat the room, so the **hero's sprite is not drawn at all**, while a
  lone foe still stands at **×3**.
- **Three foes** (a pack): the foe column is tall, so the soldiers drop to **×1** (one of them is
  small, the others barely show) while a hero with one ally is still **×3**.
- **Three allies and three foes:** no hero, soldiers at ×1.
- **320 px:** the hero at ×2 and the warden at ×1; with three allies, no hero.
- **Allies never have a sprite** (only the hero and foes with art do); a foe with no art (a thug) is a
  card alone.
So the hero can be huge, small or missing, and a foe can be three sizes, from one fight to the next, and
inside one fight when a pack thins out.

## The fixed-size version (`fight-sizes-fixed.png`)
One box per figure; a box never changes with the fight. The art is **scaled to fit its box** (integer
steps of the 48 px frame) and **bottom-aligned on one ground line**.
- **Boxes** (phones of 360 px and more): hero **96**, ally **64**, foe **96**, boss **144**. Under 360 px
  (the 320 phone): hero **72**, ally **48**, foe **72**, boss **108** (a scale of 1.5; at 320 px a pixel
  of 1.5 draws slightly uneven, the other choice is ×1, which is small).
- **Slots, by position, whatever the numbers:** the hero stands in front on the right of its half; the
  allies in a back row to the left of the hero, one step higher on the ground (their boxes overlap, the
  hero in front); the foes fill front-right, front-left, then back-middle; a **boss** has its own big box
  and the foes' half to itself.
- **The boss:** a bigger fixed box for the **boss class only** (`isBossEnemy`, the same test the fight
  already uses), 1.5 times the others. Everything else is one size, so a thug and a warden stand equally
  tall and a boss reads as a boss.
- **HP bars and damage numbers are anchored to the box:** the bar sits over the box's top, the damage
  number rises from the box's top centre, the target marker rings the box; none follow the sprite's own
  silhouette, so a small sprite and a tall one behave alike.
- **The stage is reserved:** the band under the cards gets a fixed height (about 150 px at 412 px: the
  box, its bar and the ground), so the dice and the controls never move. What gives is the card
  area above it: **ally cards become slim** (name, bar) and a **pack's foe cards too**, so a hero card
  and three allies, or three foes, fit in the rest; if they still do not (a 320 px phone with a pack),
  the cards scroll, never the stage.
- **An ally** stands in an ally box. They have no art yet: the picture shows a disc with the initial;
  the build uses the class mark until each companion has a standing sprite (the guide dog already has
  its frames: `assets/visuals/companion/`). A **foe with no art** gets its portrait in its box, so a slot
  is never empty.

## Files I would touch (UX's look; Core's logic untouched)
- `lib/screens/fight/fight_effects.dart`: `_heroOnGround` and `_enemiesOnGround` become one
  `_figuresOnGround` that places boxes by slot (the sizes and slots in one table).
- `lib/widgets/fight_figure.dart`: take a **box** instead of a sprite pixel; the bar and the damage
  anchor are the box's.
- `lib/widgets/fight_sprites.dart`: the box sizes (a small `FightBoxes` table by width), the ally
  resolver (class mark for now), the no-art foe's portrait.
- `lib/widgets/combat_vfx.dart`: where the damage numbers and cues anchor (the box, not the card).
- `lib/screens/fight_screen.dart` and `lib/screens/fight/fight_cards.dart`: the reserved stage band, the
  slim ally and pack cards (these two are shared files: the change is layout only).
- `lib/screens/fight/fight_rounds.dart`, `fight_dice_rules.dart`, `fight_queries.dart`,
  `fight_models.dart`, `fight_rewards.dart`, `fight_ground.dart`, `fight_goals.dart`: **not touched**.
- Open PRs touching these files at the time of writing: none (the open PRs are docs; checked with
  `git diff --stat origin/main...origin/<branch>`). I will check again before the build.
- Tests: `fight_figure_test.dart`, `ux_fight_hero_test.dart`, `ux_fight_hero_small_test.dart`,
  `ux_fight_enemy_test.dart`, `ux_fight_enemy_none_test.dart` assert today's sizes and would be
  rewritten for the boxes.

## What it needs
- **Core:** nothing.
- **Art (UX):** a standing sprite per companion (and for the dog, its frames exist); until then the
  class mark in the ally box.

## Questions for the user
1. A bigger box for bosses only (recommended), or one size for everyone including bosses?
2. Allies in a back row behind the hero (as drawn), or in a line in front, smaller?
3. Are slim ally and pack cards fine, to keep the stage from ever moving?
