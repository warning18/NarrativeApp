# Tower wording (v2.6.0): clan offers and briefs (draft, for Core to paste)
Draft only; nothing is in `lib/l10n/app_strings.dart`. Keys are proposals, to sit beside the `tower_oath_*` and `tower_merchant_*` blocks; no existing key is renamed. FR passes the lint rules.
Notes: the game's Tower currency is *Ash Marks* (`tower_marks_name`), so the shop lines say marks, not coins. `tower_unlock_*` exists for three clans (Crows, Vigil, Compact); a fourth clan needs its three lines (toast, banner, oath line) written in the same pattern. In FR a clan is “la Veille”, “le Pacte”, “les Corneilles” (short forms of factions.json names).
## 1. Clan offers
All six clans of Core’s plan (Dominion, Vigil, Compact, Mire, Crows, Penitents). Offer cards read +2 for the clan, +1 allies, −1 rivals: the oath line is the only clan text on the card, the numbers are Core’s. Core keeps a refusal at +1 mark.

| key | EN | FR | where |
|---|---|---|---|
| `tower_offer_frame_title` | The clans come to you | Les clans viennent à vous | header of the offer card |
| `tower_offer_frame_body` | Word travels up a staircase faster than a climber. Those who watched you pass have sent someone to the landing. | La rumeur monte un escalier plus vite qu’un grimpeur. Ceux qui vous ont vu passer ont envoyé quelqu’un sur le palier. | under the header |
| `tower_standing_toast_crows` | The Crows think more of you. | Les Corneilles vous estiment davantage. | standing toast |
| `tower_standing_toast_vigil` | The Vigil thinks more of you. | La Veille vous estime davantage. | standing toast |
| `tower_standing_toast_compact` | The Compact thinks more of you. | Le Pacte vous estime davantage. | standing toast |
| `tower_unlock_banner_crows` | A door opens: the Crows think you worthy of their oath. | Une porte s’ouvre : les Corneilles vous jugent digne de leur serment. | oath-unlock banner |
| `tower_unlock_banner_vigil` | A door opens: the Vigil think you worthy of their oath. | Une porte s’ouvre : la Veille vous juge digne de son serment. | oath-unlock banner |
| `tower_unlock_banner_compact` | A door opens: the Compact thinks you worthy of its oath. | Une porte s’ouvre : le Pacte vous juge digne de son serment. | oath-unlock banner |
| `tower_oath_line_crows` | Salt on the rope and a debt on the tide: the Crows will carry you if you carry them. | Du sel sur la corde, une dette sur la marée : les Corneilles vous porteront si vous les portez. | oath card, one line |
| `tower_oath_line_vigil` | The Vigil keeps the count of the dead. Swear, and yours will be kept too. | La Veille tient le compte des morts. Prêtez serment, et le vôtre sera tenu aussi. | oath card, one line |
| `tower_oath_line_compact` | The Compact trades in what burns down. Swear, and it will not trade you. | Le Pacte commerce ce qui brûle. Prêtez serment, et il ne vous vendra pas. | oath card, one line |
| `tower_standing_toast_dominion` | The Dominion thinks more of you. | Le Dominion vous estime davantage. | standing toast |
| `tower_standing_toast_mire` | The Mire Courts think more of you. | Les Cours du Marais vous estiment davantage. | standing toast |
| `tower_standing_toast_penitents` | The Penitents think more of you. | Les Pénitents vous estiment davantage. | standing toast |
| `tower_unlock_banner_dominion` | A door opens: the Dominion thinks you worthy of its oath. | Une porte s’ouvre : le Dominion vous juge digne de son serment. | oath-unlock banner |
| `tower_unlock_banner_mire` | A door opens: the Mire Courts think you worthy of their oath. | Une porte s’ouvre : les Cours du Marais vous jugent dignes de leur serment. | oath-unlock banner |
| `tower_unlock_banner_penitents` | A door opens: the Penitents think you worthy of their oath. | Une porte s’ouvre : les Pénitents vous jugent dignes de leur serment. | oath-unlock banner |
| `tower_oath_line_dominion` | The Dominion keeps the lamps lit and the books closed. Swear, and you are written in both. | Le Dominion garde les lampes allumées et les livres fermés. Prêtez serment, et vous figurerez dans les deux. | oath card, one line |
| `tower_oath_line_mire` | The Courts of the Mire forgive nothing and forget nothing. Swear, and they will remember you kindly. | Les Cours du Marais ne pardonnent rien et n’oublient rien. Prêtez serment, et elles se souviendront de vous avec bonté. | oath card, one line |
| `tower_oath_line_penitents` | The Penitents climb on their knees. Swear, and they will make room on the stair. | Les Pénitents montent à genoux. Prêtez serment, et ils vous feront de la place dans l’escalier. | oath card, one line |

