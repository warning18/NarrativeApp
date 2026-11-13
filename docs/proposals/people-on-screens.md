# The user's PixelLab characters on the screens, step (b): shopkeepers and the town crowd (a proposal, nothing built)

**Where a still figure can stand today** (read in `lib/`):

| spot | what it shows today | proposal | for |
|---|---|---|---|
| **The shop's keeper strip** (`_KeeperStrip` in `shop_detail_screen.dart`, above the shelf) | the shop's pixel sign (48 px), the keeper's line and name | the keeper stands at the strip's left (about 100 px tall, like the Tower cards), the line and name at his side; the sign stays when a shop has no figure | the 14 shops that name a keeper (`keeperName` in `shops.json`) |
| **The NPC page** (`npc_detail_screen.dart`) | a 48 px head (`HeadAvatar`) or the mark of their kind | the standing figure at the card's left, the name and role beside it | the NPCs that have a status |
| **Heads** (`HeadAvatar`, `assets/visuals/heads/`, made by `tool/gen_fight_heads.py`) | a crop of the sprite for the hero, enemies and some NPCs, else the initial | heads cropped from the figures for the NPCs that have a status, so the scene vignette (the one the scene faces), the fight's lists and the NPC page show a face instead of a letter | every recurring NPC with a status |
| **A story scene's band** (`StorySceneBand`) | the place's picture, no figures by design | **not proposed**: a figure standing on a picture drawn without one floats; the vignette's head is the better place | |
| **The road crossing's roadside** (`encounter_figure.dart`, code placeholders) | code figures for an encounter (a trader, a toll-taker) | only the side-view groups; Young peasant has 2 walks (#48, #55), the others are still: a still figure could stand on the near layer's line and drift past with it (speed 0.8). **Wait**: better when more statuses have walks | later |
| **The camp, the towns' street view** | companions' own art; street scenes of buildings | nothing: a crowd needs walks | |

**The rule of the user** (top-down groups only in still spots, never walking on a side-view road) is kept: the keeper strip and the NPC page are counters and cards, so the Male - Peasant and Peasant woman statuses are allowed there.

