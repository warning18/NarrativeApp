# The in-place data: who you face, what the scene asks, what a hub choice is about (Narrative)

The data UX asked for in `docs/proposals/inplace-choices.md` ("What I need"). All fields are plain and optional in `Cleaned_Narrative_DAG.json`; a node or choice without them reads as before.

| Field | On | Meaning | Count |
|---|---|---|---|
| `facing` | a node | the id of who the scene is with: an NPC (`npcs.json`), a companion (`companions.json`) or an enemy (`enemies.json`). Absent for a narrator-only node and for every hub (a hub is the map). | 87 |
| `prompt`, `prompt_fr` | a node | one short line for the question the scene ends on ("How do you get aboard?"). Written for every scene with two or more choices that is not a hub. The French has its no-break space before `?`. | 218 |
| `about` | a hub's choice | who or what the choice is about: an NPC id, a clan id (`factions.json`) or a sub-clan id (`subclans.json`). The label comes from that record. Absent when the choice is about nothing in particular. | 70 |

**How `facing` was set.** From the NPC records' `metNodes` first. Failing that, from the enemy a scene's fight names, but only when the scene has three choices or fewer and all its fights name the same enemy; scenes about a clan's people (`*_house_*`, `*_clan_*`) take no enemy face, since the person you speak to there is not the foe. A first pass: where it is wrong or empty UX falls back to the narrator view, and I correct it as it is seen.

**Hubs.** Twenty nodes are hubs (a settlement or a progress counter). The Reliquary Quarter (6010) has 28 choices and 70 `about` values cover the hubs together; choices that lead to a scene about no one in particular carry none, and UX can group them under "Other" or by Core's action.

**What UX does with a missing value.** `facing` empty: the narrator scene. `prompt` empty: the last sentence of the text. `about` empty: group by action.
