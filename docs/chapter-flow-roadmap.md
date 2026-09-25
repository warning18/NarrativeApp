# Chapter flow roadmap — status after v1.148

The owner's intended structure (restated for v1.147):

- **Chapter 1** — introduction (tutorial 1): the player flees the
  invasion of the hometown. Every origin leaves with the first piece of
  the Shroud (the Void Banner).
- **Chapter 2** — introduction (tutorial 2): the player reaches a town and
  builds a ship to flee somewhere else and start from scratch. The Rusty
  Eel needs a hull (Fisherman's Row) and a sail (Tanner's Court).
- **Chapter 3** — introduction (tutorial 3), then the real game: the camp
  is the main base. Expeditions on foot or by boat discover the lands
  around it: a town, a village, other places. The party travels between
  the camp and these places, and meets raids on the way. Once enough is
  done, the chapter's main quest opens at the camp and leads to a piece
  of the banner.
- **Chapters 4, 5 and 6** — the same loop, each with its own lands, its
  own places and its own piece of the banner.
- **Ending** — from the camp, the last boss and the last piece.
- **Epilogue** — the whole banner turns time back: New Game+.

Chapters 1 and 2 are a straight road. From chapter 3 the game is not
linear: each chapter is split between exploring (expeditions, places,
bosses) and its main quest, which waits until enough has been explored.

## What shipped

| Version | Batch | Headline |
|---|---|---|
| 1.109.0+137 | Hub loops | Harbor market and Spire district are loop hubs; Main quests; guaranteed quest drops; `hideIfFlags`. |
| 1.110.0+138 | Difficulty | Chapter difficulty curve; zone tiers, recommended levels and bosses. |
| 1.111.0+139 | Boat | Camp founding; ports; the Rusty Eel; voyages with sea events and ship battles. |
| 1.112.0+140 | Late game | Chapters 4 and 5 hubs and zones, chapter 6 and its endings. |
| 1.140–1.146 | Camp | The camp as the story's base, camp works, travel back from towns, the skill economy and a difficulty retune. |
| 1.147.0+176 | Open chapters | Chapters 3–6 as loops around the camp, found places, villages, a chapter 6 loop, six banner pieces, the time-rewind epilogue. |
| 1.148.0+177 | Companion hint | The camp names places with a companion to meet; each chapter asks for 8 things done. |

## How the chapters flow now

Each open chapter is a row of `assets/gamedata/chapters.json`: the camp
scene the story stands at, the activity goal (8), the place the main
quest needs visited first, and the main quest's title and hint. The
camp's Chapter card shows "Explored: N of 8", the main quest, what it
still needs, and word of any companion still to meet in a known place
(`placeCompanionLeads`: an open scene that starts a companion's quest,
unless the party's alignment or story rules them out).

- **Activities**: each thing done in one of the chapter's places (a
  `hub_<place>_…` marker) and each of the chapter's expeditions cleared
  (not its main zone, which belongs to the main quest).
- **Places** are found by expeditions (zones.json `discoversPlaceIds`):
  the first at the expedition's midpoint, all of them on clearing it. A
  place without `mustDiscover` is known from the start of its chapter.
- **Travel**: a place on the camp's shore is a walk (the road may hold a
  detour or a raid); a place with a landing of its own is a voyage there
  and back. From one place the party can travel on to any other it knows,
  or back to the camp.
- **The main quest** is a choice on the camp scene (`mainQuest`). Its
  `travelPlaceId` is where the trip goes first; a `launchZoneId` runs the
  main zone.

| Chapter | Camp scene | Places (found by) | Expeditions (tier · rec. level · boss) | Main quest → banner piece |
|---|---|---|---|---|
| 1 | — | — | — | the heirloom (every origin) |
| 2 | — | Harbor market (2015) | Fisherman's Row, Tanner's Court, Lantern Docks | — (the boat) |
| 3 | 3001_camp | Ashen Quarter 3005 (Cinder Row), Emberwick 3100 (Scaffold Yards) | Cinder Row (2 · 6 · Iron Golem), Scaffold Yards (3 · 8 · Void Stalker) | Climb the Spire → the Warden's standard |
| 4 | 4999_camp | Wrack's End 5100, Drowned Cloister 5010 (Ossuary Galleries) | Ossuary Galleries (1 · 8 · Bone Warden) | The Drowned Stair (2 · 9 · Hollow Court Inquisitor) → the Court's twin |
| 5 | 6002_camp | Rimewell 6100, Reliquary Quarter 6010 (Dead Heart Approach) | Dead Heart Approach (2 · 10 · Tear-Spawn) | The fourth piece: the Shroud's Vigil (3 · 11 · Void Archon) → the reliquary thread |
| 6 | 7001 | Hollow Shore 7002, Greyhithe 7200, White Anchorage 7100 (Glass Strand) | Glass Strand (2 · 12 · Strand Colossus) | The White Fleet's Grave (3 · 13 · White Admiral) → the White Fleet's sail |
| End | 7400 | — | — | Into the tear: Beyond the Tear (3 · 14 · Void Sovereign) → the Sovereign's mantle |

