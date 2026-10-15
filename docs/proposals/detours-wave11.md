# Wave 11: detours as places to explore (Narrative, proposal)

**The user's words:** *"Detours should open an exploration-like scene or be included in the journeys details. They could also be specific to some chapters etc. The idea would be to improve their consistency, time of appearance and interest."*

**Status:** proposal only, docs only; nothing is built. **[N]** is Narrative's part, **[C]** Core's, **[UX]** UX's. Numbers marked *(Core to fill)* wait for the simulator figures the manager asked Core for.

**In short**
- Today a detour is one small event, rolled with the same 35% at every road, with no memory of the last one.
- The proposal makes it a **short scene (2–4 beats) in a named place**, **rumoured on the journey before you set out** so you can take it or leave it, **tied to the chapter** (one memorable one per chapter), and **paced** (no two in a row, fewer when the clock is short, more on long roads).
- The expedition step kinds and the place pools already exist; most of the writing reuses them.

---

## 1. Audit of today

### 1.1 When a detour appears

Read from `lib/screens/story_player_screen.dart` (`takeStoryChoice`, `rollRoadEncounter`) and `lib/data/sub_node_engine.dart`.

**The order of what a road can hold.** For a choice that moves between two scenes:
1. **A walk between places** (`choice.travels`, or two places of the geography) spends a ration and the watches of the destination.
2. **A road event** (`roadEventFor`): rolled *before* the party sets out, deterministic from the run's seed. If one is waiting, it replaces everything below. Not in chapter 1, not in a crisis.
3. Otherwise, **at rest** (`detourAllowedBetweenScenes`: chapter 2 or later, neither scene `noDetour`, not both scenes `tense`) the road rolls, in this order:
   1. an **alignment hunter** ambush (`maybeAlignmentEvent`);
   2. a **familiar face** (`maybeRecurringEncounter`, someone met on an earlier road);
   3. a **detour** (`SubNodeEngine.maybeGenerate`): **35%** (`detourChance`), or 100% if one is *owed*.
4. **Mid-crisis** (both scenes tense): the road rolls the 35% anyway, and a hit is *owed* (`oweDetour`), taken at the next road at rest.

So per eligible road the odds are *at most* 35%, and less when a hunter or a familiar face took the slot. A road with a road event never rolls a detour. Chapter 1 has none, by design.

**What it does not know.** The roll has no memory: no cooldown after a detour, no pity timer after quiet roads, no length of road, no deadline, no chapter story. It cannot be seen before it happens.

### 1.2 What it leads to, and how long it is

Per detour (`maybeGenerate`):
- **35% of detours with a quest available** are a quest pickup: a chain of **3–4 nodes** (the quest’s “mini-arc”). Otherwise the chain is **1–2 nodes**.
- Each node, drawn independently (`buildNode`): **shop 25%**, **fight 25%** (30% of those a pack of 2–3), **treasure 15%**, **rest 15%**, **generic 20%** (a line and “Move on”).
- A fight node offers “fight” or “slip past” (Dexterity check); treasure is gold plus a “dig deeper” gamble; rest is +HP or a scavenge; a shop opens a shop; a quest node offers “take the job”.
- After the chain, `withHunts` adds a hunt (trail then quarry) 35% of the time.

So the typical detour is **one node, one decision, ~30 seconds**. It does not take a watch of its own as far as I can read (*Core to confirm*); the road before it already did.

### 1.3 Which words answer: place, location, zone, biome, theme

`flavorFor` / `PlacePools.flavorAt` (`lib/data/place_pools.dart`, filled from `assets/gamedata/detours.json`): for each *kind* (shop, enemy, quest, treasure, rest, generic) it walks `Geography.pathOf(location)` (district → location → zone → country), then `biomes[<the zone’s biome>]`, then `themes[...]`, then the Dart pools of `map_themes.dart` (four hard-coded themes). A line may carry `mood` (calm/tense) and `minChapter`.

**What the data holds today** (`detours.json`, mine, v1.342):

| Level | Entries | Lines each |
|---|---|---|
| Places | 15: six Saltmouth districts; Cove camp, Rimewell, Highhearth, the Black Reliquary, Wrack’s End, Candlehold’s gates and lantern hall, White Anchorage, Greyhithe | 2 per kind (3 generic in the Saltmouth districts) |
| Biomes | 7: tear, frost, ashlands, fen, volcanic, arid_coast, sea_cliffs | 6 per kind (4 for arid_coast) |
| Themes | 0 | the four Dart themes are the last fallback |

