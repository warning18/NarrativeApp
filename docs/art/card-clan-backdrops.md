# Clan backdrops for the offer card (16 November)

UX-2's "clan backdrop" direction (branch `claude/ux-2-card-colours`): the art zone is the clan's own, a dark gradient in the clan's colour with the clan's sign large and faint in the middle. Seven pieces, **104 x 76 art px** (1 art px = 2 dp), PNG8, no text, in `art/pixellab-cards/clans/final/`. They replace the tier backdrops (`art/pixellab-cards/final/backdrop_<tier>.png`) in the art zone; the rarity frame goes on top.

| Clan | File | Colour (factions.json) | Sign |
|---|---|---|---|
| The Lantern Dominion | `backdrop_dominion.png` | 2F62B5 | lantern |
| The Salt Crows | `backdrop_crows.png` | B0303F | anchor inside a ring |
| The Cinder Compact | `backdrop_compact.png` | B86B3C | hammer over an anvil |
| The Mire Courts | `backdrop_mire.png` | 3F8F5A | reed leaf over waves |
| The Grey Vigil | `backdrop_vigil.png` | 8A8F98 | open eye |
| The Ashen Penitents | `backdrop_penitents.png` | CBB68E | flame over a cross |
| The Wayfarer | `backdrop_wayfarer.png` | neutral brown 7A5A44 | a road narrowing to the horizon |

Sheet: `docs/art/boards/card-clan-backdrops-1x.png` and `-2x.png`: the seven cards in the real card, one gift each as in UX-2's compare row (Fireball rare, Frost Nova rare, Iron Stance uncommon, Multi Shot epic, Quick Heal uncommon, Second Dawn legendary, Keen Eye common), so each of the five frames is seen over a clan backdrop. Icons and text are placeholders.

Method: a code skeleton (`art/pixellab-cards/clans/skel.py`: a gradient from 42 % to 10 % of the clan colour over ink, and the sign at a low contrast) redrawn by PixelLab (`create_image_pixflux` img2img, init strength 250, `gen.py`), 7 clans x 2 seeds, 1 generation each = **14 generations**; seed 1 picked for all seven (raw outputs in `raw/`). The left third stays calm for the banner.

Palette note: not remapped to Apollo. A nearest-colour remap to Apollo drifted the Penitents' sand to grey-teal and dropped the faint signs, so the pieces keep the clan's own dark shades (at most 63 colours, transparent index 63 unused). They are backgrounds only; the Apollo palette still rules the frames, plates, banners and icons.
