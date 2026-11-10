# A tower in each town (Core's part)

The user's request: "I would potentially want a tower in each town; propose
a draft of the towns' maps and mainly the sphere with the towers on it."
UX-2 draws the maps and the sphere. This note covers what only Core can say:
which towns, what a town tower is in the rules, how it ties to the world,
what it costs, and the options.

Measured on main at v1.888. Proposal only: no code, no numbers changed.

## 1. The towns

`geography.json` holds 16 settlements. The chapter of each comes from the
journey map (`world_map.dart`), the biome from its zone, and the clan from
its country's static `ruler`. In the story the holder can change with clan
power (`town_rulers.dart`).

| Ch. | Settlement | Kind | Biome | Static ruler | Tags |
|---|---|---|---|---|---|
| 1 | **Alster** | city | temperate | Dominion | |
| 1 | The White Wells | village | desert | — | wild |
| 2 | **Saltmouth** | city | arid_coast | — | market |
| 3 | **The Ashen Quarter** | town | ashlands | Dominion | ruin |
| 3 | Emberwick | village | ashlands | Dominion | |
| 3 | Akagiri | village | volcanic | Dominion | |
| 3 | The Cove Camp | camp | sea_cliffs | Dominion | sea |
| 4 | **The Drowned Cloister** | town | fen | — | holy, haunted, ruin |
| 4 | The Kindly Hill | village | fen | — | |
| 4 | Wrack's End | village | sea_cliffs | — | sea |
| 5 | **The Black Reliquary** | city | frost | Dominion | holy |
| 5 | Rimewell | village | frost | Dominion | |
| 5 | Highhearth | village | frost | Dominion | |
| 6 | **The White Anchorage** | town | tear | — | sea, market |
| 6 | Greyhithe | village | tear | — | sea |
| 7 | **Candlehold** | city | sea_cliffs | Dominion | stronghold |

**Proposed: one tower per chapter, in its city or town (the 7 in bold).**

- The villages share their region's tower. Most stand in the same biome as
  that region's city or town (Emberwick, Rimewell, Highhearth, Kindly Hill,
  Greyhithe), so a second tower there would play the same foes.
- **No tower** at:
  - the Cove Camp: a camp, not a town;
  - the White Wells: a wild place, and only one foe lives in the desert;
  - Wrack's End and Akagiri: villages whose biomes hold 2 foes each (see §2).
- The static ruler is the Dominion for 4 of the 7 towers and nobody for the
  other 3. A tower's clan (§2) should therefore come from a table Narrative
  writes, not from the ruler, or 4 towers in 7 would offer the same oath.

## 2. What a town tower is in the rules

**It reuses `lib/data/tower/` as it is.** The Tower today is a main-menu
mode with its own hero (`towerHeroOf`). Each climb is 30 floors, not 25
(`towerTop = 30`):

- bosses on floors 10, 20 and 30;
- wardens on floors 5, 15 and 25;
- boons on floors 5 to 25;
- oaths on floor 1 and on 35% of the other floors.

**What changes per tower:** a new `TowerSite` record (id, place, biome,
clan, warden pools) selects:

- **Foes, weighted rather than filtered.** Of the 78 enemies, 50 have no
  `biomes` tag. The ordinary foes per biome are:

  | Biome | Foes |
  |---|---|
  | temperate | 8 |
  | arid_coast | 7 |
  | ashlands | 7 |
  | fen | 6 |
  | tear | 5 |
  | frost | 4 |
  | sea_cliffs | 2 |
  | volcanic | 2 |
  | sea | 2 |
  | desert | 1 |

  A floor can't repeat a foe from the 3 floors before it, so a pool limited
  to the biome would run dry. The proposal is to draw the tower's biome
  first with some share, and fall back to the global pool by chapter. The
  share is one number, to be measured with the bot.
- **The first oath** is the tower's clan, from Narrative's table; later
  oaths stay random from `towerClans`.