396 lines in all, each a **line of description**, not a scene.

### 1.4 Where it feels wrong

- **Forgettable.** A line plus a button. A shop detour is “a stall by the road”, a treasure detour is gold. Nothing is *somewhere*; there is no reason to remember where it happened.
- **Repetitive.** Six lines per kind per biome, and `_freshIndex` only avoids the last few. After four or five detours in a biome you have heard everything, and the mix is always the same five kinds. There are no **landmarks**: nothing is unique to a place beyond a few lines.
- **Out of chapter.** The mix ignores the story: chapter 3 (the Spire of Judgment) and chapter 6 (the Hollow Shore) draw from the same biome lines, with `minChapter` the only brake. A detour never echoes what the chapter is about (judgment and ash, the drowned cloister, the Dead Heart’s frost, the war for the Throne).
- **Out of place.** Only the pool follows the place; the **kind** does not. A rest and a shop come as readily in the middle of the Dead Heart as on Tern Row; there is no “nobody sells here”.
- **No consent.** A detour just happens at the next road. You cannot leave it, plan for it, or be told it is there, and you cannot reach one you would *want*.
- **No pacing.** Two in a row are possible (a road event or a hunt may sit between); a long road gets the same odds as a short one; a delivery with one day to spare gets the same odds as a free walk; a chapter with six roads may produce none or three.

### 1.5 The numbers (Core, 200 replayed runs)

The simulator does not model detours, so Core recomputed them from the rules: **200 runs replayed through the real detour, road-event, alignment and familiar-face functions.** (My own 50-run replay, `docs/narrative-audit/playthroughs-50.md`, agrees on the shape: 3.8 detours a run, chapter 4 empty, most of them in one place.)

**Trigger, as built**
- Base chance **0.35**. It rolls only when leaving one of the **~44 chapter-spine beats**: about **11.9 chances per run** out of ~174 choices. Never in chapter 1. Blocked when either scene is `noDetour`, or when both scenes are tense.
- Checked first, in order: road event (0.3 × condition × danger, travelling choices only), then alignment (hunter 0.06 + 0.0015 per point, capped at 0.15; temptation 0.10), then familiar face (0.4 while a recurring beat is open, chapters 2 to 6).
- A blocked transition **still rolls 0.35** and, on a hit, *owes* a detour, which the next free transition takes at 1.0.
- Chains are 1 to 2 nodes, or 3 to 4 with a quest pickup (0.35), plus 2 for a hunt after a pack fight (0.35). Node mix: shop 25%, enemy 25% (30% of those packs), treasure 15%, rest 15%, generic 20%.

**What fills the 2,380 free transitions:** familiar face 32.6%, detour 28.8%, nothing 20.8%, road event 9.9%, alignment 8.0%. **61% of detours are owed ones**, so when the die actually rolls it fires 58% of the time, not 35%.

**Per run:** 3.43 detours on average (median 3, p90 5, max 8).

| Chapter | Detours per run | Runs with at least one |
|---|---|---|
| 2 | 0.67 | 56% |
| 3 | 0.46 | 40% |
| 4 | **0** (no free transitions at all) | 0% |
| 5 | 0.98 | 84% |
| 6 | 0.57 | 52% |
| 7 | 0.52 | 38% |
| 8 | 0.25 | 24% |

**By zone** (detours / free transitions): saltmouth_headland 133/533, the_cove 294/1151, the_fen 169/400, glass_shore 60/200, ashlands 30/96.

**Per journey**
- 24.5% of road legs have a detour, against **31% of moves within one place**.
- Longest dry spell: median 4 free transitions (max 11), which is median 76 choices (max 167). Most in a row: median 2, max 4.
- Chain lengths: 1 node ×221, 2 ×219, 3 ×110, 4 ×119, 5 to 6 ×17.

**Which pool supplies the 1,191 non-fight lines:** district 16%, location 34%, biome 50% (**all the treasure lines**, because no place pool has treasure). Zone and country pools do not exist. The themes pool and the Dart fallback supply 0%. **All 311 fights used the enemy's own encounter line**, so the pools' enemy lines never show.

