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

## Style rule from the user (2026-11-10): inspired by the main character sprite
"Ensure that character, enemy or NPC generations are inspired from the main character sprite style in pixellab.ai."
- **The reference:** the straw-hat hero, group "Hero" in the PixelLab library, tag `Main_Ronin` (states `Idle-Walking`, `Idle-Walking (copy)`, `Idle-Walking (copy 2)`; id `3cd4c1e2-a9b9-4b5b-945a-a219c084b7bd` is the one used). It is the sprite the fights show as "You" (`assets/visuals/walker`). Staged: `art/pixellab-enemies2/style/ronin_main_west.png`.
- **What defines it:** chibi proportions (head about 40% of the height), a thick clean dark outline, flat rounded shading in few tones, 48x48 canvas, side view.
- **How it is applied:** as a style reference, not only text: `create_character` in `pro` mode with `style_character_id` set to the ronin (it copies the outline, proportions and shading); every other parameter stays (60 px, no text, muted warm palette).
- **Check:** `docs/art/boards/style-check.png` (the ronin next to the approved sprites) and `docs/art/boards/style-test.png` (same enemy in v3, standard + chibi, pro + style reference). The v3 sprites (realistic 3.5-head proportions, finer detail) drift from the ronin; standard + chibi is too small and weak; pro + style reference matches but costs 10 instead of 2.
