# Detours and expeditions that fit their place: the audit (Narrative, step 1)

For the manager and Core. Docs only; nothing is written or wired yet. Step 2 (the content) starts when Core has OK'd the shape in section 2. Numbers marked **[Core]** are suggestions: steps, enemies, rewards, DCs stay Core's.

## 0. What I read

- `lib/data/sub_node_engine.dart`: a detour is 1 to 2 nodes, 3 to 4 with a quest pickup (the file's own doc says 1-3 / 4-7; the code is `1 + nextInt(2)` / `3 + nextInt(2)`), rolled at 35% between two story scenes, from chapter 2, never between two tense scenes. Every sentence comes from `flavorFor(theme)`.
- `lib/data/map_themes.dart`: four themes (`ashenStreets`, `saltRoads`, `hollowReaches`, `wildsBeyond`), each with 12 EN + 12 FR lines for each of 6 kinds (shop, enemy, quest, treasure, rest, generic) = 72 lines per theme. The theme is chosen by `mapThemeForUiTheme(fromNode.uiTheme)` (`story_player_screen.dart:1865`), which knows only five of the story's ui themes: `docks` → saltRoads; `sewers`, `torture_chamber`, `cathedral`, `catacombs` → hollowReaches; **everything else → ashenStreets**. `wildsBeyond` is never reached by a story detour: only expeditions use it, through the zone's `mapTheme`.
- `assets/gamedata/zones.json`: 20 zones. Each already carries `location` (a geography id), `mapTheme`, `chapter`, `tier`, `expeditionCount` (3 or 4), `kind` for the 5 escort / delivery ones, a flavorText, a boss and a bossFlavorText. A clear zone's steps are `SubNodeEngine.buildNode(flavor: flavorFor(zone.mapTheme))`, so the same 72 lines as a detour; an escort or delivery draws from 7 + 7 scenes in `expedition_kinds.dart` (`ambush, axle, ford, toll, thieves, mules, stragglers` / `crossroads, checkpoint, pursuers, bridge, guide, storm, letter`), which say nothing about the zone they are in.
- `assets/gamedata/geography.json` (66 records, with the two Saltmouth districts of v1.312) and `Cleaned_Narrative_DAG.json` (426 scenes, each with `location`, `ui_theme`, `mood`).
- `land_routes.json` / `land_events.json`: the model for place-aware data (id, name, EN/FR, biome and terrain, events with choices, checks and outcome notes).

## 1. What a player sees now, and why it does not fit

A detour is placed by one signal only, the scene's `ui_theme`. In the story's 426 scenes the ui themes are: docks 131, cathedral 94, epilogue 61, slums 52, catacombs 48, desert 10, origin_ending 6, torture_chamber 6, sewers 5, hovel 4, gate 4, bridge 3, market 1, prologue 1. So the engine sees **three moods**: *salt* (docks), *hollow* (cathedral, catacombs, sewers, torture) and *ashen* (everything else). The table is what each place actually gets, from the scenes that stand in it (counts are DAG scenes; the engine's theme is the one most of them roll):

| Place (geography id) | Biome | Scenes | Detour theme today | What the player reads | Why it is wrong |
|---|---|---|---|---|---|
| `white_wells`, `sleepers_face`, `lark_wreck` | desert | 14 | ashen (salt for 1) | "A stall has been set up in a doorway…", "Footsteps close in fast from behind", "lantern light spills from a half-hidden storefront tucked between the ruins" | **Worst.** A desert oasis and a buried face get streets, doors, alleys and shopfronts. No sand, heat, wind, salt-caravans, scavengers, water, no sky. |
| `rimewell`, `highhearth`, `reliquary_quarter`, `dead_heart` | frost | 75 | hollow (rimewell, highhearth) / ashen (the Reliquary) | catacomb and ash-drift lines: "Something has been sleeping in the ash-drift under the eaves" | The frost the tear sends down is the whole mood of ch.5: cold hearths, rime, giants, quarry stone, tear light. The detours are stone-crypt or ash, not frost. |
| `white_anchorage`, `greyhithe`, `hollow_shore`, `hollow_shore_battlefield`, `beyond_the_tear`, `white_fleet_grave` | tear | 68 | salt (anchorage, grave) / ashen (the rest) | harbour-market lines ("a cart of salvage… selling the district back to itself") | The glass strand, the White Fleet's wreck-field, the invasion and the tear itself get a market and a gutter. No glass, wrecks, tear-things, lantern light, the widening Tear. |
| `drowned_cloister`, `kindly_hill`, `hollow_court` | fen | 51 | hollow | crypt and sewer lines | Closest fit of the lot, but the fen is reeds, black pools, bells, the Court's lights and a rider every seventh year. Nothing of water, reeds, villages, bells. |
| `ashen_quarter`, `emberwick`, `spire_of_judgment` | ashlands | 56 | hollow (ashen_quarter 33 of 34!) / ashen | the Ashen Quarter reads as a catacomb | The scenes' ui theme there is `cathedral` (the Spire's quarter), so the purge-burned town is told as a crypt. Slag, cinders, scorched tabards, iron sentinels and the Reckoning Wall are missing. |
| `akagiri` | volcanic (the Red Hills) | 10 | ashen | street and shopfront lines | A red-hill village of the oni and the exorcists' bells; no hills, bells, wardings, red earth. |
| `candlehold_gates`, `candlehold_lantern_hall` | sea cliffs | 19 | hollow | crypt lines | The Throne's seat: cliffs, brass, lanterns, the Host. |
| `cove_camp`, `wracks_end` | sea cliffs | 40 | salt | harbour lines | Fine for a quay, wrong for a hidden cove and a wrecker's cliff-village: no shingle, kelp, wreck-timber, tidal caves. |
| Saltmouth districts (`saltmouth_*`, 6) | arid coast | 59 | salt, or ashen at the gate | the same harbour lines in all six | Six places with six identities (a gate with a queue of wagons, paper-boat Tern Row, card barrels, lantern alleys, a ship-breaker's yard, a smugglers' wharf) read as one. |
| `alster_*` (5 districts, the ch.1 city) | temperate | 33 | ashen | n/a: chapter 1 never detours | Not a problem now. Only worth a pool if a later chapter ever returns there. |

**Worst mismatches first:** (1) the desert; (2) the tear shore and Hollow Cape; (3) frost city; (4) the Ashen Quarter read as a crypt; (5) Saltmouth's six districts identical; (6) the fen being "close but generic"; (7) Akagiri and Candlehold.

**Expeditions are no better.** Each of the 20 zones has one flavor text, a midpoint text and a boss text of its own, and the steps between are the same 72 lines of one of four themes:

- `z_changeling_fen` (reed-beds, black pools, the Teind-Rider's road) and `z_ossuary_galleries` (flooded bone-shelves) both get `hollowReaches`, which also serves `z_bell_road`, `z_drowned_stair`, `z_shroud_vigil`; the player cannot tell a fen from a crypt from a square.
- `z_exorcists_road` (red hills, warding posts, bells and bowls of salt) gets `ashenStreets`, the *same pool* as `z_dead_heart_approach` and `z_cinder_row`.
- `z_frost_quarry`, `z_ember_run` (frost, a coal carried through a dying city), `z_glass_strand`, `z_white_fleet_grave`, `z_lantern_train`, `z_beyond_the_tear` all get the *same* `wildsBeyond` pool.
- The five escort and delivery zones read the same seven escort scenes or seven delivery scenes whatever the road: the Salt Road, the Bell Road and the Lantern Train all have "a ford", "a toll" and "mules".
- Lengths are 3 or 4 steps, so the boss text arrives after two or three generic events; the player gets very little of the place before its boss.

## 2. Proposed data shape: `assets/gamedata/detours.json` (mine, EN + FR)

Wording leaves Dart. Each pool is keyed by a place id at any level of the geography chain, and the engine takes the **most specific pool that has the kind it needs**, falling back up the chain, then to the theme pool (today's four, moved here unchanged as the last resort).

```json
{
  "version": 1,
  "kinds": ["shop", "enemy", "quest", "treasure", "rest", "generic"],
  "places": {
    "saltmouth_card_row": {
      "shop":   [{"en": "A dockhand deals a hand on a barrel-head and sells you the loser's boots.", "fr": "…"}],
      "enemy":  [{"en": "…", "fr": "…", "mood": "tense"}],
      "rest":   [],
      "generic":[]
    },
    "dune_sea": { ... },
    "ashlands": { ... }
  },
  "biomes": {
    "desert": { "...": [] }, "frost": { "...": [] }, "tear": { "...": [] }, "fen": { "...": [] },
    "ashlands": {}, "volcanic": {}, "sea_cliffs": {}, "arid_coast": {}, "sea": {}, "temperate": {}, "jungle": {}
  },
  "themes": {
    "ashenStreets": { "...": [] }, "saltRoads": {}, "hollowReaches": {}, "wildsBeyond": {}
  }
}
```

- **Line = `{en, fr}`** (one object per line, not two parallel lists, so a line can never lose its translation). Optional keys: `mood` (`calm` | `tense`: for lines that only fit one; default both), `time` (`day` | `night`), `needs` (a flag or a chapter floor, e.g. `"minChapter": 5` for lines that name the frost).
- **Lookup order** for a detour: the scene's district → its location → its zone → its biome → its ui theme's pool (today's). Core merges kinds: a pool with no `rest` lets the next one up answer for `rest`.
- **Expedition steps** use the same pools by the zone's `location` for any step left generic. Zones get their own steps in `assets/gamedata/expedition_steps.json` (section 3), with a pool fallback.
- **Size** (what I would write, section 4): 11 biome pools × 6 kinds × 6 lines = 396 lines; 20 place pools (the six Saltmouth districts, the tear, frost and fen towns, the desert sites, the camp) × 6 kinds × 3 lines = 360 lines; each EN + FR.
- **Keys a scene must expose.** The player screen needs to pass, from the *from*-node: `location` (already on `StoryNode`), its `mood` (already there), and the **geography chain** (the district's parent location, zone and biome, from `geography.json`; one helper, e.g. `Geography.chainOf(locationId)` returning `[district, location, zone, biome]`). `uiTheme` stays as the last fallback. For an expedition: `zone.location` + its chain + `mapTheme` (kept as the fallback).
- **Hunts** (`withHunts(..., flavor)`) draw from `flavor` too; they would take the same lookup.

### Core's list (engine, fields, numbers)

1. Load `detours.json`; `SubNodeEngine.maybeGenerate` and `buildNode` take a `PlacePools` (or the `locationId` and the loader) instead of `ExcursionFlavor`; build the lookup chain (district → location → zone → biome → theme); keep `flavorFor(theme)` as the last fallback, and delete the Dart pools only after the JSON carries them.
2. `story_player_screen.dart:1865`: pass `fromNode.location` and `mood` (and the zone's `location` in `expedition_screen.dart`).
3. A `Geography` helper for the chain, and a unit test that every `places` / `biomes` key in `detours.json` exists in `geography.json` / `biomes.json`, and that every line has both languages (as `l10n_data_test` does for strings).
4. Expedition lengths: derive `expeditionCount` from the number of steps in `expedition_steps.json` (or keep it in `zones.json` and test they agree); midpoint text at `count ~/ 2` already works for any count. `deliveryDeadlineOf` is `count + 2`: check it still plays fair at 8 to 15 steps.
5. A `steps` schema: a zone with a list of steps uses it; a zone without falls back to the pools. Escort and delivery scenes (the 14 in Dart) get the same treatment: either zone steps replace them, or the 14 scenes get `{place}` overrides per zone. My suggestion: zone steps replace them, and the 14 become the fallback.
6. Numbers I mark as suggestions below: step counts, DCs, enemies, rewards, deadlines.
7. Simulator and pinned tests: `chapter_loop_test`, expedition tests, `qa_*` guards that count steps will need their counts relaxed; the simulator's expedition averages shift with 5 to 15 steps.

## 3. The 20 expeditions: outline per zone

Step types: **event** (a scene with choices), **check** (a stat roll), **fight**, **discovery** (a place, a find or a material), **rest**. The last step is always the **boss** (the zone's existing boss text). The midpoint text lands at `count / 2` as now. Foes named are from `enemies.json` and fit the zone's biome and chapter; `[new]` marks a foe I think the zone needs and Core would have to add. Materials are the zone's own `rewardMaterials` plus the ones that fit. A **discovery** names a place on the road (an invented sub-place of the zone, with EN/FR names I write in step 2); none is a new geography record.

**Suggested length per tier [Core]:** tier 1 about **5-6** steps; tier 2 clear **8-9**, escort / delivery **8-10** (a stage is a day: deadline stays `steps + 2`); tier 3 **12-15** (the main-story bosses).

### Tier 1 (5-6 steps)

**1. `z_fishermans_row`** (Saltmouth wharf, ch2, boss `dock_overseer`, timber ×3). 6 steps. 1 event: a gutting-table line that does not look up (nobody answers a stranger) · 2 check (Perception): which of the sheds is used for what is not fish · 3 fight: `harbor_rat` ×2 in a net-loft · 4 discovery: a tarred locker under the floor, timber · 5 rest: the smokehouse brazier · 6 boss.

**2. `z_tanners_court`** (wharf, ch2, boss `plague_hound`, cut stone ×3, armor_leather). 6 steps. 1 event: the lime-pit foreman wants his pit left alone · 2 check (Constitution): the smell has a door in it · 3 fight: `street_bandit` ×2 who tan their loot · 4 discovery: a drying-loft with stone ballast, cut stone · 5 event: a drain that something has been fed through · 6 boss.

**3. `z_ossuary_galleries`** (`drowned_cloister`, ch4, boss `bone_warden`, iron ore ×2, ash steel ×1). 6 steps. 1 event: the first gallery, flooded to the second shelf · 2 check (Wisdom): the bones have been moved since the last water · 3 fight: `catacomb_ghoul` ×1 · 4 discovery: a Court ledger-niche, ash steel · 5 rest: a dry shelf with candle ends · 6 boss.

### Tier 2, clear (8-9 steps)

**4. `z_lantern_docks`** (wharf, ch2, boss `smuggler_captain`, timber ×2, cut stone ×1, needs `hull_patched`). 8 steps. 1 event: the chart-seller's lantern, past curfew · 2 check (Charisma): what she knows is for sale; what she sells is not what it was · 3 fight: `harbor_rat` ×3 under a quay · 4 event: a boathouse with a second door · 5 discovery: a chart tube in a tide-pool locker (a place on the coast to find) · 6 fight: `inquisition_soldier` on a patrol that wants a bribe · 7 rest: the lantern-lit steps · 8 boss.

**5. `z_cinder_row`** (`ashen_quarter`, ch3, boss `iron_golem`, slag glass ×2). 8 steps. 1 event: the market that burned twice · 2 check (Perception): what is still worth selling · 3 fight: `cultist_acolyte` at a gutted stall · 4 discovery: a melted ledger-vault, slag glass · 5 event: a scorched-tabard purifier asks for a name · 6 fight: `inquisition_auxiliary` ×2 · 7 rest: a doorway swept clean, a lamp · 8 boss.

**6. `z_drowned_stair`** (`hollow_court`, ch4, boss `hollow_court_inquisitor`, slag glass ×2, ash steel ×2, sword_t8, needs `ossuary_galleries_cleared`). 9 steps. 1 event: the top landing's last candle · 2 check (Dexterity): a turn of the stair under water · 3 fight: `hollow_court_zealot` ×2 · 4 discovery: a landing with a drowned reliquary, ash steel · 5 event: names scratched on the wall, a dead man's route home · 6 fight: `bone_sexton` · 7 check (Constitution): the cold pour of a flooded stair · 8 rest: a dry chamber kept at great expense, the door ajar · 9 boss.

**7. `z_dead_heart_approach`** (`dead_heart`, ch5, boss `tear_spawn`, rime crystal ×2, shroud thread ×2). 9 steps. 1 event: frost in summer, shadows the wrong way · 2 check (Wisdom): the way the shadows lie · 3 fight: `void_hound` ×2 · 4 discovery: a shuttered shop with a hearth gone cold, rime crystal · 5 event: the last pilgrim in the street · 6 fight: `masked_penitent` · 7 rest: a chapel nave without its roof · 8 event: the tear-stuff in the stained glass · 9 boss.

**8. `z_glass_strand`** (`hollow_shore`, ch6, boss `strand_colossus`, tear glass ×3). 9 steps. 1 event: sand that ran to glass in one breath · 2 check (Dexterity): glass shards, a hum underfoot · 3 fight: `hollow_reflection` · 4 discovery: a White Fleet keel half in glass, tear glass · 5 event: wreckage with a sailor's name cut into it · 6 fight: `drowned_pilgrim` ×2 · 7 check (Wisdom): a humming that is not the wind · 8 rest: a hull rib, shelter from the glare · 9 boss.

**9. `z_exorcists_road`** (`akagiri`, ch3, boss `horn_taker`, iron ore ×2, needs `cinder_row_cleared`). 8 steps. 1 event: the first warding post and its bowl of salt · 2 check (Wisdom): a bell that is not rung from where it hangs · 3 fight: `cultist_acolyte` ×2 on the red hill · 4 discovery: a roadside shrine with a bowl of salt and a coin, iron ore (a place on the road) · 5 event: an exorcist's apprentice asks you to carry a bell · 6 fight: `demon_imp` (the road's lessons) · 7 rest: the shrine bench at the top of a mile · 8 boss.

**10. `z_changeling_fen`** (`kindly_hill`, ch4, boss `teind_rider`, iron ore ×2, needs `ossuary_galleries_cleared`). 9 steps. 1 event: lights over the pools that belong to neither the Court nor the villages · 2 check (Wisdom): which light is a lantern · 3 fight: `void_wisp` ×2 · 4 discovery: a reed-bed boat with a villager's bell, iron ore · 5 event: a child the fen has swapped, or not · 6 fight: `catacomb_ghoul` in the shallows · 7 check (Dexterity): a plank bridge over black water · 8 rest: a dry mound, a hearth in a hut · 9 boss.

**11. `z_frost_quarry`** (`highhearth`, ch5, boss `frost_kept_giant`, rime crystal ×3, shroud thread, tear glass ×2, needs `dead_heart_cleared`). 9 steps. 1 event: the first hundred steps of white rock · 2 check (Strength): a cut block across the stair · 3 fight: `inquisition_penitent` ×2 who guard nothing · 4 discovery: a stone with names cut into it, rime crystal · 5 event: the Inquisition owns this on paper; nobody has worked it since · 6 fight: `void_hound` · 7 check (Constitution): the frost the tear sends down · 8 rest: a quarrymen's hut, a stove with no fuel · 9 boss.

### Tier 2, escort and delivery (8-10 steps)

Each stage replaces the generic scene with one tied to the road; `{cargo}` and `{days}` effects stay as the numbers Core sets.

**12. `z_salt_road`** (escort, `saltmouth`, ch2, boss `brine_jack`, cut stone ×2, coat_brigandine). 9 stages. 1 event: the saltworks' four wagons, Old Maudry's instructions · 2 check (Charisma): a driver who will not leave the pans · 3 fight: `street_bandit` ×2, wreckers on the coast road · 4 event: a wagon sinks in a salt-flat crust · 5 check (Strength): hauling it clear · 6 discovery: an abandoned drying-hut, cut stone · 7 fight: `plague_hound` among the dunes · 8 event: the inland market's tollgate · 9 boss.

**13. `z_fever_bark`** (delivery, `ashen_quarter`, ch3, boss `purifier_vell`, slag glass ×2, boots_iron_shod). 8 stages. 1 event: the apothecary's chest of fever-bark and the landing · 2 check (Dexterity): the quickest way through the burned arcade · 3 event: a purge-checkpoint with a list of names · 4 fight: `inquisition_soldier` ×2 · 5 discovery: a gutted pharmacy with something worth a day, slag glass · 6 event: smoke over the shacks under the Reckoning Wall · 7 rest: a burned chapel's step, a lamp · 8 boss.

**14. `z_bell_road`** (escort, `kindly_hill`, ch4, boss `knell_keeper`, slag glass ×2, helm_drowned_sallet). 9 stages. 1 event: three new bells from the foundry, wrapped for the road · 2 check (Wisdom): the fen's lights on the first night · 3 fight: `void_wisp` ×2 · 4 event: a village that rang its bell too late · 5 check (Dexterity): the plank bridge with the heaviest cart · 6 discovery: a roadside bell-post with a cut rope, slag glass · 7 fight: `catacomb_ghoul` · 8 rest: a village that rings at dusk · 9 boss.

**15. `z_ember_run`** (delivery, `rimewell`, ch5, boss `rime_bailiff`, rime crystal ×2, tear glass ×2, phoenix_sigil). 8 stages. 1 event: the last forge's coal in its iron box, a promise to keep warm · 2 check (Constitution): frost on the first mile · 3 event: a cold street where every hearth is out · 4 fight: `inquisition_penitent` ×2 who want the fire · 5 discovery: a sealed bakery with a dry oven, rime crystal · 6 check (Wisdom): feeding the coal through a crosswind · 7 rest: a doorway on the lee side · 8 boss.

**16. `z_lantern_train`** (escort, `greyhithe`, ch6, boss `glass_shepherd`, lantern brass ×2, boots_tearwalker). 10 stages. 1 event: the shore villages' grain and lamp oil left in the barns · 2 check (Charisma): a farmer who will not leave his barn · 3 fight: `hollow_reflection` · 4 event: a lamp-oil wagon that leaks · 5 check (Dexterity): a washed-out ford on the shore road · 6 discovery: a barn with a sealed oil-cellar, lantern brass · 7 fight: `drowned_pilgrim` ×2 · 8 event: the widening Tear in the corner of the eye · 9 rest: the high ground, the first lanterns lit · 10 boss.

### Tier 3 (12-15 steps)

**17. `z_scaffold_yards`** (`emberwick`, ch3, boss `void_stalker`, iron ore ×2, slag glass, plate_emberproof, needs `cinder_row_cleared`). 12 steps. 1 event: the forges gone cold · 2 check (Perception): fresh scorch where nothing should burn · 3 fight: `iron_golem` · 4 discovery: a toolrack with a master's mark, iron ore · 5 event: a foreman's grave with his tongs on it · 6 fight: `cultist_acolyte` ×2 · 7 check (Dexterity): a scaffold that sways · 8 discovery: a cooling-trough with slag glass · 9 fight: `inquisition_auxiliary` ×2 · 10 rest: a cold forge with a banked ember · 11 event: something folds itself into the shadows between the poles · 12 boss.

**18. `z_shroud_vigil`** (`dead_heart`, ch5, boss `void_archon`, tear glass ×2, shroud thread ×2, needs `dead_heart_cleared`). 13 steps. 1 event: the square where the tear hangs in the air · 2 check (Wisdom): where the shadows come from · 3 fight: `void_hound` ×2 · 4 discovery: a reliquary in the square's edge, shroud thread · 5 event: an Inquisitor's chair, empty, still warm · 6 fight: `masked_penitent` ×2 · 7 check (Constitution): a long cold breath · 8 event: a name read out by the wind · 9 fight: `tear_spawn` · 10 discovery: a lantern still burning in the shroud, tear glass · 11 rest: the last chapel's undamaged corner · 12 event: the vigil, the shape of an office under what the tear made · 13 boss.

**19. `z_white_fleet_grave`** (`white_fleet_grave`, ch6, boss `white_admiral`, white-fleet oak, lantern brass). 13 steps. 1 event: forty hulls on a floor of glass, masts standing · 2 check (Dexterity): a gangway of glass · 3 fight: `drowned_pilgrim` ×2 · 4 discovery: a captain's cabin with a log, white fleet oak · 5 event: a signal flag still raised · 6 fight: `unmade_knight` · 7 check (Wisdom): a bell below deck · 8 event: the muster of a crew that did not stop · 9 fight: `hollow_reflection` ×2 · 10 discovery: a brass lantern in a binnacle, lantern brass · 11 rest: a chart-room table, a candle · 12 event: the flagship with its colours flying · 13 boss.

**20. `z_beyond_the_tear`** (`beyond_the_tear`, ch6, boss `void_sovereign`, tear glass ×2, lantern brass ×2). 15 steps. 1 event: the far side, no sky, no ground that stays · 2 check (Wisdom): the Rusty Eel remembers what a world is for · 3 fight: `hollow_reflection` · 4 event: the faces of everyone the invasion took, walking · 5 discovery: a street that remembers a name, tear glass · 6 fight: `unmade_knight` ×2 · 7 check (Constitution): the weight of the air · 8 event: a companion's voice, calling from somewhere · 9 fight: `void_hound` ×3 · 10 discovery: a lamp lit by someone who is not there, lantern brass · 11 rest: a held breath · 12 fight: `tear_herald` [Core: it is ch8; or a new ch6 foe] · 13 event: the throne seen from far off · 14 check (Charisma): the thing that knew the family name · 15 boss.

## 4. All the data updates, split

**Narrative (text; EN + FR; all new files are mine):**

- `assets/gamedata/detours.json`: 11 biome pools × 6 kinds × 6 lines (396 lines), 20 place pools × 6 kinds × 3 lines (360), and the four existing theme pools moved over unchanged (288 lines). Written in four small PRs by priority: **(a)** desert and tear (the two worst), **(b)** frost and the Ashen Quarter, **(c)** the six Saltmouth districts, **(d)** fen, Akagiri, Candlehold, the camp and cliffs.
- `assets/gamedata/expedition_steps.json`: the 20 outlines above as steps: each a `{id, type, text, text_fr, choices[]}` in the `land_events.json` shape (`check`, `dc` left to Core, `success` / `fail` / `outcome` notes, fight ids), 8 to 15 per zone, about **190 steps** in all. Written in tier order: the three tier-1 zones first (they teach the format), then the five escort / delivery, then the clear tier 2, then tier 3.
- Names for each discovered place on the road (EN/FR), about 40; a short extra boss midpoint line where a zone's step 5 has changed the story.
- The wording for the two things the engine needs a label for (a "step N of M" label already exists).

**Core (numbers, fields, engine, tests):**

- The loader, lookup chain, `locationId` / geography-chain plumbing and the fallback (section 2, items 1 to 3).
- Step counts per tier, DCs, which foes fight where (the lists above are suggestions), rewards and drops per discovery, the rest healing amount, the deadline per delivery.
- `expeditionCount` derived from the step list, and the tests that pin it (item 4 and 7).
- A foe for each gap: `tear_herald` is ch8 and the ch6 tear zone wants one of its own; a `lime_pit_thing` / `net_eel` style small foe for the wharf's tier-1 zones is optional.
- Retiring the Dart pools and the 14 escort / delivery scenes after the JSON is in (or keeping them as the fallback).
- Anything in `db_schema.dart` the new files need, and the simulator pass.

## 5. Decisions I need from Core before step 2

1. **Pool keys:** is the lookup chain (district → location → zone → biome → theme) right, or do you want fewer levels (location → biome → theme)?
2. **Step types:** do `discovery` and `rest` exist as step kinds already, or do I use event choices for them (`outcome` with `healthPct` / material / gold, as in `land_events.json`)?
3. **Format of a step:** is the `land_events.json` choice shape (`check`, `dc`, `success`, `fail`, `outcome`, `fight`) what `ExpeditionScreen` can play? If not, name the fields it can.
4. **Lengths:** are 5-6 / 8-10 / 12-15 acceptable, or should the first PR try one tier only?

When you have answered, I start with the tier-1 steps and the desert and tear pools.
