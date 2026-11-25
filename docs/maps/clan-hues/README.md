# The maps in the clans' approved hues (v2.9.5)

Checked on main after the six main clans changed colour (2F6FE0 Dominion,
E0479E Crows, E8782A Compact, 3FB06A Mire, E8C21A Vigil, 9B5DE5 Penitents).
Real screens at 412, Night and Parchment; the epilogue map from its own
screen test.

| Picture | What it shows |
|---|---|
| `01-plans-*` | Saltmouth: Town, the plan page, the plan zoomed in |
| `02-clans-layer-*` | Mid-game World with the Clans layer: near, nearer, whole ball, full map |
| `03-alster-ashen-*` | Alster Town and plan, the Ashen Quarter's plan, its World with the Clans layer |
| `04-epilogue-map.png` | The epilogue map with every clan's towns |

## What holds

- City plans: the holder's tint under the houses, the standing bars and the
  "Held by" dot read well in both looks. The party's gold ring stays clear
  of Crows' pink.
- Clans layer: the wash is brighter than before (Compact went from a brown
  to a full orange) but names keep their plates, the road keeps its dark
  casing, and the legend's seven swatches are easy to tell apart.
- Epilogue map: the nine holders are easier to tell apart than before; the
  clan road in Dominion blue is clear.

## What needs adjusting

The white number on a big town's disc (epilogue map and its list). Contrast
of white on the disc, old colour then new:

| Clan | Old | New | Dark ink on new |
|---|---|---|---|
| Dominion | 5.9 | 4.7 | 3.9 |
| Crows | 6.3 | 3.8 | 4.8 |
| Compact | 4.0 | 2.9 | 6.2 |
| Mire | 4.0 | 2.8 | 6.6 |
| Vigil | 3.2 | 1.7 | 10.6 |
| Penitents | 2.0 | 4.1 | 4.4 |

Vigil's 6 is the weak one; Compact and Mire lean on the number's shadow.
Fix in `epilogue_map_screen.dart` (Maps'): dark ink on a light disc, white
on a dark one, chosen by the disc's brightness. Two places, no colour
changed.

## Not seen

Only Compact's and Crows' lands are reached in the scenes pictured, so the
Clans layer wash of Vigil yellow, Mire green, Dominion blue and Penitents
violet over a whole land was not pictured.
