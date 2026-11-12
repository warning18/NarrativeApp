# City plans: which tool to run

`assets/gamedata/city_plans.json` holds the plan of every town, village and
camp. Three tools in `tool/city_plans/` write it.

| Tool | What it does | Safe to run? |
|---|---|---|
| `turn_city_plans.dart` | Turns each stored plan so its sea lies on its side of the coast (`citySeaSides` in `city_plan_generator.dart`), then pins the services again. Each plan's side is stored in its `seaSide` field, and a plan already on its side is left as it is. | Yes, any number of times |
| `place_services.dart` | Pins each town's services again on its stored plan | Yes |
| `gen_city_plans.dart` | Lays every plan out again from scratch | **No, not for now** |

## Do not regenerate the plans

`gen_city_plans.dart` no longer reproduces `city_plans.json`. On v1.939, a
fresh run changes the anchors, names or services of 15 of the 16 plans
(only White Wells comes out the same). That is the hand edits and story
moves made since the plans were last laid out. Running it would undo them.

Until the generator is brought back in step (a later task, Core's), change
the stored plans with the two safe tools above, or by hand.

## The sea side (v1.941)

A plan is laid out with its sea to the south. Maps read each coastal place's
coast on the story chart (`chart_story.dart`): the bearing of the nearest
coast and the share of sea within 16 units in each quarter. From that, three
plans have their sea to the north and are turned by a half turn around
(500, 500):

- Saltmouth
- Greyhithe
- the White Anchorage

Every other plan keeps its sea to the south. Candlehold, the Drowned
Cloister, Wrack's End, Cove Camp and Kindly Hill were all read as south.

A turn changes every point of the plan and each bridge's angle:
- the points: `sea`, `rivers`, `islands`, `canals`, `wall` (runs, gates' `at`,
  towers), `avenues`, `streets`, `bridges` (`at`), `squares`, `districts`
  (`shape`, `label`, `entry`) and `buildings` (`shape`);
- each bridge's `angle`, which gains 180° and is kept in (-180, 180].

The `services` are then pinned again on the turned plan, as
`place_services.dart` pins them, so a pin can sit a unit off the old one
turned (Saltmouth's forge: 252 rather than 253).

Ids (the gates' among them, so `gate_northwest` keeps its name), `names`,
`anchors`, `seed` and the widths and lengths stay as they are.
