# Design proposal: characters (enemies, NPCs, companions)

Board: `boards/characters.png`. Pilots: `iron_golem`, `void_sovereign`, `lysa`, `renn`, `kelda`, `sable`.

## Shared rules
- **Look:** "Stitched Ink": muted warm palette, one dark ink outline, 3 to 4 shades per material, one accent colour per character (a faction colour, an eye, a lantern).
- **Palette (read from today's sprites):** ink `#000000` / `#1F1F27`, browns `#3B3630 #5D5346 #81615B`, leather/sand `#B79C6E`, skin `#AC8078`, steel `#8E93A4 #B5B9C5`, bone `#D7D8C8 #E0E4ED`, blood accent `#8A2330`. Max 16 colours per sprite (reduce_colors, then `tool/png8.py`).
- **Outline:** 1 px, darker than the fill (selective outline), no outer glow.
- **View:** side view facing west for enemies (hero faces east), eye-line at about 1/4 of the height, feet 1 to 2 px above the bottom edge. Light from the top-left, so shadow falls right and down.
- **Faction reads by colour only, never by text:** Dominion white/grey with a lantern; Vigil blue; Compact iron/brown; Mire green; Crows black/red; Penitents ash-grey; Void purple `#6A4FB0`.
- **Constant across the set:** same outline, same light, same proportions per size class (a person is 3 heads tall at 48 px, 3.5 at 64 px), no text.
- **Delivered files:** palette PNG8, idle frame only (walk strip only for companions if asked), named `<id>_idle_west.png`, frame size listed in `fight_sprites.dart`'s `_enemyFrames` format (size, foot inset, draw scale).

## Options for the canvas (board A, B, C)
| | Canvas | View | Fits |
|---|---|---|---|
| A | 48x48 | low top-down (today's dominion sprites) | the default frame, no table row |
| **B** | **60x60** | **side view (today's sewer sprites)** | creatures and bosses; one `_enemyFrames` row each |
| C | 42x47 | side view at hero scale | people only; small for bosses |

## Recommendation
**B (60x60 side view) for every enemy and boss; people (NPCs, companions) at 48x48 side view** so a person never outgrows the hero. A is retired because it is the only top-down set and mixes badly with the side-view backdrops. Cost: PixelLab standard character, 1 generation, plus about 8 for an idle clean-up pass per sprite.