## 2. Heat levels (1–3), name and one line
| key | EN | FR |
|---|---|---|
| `tower_heat_1` | Embers | Braises |
| `tower_heat_2` | Flame | Flamme |
| `tower_heat_3` | Pyre | Bûcher |
| `tower_heat_1_line` | Foes fight as they are. | Les adversaires combattent tels qu’ils sont. |
| `tower_heat_2_line` | Foes hit harder; marks come faster. | Les adversaires frappent plus fort ; les marques tombent plus vite. |
| `tower_heat_3_line` | Foes hit hardest; marks pay in full. | Les adversaires frappent au plus fort ; les marques paient plein tarif. |

Draft lines `_line` match the names: the heat only describes what the numbers do (Core sets them); no number is quoted in the text.

## 3. Daily climb, records
| key | EN | FR | where |
|---|---|---|---|
| `tower_daily_entry` | Today’s climb: the same stairs for everyone. | L’ascension du jour : les mêmes escaliers pour tout le monde. | daily climb, entry line |
| `tower_daily_done` | Today’s climb is done. The stairs reset at dawn. | L’ascension du jour est faite. Les escaliers se rebâtissent à l’aube. | after the run |
| `tower_record_best_floor` | Highest floor | Étage le plus haut | best-run label |
| `tower_record_fastest` | Fastest climb | Ascension la plus rapide | best-run label |
| `tower_record_marks` | Most marks in one climb | Plus de marques en une ascension | best-run label |
| `tower_record_streak` | Longest streak of wins | Plus longue série de victoires | best-run label |
| `tower_record_daily` | Best daily climb | Meilleure ascension du jour | best-run label |

## 4. Merchant lines (paid in Ash Marks)
| key | EN | FR | where |
|---|---|---|---|
| `tower_shop_salve_line` | A salve, still warm from the candle. It costs marks; the Tower does not take silver. | Un onguent encore tiède de la chandelle. Il se paie en marques ; la Tour ne prend pas l’argent. | merchant: salve |
| `tower_shop_potion_line` | Potions, three to a tray. Take two and the third is for the next climber. | Des potions, trois par plateau. Prenez-en deux, la troisième est pour le prochain grimpeur. | merchant: potions |
| `tower_shop_poor_line` | Not enough marks. Come back with ash on your hands. | Pas assez de marques. Revenez avec de la cendre sur les mains. | merchant: cannot afford |
| `tower_shop_bought_line` | Marks counted, ash swept. It is yours. | Marques comptées, cendre balayée. C’est à vous. | merchant: after buying |
| `tower_shop_sworn_line` | You wear their colours; the price is halved, and he does not look up. | Vous portez leurs couleurs : le prix est divisé par deux, et il ne lève pas les yeux. | merchant: sworn half price |
| `tower_shop_leave_line` | The candle gutters behind you. Climb well. | La chandelle vacille dans votre dos. Montez bien. | merchant: leaving |

Size: S. Tag: quick win once Core confirms the keys it uses; the Dart block can be generated from these tables.
