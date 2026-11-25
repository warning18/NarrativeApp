# Tower: the late oath offer (v2.8.0), one line per clan (draft)

Draft only, nothing is in `app_strings.dart`. Since v2.8.0 a climb with no oath is offered its best clan's oath from floor 16 even below standing 6/6. These lines say why, in the voice of the clan's envoy, on the offer card. EN and FR; FR passes the lint rules. No floor number is quoted, so Core can move the threshold without touching the text.

## Per-clan lines (recommended: the voice differs and it is cheap)

| key | EN | FR |
|---|---|---|
| `tower_oath_late_dominion` | You have climbed far with no banner. The Dominion does not leave a lamp unlit. | Vous avez gravi bien des étages sans bannière. Le Dominion ne laisse aucune lampe éteinte. |
| `tower_oath_late_vigil` | Halfway up the Tower, and nobody has kept your count. The Vigil will. | À mi-hauteur de la Tour, et personne n’a tenu votre compte. La Veille le tiendra. |
| `tower_oath_late_compact` | Whoever climbs with no sworn ledger is a debt nobody holds. The Compact will hold yours. | Qui monte sans livre juré est une dette que personne ne tient. Le Pacte tiendra la vôtre. |
| `tower_oath_late_mire` | You have climbed far without a banner. The Mire will not wait for you to ask. | Vous avez gravi bien haut sans bannière. Les Cours du Marais n’attendront pas que vous demandiez. |
| `tower_oath_late_crows` | Far up, with no flag to carry. The Crows keep a perch for that. | Si haut, et sans pavillon à porter. Les Corneilles gardent un perchoir pour cela. |
| `tower_oath_late_penitents` | You climb as if you owed someone. The Penitents know the feeling, and they have room to kneel. | Vous montez comme si vous deviez quelque chose à quelqu’un. Les Pénitents connaissent cela, et ils ont de quoi s’agenouiller. |

## One shared line (fallback)

| key | EN | FR |
|---|---|---|
| `tower_oath_late` | You have climbed far without a banner. {clan} will not wait for you to ask. | Vous avez gravi bien haut sans bannière. {clan} n’attendra pas que vous demandiez. |

The shared FR line only works when `{clan}` is singular (“le Dominion”, “la Veille”, “le Pacte”, “les Corneilles” and “les Pénitents” would need “attendront”): use the per-clan lines, or a plural-aware template.

Placement is UX's (picture first): one line under the oath card's title, in the clan's colour, shown only on a late offer.