**Cost:** the detour itself costs no time and no ration; only the walk before it does. Treasure gold (5 to 20) × (1 + 0.5·(chapter − 1)); rest +20 HP, plus 10 per chapter after the first; slip past on Dexterity DC 9 + chapter.

**Already off** (Core’s to fix inside the detour engine, see section 6):
1. Detours only roll from spine beats.
2. Chapter 4 never gets one, and its owed rolls spill into chapter 5 (146 times).
3. 87% of owed detours fire in a later chapter than the one that owed them.
4. Owed detours come mostly from `noDetour` set pieces (3,625) rather than crises (730).
5. Each place pool has 2 lines and a memory of 1, so the same two lines alternate.
6. The pools’ enemy lines and the themes pool never show.
7. Quest chains are 3 to 4 nodes, not the 4 to 7 the code comment says.
8. Walks from the camp skip the mood and `noDetour` checks.
9. Deadlines are unaffected: no detours inside expeditions, and detours cost no days.

**Where the roads run, and which pools exist** (my reading of the geography; the biome is the zone’s):

| Chapter | Where the roads run | Zones with expeditions | Detour pools that answer |
|---|---|---|---|
| 1 | Alster’s flight | none | **none** (no detours) |
| 2 | Saltmouth, Cove | Fisherman’s Row, Tanner’s Court, Lantern Docks, Salt Road (escort) | six Saltmouth districts; Cove camp; arid_coast / sea_cliffs |
| 3 | The Spire of Judgment: Ashen Quarter, Emberwick, Akagiri | Cinder Row, Scaffold Yards, Exorcist’s Road, Fever-Bark (delivery) | ashlands, volcanic; no place pools |
| 4 | The Hollow Court: Drowned Cloister, Kindly Hill | Ossuary Galleries, Drowned Stair, Changeling Fen, Bell Road (escort) | fen, tear; no place pools |
| 5 | The Shroud’s Truth: Black Reliquary, Rimewell, Highhearth, Dead Heart | Dead Heart Approach, Shroud’s Vigil, Frost Quarry, Ember Run (delivery) | frost, tear; Rimewell, Highhearth, Black Reliquary |
| 6 | The Hollow Shore: Wrack’s End, White Anchorage, Greyhithe | Glass Strand, White Fleet Grave, Beyond the Tear, Lantern Train (escort) | sea_cliffs, tear; Wrack’s End, White Anchorage, Greyhithe |
| 7 | The Lantern Throne: Candlehold | none | Candlehold gates and hall |
| 8 | Beyond the Tear | Beyond the Tear | tear |

**What this changes in the proposal**
- **The scene engine replaces the pools’ role for fights.** All 311 fights used the foe’s own line, so the place has no say in a fight today. A scene’s `fight` beat names its foe and writes its own text (section 2); the foe is chosen for the place.
- **Rolls need to be honest.** 61% of detours are *owed* ones, often from set pieces, and 87% land in a later chapter than the one that owed them. Section 5’s pity timer and cooldown should replace the owed roll, not sit beside it; a detour owed by a set piece is simply dropped.
- **The same-place problem is bigger than I counted:** 31% of moves within one place carry a detour against 24.5% of road legs. The rule “a detour is a place off the road” (section 2.1) is the fix: **no detour rolls between two scenes of one place, except a city scene (section 5.5).**
- **Pools:** more than 2 lines per kind at every place, **treasure lines in every place pool**, and a memory longer than 1. Narrative’s part: a pool top-up (section 6).

---

## 2. Detours as exploration scenes

### 2.1 The idea

A detour is not an event in the middle of a road: it is **a place a little off the road**, with a name, that you walk into. It plays as **2–4 beats**, in the same shape as the expedition steps, in the place it happens, and it ends back on the road.

**Step kinds reused** (`expedition_steps.json`): `event`, `check`, `fight`, `discovery`, `rest`. The beat shape is unchanged: `{id, type, text, text_fr, place?, place_fr?, material?, choices:[{id, text, text_fr, check?, hard?, fight?, success?, fail?, outcome?}]}`. Outcomes carry only a note; gold, health and days are Core’s.

