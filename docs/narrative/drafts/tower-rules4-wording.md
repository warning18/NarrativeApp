# Tower rules 4: wording for the gamble, the stat pick and the hints

Core's PR #1214 (v2.10.36) defines four placeholder keys; they are not on `main` yet, so this branch (`claude/narrative-r4`) cannot edit them. Core or UX applies the four rewordings below when the PR lands. The new keys (outcome names and lines, the Perception hints) are already in `lib/l10n/app_strings.dart` on this branch. No figure appears in any line (Core may tune the shares, the tiers, the coins).

## The four placeholders (reword in #1214's keys)

| key | EN | FR |
|---|---|---|
| `tower_kind_gamble` | Gamble | Pari |
| `tower_gamble_name` | A card laid face down | Une carte posée face cachée |
| `tower_kind_stat_pick` | Training | Entraînement |
| `tower_stat_pick_name` | A stat of your choice, a little stronger | Une caractéristique de votre choix, un peu plus forte |

`tower_kind_gamble` and `tower_kind_stat_pick` stay as Core drafted them (they read well). Only the two names change: the old ones carried “+1”, a figure Core may tune.

## The new keys (in app_strings.dart on this branch)

The name (`tower_gamble_<outcome>`) is shown on the card's back when the hero's Perception reads what it is (`tower_gamble_hint_kind`); the line (`tower_gamble_<outcome>_line`) is shown when the card is turned over.

| outcome | name EN / FR | line EN / FR |
|---|---|---|
| gilded | Gilded / Dorée | The best of the spoils comes from a finer chest than it looked. / Le meilleur du butin sort d’un coffre plus beau qu’il n’y paraissait. |
| twin | Twin / Jumelle | Beneath it, both the other cards: take them all. / Dessous, les deux autres cartes : prenez-les toutes. |
| hoard | Hoard / Magot | A hoard of coins was tucked in behind it. / Un magot de pièces était glissé derrière. |
| dud | Dud / Fausse carte | Nothing. It was only a card. / Rien. Ce n’était qu’une carte. |
| wound | Wound / Blessure | It bites: you lose a good part of your health. / Elle mord : vous perdez une bonne part de vos forces. |
| spill | Spill / Fiole brisée | A flask spills in your bag; with none to spill, it costs you health. / Une fiole se renverse dans votre sac ; sans fiole, cela vous coûte des forces. |
| bright | Bright / Éclat | The skill shines a rarity higher. / La compétence brille d’une rareté de plus. |
| hex | Hex / Mauvais sort | A hex: the next floor’s foes will be tougher. / Un mauvais sort : les adversaires du prochain étage seront plus coriaces. |

| hint key | EN | FR |
|---|---|---|
| `tower_gamble_hint_good` | It feels lucky. | Elle semble porter chance. |
| `tower_gamble_hint_bad` | Something about it feels wrong. | Quelque chose en elle sonne faux. |
| `tower_gamble_hint_kind` | You can tell what it is: {name}. | Vous devinez ce que c’est : {name}. |

`{name}` is the outcome name above. Gilded, Twin, Hoard and Bright read as good; Wound, Spill, Hex and Dud as bad (Core counts Dud bad).
