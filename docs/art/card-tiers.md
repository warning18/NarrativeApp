# Card tiers: frame, plate and backdrop (approved 16 November; epic and legendary added)

For the clan offer card (UX-2, branch `claude/ux-2-skill-cards`, 210 x 346 dp). Five tiers: common, uncommon, rare, epic, legendary. Pieces are PNG8, Apollo + cores palette, no text. **1 art pixel = 2 dp** (the same chunky scale as the banners).

| Piece | File (`art/pixellab-cards/final/`) | Art size | dp | Use |
|---|---|---|---|---|
| Frame, 3 tiers | `frame_common.png` (iron), `frame_uncommon.png` (bronze), `frame_rare.png` (silver + pale blue gem at the top centre, stands 3 art px above the edge) | 104 x 172 | 208 x 344 | the centre is transparent; draw it over the card at (1,1). A 6 art px band, so it is also 9-sliceable (corner 12 art px) |
| Epic and legendary (same sizes, same folder) | `frame_epic.png` (gilded gold, purple trim, two purple gems top and bottom), `frame_legendary.png` (bright gold, a crown of sun rays and a gold gem at the top, stands above the edge), `plate_epic.png` (4 purple gems), `plate_legendary.png` (4 white-gold gems), `backdrop_epic.png` (purple glow), `backdrop_legendary.png` (golden halo ring) | as above | as above | as above |
| Icon plate, 3 tiers | `plate_common.png`, `plate_uncommon.png` (4 rivets), `plate_rare.png` (4 gems) | 40 x 40 | 80 x 80 | behind the 16 px skill icon (shown at 3x); the inside is neutral dark, so the element tint stays UX's |
| Art backdrop, 3 tiers | `backdrop_common.png` (plain), `backdrop_uncommon.png` (a faint bronze ring and a beaded line), `backdrop_rare.png` (light rays and sparkles) | 104 x 76 | 208 x 152 | under the banner and the plate; the clan colour is a 18 % tint over it in the mock, so the tier and the clan do not fight |

Metals: iron 202E37 394A50 577277 819796; bronze 602C2C 884B2B BE772B E8C170; silver 394A50 819796 C7CFCC EBEDE9; gem 73BED3. The clan colour stays on the name band and the banner.

## Sheets (`docs/art/boards/`)
- `card-tiers-1x.png`, `card-tiers-2x.png`: common (Power Strike icon), uncommon (Arcane Missile), rare (Fireball), all on the Lantern Dominion, so only the tier changes.
- `card-rare-clans-1x.png`, `-2x.png`: the rare tier on the Dominion, the Salt Crows and the Ashen Penitents.
The mock is composed in `art/pixellab-cards/mock.py` (real banners, real icons, the clan colours of factions.json); the text lines are placeholders.

## Catalogue (PixelLab, `create_image_pixflux` img2img from a code skeleton `skel.py`, 1 generation each)
| Piece | Seeds tried | Picked | Strength |
|---|---|---|---|
| frame x3 | 1, 2 (+ a first try at 300 that only copied the skeleton) | common 2, uncommon 1, rare 1 | 110 |
| plate x3 | 1, 2 (+ the same first try at 300) | 1 each | 110 |
| backdrop x3 | 1, 2 | 1 each | 250 |
Cost: 30 generations in all (18 for the first round at strength 300, 12 for frames and plates at 110). The raw outputs are in `art/pixellab-cards/raw/` and `raw1/`.

## Epic and legendary (12 gens)
| Piece | Seeds | Picked | Strength |
|---|---|---|---|
| frame epic, legendary | 1, 2 | 1, 1 | 110 |
| plate epic, legendary | 1, 2 | 2, 2 | 110 |
| backdrop epic, legendary | 1, 2 | 1, 1 | 250 |
Sheets: `docs/art/boards/card-five-tiers-1x.png` and `-2x.png` (Power Strike, Arcane Missile, Fireball, Frost Nova, Archon Eclipse on the Lantern Dominion).

## Honest notes
- PixelLab is used as a stylist on a skeleton I drew in code: asked for a free card frame it gives no clean transparent centre, so the layout is fixed and PixelLab adds the metal, the rivets and the gem.
- The common frame is plain on purpose; the rare one is the only one with a gem. The legendary halo is a ring in the backdrop plus a ray crown on the frame, not a ring around the card.
