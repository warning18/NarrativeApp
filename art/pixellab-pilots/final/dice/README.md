# Dice for the inventory tile (the five approved bone bodies; the d10 stays the code painter)

Source: `art/pixellab-pilots/round3/pixellab/` (`d4_c`, `d6`, `d8`, `d12_c`, `d20_a`, 64x64). No new generation (0). All files are palette PNG8 with transparency, at most 24 colours.

| File | What it is |
|---|---|
| `die_<shape>_bone_44.png` | the die fitted into a 44x44 tile (die about 40 px with a 1 px dark outline), transparent margin |
| `die_<shape>_bone_48.png` | the same in a 48x48 tile (die about 44 px) |
| `die_<shape>_bone_44_half.png`, `_48_half.png` | the exact whole-number cut: the 64 px source halved 2:1 (box average) to 32 px, centred in a 44 or 48 tile |

How the fitted cuts were made (free, PIL): crop to the die, box-average down (not nearest, so details do not tear), hard alpha, reduce to 20 colours without dithering, then a 1 px outline in the die's own darkest colour is redrawn around it so the edge stays crisp. Looked at at 5x: clean edges, faces stay flat.
Honest note: 40/44 px from 64 px is not a whole-number ratio (0.62 and 0.69). If the app needs a strict whole-number cut, use the `_half` files (clean, but the die is only 32 px in the tile). Recommended: the fitted `_44` or `_48`.

Resting bodies only: numbers, skill glyphs and the roll stay code. The skill icons fit best on the big faces (see `docs/art/boards/dice-with-skill-icons.png`; at 44 to 48 px the icons would have to be 8 to 12 px, so the tile should show the body, with the glyph drawn small or not at all).