- **Wardens (optional, later):** floors 5, 15 and 25 use the tower's own
  pool. Natural sources are the bosses of the zones around that town
  (`zones.json`'s `bossEnemyId`). Floors 10, 20 and 30 keep the global
  bosses.

**What stays the same everywhere:**

- the 30-floor difficulty curve (`towerBudgets`), so one set of QA bands
  covers every tower;
- the hero, its copy and cache (#878);
- the bag cap of 5, spoils, boons, the profession scales, `towerFoeScale`;
- marks and unlocks: one shared progress, so a climb anywhere advances the
  same unlocks.

**Difficulty by town level: not proposed for the first step.** Starting
Candlehold's tower at chapter 7 would mean a new curve per tower, measured
and banded separately (7 × the bot's work). A flavour-only tower changes
the bands by the foe weighting alone, which the bot can measure in one
pass.

## 3. The world and the sphere

- **Entry: the Tower's start screen becomes the sphere.** The 7 towers sit
  on their towns' points of the world chart; UX-2 draws it. Tapping one
  picks the tower and opens today's start screen (calling, race, unlocks)
  with that tower's name and clan.
- **Unlock ladder:** Alster's tower is open from the start. Tower *k* opens
  once tower *k−1* reaches floor 10, its first boss. This needs a best
  floor per tower in `TowerProgress`, which keeps one global best today.
  The alternative, opening each tower once the story has reached its
  chapter, ties a separate mode to the story save. I'd keep them apart.
- **Several runs:** one run per tower, each under its own save key, so a
  player can leave Saltmouth's tower at floor 12 and climb Alster's. Marks
  and unlocks stay one shared file.
- **Journey (option C only):** the town's place view shows its tower as a
  landmark that opens the Tower mode on that tower. No story reward and no
  story hero, so the story's balance doesn't move.

## 4. Cost

| Area | Change |
|---|---|
| Data | a new `tower_sites.json` (7 rows: id, place id, biome, clan, warden pools); names and lore are Narrative's |
| Save | `TowerRun.towerId` (a save without one is Alster's, the tower that exists today); save key `tower_run_v1` → one key per tower, with today's key read as Alster's; `TowerProgress.bestFloorByTower` (old `bestFloor` read as Alster's) |
| Simulator and balance | `playTowerRun(..., site:)`; QA's bands run per tower: 7 × 300 runs ≈ 7 × 4 s on CI with the hero cache; the biome share is tuned once so every tower stays inside today's bands |
| Size | Core: 2 PRs (A1 sites + save + weighting + bot; A2 wardens per tower + unlock ladder). UX: 1–2 PRs (the sphere start screen; the towns' maps). Narrative: 1 PR (names, lore, clans of the 7 towers) |

## 5. Options

| | What | Size | Risk |
|---|---|---|---|
| **A** | One Tower mode, seven doors on the sphere; same curve; local foes, clan and (later) wardens | Core 2 PRs, UX 1–2, Narrative 1 | low: the rules and bands stay; the biome share needs one measure |
| **B** | Short towers inside the story: in each town, a 7–10-floor climb by the story's own hero, difficulty from the town's chapter, rewards into the story save | Core 5–7 PRs, plus UX and Narrative | high: a new fight path for the story hero, new story save fields, the playthrough simulator must climb, and story balance moves |
| **C** | A, then each town's place view links to its tower (§3) | A + 1 small PR | low |

**My recommendation is A, then C.**

- A gives the user what they asked for: a tower in each town and a sphere to
  choose from. It reuses all of the Tower, and the balance holds by
  construction.
- C ties it into the journey without touching the story's numbers.
- B is the version where towers feed the story. It is a different game
  loop, and I'd only build it if the user wants the story hero to climb.

**Risks:**

- Seven towers with one curve could feel alike. The local foe share,
  clans and wardens carry the difference, so it should be measured (how
  many floors show a local foe) before adding more.
- The 3 towers with no static ruler need Narrative's clans.
- Saves: old saves migrate in `fromJson`, as in #871.
