# Story scene bands: final pack (hand-off for UX-2)
5 bands, 240x100 PNG8 (32 colours), keyed by the DAG `location` id (`Cleaned_Narrative_DAG.json`), picks in `picks.json` (the user's choice; seeds s4/s3/s3/s3/s4). 0 generations. Nothing wired.

| location id | file | covers |
|---|---|---|
| `alster_lower_town` | alster_lower_town.png | prologue, 3 nodes (also reasonable for `alster_high_quay`, `alster_family_house` if UX wants) |
| `cove_camp` | cove_camp.png | 39 nodes, the most used location |
| `saltmouth_wharf` | saltmouth_wharf.png | night wharf |
| `black_hold_cells` | black_hold_cells.png | the cells |
| `candlehold_throne_room` | candlehold_throne_room.png | the throne room |

Hollow Shore: no scene for now (the user's pick: neither). The other 68 places: not now, see these 5 in the game first.
Wiring suggestion: a band at the top of a story node, scaled by whole pixels with nearest-neighbour filtering (`FilterQuality.none`), full width, 2.4:1; no band when the location has no file.
Checked for baked text and odd details (as with the intro): none readable in any of the five. Black Hold has a dark rounded vignette baked into its corners (part of the picture; crop 2 px if UX prefers a clean edge).
