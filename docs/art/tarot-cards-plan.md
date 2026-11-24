# Tower tarot cards (direction B): plan, pilot and cost (24 November 2026)

UX-2's notes (`claude/ux-2-tower-cards`, `docs/ux-shots/tower-cards/README.md`): direction B needs vignettes of about 96 x 64, three rarity seals, a tarot frame with corner ornaments and a "new" stamp, in the Tower ink style.

## The exact list (names from the data)
| Piece | Items | Size | How |
|---|---|---|---|
| School vignettes (9) | the skill elements of `skills.json`: Fire, Earth, Wind, Water, Ice, Light, Electricity, Void, and None (the 41 martial skills) | 96 x 64 | PixelLab, `create_image_pixen`, ink style plus the one spot colour of the school |
| Dice vignette (1) | dice | 96 x 64 | PixelLab |
| Spell-family vignettes (4) | the `effect` of the 17 spells: Damage (7), Block as ward (3), Heal with Cleanse (4), Status as hex (3) | 96 x 64 | PixelLab |
| Clan-oath vignette (1) | the clan banner on a plate | 96 x 64 | code, from `assets/visuals/banners`: 0 generations |
| Rarity seals | UX asked for 3; the skills carry 5 rarities (common 29, uncommon 36, rare 45, epic 43, legendary 9), so 5 are proposed: red wax with 1 to 5 dots | 32 x 32 | PixelLab |
| Tarot frame (1) | corner ornaments | about 112 x 160 | PixelLab, as for the card frames |
| "New" stamp (1) | a red ink stamp | about 48 x 24 | PixelLab |

## Prompts
`INK` = "pixel art, black ink brush painting, dry-brush texture, strong contrast, large areas of solid black, cold grey and paper white, only deep red accents" (`art/pixellab-ink/gen.py`), then per piece: Fire "a hand holding a flame inside a black stone arch, drifting embers, mist, snow, a red flame as the only colour"; Dice "three dice lying on a dark stone floor with snow, mist, one red pip"; Heal "an open palm above a lit candle in a stone alcove, soft white light, mist, a small red drop"; the other schools in the same pattern (Earth: a cracked boulder with a red vein; Wind: a torn banner in a gale; Water: a still black pool with one ripple; Ice: a frozen hand reaching out of ice; Light: a shaft of white light through a broken roof; Electricity: a forked red-white crack across a black sky; Void: a black ring with a red eye; None: a plain sword and a shield on a stone step); spell families: Damage "a bolt striking a stone floor", Ward "a round shield held up against snow", Hex "a hanging charm with a red thread". Seals: "a round red wax seal with a rough edge, N small dots pressed into its face in a row".

## Cost (1 generation per piece)
- Full set, one seed: 9 + 1 + 4 + 5 + 1 + 1 = **21**; with about 8 retries for the weak ones: **about 29**, under 30.
- Two seeds for everything: **42** (needs the user's OK).

## Pilot, 8 generations (done): Fire, dice and Heal vignettes + the rare seal, 2 seeds each
Board `docs/art/boards/tarot-pilot.png` (the pilot above; below it the plate UX uses today: crops of the ward, shop, parley and bargain plates). Files `art/pixellab-tarot/final/`: `vignette_fire.png`, `vignette_dice.png`, `vignette_heal.png`, `seal_rare_3dots.png` (and `alt_` for the other seed). Balance 1806.
- What worked: the dice and the fire read well and are clearly in the ink style; the seals work (`seal_rare_3dots.png` has the better wax edge; `alt_seal_rare_3dots.png` has the clearer three dots).
- What did not: in the Fire second try and both Heal tries the model drew a tarot card inside the picture; I picked the first Fire and the first Heal (the cleanest), but Heal also has a card-like frame that needs a retry with "no card, no frame".
- The vignettes are not tied to the Tower plates (no scene to crop): they are made as small paintings, so UX can drop the plate stand-ins.
