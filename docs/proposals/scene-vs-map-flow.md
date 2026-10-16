# Scene or map: when the game hands you the map

A review for the user, by Core. Docs only: no code changed.

**Your rule** (with the three answers you sent through the manager):

> The map is for moving. While the next scene is in the same place, the game shows the story or scene view. Only a choice that leads to another place hands you the map. "The same place" means the same district, or the same location when it has no districts. A walk to another district, even inside one town, is a move on the map. At a hub, you pick among that place's scenes; leaving the hub is a map move. Arriving at a place opens a sheet over the map (UX's S2). Main-story scenes use the full scene view (S1).

**The short answer.** Today the game works the other way round. In play there is no story page with choices. Every scene is first read full screen with a single **Continue** button, and then **every** choice is taken on a map: the city chart, the room plan of a building, or the place view with pins and cards. That holds even when the next scene is in the same room. Of the story's 1,061 choices, **729 (69%) stay in the same place** and still go through the map. Going the other way, **33 moves to another district happen with no map at all**: the story reads straight through them.

---

## 1. What the game shows today

In play the story is followed only on the **Journey** tab. The old Story reader is used only in Edit Mode and for the ending. The Journey shows a scene in one of these ways:

| What you see | When | Where the choices are |
|---|---|---|
| **Story page** (full screen, text only, a *Continue* button) | Right after any choice that moves the story to a new scene | Nowhere. *Continue* brings the map back. |
| **City chart** (board 15: streets, districts, numbered pins and rows) | A scene in a city, town or village that has a stored plan, and is not inside a building | **Every** choice is a pin on a building and a row under the map, grouped by district: fights, rolls and talks too. No cards, no rings. |
| **Room plan** (the inside of a building) | A scene inside a building. Only the Blind Beggar is one today. | Every choice is a spot in the room (the tables, the bar, the door). |
| **Place view** (a place up close, pins for the ways, cards for the rest) | A place with no stored plan: a site such as the wreck or the Sleeper's Face, the camp, the Hollow Shore | A fight, a roll, a payment or a decision is a **card** under the map. A plain way somewhere is a **pin**. With more than 4 cards, the scene is a hub and shows ring chips instead. |
| **Road view** | No known place (a detour) | Each choice is a step on the road. |
| Screens of their own | Character creation, a fight, an expedition (`launchZoneId`), a land crossing (`landRouteId`), a voyage | That screen. |

Two more behaviours matter for your rule:

- **Read-through.** When a scene has only one plain "go on" choice (no fight, gold, roll and so on), the game plays it straight through: its text opens the next scene, with no stop. A way to another *location* stops the read-through. A way to another *district of the same city* does not, so the walk happens on the story page with no map.
- **Being carried.** A fight lost or a roll failed that puts you somewhere else plays a short trip on the map (the party is carried, with a line saying why). A trip to a far place plays a flight along the road. Inside one city there is no trip: the chart only re-centres.

