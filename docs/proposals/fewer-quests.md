# Fewer quests to pick from (Narrative, proposal)

Status: **proposal, no edits.** The user approves the target and the pilot first.

The user's words: keep the story content, but have fewer quests (fewer entries to pick from at a place and in a district). The rows they pointed at, in the Smugglers' Quay list ("Accept the harbour master's job", "Deal with a smuggler captain on the watch", "Separate two harbour rats over a spoiled cargo", "Look across the gangway toward Tern Row"), are **hub errands**: the choices of a town's hub scene (here node `2015`) that open one short scene each. They are not entries of `quests.json`.

## 1. The numbers

Counted from the story file and `city_plans.json` (a scene's district is its anchor's building's district). An *entry* is one choice of a hub scene that leads to an errand or a story way; *single-scene* means the errand is one node that returns to the hub.

### All hubs

| Chapter (game) | Hubs | Entries | Single-scene |
|---|---|---|---|
| 2 Saltmouth | 2015 | 38 | 27 |
| 3 Ashen Quarter, Emberwick, Akagiri | 3005, 3100, 3200 (+ camp 3001) | 26 + 9 + 7 + 1 | 23 + 8 + 6 |
| 4 Drowned Cloister, Wrack's End, Kindly Hill | 5010, 5100, 5200 (+ 4999 camp) | 21 + 15 + 8 + 1 | 18 + 12 + 6 + 1 |
| Chapters 2–4 | 9 hub scenes | **126** | **101** |
| Chapters 5–7 and the end | 6010, 6100, 6200, 7100, 7200, 7400, 7500, 7800, 7002 | 127 | 106 |

In chapters 2–4, of the 126 entries 98 are talks, 16 fights, 9 open a quest, 3 open a shop. About 80% are one scene that returns to the hub. Only 94 of the 126 are open at the start; the rest wait for a flag.

### Busiest places, chapters 2–4

(entries in all / open at the start / single-scene; a place here is a district of the city plan, or the village's place.)

| # | Place | Hub | All | Open at start | Single-scene |
|---|---|---|---|---|---|
| 1 | Smugglers' Wharf (Saltmouth) | 2015 | 13 | 11 | 8 |
| 2 | Ash Market (Ashen Quarter) | 3005 | 12 | 8 | 12 |
| 3 | Drowned Cloister, nave | 5010 | 8 | 6 | 8 |
| 4 | Wrack's End, hull houses | 5100 | 8 | 4 | 7 |
| 5 | Tern Row | 2015 | 7 | 6 | 6 |
| 6 | Drowned Cloister, ossuary | 5010 | 7 | 3 | 4 |
| 7 | Spire Stair (Ashen Quarter) | 3005 | 7 | 4 | 7 |
| 8 | Landward Gate | 2015 | 6 | 6 | 4 |
| 9 | Drowned Cloister, stair | 5010 | 6 | 4 | 6 |
| 10 | Kindly Hill, hall | 5200 | 5 | 4 | 5 |
| 11 | Card Row | 2015 | 5 | 3 | 3 |
| 12 | Wrack's End, quay | 5100 | 4 | 3 | 3 |
| 13 | Emberwick, kilns | 3100 | 4 | 4 | 4 |
| 14 | Wall of Names | 3005 | 4 | 4 | 2 |
| 15 | The Ship-breaker's Yard | 2015 | 4 | 3 | 3 |
| 16–20 | Fen edge, lamp path, Akagiri springs, Akagiri forge terrace, Emberwick smithy lane, Lantern Alleys | | 3 each | | |

27 places in all; 5 are above 5 open entries at the start (the Wharf 11, Ash Market 8, Landward Gate 6, Tern Row 6, the nave 6).

### Quests (`quests.json`)

51 quests: 32 side, 13 main, 6 nemesis. 44 have one objective, 6 have two, 1 has three, so almost all are short. 41 are opened by a choice (`unlockQuestId`). 12 are tied to a district for the wave 18 holding (`district`, `faction`); none is read by an achievement by id. The quests are not what makes the list long: the **entries** are.

I did not recount the 1,030 "ways in the planned cities" (the manager's figure, from the street and district views); these numbers are hub entries.

## 2. What can fold, what must stay

**Can fold without losing content**
- **A quest chain at one giver** into one entry. The Wharf's harbor master has quests that already chain (`q_ch2_dockside_debts` → `smugglers_favor` → `burning_manifest` → `captains_gambit` → `harbor_reckoning`), and the Wharf shows three rows for them (the job, the captain, the bounty on the bandits), plus the rats. One entry, "The harbor master's work", opens the step the party is on. (The last quest's row, the plague hound, is at the Yard, another district, and stays there.)
- **Doors and looks**: "try the first arch of the Lantern Alleys", "look across the footbridge to Tern Row" are two doors off one wharf. One scene, two ways.
- **The ways of one confrontation shown as hub rows**: "Bribe Vane", "Threaten him", "Push past him" are three choices of one scene; the hub can show one row, "Deal with Vane at the gate", and the three ways move into a scene.
- **Flavour looks with no flag** ("Look at the blades on the Inquisitors' belts", "Follow the child who is talking to the gulls") when two or three share a district: one "Walk the wharf" scene, each look a way inside it that plays its own text.
- **Pure errands that only differ by the enemy or a small number** (two fights at one giver for gold of the same size).

**Must stay as its own entry**
- anything that sets a flag other nodes read, flips or holds a district or a clan standing, an intrigue stage, a companion beat, a loyalty scene, a roll with its own failure scene, a shop, the main story's ways.
- any quest an achievement, the simulator, or another quest names.

## 3. Target

- **At most 5 open entries at a place at once** (the story's own ways to the next scene count in the 5), at most 8 per district over a playthrough.
- It takes the 5 places above 5 down to 5. Open entries removed: **12** (the Wharf 6, Ash Market 3, and one each at the Gate, Tern Row, the nave). Entries in all removed: about **20** of 126 in chapters 2–4 if the same folds apply at the places over 5 (the Wharf 13 → 7, Ash Market 12 → 8, Spire Stair 7 → 5, the nave 8 → 5, the ossuary 7 → 5, hull houses 8 → 5, stair 6 → 5, Tern Row 7 → 5). Content removed: none.
- Chapters 5–7 follow the same rule, in a second step.

## 4. How a fold keeps its content

- The merged scene carries every beat: each of the old errands becomes a **step** (a node in the same place) reached from the merged entry, in order, the first step's end opening the next.
- **Rewards stay**: each step keeps its own choice with its own gold, items and `unlockQuestId`/`questIDToProgress`. Core sets the numbers; I move no number. If two rewards ever need to be combined, I list them for Core first.
- **Flags stay**: `hub_2015_dockside`, `hub_2015_smuggler`, … are still set, on the step that earns them, so every `hideIfFlags` / `showIfFlags` that reads them still works. Where two harmless flags are always earned together, both are set by the one step; where they differ, an inner choice sets the right one.
- **Quest ids stay**: the quest chain is untouched; only the hub rows that hand quests out are grouped. The journal text (`quests.json`) is not changed; it already describes each quest.
- **The entry is picked by flags**: the merged entry opens the earliest unfinished step; when the chain is done the entry hides (`hideIfFlags` of the last step's flag).

## 5. Risks

- `quest_rewards_test`, `turn_in_choices_test`: unchanged as long as no quest or reward moves.
- **Achievements and the 12 district-held quests** (wave 18): the holding is read from the quest's `district` and `faction`, and from `held_`/`flipped_` flags; steps keep the same quest ids, so the holding is unaffected. The hub `hub_progress` lines (`after: N`) count flags, so they must be re-checked against the new number of steps.
- **The simulator's pinned tuple** (`sim_competent_test`, `sim_companions_test`) and the naive run's choices hash: they will move, because the extra nodes move the dice, as at v1.577. I re-pin with a note, as before.
- **The competent player** takes quests offered; a merged entry changes what it is offered at a time. Core should check its policy still picks every quest.
- **`qa_` blocking-nodes guard** and `story_rules`: every new step needs a way back; I would run them for each fold.
- **Core's presentation contract**: the merged entry is one pin; the steps are scenes at the same building, so `scene.kind` / `building` stay valid. Core would need to know the new ids.
- **Saves**: a save inside an old errand (`2015_smuggler`, …) must still load. The old node ids stay as the steps, so saves are safe.
- The page-turn field (`page_turn`, v1.577) is a separate tool; I might use it for the merged entry's intro page.

## 6. Pilot: Smugglers' Wharf, Saltmouth

### Before (13 rows at the start, 11 open)

| # | Row (hub choice) | Node | What it is |
|---|---|---|---|
| 2 | Take the harbor master's job | `2015_dockside` | errand; opens `q_ch2_dockside_debts`; fights a harbor rat |
| 3 | Deal with a lurking smuggler captain | `2015_smuggler` | errand; opens `q_ch2_captains_gambit`; fights the captain |
| 5 | Break up two harbor rats over spoiled cargo | `2015_rats` | errand; fights two rats |
| 6 | Answer the harbor master's bounty on the wharf bandits | `2015_bandits` | errand; opens `q_ch2_burning_manifest`; fights two bandits |
| 21 | Buy a quiet route from a Crow tout | `2015_route_sold` | intrigue stage (`double_ledger`), Crow standing, 3 ways |
| 31 | Ask the Tide Cellar's fence about the girl | `2015_lysa_line` | shown only if Lysa was lost; pay, threaten, or leave; sets `lysa_trail_ledger` |
| 32 | Try the first arch of the Lantern Alleys | `2015_alleys_door` | a door; two ways |
| 33 | Look across the footbridge to Tern Row | `2015_ternrow_door` | a door; opens `q_ch2_terns_toll` |
| 26 | Bribe Vane with information | `2030` | story way |
| 27 | Threaten him to clear the path | `2040` | story way |
| 28 | Push past him toward the exit | `2011` | story way |
| 29 | Force the loading crane's jammed winch open | `2010_crane` | story way, a roll |
| 30 | Follow Liora to the captain's raiding skiff | `2010_liora` | story way, if Liora was met |

(The hound row, 4, `q_ch2_harbor_reckoning`, is at the Ship-breaker's Yard, not here.)

### After (7 rows at the start, 5 open)

| # | Row | What it opens | Content kept |
|---|---|---|---|
| 1 | **The harbor master's work** | the step the party is on: the job (`2015_dockside`) → the rats (`2015_rats`) → the captain (`2015_smuggler`) → the bounty (`2015_bandits`) | all four scenes and fights, the three quests they open and their order, flags `hub_2015_*` |
| 2 | Buy a quiet route from a Crow tout | `2015_route_sold`, unchanged | the intrigue stage, the Crow standing, `plot_ledger_1` |
| 3 | Ask the Tide Cellar's fence about the girl | `2015_lysa_line`, unchanged, only if Lysa was lost | `lysa_trail_ledger`, the gold, the alignment |
| 4 | **Two doors off the wharf** | one scene: the first arch of the Lantern Alleys, the footbridge to Tern Row | both doors, `q_ch2_terns_toll`, both `hub_2015_*_door` flags |
| 5 | **Vane at the gate** | a scene whose three ways are bribe, threaten, push past | `2030`, `2040`, `2011` unchanged |
| 6 | Force the loading crane's jammed winch open | `2010_crane`, unchanged | the roll |
| 7 | Follow Liora to the captain's raiding skiff | `2010_liora`, unchanged, if Liora was met | |

At the start the player sees 5 rows (1, 2, 4, 5, 6; the fence and Liora appear only for their flags): 11 → 5. In all 13 → 7.

What the player experiences: the harbor master is one person with one standing job. They take it, finish it, return, and the next piece of work is on offer, as the quest chain already says. Everything that happened before still happens; only the list is shorter.

New scenes to write: the entry scene of the harbor master's work (one short page, EN/FR), the "two doors" scene, the "Vane at the gate" scene. The five errands' own text and choices do not change. Net: 10 old rows (2, 3, 5, 6, 32, 33, 26, 27, 28) become 3 new rows, so 13 rows become 7 (six fewer); three short scenes are new.

**Asks for the manager, if the user approves:** which Core numbers I touch (none in this pilot); the simulator re-pin after the fold; and the order of the other towns (Ash Market next, then the Drowned Cloister).