**The mock-up:** `docs/ux-shots/people-mock/keeper-mock-light.png` and `keeper-mock-dark.png` (four shops: Orrin Vell, Sister Ysolde, the Wreck-Wright, Old Pell; today's strip above, the proposed one under it; their real lines from `shops.json`). The figures are stand-ins cut from the inventory's workbench frames (#36, #50, #38, #41), a little chunkier than Art's real 64x64 files will be.

**What I need:** (1) Narrative's list (the 14 keepers and about 25 recurring people with the looks the data states), to match each to a status; the likely pool is #36, #38, #41, #37, #35 (men), #50, #20, #49, #53 (women, top-down: fine at a counter), #39 and #19 for a beggar, so about nine statuses for fourteen keepers (a status may serve two shops far apart); a keeper with no human look (the Keyholder, the cellar-boy) keeps the sign. (2) From Art, on the user's word: the chosen statuses exported as PNG8 64x64, the east frame (facing the text, as the figure stands at the left), as for the Tower three. (3) The user's answer on the heads: cropping heads for the NPCs (a `tool/` change, mine, one PR) is the biggest gain for the least screen change.

**How it would ship:** one PR per spot, picture first on the real screen: (1) the keeper strip, (2) the NPC page with the heads. No data field is needed if the figure's file is named by the shop id (`assets/visuals/people/shop_<shopId>.png`) and by the NPC id for the NPC page; a status shared by two shops is the same file twice, which costs a few KB.

## Narrative's list matched to the statuses (proposal; fit: good / ok / weak / none; only the looks the data states)
The sets: men in `Young peasant` #34-#45 (side view) and `Male - Peasant | Warrior | Mercenary | Hunter` (top-down, still spots only); women only in `Peasant woman` #7, #8, #19, #20, #21, #22, #49, #50, #53 (top-down, still spots only: the keeper strip and the NPC page are). Masks, horns, giants, oni, children and a mule have no match: "none" below, or a new figure from `Starter_basic_hero` (cost via Art).

**The 14 shopkeepers** (one figure per shop, a status may serve two shops far apart)
| shop | keeper | stated look | pick | fit |
|---|---|---|---|---|
| blind_beggar_stall | the cellar-boy | a boy with a barrow of bottles | none (every status is an adult); #43, the youngest man, only if the user accepts it | weak |
| black_market_docks | a Crow with no name | none | #42 (dark brown cloak) | ok |
| weaponsmith_forge | Orrin Vell | Compact weaponsmith | #38 (bearded man, blue and green vest) | ok |
| shieldwrights_hall | Hesta Brann | quarry-born shieldwright | #8 (armoured woman), if she is a woman (not stated; Narrative to say) | weak |
| arcane_bazaar | Imra of the Smoke | bazaar trader in incense | #20 (woman with a feathered hat, merchant) | good |
| apothecary_row | Sister Ysolde | Mire Courts sister, boiling fever-bark | #50 (red-haired woman, green dress) | ok |
| smugglers_vault | the Keyholder | a counter in a cellar | none (no look stated); #43 if one is wanted | none |
| hammersmith_forge | Dagny Ironhand | Anvil-Deaf smith | #30 (gambison and an axe, a man) or none; no smith among the women | weak |
| arcane_academy | Magister Corvane | runs the academy | #35 (old grey-haired scholar) | good |
| sharpweave_den | Needle | "a door with no sign" | none (keeps its sign, which suits it) | none |
| ossuary_relics | a deserter called Hask | a deserter | #29 (helmet and spear, a guard) | ok |
| last_lantern | Wickwarden Tallis | a woman, the only stall lit | #53 (brown-haired woman, green dress) | ok |
| anchorage_chandlery | the Wreck-Wright | a woman, reforged fleet blades | #49 (blonde in a straw hat, blue skirt) | ok |
| wayfarer_caravan | Old Pell | old muleteer with a mule train | #39 (ragged peasant) or #42; the mule is not there | weak |

**Recurring people with a stated look**
| person | stated look | pick | fit |
|---|---|---|---|
| Aurel Vane | tall, dark robes, white mask | none (he has his own head sprite already) | none |
| Brother Clement | porcelain mask | none | none |
| Vane the quartermaster | scarred, carries a ledger | #31 (helmet and staff, a watchman), no ledger | weak |
| the Wharf Keyholder | a woman in a good coat, an iron key | #20 | ok |
| Tamsin Brask | small woman, plain coat | #53 | ok |
| Tetsu | oni smith, one horn | none (a new figure) | none |
| Imeh | oni glass-trader | none | none |
| Brannoc Reedtithe | elf healer | none (no elf among the statuses) | none |
| Nadira | Tide-Kin woman of Tern Row, tired | #49 | weak |
| Old Harker | an old man | #35 | ok |
| the sign-painter | an old man, a wet brush | #34 (thin man, brown vest) | ok |
| Hesk Morrow | a big man gone grey | #36 | ok |
| Joss Harrow | lean, grey old man | #35 or #34 | ok |
| Hathra, Ghrem Stonebrow | giants | none | none |
| Dorran Quill | dwarf foreman | #2 or #6 (the dwarf guards, from the Hero group) | ok |
| Sister Odile | nurse | #53 | weak |
| Sister Inès | young acolyte | #19 or #49 | weak |
| Old Wick | old ash-sweeper | #39 | ok |
| Tam | a boy of about twelve | none (no child) | none |
| Sedge | a child in a reed mask | none | none |

**In all:** of 14 shopkeepers, 2 good, 6 ok, 4 weak, 2 none; of the 20 recurring people listed, 9 are none (masks, horns, giants, oni, children, an elf), 8 ok, 3 weak. The weak ones (Hesta Brann, Dagny, Pell, the cellar-boy) are the ones to ask Art about: a new figure from `Starter_basic_hero` is cheaper than a wrong face. Narrative's one-line look briefs would serve for those.