**A scene** (new file, suggested `assets/gamedata/detour_scenes.json`):
```
{ "<scene id>": {
    "title": "...", "title_fr": "...",
    "rumour": "...", "rumour_fr": "...",     // one line, for the journey details (3.1)
    "where": { "biome": "fen" }  or { "place": "saltmouth_wharf" },
    "minChapter": 3, "maxChapter": 5,
    "requires": { "flag": "..." },           // optional (section 4)
    "tags": ["landmark"],                    // optional
    "beats": [ <step>, <step>, ... ]          // 2 to 4
} }
```

**Shape of a scene** (the rule I will write to):
1. **Arrive** (an `event` or `check`): the place, and a reason to go in.
2. **The thing** (`fight`, `check` or `discovery`): what is here. Almost always has a way round.
3. **The turn** (`event`, optional): a consequence you can read, or a second small choice.
4. **Leave** (`rest` or `discovery`): what you take away, and one line that stays with you.

Beats 2 and 3 carry the only danger. A scene with a fight in it has exactly one foe or a pack, as the expedition rule has it.

### 2.2 What the old kinds become

The six kinds (shop, enemy, quest, treasure, rest, generic) do not disappear: they become the **content of a beat**.

| Today’s kind | Becomes |
|---|---|
| shop | a beat where the place’s own seller is *there* and opens the shop (the choice carries `shop`) |
| enemy | the `fight` beat, with its way round |
| quest | the scene’s hook: someone at the place asks for the job; accepting is the beat’s choice |
| treasure | the `discovery` beat |
| rest | the `rest` beat |
| generic | the `event` beat, or the connecting line |

The old random chain stays as the **fallback** where no scene is written: a place with no scene is no worse than today.

### 2.3 Example scenes

Each shows the scene’s title, its rumour (for 3.1), and its beats. EN in full here; FR is written in full when the shape is agreed. **All fights are one foe or pack as the engine allows.**

#### Biomes

**Tear (the Hollow Shore, the rifts)**
- **The Chair That Faces the Water** · *rumour: “a chair set on the sand, two hours off the road”*
  1. *event:* A single chair stands on the tideline, facing the sea. It is dry. Everything around it is wet.
  2. *check (Wisdom):* Sit in it. → success: you see the shore as it was, a quay, a name; fail: you see only what looks back.
  3. *discovery:* A cord of ship’s rope, still knotted, coiled at the chair’s foot. (reward material)

**Frost (Highhearth, the Dead Heart)**
- **The Bell Without a Rope** · *“a bell on a pole, a morning’s walk from the stair”*
  1. *event:* A hanging bell, rimed, with no rope. It rings once, when no wind moves.
  2. *check (Perception):* Find what rings it. → success: a hollow in the ice, a hand-worn handle; fail: you hear it ring behind you.
  3. *fight (one foe) or discovery:* Whoever was ringing it comes out of the white. / Or, if you were quiet, there is a cache the ringer left.

**Ashlands (the Spire, the Ashen Quarter)**
- **The Court in the Cinders** · *“a judgment seat in a burned yard”*
  1. *event:* A table, a gavel, a row of burned stools. Someone has set a ledger on the table, open.
  2. *check (Charisma):* Be heard. → success: the dead court agrees to adjourn; fail: it hears *you*.
  3. *fight (one foe, a zealot or penitent):* The court’s last clerk, still taking the roll.

**Fen (the Hollow Court, Kindly Hill)**
- **The Lamp That Counts** · *“a lamp lit over the reeds, calling the hour”*
  1. *event:* A lamp hangs from a pole in the water. It flickers once a minute, exactly.
  2. *check (Dexterity):* Cross the plank. → success: dry; fail: you wade, and something cold takes your wrist.
  3. *rest:* A dry hummock with a stack of fen-cut peat: the Mire’s courtesy, for the road.

**Volcanic (Emberwick, the Spire road)**
- **The Charcoal Tithe** · *“smoke from a clamp, a mile off the way”*
  1. *event:* A clamp of charcoal burns under turf. Three Emberwives tend it, and will not look up.
  2. *check (Charisma / or pay):* Ask for coal for the road; the price is a favour or a coin.
  3. *discovery:* A coal-seam that is not in any ledger. (reward material)

