# Names for the Smugglers' Quay buildings (Narrative, list for the mocks)

Status: **a list, no data change.** For the district-places and map-first mocks, and for the user to read. If they approve, the names go into `city_plans.json` (`names`) in a small data PR with a version.

The seven buildings below have scenes at them but no name today. The Wharf's named buildings use the same style: *The harbor master's office*, *The bounty door*, *The captain's moorings*, *The Crow tout's corner*, *The spoiled-cargo crate*. The French follows the wharf's own words (*maître du port*, *Quai des Contrebandiers*, *douane*).

| Building | Kind | Scene(s) there | EN | FR | Why this name |
|---|---|---|---|---|---|
| `saltmouth_b157` | warehouse | 2030, Vane takes the bribe | **Vane's barrel** | **Le tonneau de Vane** | He tosses the iron key onto "the barrel between us". |
| `saltmouth_b171` | warehouse | 2040, Vane's crossbow and guards | **Vane's guard corner** | **Le coin des gardes de Vane** | His guards come on you "from behind". |
| `saltmouth_b149` | warehouse | 2011, pushing past Vane | **The wet boards** | **Les planches mouillées** | "Boots slapping wet boards", the rats underfoot in the dark. |
| `saltmouth_b168` | warehouse | 2010_crane, the jammed winch | **The loading crane** | **La grue de chargement** | The scene's own words ("the loading crane's jammed winch"). |
| `saltmouth_b147` | house | 2010_liora, the raiding skiff | **The old customs house** | **L'ancienne douane** | The skiff "lay tied under the old customs house". The skiff is the scene; the building is the customs house. |
| `saltmouth_b158` | warehouse | the hub 2015 itself, 2015_ternrow_door, 2015_alleys_door | **The wharf steps** | **Les marches du quai** | The hub scene is anchored here too, and both doors start at "the steps from the wharf": the drawn-up footbridge to Tern Row, and the first arch of the Lantern Alleys. A name tied to the footbridge alone would be wrong for the hub. |
| `saltmouth_b163` | warehouse | 2010, the quartermaster at the shipyard gate | **The shipyard gate** | **La porte des chantiers** | Not asked for, but it is the first scene of the Wharf; "a scarred quartermaster blocked the gate to the shipyards". |

## The lines for `names`

```json
"saltmouth_b157": { "en": "Vane’s barrel", "fr": "Le tonneau de Vane" },
"saltmouth_b171": { "en": "Vane’s guard corner", "fr": "Le coin des gardes de Vane" },
"saltmouth_b149": { "en": "The wet boards", "fr": "Les planches mouillées" },
"saltmouth_b168": { "en": "The loading crane", "fr": "La grue de chargement" },
"saltmouth_b147": { "en": "The old customs house", "fr": "L’ancienne douane" },
"saltmouth_b158": { "en": "The wharf steps", "fr": "Les marches du quai" },
"saltmouth_b163": { "en": "The shipyard gate", "fr": "La porte des chantiers" }
```

## Notes

- The manager's list said five buildings and named six spots (Vane's three, the crane, Liora's skiff, the footbridge door); I added the shipyard gate as the seventh.
- If the fewer-quests pilot goes ahead, the two doors become one scene: `saltmouth_b158` is already shared by both, so "The wharf steps" stays right.
- "The old customs house" is a *house*-kind building in the plan; if the mock wants the skiff itself as the pin, the pin label can be "The raiding skiff" and the building keeps the customs house name.
- Nothing here changes a scene, a quest or a number. Names only.