The Reliquary Quarter's first visit goes through its gate (`arrivalNodeId`
6010_gate), where Lysa's fate plays out; its main quest needs the Quarter
visited, so that scene is never skipped. The epilogue (7005 and its three
variants) ends on the night before the invasion: the whole Banner turns
time back, which is where New Game+ starts.

Old saves standing on the two scenes the update removed (5001, 5002) pick
up at the fourth chapter's camp (`retiredNodeIds` in story_providers.dart).

## Difficulty model

Enemy stats are scaled four ways, multiplied together, before the Elite
and pack multipliers:

1. **Player level**: health ×(1 + 0.12·(L−1)), damage ×(1 + 0.08·(L−1)),
   rewards ×(1 + 0.10·(L−1)).
2. **Floor**: a regular enemy's health ×1.15, ×1.25, then ×1.35 from
   chapter 3, and damage ×1.10, ×1.15, then ×1.20. Bosses take ×1.10
   health and ×1.05 damage.
3. **Chapter curve**: health ×(1 + 0.15·(chapter−1)), damage half of that
   excess, rewards ×(1 + 0.10·(chapter−1)).
4. **Zone tier**: health ×(1 + 0.10·(tier−1)), damage half of that.

A fight's chapter is its scene's (`storyChapterOf`: a place's own
chapter, however late the party comes back to it), or the zone's for an
expedition.

The open chapters send the party to sea about twice as often as before,
so v1.147 adds two rules:

- **Known waters** (`knownWatersRaiderChance`): a crossing to a port the
  Eel has put in at before, or home, has a 15% chance of raiders a day
  (35% on new waters) and at most one raider.
- **Boarding crews** (`boardingChapterFor`) fight at most one chapter past
  the chapter their ship first sails in, as the ship's hull does not grow
  either.

## Simulation

`scratchpad` holds a Python re-implementation of the playthrough. v1.147
added `sim_v147.py`: the spine above, the camp loop (rest, expeditions of
the chapters reached, places found, trips to them and back), the main-quest
gate, known waters, boarding crews, and bosses kept out of random pools.
Two player styles, 200 seeded runs each:

- **Thorough**: visits every place of the chapter once (4 things done per
  trip) and goes for the companions on offer.
- **Rusher**: the minimum: the goal and the needed place only. With the
  camp's hint (v1.148) a rusher also takes a companion on offer in a
  place it visits.

| Measure | Thorough (v1.148) | Rusher (v1.148) | Rusher, goal 8 without the hint | Rusher (v1.147: goal 6, no hint) | v1.146 |
|---|---|---|---|---|---|
| True endings | 200/200 | 200/200 | 200/200 | 199/200 | 200/200 |
| Fights lost a run | 1.30 (median 1) | 1.10 (median 1) | 1.69 | 4.24 | 1.46 |
| Companions recruited | 4.0 | 4.1 (none alone) | 3.6 (1 alone) | 3.3 (5 alone) | 4.2 |
| Final level | 23.0 | 22.4 | 22.6 | 22.2 | 23.2 |
| Level at the main quest (ch 3/4/5/6) | 9.1 · 12.4 · 16.5 · 20.7 | 9.1 · 12.4 · 16.6 · 20.1 | — | 8.9 · 12.3 · 16.2 · 19.8 | — |
| Voyages / raiders a run | 20.5 / 10.9 | 18.4 / 10.0 | — | 17.9 / 9.9 | 10.8 / 11.2 |
| First try: Archon · White Admiral · Sovereign | 98% · 92% · 94.5% | 98% · 93.5% · 96% | — | 95% · 87% · 89% | 87.5% · — · 89.5% |

## Open points

- **The activity goal and thorough players.** A thorough player reaches
  10–12 things done before setting out; the goal of 8 mostly shapes the
  rusher's pace (two trips a chapter).
- **Midpoint discoveries are rare in the simulation**, since parties clear
  every expedition. They matter for a player who retreats halfway.
- **Ship battles are deterministic** (no variance, no enemy specials).
- The in-app simulator tours each place once (3 things) before the main
  quest; it does not model expeditions or voyages.