**Arid coast (the Waste)**
- **The Well That Stayed** · *“a well in the dunes, still wet”*
  1. *event:* A stone well. The rope is new.
  2. *check (Constitution):* Drink, or fill your flask and go.
  3. *fight (pack of hounds):* Thirst draws more than you. With a way round.

**Sea cliffs (Wrack’s End, Greyhithe)**
- **The Light That Was Not Lit** · *“a lighthouse door ajar”*
  1. *event:* A cliff light with the door open, the lamp cold, and a kettle warm.
  2. *check (Perception):* Whoever is here is hiding.
  3. *discovery or fight (one foe):* A Wickwarden’s ledger, or a salvager who thought the light was theirs.

#### Saltmouth districts (chapter 2)

| District | Scene | Rumour | Sketch |
|---|---|---|---|
| **Landward Gate** (`upper`) | **The Toll Nobody Wrote** | “a clerk at the gate with a new book” | event: a clerk collects a levy no one has authorised → check (Charisma or Wisdom) to read it → pay, bribe or turn the clerk |
| **Tern Row** (`tern`) | **A Net Left to Dry** | “a net hung out as a signal” | event: nets in a colour that means something → check (Perception) to read it → a fisher’s family needs a hand: quest hook |
| **Wharf** (`wharf`) | **Short Count at the Berth** | “a crate that does not match its tally” | check (Perception) → fight (one hand, a bribed docker) or discovery (a smuggler’s extra) |
| **Yard / Berths** (`berths`) | **The Hull Under Canvas** | “a hull under canvas, a night’s work” | event: a refit being hidden → check (Dexterity) to see → a Tar-Hands favour, or a fight with its guard |
| **Lantern Alleys** (`alleys`) | **The Lamp-Lighter’s Round** | “a lamp-lighter going the wrong way” | event → check (Dexterity) to follow → a hidden room: shop of an unlicensed seller |
| **Card Row** (`cards`) | **The Hand Left Face Down** | “a hand of cards left on a table, still warm” | event: a hand with your name written on one card → check (Luck) → discovery or a Crow’s offer |

A city scene happens *in the city*: on foot, inside the districts. It does not need a road, and it does not spend a ration (see 5.5).

---

## 3. Detours in the journey details

### 3.1 Known and rumoured

A road event is already **rolled before the party sets out** (`roadEventOn`: “what waits on this road, known before the party set out”). Detours follow the same rule: **the road’s detour is rolled when the road is chosen**, not at the next step. That makes it possible to say something about it.

- The journey panel for a route shows up to **two lines of rumour** under the route: the scene’s `rumour` line. *“A ruined chapel, two hours off the road.”*
- A **known** detour (rumoured by a neighbour, heard-of, read off a map, or seen on a previous trip) shows its title and what it costs; an **unknown** one shows only a mark, or nothing.
- How a detour becomes known (suggested, in order of effort): a place’s *heard-of* text can name one (the heard-of system already exists, `docs/proposals/heard-of-places.md`); a companion remarks on it; a high Perception reveals it; a rumour is bought in the tavern or from a Crow.
- A road with a **landmark** (section 4) always shows it, so the chapter’s memorable detour is never a surprise that cannot be found.

### 3.2 The choice: take it or leave it

- **Take it:** the scene plays. The road continues from there to the destination.
- **Leave it:** the road goes on; the detour is **not** lost: it is *remembered* as a place of that road and may be taken from the same route later (once per chapter per scene; a landmark stays until taken).
- Mid-crisis roads show nothing (as today, owed detours wait).
- An **unknown** detour found on arrival can be backed away from at the first beat (“Leave it”), at no cost, on every scene’s first beat. This keeps the surprise without forcing the player.

### 3.3 What it costs

Everything here is Core’s to set. What the journey panel should show:

| Cost | Suggestion |
|---|---|
| **Time** | the scene takes **1 watch** (a half-day) if it has a fight or a check, **0** if it is only an event, so a long scene costs more. A delivery with a deadline sees the cost *before* it chooses. |
| **Supplies** | **0** by default; a camp-out scene (a rest beat) may spend a ration and give back more. |
| **Risk** | a coloured pip: calm, uncertain, dangerous (from the scene’s beats: any fight = dangerous). |
| **Reward** | one word from the scene’s reward, if known: *a find*, *a seller*, *a favour*. |

