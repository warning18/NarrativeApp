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
