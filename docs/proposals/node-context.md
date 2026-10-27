# Node context: where, when, who, mood (proposal)

Status: **proposal, nothing built.** Waiting for the manager's OK, then the
data goes in as its own PR with a version.

## What exists today

Every node already carries some of this, and the code reads it:

| Field | Now | Used by |
|---|---|---|
| `location` | a geography id (35 distinct in ch1–3) | map, scene art, `lib/models/story_node.dart` |
| `spot` | a spot inside the place (`floor`, `door`, `guard`, `cells`, `stacks`) — set on 27 of 182 nodes | scene staging |
| `facing` | an npc or enemy id (52 of 182) | the portrait |
| `context_taxonomy.ui_theme` | a place tag (`docks`, `cathedral`, `slums`, …) | palette (`ui_theme_palettes.dart`) |
| `context_taxonomy.mood` | `neutral` / `tense` / `action` / `tender` / `grim`… | `sub_node_engine.dart` |
| `settlement` | on 6 nodes | town/camp discovery |

What is missing: the district and building behind `location`, whether the
scene is inside or out, the hour, the weather, **who is in the room besides
the one the portrait faces**, and a hint for the camera. Writers, UX and the
engine each guess those from the prose today.

## Proposed: one optional `scene` block

All fields optional; a node without `scene` behaves exactly as now. Ids only,
no text, so nothing needs an FR twin.

```json
"scene": {
  "district": "saltmouth_card_row",
  "building": "saltmouth_b042",
  "kind": "inside",
  "time": "dusk",
  "weather": "rain",
  "season": "autumn",
  "present": ["voss", "sable"],
  "mood": "tense",
  "camera": "close"
}
```

| Field | Values | Source of ids |
|---|---|---|
| `district` | a district id | `city_plans.json` → `districts` (e.g. `saltmouth_card_row`) or a geography id |
| `building` | a building id, or `doorstep:<building>` | `city_plans.json` → `buildings`; `anchors` already maps scene → building for 2015_* |
| `kind` | `inside` · `street` · `road` · `water` · `underground` | fixed list |
| `time` | `dawn` · `day` · `dusk` · `night` | fixed list; omitted = unspecified |
| `weather` | `clear` · `rain` · `fog` · `ash` · `storm` · `snow` | fixed list; `ash` is the Spire's fall |
| `season` | `spring` · `summer` · `autumn` · `winter` | only where the prose names one |
| `present` | npc ids from `npcs.json`, companion ids from `companions.json` | existing ids; `facing` stays the one the portrait shows |
| `mood` | same tags as `context_taxonomy.mood` | **no new field:** read the existing one; `scene.mood` is only an override when the scene turns mid-way |
| `camera` | `wide` · `close` · `low` · `over` · `static` | UX's vocabulary; a hint, UX may ignore it |

`location` and `facing` are not duplicated: `scene.district` / `building`
refine `location`, `present` extends `facing`.

## Size

- Chapters 1–3: **182 nodes** (49 are `2015_*` Saltmouth scenes, 35 are `3005_*`, 22 clan scenes in 3100–3200).
- 35 distinct `location` values, so ~35 `district`/`building` lookups, not 182.
- Of the 182, `time` is stated or implied in roughly 60, `weather` in about 25; the rest stay empty on purpose.
- The other chapters can follow the same way in later PRs.

## Ten sample nodes

| Node | scene |
|---|---|
| `100` Blind Beggar, the back room | `{district: alster_lower_town, building: blind_beggar, kind: inside, time: night, present: [], camera: close}` |
| `250` Alster kneels | `{district: alster_lower_town, kind: street, time: dusk, weather: ash, camera: wide}` |
| `470` the ruined house | `{district: alster_lower_town, building: alster_family_house, kind: inside, time: dawn, weather: ash, present: [old_hesk]}` |
| `800` Black Hold | `{building: black_hold_cells, kind: underground, time: night, present: [brother_clement], camera: low}` |
| `890_trainer` quay drill | `{district: alster_high_quay, kind: street, time: dawn, present: [], camera: wide}` |
| `2005` landward gate | `{district: saltmouth_landward_gate, kind: street, time: day, present: [crape_courier], camera: wide}` |
| `2015_crow_offer` | `{district: saltmouth_wharf, kind: street, time: dusk, camera: over}` |
| `2015_ternrow` | `{district: saltmouth_tern_row, kind: street, time: day, present: [renn], camera: static}` |
| `2015_sable_lifted` | `{district: saltmouth_card_row, kind: street, time: night, present: [sable]}` |
| `3001_camp` | `{district: the_cove, building: cove_camp, kind: street, time: dusk, weather: clear, camera: wide}` |

(Times and weather here are read from the prose; I will re-read each scene
when the real PR is built.)

## What it needs

**Narrative (me):** fill the block for chapters 1–3 after the OK; check each
id against geography and `city_plans.json` with a script, so a typo cannot ship.

**Core:** a loader for the optional block in `lib/models/story_node.dart`
(parse, keep on round-trip, `null` when absent), and a test that every id in
`scene` exists. Nothing in the game's rules reads it; no node breaks if the
block is absent. The story editor should keep the block on save (the same
gap `returnToCamp` had).

**UX:** decide what to do with `time`, `weather`, `kind` and `camera` (tint,
rain overlay, framing). Nothing is required of UX; the data is useful as soon
as one of them reads it. If UX wants other `camera` or `weather` words, say
so before the data is written.

## Questions for the manager

1. OK to add the `scene` block, with `mood` staying in `context_taxonomy`?
2. Core slot for the loader and the id-check test, before or with my data PR?
3. Chapters 1–3 only first (182 nodes), as asked?