In the panel, a rumoured detour looks like a small row: `Ruined chapel · 1 watch · uncertain`, with “Take it” and “Leave it”.

---

## 4. Chapter-specific detours

Each chapter has **three kinds**:
- **Echoes:** general scenes in the chapter’s biomes whose words use the chapter’s clans, threats and weather.
- **A landmark:** *one memorable, authored detour per chapter* (5.4). It is tagged `landmark` and always rumoured.
- **Gated scenes:** scenes with `requires` that only open after a story beat (a flag, a companion present, a clan standing, a quest done).

### 4.1 By chapter

| Ch | Theme | Echoes (the words) | The landmark (working title) | Gated example |
|---|---|---|---|---|
| **2** Saltmouth | the coast, smugglers, the Crows’ docks | tolls, nets, tallies; the Dominion’s patrols, the Salt Crows | **The Short Count**: a berth where the manifest does not match the hull | after the first Crow contract: a *Brig-Born crew* offers a favour |
| **3** The Spire of Judgment | judgment, ash, the Compact’s coal | benches, verdicts, cinders; the Inquisition’s patrols; the Compact’s coal tithe | **The Court in the Cinders** (above) | after the Spire’s gate: the *Scaffolders* build a new thing, and want a witness |
| **4** The Hollow Court | drowned cloister, the Mire’s courtesy | lamps, tallies of the dead, hospitality; the Mire’s asks | **The Lamp That Counts** (above) | after a Mire gift: a *Barkbleeder* offers a cut from the fever-tree |
| **5** The Shroud’s Truth | frost, relics, Highhearth | bells, frost-grown guards, ledgers; the Black Reliquary’s skull-lanterns | **The Bell Without a Rope** (above) | after a Reliquary quest: a *Reliquary Thief* offers to break a relic |
| **6** The Hollow Shore | glass, drowned fleet, the Tear | reflections, hulls, light; the Admiralty’s grave-hunters | **The Light That Was Not Lit** (above) | after the White Fleet quest: the *Drowned Debt* offers to pay it |
| **7** The Lantern Throne | the war, the five claimants | banners, supply lines, scouts; each clan’s road | **The Banner on the Hill**: whoever you back, their camp is hungry | gated by *the claim you made*: one scene per claim |
| **8** Beyond the Tear | the end | the tear’s quiet | none: no detours; the ending rule holds | — |

### 4.2 After a story beat

Scenes can open after:
- a **flag** (a choice made earlier: `companion_turned`, a quest done, a Crow contract signed);
- a **companion** present (their own remark on the road is the hook, in `companion_remarks.json`);
- a **clan standing** (a Friend of the Mire sees the fen guide’s lamp; a Hunted one finds the road watched);
- the **chapter condition** (`quarantine`, `contestedRoads`, `stormSeason`, …): *quarantine* turns the shop beat into a closed gate; *rivalCompany* adds a rival crew at the scene; *leanSeason* turns a treasure into a ration. This reuses `chapter_conditions.dart`, so the same chapter feels different from run to run.

---

## 5. Timing

All numbers are proposals; **[C]** to tune with the simulator.

### 5.1 How often

- **Aim:** about **one detour every three roads** across a chapter. Today it is 35% per eligible road (about one in three, but luck-dependent and eaten by hunters and familiar faces).
- **Make it dependable:** a **pity timer** replaces the flat 35%. Each quiet road adds +10% to the next, up to 60%; a detour resets it to 20%. The average stays near one in three, but a dry run of five roads becomes rare.

### 5.2 No two in a row

- A **cooldown of one road** after any detour or hunter ambush. An *owed* detour (from a crisis) pays off on the first road at rest *after* the cooldown, not inside it.
- Landmarks ignore the cooldown (they are the chapter’s promise).

### 5.3 Fewer when time is short, more on long roads

| Factor | Effect |
|---|---|
| A **delivery** with ≤1 day to spare | ×0.3, and a detour on offer shows its time cost; “Leave it” is the default |
| A **delivery** with plenty of time | ×1 |
| A **road** of ≥2 watches (far place) | ×1.3 |
| A **move within a city** (between districts) | ×0.5, and its scenes use the district’s pool |
| The **Dead Heart / the Hollow Shore** (dangerous roads) | ×1 (their atmosphere is already high); but their scenes are written darker |
| A **hunter** or **familiar face** on the road | the detour yields; its slot is not owed |