How much of the story each view covers (each scene counted by where it happens): **city chart 362 scenes (82%)**, place view 71, room plan 7. The 20 camp scenes show the Camp screen instead (it takes the Story tab's place while the party is at the camp).

---

## 2. Chapter 1, step by step

"Place" below is the district, or the building when the scene is inside one. See §5 for why a building counts.

| # | What happens | Scenes | Place | Today | Your rule wants |
|---|---|---|---|---|---|
| 1 | The prologue: who were you? | `0` | Lower Town (data). In the story it happens nowhere. | **City chart of Alster**, Lower Town, with one row, "Choose who you are...", already picked. The prologue text is behind a *Read* button. Go opens character creation. | **Story page only**: the text and the one button. No map, no town. ✗ |
| 2 | You wake in the Blind Beggar | `100` | Blind Beggar (building) | Story page of 100, then *Continue*, then the **room plan** with 3 spots (tables, bar, door) | Scene view with the 3 choices (all three stay in the room). The room plan can be the scene's picture, but it isn't a map to move on. ~ |
| 3 | The fight that follows your pick | `105`, then `106` | Blind Beggar | Page, *Continue*, room plan (one fight spot). Then the fight screen. | Scene, then the fight. ~ |
| 3b | The casino's nodes: robbing the tables (`110`, a hub that loops on itself), digging people out (`120`, the same), or a lost fight (`115`, `125`) | `110`, `120`, `115`, `125` | Blind Beggar | Each pick: page, *Continue*, room plan again. A loop back to `110` shows its page again each time. | Stay in the scene. The hub's remaining choices come back as cards, with no page in between. ✗ |
| 4 | Out into the street | `106`/`110`/`115`/`120`/`125` → `250` | Leaving the building for the Lower Town | A spot at the door of the room plan. | **Map**: you leave the casino. ✓ (the door spot does lead out) |
| 4b | The town walk home: Stone Bridge route | `250` → `260` → `261` → `300` | Lower Town, Stone Bridge, Lower Town | `250`: city chart with two rows. `260`: city chart, "Pay the toll" pinned in the Stone Bridge district and "Refuse and fight" pinned in the Lower Town. `261` "Cross the bridge" (it costs 30 gold): city chart pin, then `300`. | `250`→`260`: **map** ✓. `260`: scene with the toll and the fight ✗. `261`→`300`: **map** (the walk back over the bridge) ✓ on the map, but today it is a pin on the city chart, not a walk with the destination pinned. |
| 4c | The town walk home: Weaver's Alley route | `250` → `270` → `300` | **All Lower Town** | City chart each time | **Scene view the whole way.** With districts as the measure, the alley and your street are in the same district. If you want the map here (your step 4 says "using the map to his house"), see question Q1 in §9. |
| 5 | Home: the cannonball, Aurel Vane, the trapdoor | `300`, `400`, `450`, `400_lost`, `470` | Lower Town | City chart, every choice a pin (watch, slip round, run, charge...) | **Scene view**: all of these stay. ✗ |
| 5b | Taken to the Black Hold | `400` "Run" or "Kneel" → `800`; `400_lost` → `800` | Lower Town → Black Hold | A pin placed *in the Black Hold district*, though the choice is a decision made at the house | Act in the scene, then the party is **carried** to the Black Hold (a short trip on the map, no walking yourself to prison), then the arrival sheet. ✗ |
| 5c | The Black Hold escape | `800`, `816`, `820`, `822`, `822_lie_failed`, `823` | Black Hold | City chart pins | Scene view (all stay). ✗ |
| 5d | Out by the battlements or the sewers | `823` → `470` / `840`; `840`, `850`, `855`, `850_fed_failed` → `470` | Black Hold → Undercroft → Lower Town | City chart pins | `823`'s two exits: **map** ✓. The sewer scenes: scene view ✗. The kills and rolls that end in the Lower Town: act in the scene, then carried. |
| 6 | To the High Quay | `470` → `890_trainer` | Lower Town → High Quay | City chart pin (both choices) | **Map** ✓ (but the pin should be a walk with the quay pinned) |
| 6b | The trainer, the quay (a hub that loops on itself), the mate, the gangway | `890_trainer`, `891`, `895`, `896_failed`, `897_failed`, `898_failed`, `960` | High Quay | City chart pins | Scene view (all stay). `891` is a hub: a scene with its rings. ✗ |
| 7 | The Lark sails, and burns | `960` → `965` | High Quay → the wreck of the Lark | City chart pins. The ways out of the city are pinned **in the party's own district**, not at the destination. Then a flight trip. | Decide on deck in the scene, then carried by the ship (trip), then the arrival sheet. ~ |
| 8 | The wreck and the tear | `965`, `1100`, `1101`, `1101_scarred` | The Wreck (a site, no districts) | Place view with cards | Scene view ✗ (cards under a map) |
| 9 | Across the dunes | `1100`/`1101` → `1120`, `1140` → `1200` (with `landRouteId`) | Wreck → Sleeper's Face → White Wells | The land-crossing screen | The crossing **is** the move ✓ |
| 10 | The Sleeper's Face | `1120`, `1125`, `1130`, `1140`, `1140_spotted` | Sleeper's Face (site) | Place view with cards | Scene view ✗ |
| 11 | The White Wells: rest, Vess, the three endings | `1200` (a hub that loops on itself), `1210`, `1000`, `1001`, `1002` | White Wells (village). The data says the whole village, not a district. | **City chart** of the village, every choice a pin | Scene view, with the hub's rings. ✗ |
| 12 | "Proceed to Chapter 2" | `1000`/`1001`/`1002` → `2001` | White Wells → Saltmouth | A row on the White Wells chart, pinned where you stand | **Map** with Saltmouth pinned (the land or world map), then the arrival. ✓ in kind, ✗ in where the pin is |

✓ agrees · ~ close · ✗ disagrees

## 3. Chapter 2, step by step

| # | What happens | Scenes | Place | Today | Your rule wants |
|---|---|---|---|---|---|
| 1 | The caravan at the landward gate, the rats | `2001`, `2000`, `2005` | Landward Gate | City chart pins | Scene view (all stay). ✗ |
| 2 | In with the caravan, or hidden in a salt wagon | `2005` → `2010` (Wharf) / `2020` (the Gate) | — | City chart pins | "Go in with the caravan": **map** ✓. "Hide": stay in the scene ✗. |
| 2b | The wagon, the drain, the inspector | `2020` → `2050` (Wharf) / `2021`; `2021` → `2015` (Wharf) | Gate → Wharf | City chart pins | The drain and the slip into the crowd: **map** ✓. The ambush fight: scene ✗. |
| 3 | The Wharf: the Crow tally-boy, then the market | `2010`, `2050` → `2015_crow_offer` → `2015` | Wharf | City chart pins | Scene view ✗ |
| 4 | **The Smugglers' Wharf hub** | `2015`: 32 choices | Wharf | 32 pins spread over **6 districts** of the city chart. No rings (the city chart has no card panel). | The hub is a scene with **11 choices done here** (Vane, the crane, the rats, the bounty, the smuggler, the route...) as rings or cards, and **21 ways to other districts** (the bazaar, Card Row, Tern Row, the yard, the gate) that hand you the city map with those places pinned. ✗ |
| 4b | An errand in another district, then back | e.g. `2015_sable` (Card Row), `2015_kelda` (Gate), `2015_liora` (Yard), `2015_ternrow` (Tern Row) | Other district, then the Wharf | City chart again. 18 of the hub's 21 ways come straight back to `2015`. | Arrival sheet at the errand's district, the errand in the scene, then the way back is a **map** move to the Wharf. ~ |
| 4c | Errands that read straight back | `2015_bazaar`, `2015_apothecary`, `2015_hound`, `2015_house_keyholders_turned`, `2015_sable_lifted`, `2015_sable_bought`, `2015_sable_talk_failed`, `2015_liora_refused`, `2015_scaffold_clerk` → `2015` | Other district → Wharf | **No map**: their one plain way back is read through, and you land on the Wharf's page | A walk back to the Wharf: **map** (or a one-tap return, see §6). ✗ |
| 5 | Vane: bribe, threaten, push past; the crane; Liora's skiff | `2030`, `2040`, `2040_paid`, `2070`, `2070_cut_failed`, `2011`, `2011_roof_fall`, `2010_crane`, `2010_liora` → `2900` | Wharf → the Ship-breaker's Yard | City chart pins (the way to the yard is pinned in the yard). `2040_paid` → `2900` is read through with no map. | Talks and fights in the scene, then the walk to the yard: **map**. `2040_paid`: **map** ✗. |
| 6 | The yard: buy or earn the Eel, patch, mend (a hub that loops on itself; two expeditions) | `2900`, `2900_boat_fixed` | Yard | City chart pins | Scene view with rings; the expeditions open their own screen ✗ |
| 7 | Cast off: who you take | `2900_boat_fixed` → `2999` | Yard → the Crossing (sea) | City chart pins (pinned where you stand) | A decision in the scene, then **carried** by the Eel (a trip at sea), then the storm scene ~ |
| 8 | The storm, the end of chapter 2 | `2999` → `3001` | The Crossing → the Cove Camp | Place view with cards; then the camp | A decision in the storm, carried to the camp ✓ |

---

## 4. Every disagreement

| # | Disagreement | How many | Examples (node ids) |
|---|---|---|---|
| D1 | **A choice that stays in the same place still goes to a map.** Story page, *Continue*, then a map to pick the next choice. | **729 choices** (69%): 598 on a city chart, 117 in a place view, 14 in the room plan | `100`, `105`, `300`→`400`, `800`→`816`, `891`, `2001`→`2005`, `2015`→`2030` |
| D2 | **Choices done here shown as map pins.** On the city chart, fights, rolls, talks and payments are pins on buildings, like ways. | Every choice of the 362 city-chart scenes | `260` "Pay the toll", `820` "Bull through them", `2015` "Deal with the smuggler" |
| D3 | **A hub's own choices shown as pins over the whole town** instead of a scene with rings. The rings exist only in the place view. | 16 hubs on a city chart, 2 in the room plan | `2015`, `3005`, `5010`, `6010`, `7100`, `7500`, the 8 village hubs, `891`, `1200`, `2900`, `110`, `120` |
| D4 | **A move to another district with no map**: read straight through on the story page | **33 choices** | `2015_bazaar`→`2015`, `2040_paid`→`2900`, `3005_acolyte`→`3005`, `3005_archive`→`3005` (all 33 lead to a hub) |
| D5 | **A move after an action** (a fight, a roll, a payment, a decision whose result is elsewhere). Today: a pin in the destination's district, or a card. No trip unless the fight is lost. | 134 choices | `400`→`800`, `260` "Refuse and fight"→`300`, `840`→`470`, `2011`→`2900` |
| D6 | **A way out of a city is pinned where you stand, not at the destination.** The pin of a way that leaves the city sits in the party's own district on the city chart. | 61 choices between locations (most of them start in a city) | `470`, `960`→`965`, `1000`→`2001`, `2900_boat_fixed`→`2999` |
| D7 | **The prologue is a map.** | 1 | `0` |
| D8 | **A hub loop shows the same page again**: a choice that returns to its own hub re-reads the hub's text full screen. | 5 hubs that loop on themselves in ch. 1-2 | `110`, `120`, `891`, `1200`, `2900` |
| D9 | **A failed roll that moves you.** It leaves for another district, with the "carried" trip. | 13 | `2015` fail → `2015_informant_caught`, `3005` fail → `3005_archive_failed` |

What already agrees: leaving the Blind Beggar by its door (`106`, `110`, `120` → `250`), the land crossings (`landRouteId`), the voyages and their screens, the flight between far places, and the carried trip after a lost fight.

## 5. The other chapters (sweep)

Counted with a script over the story file and the geography, using the rule in §6.

| Chapter | Scenes | Choices | Stay | Move | Hubs | Notes |
|---|---|---|---|---|---|---|
| Prologue + 1 | 48 | 112 | 67 | 45 | 4 | Alster and the dunes, above |
| 2 | 62 | 144 | 51 | 93 | 2 | Saltmouth: 87 choices cross districts, most of them around the hub |
| 3 | 70 | 151 | 78 | 73 | 5 | **Ashen Quarter hub `3005`**: 2 choices stay, 24 go to other districts, and 21 of those come straight back. Emberwick `3100` and Akagiri `3200`: every choice stays. |
| 4 | 71 | 156 | 113 | 43 | 3 | **Drowned Cloister hub `5010`**: 6 stay, 15 move, 14 come back. Wrack's End `5100`, Kindly Hill `5200`: all stay. |
| 5 | 88 | 201 | 193 | 8 | 4 | Black Reliquary `6010`: 29 choices, **all** in its own district; Rimewell `6100` and Highhearth `6200` all stay |
| 6 | 69 | 169 | 118 | 47 | 4 | **White Anchorage hub `7100`**: 7 stay, 12 move, 11 come back. Greyhithe `7200`: 17 stay. Hollow Shore `7002` (a site with 2 districts). |
| 7 | 27 | 108 | 90 | 18 | 2 | Candlehold `7500`: 14 choices, all stay |
| 8 | 5 | 20 | 19 | 1 | 1 | The camp's last muster |
| **All** | **440** | **1,061** | **729** | **328** | **25** | Of the 328 moves, 267 stay inside one location (district to district) and 61 go to another location |

The same patterns repeat: the **town hubs** (`2015`, `3005`, `5010`, `7100`) send you round the districts and back; the **village and city hubs that keep everything in one district** (`6010`, `7500`, the 8 village hubs) are pure scenes that today are drawn as pins on a chart; and the **chains of scenes in one district** (the Black Hold, the Spire, the Hollow Court) are scenes drawn on a map.

---

## 6. The rule, in code terms

### "The same place"

Following your answer, a scene's **stop** is:

1. **its building**, when it happens inside one;
2. else **its district**;
3. else **its location** (a site, a sea, or a location that has no districts).

Two scenes are in the same place when their stops are equal.

- **Why a building counts.** Your chapter 1 has leaving the Blind Beggar as a walk on the map. The Blind Beggar is a building inside the Lower Town. Without rule 1, `106`/`110`/`120` → `250` would be "the same district" and you would never see the map until the Stone Bridge. Only the Blind Beggar is a building in the geography today, so rule 1 changes 13 choices.
- **Villages.** All 117 village scenes and the 20 camp scenes are tagged with the **whole village**, not a district. Rule 3 makes each village one place, so every village hub's choices stay. See §7 for the hubs.

### The three cases

| The choice... | Today | Proposed |
|---|---|---|
| leads to the **same stop** | page → *Continue* → map | **Scene view stays.** The next scene's text and its choices show in place, as cards, with rings for a hub. No map. |
| leads to **another stop**, and is a plain way (`ChoiceAction.go` in `choice_shape.dart`) | a pin | The choice is a **"→ destination" card** in the scene. Taking it **hands you the map** with the destination pinned (the city chart for a district, the land or world map for another location). Go walks there; arriving opens the **arrival sheet** (§8). |
| leads to **another stop** after something done here (a fight, a roll, a payment, a decision: `here == true`) | a pin or a card, no trip | **Done in the scene** (the fight or the roll plays first), then the party is **carried**: a short trip on the map with no input (the trip the game already plays after a lost fight), then the arrival sheet. You don't walk yourself to the Black Hold. |

The read-through stays, but it should stop at a change of stop: a plain way to another district is no longer read through (fixes D4).

### Where the code changes

- **Core: one new query**, next to `choiceShape` in `lib/data/choice_shape.dart`:
  - `GeoPlace? stopOfNode(StoryNode)`: the building, else the district, else the location.
  - `ChoiceFlow choiceFlow(StoryNode from, StoryChoice c)`, returning one of `scene` (same stop), `map` (a plain way to another stop: with `to`, the stop to pin), or `carried` (done here, aftermath elsewhere: with `to`).
  - `choiceShape`'s `stay`/`walk`/`travel` today compares the *place* (district or building) and calls a district change a walk. `choiceFlow` reuses it, with the stop as the measure.
- **Core: the read-through.** `passThroughChoiceOf`'s `travels` callback is `Geography.travelsBetween` today (location change only). It becomes "the stop changes", so a plain walk to another district stops on its scene (`scene_flow.dart`, and its two callers in `story_player_screen.dart` and `journey_screen.dart`).
- **The Journey (shared file, behaviour: Core's, look: UX's):** the switch is `_take` in `journey_screen.dart`. Today, any choice that moves the story sets `_reading = true` (the full page), and *Continue* returns to the map. With `choiceFlow`:
  - `scene` → keep (or open) the scene view on the new scene;
  - `map` → the map at the right level, the destination pinned and selected;
  - `carried` → the existing `_Transit` trip, then the arrival sheet.
  - The map then shows **only the ways** (the `map` choices of the scene the party stands at), not every choice. The city chart's rows today list every choice.
- **The way out of a city** is pinned at its destination on the land or world map, not "where the party stands" (fixes D6).
- **The prologue.** A scene with no place (`location: ""`), or a choice with `opensCharacterCreation`, is a story page with no map. Node `0` says `alster_lower_town` and should say `""` (Narrative's file), or the query treats chapter 0 as placeless (fixes D7).

## 7. Hubs under the rule

**Town hubs (errands in other districts).** `2015` Smugglers' Wharf, `3005` Ashen Quarter, `5010` Drowned Cloister, `7100` White Anchorage. Each reads like this:

1. **Arrive at the hub:** the arrival sheet, then the hub's scene. The choices done there are rings or cards.
2. **"Walk the town"**: the hub's ways to other districts. The city map opens with the errands pinned by category.
3. **Pick an errand:** you walk there, the errand's scene opens (sheet), and you play it.
4. **The way back** to the hub is a map move (the hub pinned, one tap).

There are 72 such ways out (21, 24, 15 and 12); 64 of them (18, 21, 14 and 11) come straight back to the hub. That is two map moves per errand. If that is too many taps, the lighter option is a **one-tap return**: a way back to the hub you came from is treated as `carried` (a trip, no map to pick on). Your answer says the walk is a move, so this doc keeps the map and leaves the lighter option to you (Q2).

**Village hubs (everything stays).** `1200` White Wells, `3100` Emberwick, `3200` Akagiri, `5100` Wrack's End, `5200` Kindly Hill, `6100` Rimewell, `6200` Highhearth, `7200` Greyhithe. All their scenes say the whole village today, so none of their 264 choices inside the village crosses a district. **But** the stored village plans (`city_plans.json`, Core's) put those scenes on lots in different districts. If Narrative tagged each scene with the district its lot is in, **155 of the 264 would become walks**:

| Hub | Village | Scenes | Choices that would cross districts | Hub's own district (from its lot) |
|---|---|---|---|---|
| `1200` | White Wells | 5 | 2 of 6 | the Pool |
| `3100` | Emberwick | 12 | 15 of 28 | the Kilns |
| `3200` | Akagiri | 10 | 12 of 20 | the Springs |
| `5100` | Wrack's End | 22 | 25 of 54 | the Hull-Houses |
| `5200` | Kindly Hill | 13 | 13 of 26 | the Hall Under the Hill |
| `6100` | Rimewell | 21 | 35 of 48 | the Bell Square |
| `6200` | Highhearth | 13 | 11 of 26 | the Moot-Hall |
| `7200` | Greyhithe | 21 | 42 of 56 | the Shingle |
| — | Cove Camp (camp) | 20 | 3 of 38 | — |

**Proposal: a village hub's scenes stay in one district.** When Narrative tags the village scenes, the hub and the scenes that loop back to it take the hub's district (the right-hand column), so the village stays a scene. A scene that really is elsewhere in the village gets its own district on purpose, and becomes a walk. Core then moves those scenes' lots in `city_plans.json` into the hub's district, so the plan and the story agree. The camp's 20 scenes stay "the whole camp".

**Hubs that loop on themselves** (`110`, `120`, `891`, `1200`, `2900`): a loop back to the hub is `scene`. The hub's scene stays, the used choice drops out (it is hidden by its flag), and there is no page in between (fixes D8).

## 8. The arrival sheet (S2) and the full scene (S1)

As you decided: **arriving at a place opens a sheet over the map (S2); main-story scenes use the full scene view (S1).**

**Which scenes count as "main story"?** The data doesn't mark them:

| Marker | What it covers | Count |
|---|---|---|
| `mainQuest: true` on a choice | Only the camp's "set out on the main quest" | 6 choices (`3001_camp`, `4999_camp`, `6002_camp`, `7001`, `7400`, `7800`) |
| The chapter spine (`lib/data/chapter_spine.dart`) | The beats every playthrough passes, not the scenes between them | 64 scene ids |
| Camp nodes (`chapters.json` `campNodeId`, camp settlements) | The camp | 20 scenes |
| `settlement` / `hub_progress` | Towns and hubs | 20 / 12 |

**Proposed rule (derived, no new field):** a scene is **main story** when it is not a hub, not a hub's errand (a scene from which the story loops back to that hub), and not a camp scene. On today's story that gives **118 main-story scenes**, and it agrees with the spine: all 54 spine beats that aren't hubs or camps are among the 118, and none is an errand. By chapter: prologue 1, ch. 1 42, ch. 2 19, ch. 3 10, ch. 4 7, ch. 5 7, ch. 6 12, ch. 7 19, ch. 8 1. The other 322 are the 25 hubs (camp hubs among them), the 292 errands and the remaining camp scenes.

- **S1 (full scene)** for the 118, so the main story always plays as a full scene.
- **S2 (sheet over the map)** for hubs, errands and the camp, so the town stays in view.
- Core would provide `isMainStoryScene(nodeId)` (computed once from the story). If Narrative prefers to mark it by hand, a node field `main: true` would replace the computed rule.

The arrival follows the same rule as the choices. The sheet or scene opens **only after a `map` or `carried` move**. A `scene` step replaces the scene's content in place: no sheet, no map behind it.

## 9. Pins by category: does "service" need a Core query?

Yes. Today a shop pin exists only for a choice that opens a shop (`unlockShopId`, 5 choices in 4 hubs), and a rest pin only for a choice that heals (31 choices in 21 scenes). Nothing says that a place *has* a trainer, an inn or a harbour master. Proposed:

`List<PlaceService> servicesAt(String placeId)`, where each item has a kind (`shop`, `rest`, `trainer`, `port`), the id (shop id, port id), its name, and the choice that reaches it (scene id and choice index) when one does.

Where the data lives today:

| Service | Data | Place |
|---|---|---|
| Shops | `shops.json` (14 shops) has **no place field**. A shop opens from a DAG choice (`unlockShopId`) or is listed on a port (`ports.json` `shopIds`) | The scene of the choice (its district), or the port's settlement (`settlement.portId` / `landingPortId`) |
| Rest (inns, healers) | Choices with `healAmount > 0` | The choice's scene |
| Trainer | Only scene `890_trainer` (chapter 1). Training offers (`training_paths.json`) have no place. | The scene |
| Port, harbour master | `ports.json` (6 ports), linked through the settlement | The settlement's scene |
| Clan courts | Not checked here | — |

So `servicesAt` can be derived with no new data, except for shops listed only on a port (the district is unknown), and the "service" scenes UX names (an inn, a healer) that are written as plain ways. For those, a `service` field on the choice (Core may add the field; Narrative fills it) would do.

## 10. Missing data

| What | Count | Examples |
|---|---|---|
| Scenes whose `location` is a whole village that has districts | 117 | `1200`, `3100_*`, `5100_*` (fine under rule 3; see §7) |
| Camp scenes tagged with the whole camp | 20 | `3001`, `7400_*` |
| Site scenes tagged with the whole site that has districts | 15 | `7002`, `7005_*` (the Hollow Shore) |
| Choices with no next scene (`EXIT`) | 4 | `7005`, `7005_seeker`, `7005_dawn`, `7005_crown` (the endings) |
| Scenes with no place at all | 0. **But** the prologue `0` should be placeless and says `alster_lower_town` | `0` |
| Scenes in a building whose lots are spread over different buildings | 6 Blind Beggar scenes on 6 different lots of the Lower Town (`100` on the Blind Beggar, `105` "the back room", `106` "the sawdust floor", `110` "the counting-room cage", `115`, `125`) | `city_plans.json` anchors (Core's). Should all be the Blind Beggar's lot. |
| Moves inside one district that the old landmarks call a change of place | 8 | `250`→`270`, `270`→`300` (Weaver's Alley), `7002_approach`→`7002_confront` |

## 11. What UX needs, and what Core provides

UX's #358 (pins by category, a key, the S1 scene and the S2 sheet) fits the rule as it stands. What changes for UX:

- The **scene view** is no longer only "on arrival". It is where you stay while the next scene is in the same place: one scene follows another inside it, without going back to the map.
- The **map** shows only the scene's ways (`choiceFlow == map`), pinned by category at their destinations. The choices done here leave it entirely (they are the scene's cards and rings).
- A `carried` move plays the trip, then the sheet or scene.

What Core provides:

1. `stopOfNode`, `choiceFlow` (`scene` / `map` / `carried`, with the stop to pin), and the read-through stopping at a change of stop.
2. `isMainStoryScene` (S1 or S2).
3. `servicesAt(placeId)` for the service pins.
4. The village plans' lots moved into the hubs' districts (after Narrative tags them), and the Blind Beggar scenes' lots joined into the one building.

From Narrative: `location: ""` for `0`, and the district tags for the village scenes (§7). From you: Q1 to Q3 below.

### Questions for you

- **Q1.** Weaver's Alley (`270`) is in the same district as your house (`300`), so that route home plays with no map. Is that right, or should the alley be its own district or building?
- **Q2.** In a town hub, should the way back from an errand to the hub be a map move (one tap on the pinned hub), or a one-tap return with only the trip?
- **Q3.** Is a building its own place (§6, rule 1), so that leaving the Blind Beggar is a map move?

## 12. Code references

Today's decisions (on main at #358):

- `lib/screens/home_shell.dart:210` — in play the visible tabs are Journey, Character, Camp and Other: no story reader (camp takes over at `:173`).
- `lib/screens/journey_screen.dart:725` — `_take`: a choice that moves the story sets `_reading = true`.
- `lib/screens/journey_screen.dart:1124` — `_reading`: the full-screen scene with only *Continue*.
- `lib/screens/journey_screen.dart:1274`–`1275` — a way to another landmark points out of the place; `travels` only for another location.
- `lib/screens/journey_screen.dart:1395`–`1407` — the stored city plan. Every way is pinned in its district; a way out of the city is pinned in the party's own district.
- `lib/screens/journey_screen.dart:1451` — inside a building: the room plan, every way a spot.
- `lib/screens/journey_screen.dart:1512` — `cardsOn`: cards only in a place view (not a room, not a detour).
- `lib/screens/journey_screen.dart:1538` — a scene with one way has it picked already (the prologue's row).
- `lib/screens/journey_screen.dart:1595`, `:1721`, `:1848` — `hostedCity`: the city chart replaces the place view.
- `lib/screens/journey_screen.dart:2178` — no card panel under the city chart, so no cards or rings there.
- `lib/screens/journey_screen.dart:841`, `:1925` — `_isHub` (more than 4 cards) and the rings, drawn only in the place view.
- `lib/screens/journey_screen.dart:1615`–`1618` — the trip: a far place, or a lost or failed fight.
- `lib/screens/story_player_screen.dart:1331` — character creation; `:1676` the road step (location change only); `:1848` `_readThrough`.
- `lib/data/scene_flow.dart:24`, `:61` — `isPlainGoOn`, `passThroughChoiceOf` (its `travels` callback).
- `lib/data/choice_shape.dart:72` — `choiceShape` (stay / walk / travel / unknown, and `here`); `:133` a plain move is `go`.
- `lib/data/geography.dart:608` `placeOfNode`, `:641` `travelsBetween` (location granularity).
- `lib/data/journey_rules.dart:77` — `isRoadStep` (the landmark fallback).
- `lib/providers/city_provider.dart:48` `partyDistrictProvider`, `:99` `walkToDistrict` (free walking between districts).
- `lib/data/chapter_spine.dart` — the beats used in §8.

The counts come from a script over `assets/Cleaned_Narrative_DAG.json`, `assets/gamedata/geography.json`, `assets/gamedata/city_plans.json` and the landmarks of `lib/data/world_map.dart`. It reimplements `choiceShape`, the read-through test and the view choice above, and is close to, not identical with, the app. For example, a scene with no landmark of its own takes the last one in the history, and the script doesn't follow that. It isn't committed.

## 13. What Core built (after the answers)

The user's answers: **Q3** a building is its own stop; **Q1** the walk home from Weaver's Alley is a map move (the house is a building); **Q2** an errand's way back to its town hub is a one-tap return, no map.

- **`lib/data/choice_flow.dart`** — `StoryStops.of(story:, geography:, cityPlans:, ports:)`, built once per story (`storyStopsProvider` in `lib/providers/choice_flow_provider.dart`):
  - `String stopOf(nodeId)`: the building, else the district, else the location; `''` for nowhere.
  - `ChoiceFlow flowOf(from, choice, {nextId})`: `FlowStay()`, `FlowMap(stop)`, `FlowTripThenArrive(stop)`, `FlowReturnToHub(hubStop, hubNodeId)` (a sealed class).
  - `bool changesStop(fromId, toId)`: the read-through's stop test.
  - `bool isHub`, `hubsOfErrand`, `isCampScene`, `isMainStoryScene(nodeId)`.
  - `List<PlaceService> servicesAt(placeId)`: `(kind: shop|rest|trainer|port, id, nodeId, choiceIndex)`.
- **The rules as coded.**
  - The prologue (a scene whose every way opens character creation, node `0`) is nowhere: no edit to its `location`.
  - An ending (`EXIT`), or a next scene that doesn't exist, is `FlowStay`.
  - A **hub** is a `settlement`, a `hub_progress`, or a scene with a way back to itself (25 hubs). An **errand** of a hub is a scene reached from it without passing another hub, from which the story leads back to it (292 scenes). A **return** is a way from an errand to its hub at another stop of the same town (not a camp).
  - A **village hub**: a scene tagged with a whole location that has districts and a hub (not a camp) takes the hub's district, the one its lot stands in on the city plan. White Wells is at the Pool, Wrack's End at the Hull-Houses, Rimewell at the Bell Square, and so on. The story's `location`s are unchanged. A scene Narrative later tags with its own district keeps that district, so moving to it becomes a walk.
  - A fail or lose branch that moves the party, and any choice that is `here` (fight, roll, payment, decision), is carried. A plain way (`go`) is a map move.
- **Data.**
  - The family house is a building in `geography.json` (`alster_family_house`, a house in the Lower Town). Scenes `300`, `400`, `400_lost`, `450` and `470` say so in the story (5 `location` fields, Narrative's file).
  - The city-plan tool (`tool/city_plans/gen_city_plans.dart`, `_joinBuildings`) puts every scene of one building on its first scene's lot, after the layout, so no other lot moves. The Blind Beggar's 7 scenes are on `alster_b000` and the house's 5 on `alster_b005`, now named "The family house". The 10 lots left with no scene lose their names. Only Alster's anchors and names change.
- **The Journey.** In `_take`:
  - `FlowStay` and `FlowMap` keep today's full page.
  - `FlowTripThenArrive` plays the carry on the map (the lost-fight trip) when the map comes back.
  - `FlowReturnToHub` lands on the hub's map with the carry and sets `lastReturnProvider` for UX's notice.
  - The read-through (Journey and story player) stops where the stop changes. The scene a page was read for is placed when the map comes back, so a carry is no longer lost behind the page.
  - Left to UX: S1 for main-story scenes, S2 for the rest, the next scene's choices inside the scene view on `FlowStay`, the map showing only the `FlowMap` ways, and the notice.
- **Counts (1,061 choices).**
  - Stay: **725**. Before, 729 same-place choices went through the map.
  - Map move: **104**.
  - Carried: **87**.
  - One-tap return: **145**.
  - District moves read through with no map: **0** (33 before).
