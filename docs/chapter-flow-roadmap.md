# Chapter flow roadmap — status after v1.112

The owner's intended structure, as stated when the difficulty/flow review
was requested:

- **Chapter 1** — introduction: fleeing the hometown. Every origin leaves
  with the first piece of the Shroud (the Void Banner); the rest of the
  story is finding the other pieces.
- **Chapter 2** — a second, bigger introduction to the roguelike mechanics.
  It ends with building the transport out of the town: the Rusty Eel needs
  a hull (Fisherman's Row) and a sail (Tanner's Court) before she can cast
  off, and casting off is a choice about who comes along.
- **Chapter 3** — after a long voyage, a remote coast: the camp is founded
  in a cove a day's walk from the Spire of Judgment, and grows from a camp
  into a town as the player builds it. The first main zone.
- **Chapter 4** — the second, bigger zone.
- **Chapter 5** — the last big zone.
- **Chapter 6** — the final zone, open only to a whole Shroud (four pieces:
  the heirloom, the Warden's standard, the Court's twin, the reliquary
  thread), each of the last three taken at a cost.
- The camp stays in the same place; a boat (FTL-like) carries the party to
  the expeditions and later chapters.
- Power is worn, not held: humans sew it into banners, elves paint it, the
  dwarves cut it into stone, orcs ink it under scar tissue, the voidkin
  carry the tear's own mark. There is no clean way through: the spine's
  dilemmas (the unfurling, the wharf, the storm, the Warden, the altar, the
  reliquary, the Sovereign's price) all cost something.

This document records what the four batches (v1.109 to v1.112) shipped
against that structure, how the chapters flow now, how difficulty is
modelled, what the 40-run simulator says, and what is still open.

## What shipped

| Version | Batch | Headline |
|---|---|---|
| 1.109.0+137 | Hub loops | Harbor market and Spire district are loop hubs on every route; Main quests handed out at their beats; guaranteed quest drops; `hideIfFlags` on choices. |
| 1.110.0+138 | Difficulty | Chapter difficulty curve; zone tiers, recommended levels and bosses; zone and camp-workshop gating; shared zone card. |
| 1.111.0+139 | Boat | Camp founding beat; ports; the Rusty Eel (hull, bulwark, parts, shipwright, chart); voyages with sea events and ship battles. |
| 1.112.0+140 | Late game | Chapter 4 and 5 hubs and zones, chapter 6 with the final zone and four endings, nine enemies, three ports, `launchZoneId`. |

## How the chapters flow now

| Chapter | Story hub (node) | Port | Zones (tier · recommended level · boss) | Main zone launched from the story |
|---|---|---|---|---|
| 1 | Iron Anvil stalls (891, loops) | — | — | — |
| 2 | Harbor market (2015, 12 activities, mandatory on every route) | Smugglers' Wharf (on foot; Town Hub) | Fisherman's Row (1 · 3 · Dock Overseer), Tanner's Court (1 · 4 · Plague Hound), Lantern Docks (2 · 5 · Smuggler Captain, needs the hull patched) | — |
| 3 | Camp founded (3001_camp), Spire district (3005, 14 activities) | Ashen Landing (home port, the camp's shore) | Cinder Row (2 · 6 · Iron Golem), Scaffold Yards (3 · 8 · Void Stalker, main, needs Cinder Row) | — |
| 4 | Sunken Cloister (5010, 7 activities) | The Drowned Stair | Ossuary Galleries (1 · 8 · Bone Warden), The Drowned Stair (2 · 9 · Hollow Court Inquisitor, main) | Hub exit launches the Drowned Stair |
| 5 | Reliquary Quarter (6010, 8 activities) | The Black Reliquary | Dead Heart Approach (2 · 10 · Tear-Spawn), The Shroud's Vigil (3 · 11 · Void Archon, main) | Hub exit launches the Shroud's Vigil |
| 6 | Hollow Shore (7002) | The Hollow Shore (needs the Vigil cleared) | Beyond the Tear (3 · 12 · The Void Sovereign, main) | "Sail into the tear" launches Beyond the Tear |

Endings (node 7004): carry the Banner home (bearers), keep seeking it
(seekers), sew the tear shut (bearers with alignment ≥ 15), take the
Sovereign's crown (alignment ≤ −15).

The boat unlocks with the camp at chapter 3 and is moored at Ashen Landing.
Ports appear on the chart once the story reaches their chapter (and their
`requiredFlags` are set). A voyage is `voyageLength` days of sea events;
raiders open a ship battle fought with the parts aboard.

## Difficulty model

Enemy stats are scaled three ways, multiplied together, before the Elite
and pack multipliers:

1. **Player level** (unchanged): health ×(1 + 0.12·(L−1)), damage
   ×(1 + 0.08·(L−1)), rewards ×(1 + 0.10·(L−1)).
2. **Chapter curve** (`chapterDifficultyMultiplier`): health
   ×(1 + 0.12·(chapter−1)), damage half of that excess
   (`damageShareOf`), rewards ×(1 + 0.10·(chapter−1)). A first pass with
   +15%/chapter on both stats turned tuned chapter-2 fights into coin
   flips and was dropped.
3. **Zone tier** (`zoneTierMultiplier`): health ×(1 + 0.10·(tier−1)),
   damage half of that.

A fight's chapter is its story node's, or the zone's for an expedition
(`EncounterModifiers.chapter`). Story and zone bosses (`soloOnlyEnemyIds`)
are never drawn as random events.

## Simulation

`scratchpad` holds a Python re-implementation of the playthrough
(playthrough_sim.py through sim_v7.py) that follows the story graph with
four choice strategies, models hubs (85% chance to take an untried
activity), zones (attempted once the party reaches the recommended level),
voyages, ship battles, the chapter curve and the spoils chest. 40 seeded
runs per batch, alternating builds.

Final state (v1.112), 40 runs:

| Measure | Value |
|---|---|
| True endings | 40/40 (bearer 6, seeker 20, dawn 10, crown 4) |
| Party level by chapter | 2.3 · 5.4 · 8.9 · 12.8 · 16.3 · 18.6 |
| Hub activities per run | 2015: 7.9, 3005: 12.0, 5010: 6.5, 6010: 7.0 |
| Quests completed per run | 22.5 (5.2 before v1.109) |
| Voyages per run | 3.0, all landfalls; 142 raider battles won |
| First-attempt boss win rate | Bone Warden 90%, Inquisitor 88%, Tear-Spawn 92%, Void Archon 72%, Void Sovereign 72% |
| Chapter-2 story fights | 100% (Kroll at 55%, chapter 1) |

The simulator retries a lost fight without resting, so its per-attempt
rates overstate the difficulty of the two hardest bosses (15% and 28% per
attempt); the first-attempt rates above are the honest read.

## Open points

- **Chapter 2–3 story fights sit at 100%** because the hub content
  levels the party past them (mean level 8.9 entering chapter 3). Trimming
  hub XP or raising the chapter-3 story enemies would restore tension; the
  boss balance test's bands constrain the High Warden.
- **Ship battles are deterministic**: no variance, no enemy specials. A
  second tier of enemy ships with cooldown moves would make voyages more
  than a resource check once the harpoon rack and plating are aboard.
- **Zone and port names are English only** (`zoneName`, `flavorText`);
  boss narration and port descriptions have French.
- The in-app playthrough simulator and the autoplay engine ignore
  `launchZoneId` (they skip the expedition).
- Camp workshops still gate on chapter-3 zone flags; moving the
  Hammersmith's requirement to a chapter-4 zone would delay tier 8–10
  gear further.
- Chapter 2's Lantern Docks is often cleared from chapter 3 by boat rather
  than on foot, which is fine but means the "hull patched" flag from
  Fisherman's Row is the only chapter-2 gate that matters.