### 5.4 One memorable detour per chapter

- Each chapter (2 to 7) has a **landmark detour** (section 4.1), written to the chapter’s story.
- **Guarantee:** once the party has taken roads equal to 60% of the chapter’s expected roads without meeting it, the *next* road at rest rumours it, and it is *there* until taken. Players who never leave the road still see it named.
- It is **always rumoured**, never ambush-only.

### 5.5 Costs of getting there

A scene in a **city** (the Saltmouth districts, Candlehold) happens inside the city: **no road, no ration**, a short scene (2 beats). A scene on a **road between places** can use rations and watches (3.3). A scene in an **expedition zone** stays an expedition step: this proposal does not change expeditions.

---

## 6. Who does what

| | **Narrative** [N] | **Core** [C] | **UX** [UX] |
|---|---|---|---|
| **Scene data** | write `detour_scenes.json`: titles, rumours, beats, in EN and FR, for biomes, districts and the chapter landmarks; reword the old lines to stay a good fallback | define and load the schema; validate in `test/` (a guard like `place_pools_test`): every scene has en+fr, 2–4 beats, real places/biomes, valid step types | — |
| **Triggers and timing** | give the timing curve a rationale; supply the list of landmarks and gates | the pity timer, cooldown, long-road and deadline factors, the landmark guarantee; move the roll to “when the road is chosen” | — |
| **Engine** | — | a scene player that runs beats like expedition steps (reuse `expedition_steps.dart`), the “back away” first-beat choice, costs in watches and rations; fall back to today’s chain when no scene matches | — |
| **Journey details** | write the `rumour` line per scene; the heard-of lines that can name a detour | expose the road’s rolled detour and its cost to the panel; the “remembered” detours per route | the route panel row: rumour, cost, risk pip, “Take it / Leave it”; a mark for unknown |
| **The exploration scene screen** | the beat texts (including `place` names) | the data | how a scene looks: the place’s art, a header with the scene title and beat count, the beat card (reuse the expedition step card?) |
| **Gating** | name the flags and conditions | read flags and chapter conditions; the `requires` check | — |
| **Fight-related text** | note the one-foe rule in each fight beat | the foe rule | — |

### Order of work (once validated)

1. **Core:** the schema and loader, the scene player, and the timing (pity timer, cooldown, factors). All with the fallback to today’s chain.
2. **Narrative:** the first batch of scenes — the six landmark scenes, one scene per biome, and the six Saltmouth districts (13 + 6 = about 19 scenes). Small PRs by chapter.
3. **UX:** the route-panel row, then the scene screen.
4. **Narrative:** the second batch (echoes per chapter, gated scenes), then an audit pass on repetition.
5. **QA:** a `qa_` guard for “no two detours in a row” and “each chapter fires its landmark”.

## Decided (the user’s answers)

1. **Opt-in: yes.** A rumoured detour is always optional (*Take it / Leave it*). An unknown one can still arrive as a surprise, and you can back out at its first beat.
2. **Length: a mix.** Some **single-beat stops** alongside the 2–4 beat scenes, so roads don’t slow down. **Proposed share: about 30% one-beat** (stops: a well, a shrine, a stall, a view), **45% two-beat**, **25% three- or four-beat**; every landmark is three or four. Core can tune the draw.
3. **Cost: yes.** One watch when the scene has a fight or a check, nothing for a simple stop (a one-beat event or discovery). A camp-out beat may spend a ration and give more back. **The cost shows before you choose** (section 3.3).
4. **One landmark per chapter: yes.** Six for the first batch (chapters 2 to 7).
5. **City scenes: yes.** Short (one or two beats), no road and no ration. **Start with Saltmouth’s six districts.**

**Next:** the first batch of scenes as data in `assets/gamedata/detour_scenes.json` (six landmarks, one scene per biome plus a few one-beat stops, the six Saltmouth districts), in its own PR with no version bump. It merges with or after Core’s detour engine, and Core reviews the schema first. Core’s detour numbers are in (section 1.5). Alongside the scenes, **a pool top-up** (Narrative, small data PR): at least 6 lines per kind in every place pool, `treasure` lines in every place pool, the Cove camp’s pool by chapter.
