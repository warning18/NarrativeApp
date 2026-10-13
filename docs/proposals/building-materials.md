# Proposal: a building economy with materials

Core, for the manager. Nothing is built yet; this is for a decision.

## Why

Camp buildings (`houses.json`, 10 entries) cost gold only: 150 to 4 000. The simulator ends a run with about 3 400 gold in the median and has nothing it wants to buy. `items.json` holds only two Material items: `material_iron_ore` (10 gold a sack) and `boss_trophy`. Gold alone can't gate anything that matters, because by chapter 5 every run has more than any building costs. Materials earned where the story goes would tie building to playing: you raise the Shroud Shrine because you went to the Dead Heart, not because you saved up.

## Tiers

Four tiers, one per stage of the story. Each tier has one common material and one rare one.

| tier | chapters | common (stacks, sells) | rare (gates) | where it comes from |
|---|---|---|---|---|
| 1 | 1-2 | timber, cut stone | — | Saltmouth shops, the docks, wreck salvage |
| 2 | 3-4 | iron ore (exists), slag glass | ash-steel ingot | Ashen Quarter and Slag Kilns fights, the Frost Quarry, the fen expeditions |
| 3 | 5-6 | rime crystal, tear glass | Shroud thread | the chapter 5-6 expeditions' bosses, Hollow Shore drops |
| 4 | 7-8 | lantern brass | white-fleet oak | the Lantern Throne war, the White Fleet's Grave |

Ten new items in all (`itemType: "Material"`, an icon, English and French names from Narrative). `boss_trophy` stays as the cross-tier wildcard: any one rare.

## Sources

- **Expeditions** (zones.json): `rewardMaterials: {id: count}` beside `rewardGold`, paid once on clearing, like the gold. Each tier's rare comes mostly from its main zone's boss.
- **Voyages**: a salvaged derelict (`sea_events.dart`, the derelict event) drops the tier's common material. A won ship battle drops 1 rare from tier 2 on.
- **Fights**: enemies' `lootTable` already takes item ids. The tier's common goes on the zone's ordinary foes at 10-20%.
- **Shops**: the commons only, at 3 to 5 times their sell price, so gold can still buy progress, but slowly. Rares are never sold.

## What it gates

`houses.json` gains `materialCost: {id: count}` beside `buildCost` (the gold cost stays, lowered by about a third). Proposed rule: a building needs materials of its own tier, and its rare only for the top building of a tier.

| building | today | proposed |
|---|---|---|
| harbor, barracks annex, Kelda's hall | 150-250 gold | gold + tier 1 commons |
| hammersmith, academy, Sharpweave den, smugglers' cellar | 350-400 gold + a flag | gold + tier 2 commons, flag kept |
| hearth hall | 1 500 gold | 1 000 gold + tier 2 commons + 2 ash-steel ingots |
| banner loft | 2 500 gold | 1 600 gold + tier 3 commons + 1 Shroud thread |
| Shroud shrine | 4 000 gold | 2 600 gold + 3 Shroud threads |

Camp upgrades (the camp works) follow the same pattern.

## Unlock rules

A building shows when its flags are held (as today) **and** its tier's chapter is reached (`reachedChapter`). It can be built when the gold and the materials are there too. Standing gates stay with the clans' offers; I'd not add them to buildings (one gate a thing is easier to read). The build sheet shows what's missing and where it comes from ("Rime crystal: the Frost Quarry, the Ember Run").

## Existing saves

Nothing is taken away. Buildings already built stay built (`builtHouseIds`). Materials are ordinary inventory items, so no new save field is needed. A save that already holds iron ore keeps it and it counts. A save in a late chapter that has skipped the earlier sources can still buy the commons, and gets one free rare of each passed tier on load (a one-time `materialsGrantedFor` flag, so it can't happen twice).

## Cost and checks

Core: items, zone and house fields, `FieldSchema`s, the build rule, the simulator's policy (it would finally spend: build when it can). Narrative: names, descriptions, French. UX: the build sheet's material chips and the material icons. QA: L2 (save data). The simulator would measure that buildings come up at the chapter they're meant for: the target is each tier's top building built by about half the runs in its chapter.
