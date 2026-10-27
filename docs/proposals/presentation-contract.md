# Presentation contract: which view shows which scene (Core, proposal)

Design only. No build and no version. Written on v1.572.

The user asked which view should show what (Journey, district, street, text, choices), and what each session needs from the others. Their example is chapter 1:

> "click on the flag on the Journey district view, the user moves on the district to the flag, it opens the street view with the choices since you are in the street, you choose, and it starts the scene with your sister since it is a main story kind of event."

**Short answer.** That flow makes sense, and most of its parts already exist:
- the district view;
- the walk to a pin;
- the street view (v1.544);
- the story page;
- the doorstep list (v1.542).

What is missing is one rule, written down, that says which view a scene opens in. Narrative should then tag only the scenes the rule gets wrong. Today the choice is made by four separate rules, and the most important one ("main story → full page") is too broad: it sends scene 300 to the page instead of the street.

Counts below come from a throwaway test that runs the game's own `choiceShape` and `StoryStops` on all 472 nodes.

## 1. The family-house chain, today and as asked

| Step | The user's flow | What the code does today |
|---|---|---|
| **270**, Weaver's Alley, the dog in the wire | The flag on the family house is on the district view and is tapped there. | **Not on the map.** 270 opens on the full page, because it is a main-story scene (`arrivalViewOf`, arrival_sheet.dart:26). "Back to the map" is hidden (`pageExitHidden`, v1.565): "Leave them both" leads to the house, and so do the two cards. That way shows as a road card under the cards. |
| The walk | The party walks on the district to the flag. | **Yes, after the road card.** It closes the page and shows the map (`_leaveByRoad`, journey_screen.dart:979). The party then walks to the pin (`_walkCity`, 0.6–1.2 s). |
| **300**, the street before the house (a doorstep of `alster_family_house`) | The street view opens, with its three choices as pins along the street. | **The page opens instead.** 300 is a main-story scene, so `arrivalViewOf` gives the page, and `pageExitHidden` holds it there: all three ways are cards. The street view exists for 300 (b005's front, the three ways as street pins, journey_screen.dart:6323), but it only shows when the page isn't forced: after loading a save, in Edit Mode, or through the Read toggle. |
| The choice | The player taps a pin in the street. | On the street view, a street pin opens the way's sheet, then Go. There is no walk at a doorstep (`_cityWalkable`, journey_screen.dart:2365). On the page, it is a card. |
| **400**, the cannonball, Vane and Lysa (a spine beat, also a doorstep) | It starts as a story page. | **Page. This matches.** |
| **450 / 400_lost** (after the fight, same doorstep) | Not said. It continues the main scene. | Page. |

**The differences:**
- **(a)** 300 opens on the page, not the street view. The cause is one rule: every main-story scene opens on the page.
- **(b)** At 270 the flag is reached through a road card, not seen on the district first. This follows the user's own v1.565 call (no "Back to the map" when the cards cover every way).

If the street view becomes the arrival view of 300, step (b) can stay as it is. The road card is already a walk to the flag.

## 2. The views

| View | Drawn by (UX) | Decided by (Core, today's code) | Reads |
|---|---|---|---|
| **World** (globe, roads, voyages) | world_map widgets | `_level == world`; a world road (`_roadWalk`) | geography (lands, roads), `travelPlaceId`, `landRouteId` |
| **Town** (the whole city plan) | city_chart | `_townView` and `_canTown` (a city plan, not in a room) | city_plans.json (districts, buildings, `anchors`), holders, influence |
| **District** (one district, its ways as pins and rows) | `_CityDistrictView` | `hostedCity`: a city, town or village with a plan, not a room or detour | the plan, `cityDistrictOf` per way, `partyDistrictNeighbours` |
| **Street view** (a building's front, the scene's ways as street pins) | street_view.dart | A **doorstep** scene (`geography.json` building `doorstep: [ids]`) in the party's district | `doorstep`, `anchors[node]`, weather, the hour |
| **Room** (a building's floor plan, ways at spots) | RoomPlanPainter | The node's place is a building and the node is not in its doorstep | node `spot`, choice `spot`, the next node's `spot`, `room.exitFrom` |
| **Road / relief chart** (no city plan: sites, the sea) | `_JourneyChart` | No hosted city | geography, landmarks |
| **Story page** (full screen, the text and its cards) | `_ScenePanel`, full | `arrivalViewOf` → page: a main-story scene or a detour. Can be held by `sceneLocked` / `pageExitHidden` | `isMainStoryScene` (not a hub, not an errand, not a camp scene) |
| **Sheet over the map** | `ArrivalSheet` | `arrivalViewOf` → sheet: any other scene | as above |
| **Nothing (map + notice)** | none | `FlowReturnToHub`: a one-tap return to a hub | the hub and errand index |
| **Fight** | FightScreen | a choice with `triggerEnemyId(s)`, a hunt, an ambush, `shipBattleId` | enemies, the party |
| **Camp / hub** | CampScreen (Camp tab) | the party is at camp; `returnToCamp` | camp state |
| **Shop / port / harbor** | shop, port and harbor screens | `unlockShopId`; a town service on the chart; the camp | shops, ports |
| **Expedition / land crossing** | expedition and crossing screens | `launchZoneId` / `landRouteId` | zones, land routes |
| **Edit Mode** | the reader tab plus the Journey unfogged | `appModeProvider == edit` | everything, no locks |

The views a scene can open in are only five: **page**, **sheet**, **street**, **room**, **map** (a hub). Every other view in the table is reached by a choice.

## 3. What a scene and a choice need

### Exists today

| Field | Count of 472 | Written by | Read by | Notes |
|---|---|---|---|---|
| `location`, a geography id | 472 | Narrative, with Core | Core (`placeOfNode`, stops), UX (the art) | Level of the place: 196 district, 170 location, 106 building. |
| `doorstep` on a building (geography) | 6 scenes: 125, 300, 400, 400_lost, 450, 2015_informant_trap | Core | Core (`doorstepOfNode`), UX (street view) | The only "outside a building" marker. |
| `anchors` (city_plans), scene → plan building | 401 of the 421 scenes in a planned city | Core | Core (`sceneDoorstep`, the pins), UX | Says *which front* a scene stands at. It doesn't say whether the scene is outside. |
| node `spot` | 60 (all in rooms) | Narrative | Core (room plan), UX | |
| choice `spot` | 12 (blind_beggar 100/105/110/120) | Narrative | Core (room plan) | |
| `settlement`, `hub_progress` | 20 and 12 | Core | Core (hubs, `isHubScene`) | |
| Spine beat (`chapter_spine.dart`) | 64 | Core | Core (main quest, progress) | The only "this is the main story" marker in data. |

**Derived today, no field:**
- **The weight.** `isMainStoryScene` (not a hub, not an errand, not a camp scene) covers 118 scenes, 54 of them spine beats. Errands of a hub are 304 scenes, and hubs and camp scenes 59.
- **How the party arrives.** From the choices that lead to the scene:
  - 104 scenes are reached only by a way taken on the map (a pin, `go`);
  - 257 only by a choice acted out where the party stands (a card, "the story brings the party");
  - 27 by both;
  - 84 by no choice at all: a start, a fight's lose or fail branch, a quest, a camp.
- **Where a choice is acted out** (`choiceShape`):
  - 675 choices stay;
  - 401 walk to another district of the same place;
  - 61 travel;
  - 4 lead nowhere.
  - Its `to` is the destination place.

### What node-context.md (Narrative) covers, and what it lacks here

Its `scene` block gives district, building, kind (inside, street, road, water, underground), time, weather, present and camera. It is the **look** of a scene. For presentation it lacks three things:
1. **The view the scene opens in.** `kind: street` says the scene is outside. It doesn't say whether the player sees the street view or a page.
2. **The weight.** Main, side or ambient, which decides page against sheet.
3. **Where each choice is acted out.** A street pin, a room spot, a card on the text, a way to another place. It also doesn't say what happens to the view after the choice: kept, or left for a page or another place.

`scene.building` with `kind: street` is what `doorstep` says today, from the scene's side instead of the building's. If both exist, one must win. My proposal: `scene` wins, and the `doorstep` lists become derived from it.

### Proposed: two optional fields, everything else derived

```json
"present": { "view": "street", "weight": "main" }        // on a node
"actedAt": "street"                                      // on a choice
```

| Field | Values | Default (derived, §4) | Written by | Read by |
|---|---|---|---|---|
| node `present.view` | `page` · `sheet` · `street` · `room` · `map` | the rule in §4 | Narrative, exceptions only | Core (`arrivalViewOf`), UX (draws it) |
| node `present.weight` | `main` · `side` · `ambient` | beat → main; `isMainStoryScene` → main; errand → side; hub or camp → ambient | Narrative, exceptions only | Core (the page/sheet rule, the quest tracker), UX (the frame) |
| choice `actedAt` | `card` (on the text) · `pin` (on the street or room, at the choice's `spot`) · `way` (a pin to another place) · `road` (World or Land) | `card`/`pin` from the scene's view; `way` from `choiceShape.move == walk`; `road` from `travel` | Narrative, rare | Core (lock, back-to-map), UX |
| choice destination | the place id | `choiceShape.to` (the next scene's place) | no new field | Core, UX |

**The view after a choice** needs no field. A choice keeps the view when its next scene has the same stop and opens in the same view (300's three choices go to 400, which is a page: the street gives way to the page). Otherwise the next scene's own view opens.

**How the player arrives** needs no field either: it is derived (above). The view rule uses it for one case only, a scene continued by a card on the same doorstep (§4, rule 5).

## 4. The default rule

The first rule that matches wins.

1. **An ending** opens the ending panel (as today).
2. **A hub or camp scene** (a settlement, `hub_progress`, a way back to itself, a camp) opens **map**: the place's view with its ways as pins and rows, the prose as a header. Today this is the sheet or nothing.
3. **A spine beat** opens **page**.
4. **Inside a building** (the place is a building, not its doorstep) opens a **room**: the plan, the ways at their spots, the text as a sheet over it. A main scene uses the page over the room instead. This is today's page or sheet with the room plan behind it; only the name is new.
5. **At a doorstep** opens **street**: the front, the hour and weather, the text as a band, the ways as street pins. One exception: a main scene whose every arrival is a card from the same stop opens **page**, because the scene continues (450, 400_lost).
6. **Otherwise**, a main-story scene opens **page** and a side or errand scene opens **sheet** (as today).

The chain under this rule: 270 page (as today), 300 **street** (changed), 400 page, 450 page.

**The rule against today's views:**
- **Unchanged:** 361 of 472 scenes.
- **Changed:**
  - 34 hubs and camp scenes that open as a sheet today get the map view; 25 already do;
  - 73 scenes in rooms name the room view that already stands behind them;
  - 4 doorstep scenes get the street: 300, 125, 2015_informant_trap and 400_lost. 400_lost is wrongly so; see below.

**Where the rule is likely wrong** (exceptions for Narrative to tag, found by script):

| Case | Scenes | Why the script can't decide |
|---|---|---|
| Arrived at by no choice (a fight's lose branch, a quest, a start) | 84 scenes; the doorstep ones are **400_lost** and 125 | Rule 5 can't see the arrival. 400_lost continues the house scene and should be `page`. |
| Approach scenes not on a doorstep: walked to, a main scene, every way acted out there, not a beat or hub | 3: 260 (the toll), 840 (the Undercroft), 890_trainer (the quay drill) | Like 300, they read as "you arrive in the street and choose". If Narrative agrees, each goes on its building's doorstep list (or `scene.kind: street`) and opens as street. |
| The same, but spine beats | 4: 2001 (the Landward Gate), 2010, 2050, 7520_morrow | Rule 3 gives them the page. The street would fit 2001–2050 if the user wants arrivals in the street even on a beat. 7520_morrow has 14 ways, too many for a street. |
| Main scenes in a room that are not beats | 12: 106, 115, 800, 816, 820, 822, 823, 4999_standard, 6010_thread, 822_lie_failed, 3010_rope_fail, 4999_drawn | Room or page is a writer's call: the Black Hold cells (800–823) read as one room scene, and 4999_* as a ceremony. |
| A whole village with no district | 6: 5200_house_barkbleeders(_bled), 5200_clan_mire_1(_edge, _answered), 5200_barrows | The street and district views need a district. Narrative or Core names one. |
| No place | 1: node 0 (the prologue) | As today. |
| Sites and the sea with no city plan | 37 (hollow_shore 21, sleepers_face 5, lark_wreck 4, hollow_court 4, three others) | There is no street or district view there; page or sheet. Right by default. |

So the tagging is about 30 scenes to read (the 26 named above, plus the doorstep and room cases among the 84 with no arriving choice), not 472.

## 5. Who does what, in order

1. **Narrative (S):** answer the open questions below. Read the ~30 exceptions above and tag the ones that are wrong, either with `present.view` / `weight`, or by adding the scene to a building's doorstep list.
2. **Core (M):**
   - `presentationOf(node)` in `lib/data/` implements the §4 rule, with the two optional fields as overrides. `arrivalViewOf` and the Journey read it instead of `isMainStoryScene` alone.
   - A test pins the chain 270 → 300 → 400 and every exception.
   - The loader keeps `present` and `actedAt` on save, in the story editor.
   - The street view stops being held by the page, for a street scene.
3. **UX (M):**
   - The street view as an arrival view: the scene's text as a band over the street, which can collapse; a fight pin in the street. The street view already exists.
   - The `map` view of a hub with its prose as a header.
   - The room view's sheet.
4. **Narrative (S), later:** the `scene` block (node-context.md) on top. Its `kind: street` can then replace the doorstep lists.

Steps 2 and 3 can run in parallel once step 1's answers are in. Step 2 lands first, because UX draws what the rule decides.

## Open questions

**For the user, through the manager:**
1. **Hubs on the map.** Should a hub (a town's or the camp's scene) open as its map, with the prose as a header, instead of a sheet?
2. **Approach scenes.** Should all "approach" scenes (the toll at 260, the Landward Gate at 2001) open as the street, as 300 would?

**For Narrative:**
1. Is `present` (view and weight) on the node right, or should it live in node-context's `scene` block?
2. Which of the approach scenes (3, and the 4 beats) are streets?

**For UX:**
1. Where does the text go on the street view: a band above, or a sheet that collapses?
2. How many street pins fit before the street gives way to the page? I assumed about 5.
