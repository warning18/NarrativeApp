# Design proposal: dice skin (body only)

Board: `boards/dice.png`. Pilot: the flame die (`flame_die`, 'Ember').
User's choice: PixelLab draws the die **body/skin**; code keeps the numbers, the pips, the glow and the roll.

## Shared rules
- One skin = a face texture per shape (d6 cube first; other shapes only after the pilot is accepted) with **no numbers, no marks that read as numbers**. The glyph painter draws on top, so the skin must leave a calm patch where the number goes.
- Colours come from `DieSkin` (`base`, `edge`): flame is base `#4D1F12`, edge `orange62`; the PixelLab art uses those hues so the die still matches its UI colour.
- The skin is a texture drawn per face inside the painter's cube shapes, not a whole replacement die, so the 3D roll and the sizes keep working.
- Light from the top-left; one pattern (cracks for flame) kept.

## Options (board A, B, C)
A today's flat vector; **B chunky pixel body**; C textured stone.

## Recommendation
**B for the pilot, with a grain from C** in the face texture. The risk is the roll: a texture on rotating faces must stay legible, so the pilot is shown on a still first. "Keep the painter" stays valid for the other 35 dice if B reads worse next to the vector ones. Cost: about 5 for the pilot (a 64x64 texture object).
