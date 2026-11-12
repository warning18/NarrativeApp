# NPC and hero characters already in the user's PixelLab account (inventory, read-only, 0 generations)

**Standing rule (the user, 12 November): for the next NPC creations, use "Hero - Starter_basic_hero" as the reference** (state `Starter_basic_hero`, id `de5e44f4-1c9d-4043-96cf-eed8d324a086`; 48x48, side view, 8 directions, a v3 walk in 2 directions). Naming examples from the account: the orc starter is "orc starter", the mage "Hero_Mage_Basic".
**What the groups are** (the user): *Male - Peasant | Warrior | Mercenary | Hunter*: every status is a variation of that character, usable as an enemy, an NPC or other by context. *Hero*: every status is a variation of the hero. *Young peasant with a straw hat*: all NPCs, each status its own character (shop owners, town crowd). *Paysant woman*: the same for women NPCs.
**Counts:** the account has 153 characters; these four groups are **62 statuses**: Hero 27, Young peasant 15, Male - Peasant 11, Paysant woman 9. All have 8 directions. Read through the client (`list_characters`, `get_character`, one front frame per status by the free workbench inspect: nothing charged, balance unchanged at 849.5). The inventory data: `art/pixellab-npc-inventory/inventory.json`, frames `art/pixellab-npc-inventory/frames/`, the generator `inventory_gen.py`. Contact sheets: `docs/art/boards/npc-hero.png`, `npc-male-peasant.png`, `npc-young-peasant.png`, `npc-peasant-woman.png`.
**Note on the animations:** the API lists them per status; only 2 of the 15 Young peasant statuses (#48, #55) show one (the user remembers "most have at least a walk": the others may have it in a sibling state or not be listed, to check with the user). Checked against the full group downloads (141 files for the young peasants): the listing is complete. Statuses with an animation: Hero 10 of 27; Male - Peasant 6 of 11; Young peasant 2 of 15; Paysant woman 0 of 9.
**Size and view mismatches to know:** the Hero is 48x48 side (the game's side-view hero sprite is 42x47); the peasants are 64x64, the Young peasant side view, but Male - Peasant and Paysant woman are *low top-down*, not side, which differs from the side-view game; one Hero state is 64x64 (#46), one Young peasant is 52x52 (#55).

## Used where (the single list; the user's order: the Tower three, then shopkeepers and town crowd, then enemies and Tower foes, then hero variations)
| status | used as | file | state |
|---|---|---|---|
| #36 Young peasant, Fatter with bigger b | the Stair-Chandler (Tower shop) | `art/pixellab-npc-export/stair_chandler.png` | exported, not wired |
| #37 Young peasant, Older librarian | the Tally-Clerk (Tower bargain) | `art/pixellab-npc-export/tally_clerk.png` | exported, not wired |
| #47 Young peasant, Another passant hat | the parley guardian (Tower parley) | `art/pixellab-npc-export/parley_guardian.png` | exported, not wired |
| the rest | shopkeepers and town crowd, enemies and Tower foes, hero variations | to export as UX-2 asks | not started |

The two groups drawn from slightly above (Male - Peasant | Warrior | Mercenary | Hunter, and Paysant woman) are **spots only**: used as they are where a figure stands facing the player, never walking on a road; no redraws (the user, 12 November).

## Hero (48x48 side (one 64x64 side))
| # | status (name as stored, cut at 20 characters) | animations | proposed use |
|---|---|---|---|
| 0 | cleric starter | none | hero variation: human cleric (blue and gold robe) |
| 1 | No armor and no shie | none | dwarf hero, no armour or shield; or a dwarf NPC (smith, miner) |
| 2 | No weapon cheaper eq | none | dwarf with helm and shield: dwarf hero, or a dwarf guard / Tower foe |
| 3 | No weapon cheaper eq | none | human in leather armour: hero variation (warrior or ranger), or a militia soldier |
| 4 | orc starter | none | orc hero starter (green skin, white shirt): hero variation by people (orc) |
| 5 | cleric | none | cleric in plate and tabard: cleric hero, or an Inquisition priest NPC / Tower foe |
| 6 | dwarf warrior | none | dwarf warrior in heavy armour: dwarf warrior hero, or a Tower guardian foe |
| 9 | Hero_Mage_Basic | none | long-haired mage, dark robe (Hero_Mage_Basic): mage hero, or a scholar NPC |
| 10 | No weapon | none | cloaked, no weapon: rogue/ranger hero or a travelling NPC |
| 11 | rogue starter | none | rogue starter with a bow: ranger/rogue hero |
| 12 | Hero_Rogue_Basic | Walking (1 dir, 8f) | hooded rogue (Hero_Rogue_Basic), has a walk: rogue hero, or a cutthroat enemy |
| 13 | Basic_Orc | none | green orc with a cloak (Basic_Orc): orc hero or an orc raider enemy |
| 14 | Hero_Mage | none | mage with orange trim (Hero_Mage): upgraded mage hero |
| 15 | Hero_Warrior_Basic | none | white shirt warrior (Hero_Warrior_Basic): warrior hero starter |
| 16 | Hero_orc_art | none | orc with a straw hat (Hero_orc_art): orc ronin variation of the user's hero |
| 26 | Same armor but add a | none | armoured human with a red scarf: warrior hero tier, or a mercenary captain |
| 27 | Same armor but more | none | chain-mail human: warrior hero tier, or a Tower soldier |
| 28 | Add cheap medieval a | Walking (1 dir, 8f) | cheap medieval armour, has a walk: warrior hero tier / militia |
| 46 | Wearing same weapon | Walking (1 dir, 8f) | small (64x64) armoured ronin, has a walk: ronin hero armoured |
| 51 | Starter_basic_hero | v3:walking (2 dir, 8f) | **Starter_basic_hero: the reference for new NPCs**; white shirt, walk (v3, 2 directions) |
| 52 | Without a weapon and (copy) | Walking (1 dir, 8f) | cloaked ronin, no weapon, has a walk: hero variation / ronin NPC |
| 54 | Without a weapon and | none | cloaked ronin, no weapon: same |
| 56 | Idle-Walking (copy 2) | taking-punch (1 dir, 6f) | ronin with a taking-punch animation: hurt reaction of the hero |
| 58 | Idle-Walking (copy) | custom-Walking forward and triggering (3 dir, 15f) | ronin with a custom walk-and-trigger animation (15 frames, 3 dirs) |
| 59 | Idle (copy) | picking-up (3 dir, 5f) | ronin with a picking-up animation (3 dirs): loot/interact |
| 60 | sleeping | Running (1 dir, 8f) | ronin "sleeping" state with a Running animation |
| 61 | Idle-Walking | Walking (3 dir, 8f) | ronin Idle-Walking (3 dirs, 8f): the walking hero of the side view |

## Male - Peasant | Warrior | Mercenary | Hunter (64x64 low top-down)
| # | status (name as stored, cut at 20 characters) | animations | proposed use |
|---|---|---|---|
| 17 | younger, no beard | Walking (2 dir, 8f) | young peasant, no beard, walk 2 dirs: farmhand / town crowd / militia recruit |
| 18 | Hunter style | none | hunter in furs: hunter NPC, or a ranger/poacher enemy |
| 23 | Same with a sword an | Walking (1 dir, 8f) | knight with sword, shield and a red cape (walk): Tower foe / guard captain / parley guardian |
| 24 | Same but winter clot | none | winter clothes: town crowd, porter |
| 25 | Same with a cape | Walking (1 dir, 8f) | helmet, cape and a pole-arm (walk): mercenary enemy |
| 29 | Change the spear for | none | helmet and spear: guard / militia (enemy or NPC) |
| 30 | Add a gambison and a | none | gambison and an axe: soldier enemy |
| 31 | Change the helmet st | none | helmet and a staff: watchman NPC |
| 32 | Mercenary style with | Walking (1 dir, 8f) | heavy hooded mercenary (walk): mercenary enemy / Tower foe |
| 33 | Mercenary same style | Walking (1 dir, 8f) | mercenary with a spear (walk): mercenary enemy |
| 57 | Idle | Walking (2 dir, 8f) | peasant Idle, walk 2 dirs: town crowd |

## Young peasant with a straw hat (64x64 side (one 52x52))
| # | status (name as stored, cut at 20 characters) | animations | proposed use |
|---|---|---|---|
| 34 | Thinner body and tal | none | thin man, brown vest: town crowd, shop assistant |
| 35 | Same with no book bu | none | old grey-haired man, green vest: elder / scholar NPC |
| 36 | Fatter with bigger b | none | fat bearded man in a brown cloak: **shopkeeper; candidate for the Stair-Chandler** |
| 37 | Older librarian | none | older librarian with books: **candidate for the Tally-Clerk** |
| 38 | Longer bear skinnier | none | bearded man, blue and green vest: shopkeeper / innkeeper |
| 39 | Medieval style peasa | none | ragged peasant: beggar (the Blind Beggar) |
| 40 | Same style but summe | none | summer clothes: town crowd |
| 41 | Same style but diffe | none | bearded man, green vest: clerk / shopkeeper |
| 42 | Change clothes for H | none | dark brown cloak: traveller / porter |
| 43 | Younger no bear shor | none | younger, no beard, grey vest: town crowd |
| 44 | No hat half long hai | none | no hat, half-long hair: town crowd |
| 45 | Different face no ha | none | different face, no hat: town crowd |
| 47 | Another passant hat | none | blue coat and cap, an officer: **candidate for a parley guardian** (a gate warden) |
| 48 | Other clothes | walk (2 dir, 6f) | straw hat, "Other clothes", has a walk (2 dirs, 6f): farmer NPC that walks |
| 55 | Idle | Walking (1 dir, 8f) | straw hat, green shirt and a satchel, 52x52, walk (8f): the most finished peasant NPC |

## Paysant woman (peasant woman) (64x64 low top-down)
| # | status (name as stored, cut at 20 characters) | animations | proposed use |
|---|---|---|---|
| 7 | Slighlty different a | none | armoured woman with an orange banner: clan standard-bearer (enemy or NPC) |
| 8 | wearing a banner | none | armoured woman with a brown banner: clan standard-bearer |
| 19 | Same but poor | none | blonde in a straw hat, ragged: poor woman / beggar NPC |
| 20 | Same as warlord a bi | none | woman with a feathered hat, green dress: merchant / noble woman |
| 21 | Same but mercenary l | none | helmeted mercenary woman: mercenary enemy |
| 22 | Same but rogue merce | none | hooded rogue mercenary woman: cutthroat enemy |
| 49 | Same style but other | none | blonde in a straw hat, blue skirt: townswoman |
| 50 | Change face and hair | none | red-haired woman, green dress: townswoman / shop owner |
| 53 | Idle | none | brown-haired woman, green dress, Idle: village woman |

## Best fits for the places the user named (a proposal; the user picks first)
- **The Stair-Chandler** (the Tower shop, sells light): #36 (fat bearded man in a brown cloak), second choice #38.
- **The Tally-Clerk** (the Tower bargain, a ledger desk): #37 (the older librarian with books).
- **Parley guardians** (the floor's own foe acting as a doorkeeper): #47 (an officer in a blue coat and cap) for a gate warden, #23 (the knight with sword, shield and a red cape) for an armoured one; any Tower foe can stand there.
- **Shopkeepers:** #36, #38, #41, #50, #20. **Town crowd:** #34, #40, #42 to #45, #17, #57, #24, #49, #53, #35. **Beggar:** #39, #19.
- **Enemies and Tower foes:** the mercenaries #21, #22, #25, #29 to #33, the hunter #18, the standard-bearers #7 and #8 (clans), the orc raider #13, #2 and #6 (dwarf guards), #5 (Inquisition cleric).
- **Hero variations by people:** human #3 #15 #28; dwarf #1 #2 #6; orc #4 #13 #16; the ronin states (#46, #51 to #61) are the user's ronin. **By calling:** cleric #0 #5; mage #9 #14; rogue/ranger #10 #11 #12; warrior #15 #26 #27 #28.
Nothing is wired; no id, number or `npcs.json` is touched. New NPCs would be made from `Starter_basic_hero` (cost first, ask above about 30 generations).
