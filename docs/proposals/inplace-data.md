# The in-place data: who you face, what the scene asks, what a hub choice is about (Narrative)

The data UX asked for in `docs/proposals/inplace-choices.md` ("What I need"). All fields are plain and optional in `Cleaned_Narrative_DAG.json`; a node or choice without them reads as before.

| Field | On | Meaning | Count |
|---|---|---|---|
| `facing` | a node | the id of who the scene is with: an NPC (`npcs.json`), a companion (`companions.json`) or an enemy (`enemies.json`). Absent for a narrator-only node and for every hub (a hub is the map). | 94 |
| `prompt`, `prompt_fr` | a node | one short line for the question the scene ends on ("How do you get aboard?"). Written for every scene with two or more choices that is not a hub. The French has its no-break space before `?`. | 226 |
| `about` | a hub's choice | who or what the choice is about: an NPC id, a clan id (`factions.json`) or a sub-clan id (`subclans.json`). The label comes from that record. Absent when the choice is about nothing in particular. | 69 |

**How `facing` was set.** From the NPC records' `metNodes` first. Failing that, from the enemy a scene's fight names, but only when the scene has three choices or fewer and all its fights name the same enemy; scenes about a clan's people (`*_house_*`, `*_clan_*`) take no enemy face, since the person you speak to there is not the foe. A first pass: where it is wrong or empty UX falls back to the narrator view, and I correct it as it is seen.

**Hubs.** Twenty nodes are hubs (a settlement or a progress counter). The Reliquary Quarter (6010) has 28 choices and 69 `about` values cover the hubs together; choices that lead to a scene about no one in particular carry none, and UX can group them under "Other" or by Core's action.

**What UX does with a missing value.** `facing` empty: the narrator scene. `prompt` empty: the last sentence of the text. `about` empty: group by action.

## Update (v1.442, main-story pass)

Core's rule for a main-story scene (not a hub, not a hub's errand, not a camp scene) gives about 120 scenes. Every one with two or more choices already had a `prompt`. This pass added:

- `facing` on 10 more nodes: `105` (the bouncer), `270` (the warhound), `2030`, `2040_paid`, `2070`, `2070_cut_failed` (Vane the quartermaster), `4999`, `4999_standard`, `4999_drawn` (the High Warden), `7520_vane` (Aurel Vane). Where the person has no record (the mate, the yard-master, the tally-boy, the archivist) the scene stays narrator-only, and where who is there depends on the origin (Lysa aboard the Lark) it does too.
- `prompt` / `prompt_fr` on the 14 hubs a sheet opens on (`2015`, `3005`, `5010`, `6010`, `7002`, the eight villages' hubs, `7100`, `7500`): "What do you do in Rimewell?". The camp nodes keep the Camp screen and have none.

Totals now: `facing` on 104 nodes, `prompt` on 243.
