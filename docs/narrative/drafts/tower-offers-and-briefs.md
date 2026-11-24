# Tower wording (v2.6.0): clan offers and briefs (draft, for Core to paste)
Draft only; nothing is in `lib/l10n/app_strings.dart`. Keys are proposals, to sit beside the `tower_oath_*` and `tower_merchant_*` blocks; no existing key is renamed. FR passes the lint rules.
Notes: two currencies. *Ash Marks* (`tower_marks_name`) last between runs and buy unlocks; *Tower coins* are earned inside a run, lost at its end, and buy rerolls, banishes and the merchant's stock (Core spec `tower-briefs-6-7-8-spec.md`, option A). The shop lines below are in coins; `tower_merchant_wallet` keeps its key and changes its text to coins. `tower_unlock_*` exists for three clans (Crows, Vigil, Compact); a fourth clan needs its three lines (toast, banner, oath line) written in the same pattern. In FR a clan is “la Veille”, “le Pacte”, “les Corneilles” (short forms of factions.json names).
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
| `tower_heat_0` | The plain climb | L’ascension simple |
| `tower_heat_locked` | Win the top at {heat} to open | Gagnez au sommet (niveau {heat}) pour ouvrir |
| `tower_heat_marks` | Marks +{n}% | Marques +{n} % |
| `tower_heat_opened` | {heat} is open | Niveau ouvert : {heat} |
| `tower_heat_chip` | {n} | {n} |
| `tower_heat_1_line` | Foes hit a little harder; marks come a little faster. | Les adversaires frappent un peu plus fort ; les marques tombent un peu plus vite. |
| `tower_heat_2_line` | Foes hit harder; marks come faster still. | Les adversaires frappent plus fort ; les marques tombent encore plus vite. |
| `tower_heat_3_line` | Foes hit hardest; marks pay in full. | Les adversaires frappent au plus fort ; les marques paient plein tarif. |

Draft lines `_line` match the names: the heat only describes what the numbers do (Core sets them); no number is quoted in the text.

## 3. Daily climb, records
| key | EN | FR | where |
|---|---|---|---|
| `tower_daily_entry` | Today’s climb: the same stairs for everyone. | L’ascension du jour : les mêmes escaliers pour tout le monde. | daily climb, entry line |
| `tower_daily_done` | Today’s climb is done. The stairs reset at dawn. | L’ascension du jour est faite. Les escaliers se rebâtissent à l’aube. | after the run |
| `tower_daily_button` | Daily climb | Ascension du jour | start screen panel action |
| `tower_daily_one_attempt` | One attempt a day. Leaving counts. | Une tentative par jour. Partir compte. | daily panel |
| `tower_daily_hero` | Today: {race} {profession} | Aujourd’hui : {race} {profession} | daily panel, the day's hero |
| `tower_daily_chip` | Daily | Du jour | floor header chip |
| `tower_record_new` | New record | Nouveau record | end screen |
| `tower_record_time` | {m} min | {m} min | record time |
| `tower_record_none` | No climb recorded yet. | Aucune ascension enregistrée. | empty record card |
| `tower_record_best_floor` | Highest floor | Étage le plus haut | best-run label |
| `tower_record_fastest` | Fastest climb | Ascension la plus rapide | best-run label |
| `tower_record_daily` | Best daily climb | Meilleure ascension du jour | best-run label |

## 4. Merchant lines (paid in Ash Marks)
| key | EN | FR | where |
|---|---|---|---|
| `tower_coins_name` | Tower coins | Pièces de la Tour | name of the in-run currency; lost when the run ends; not Ash Marks |
| `tower_merchant_wallet` | Coins to spend: {n} | Pièces à dépenser : {n} | existing key, new text |
| `tower_coins_chip` | {n} | {n} | run header chip |
| `tower_coins_gained` | +{n} coins | +{n} pièces | spoils line |
| `tower_coins_lost` | Coins left: {n} (lost) | Pièces restantes : {n} (perdues) | end screen, small type |
| `tower_reroll` | Reroll | Retirer | table button |
| `tower_reroll_price` | Reroll · {n} | Retirer · {n} | button with price |
| `tower_banish` | Banish | Bannir | card action |
| `tower_banish_confirm` | Banish this card for good? It will not return this climb. | Bannir cette carte ? Elle ne reviendra pas durant cette ascension. | confirm |
| `tower_merchant_boon` | A boon | Une faveur | stall third line |
| `tower_merchant_boon_text` | A skill, a die or a spell, your pick of three. | Une compétence, un dé ou un sort, au choix parmi trois. | stall third line, body |
| `tower_shop_salve_line` | A salve, still warm from the candle. Coins only; the Tower takes no silver. | Un onguent encore tiède de la chandelle. Des pièces seulement ; la Tour ne prend pas l’argent. | merchant: salve |
| `tower_shop_potion_line` | Potions, three to a tray. Take two and the third is for the next climber. | Des potions, trois par plateau. Prenez-en deux, la troisième est pour le prochain grimpeur. | merchant: potions |
| `tower_shop_boon_line` | Something stronger, if the purse allows. Choose with care: he will not take it back. | Quelque chose de plus fort, si la bourse le permet. Choisissez bien : il ne le reprendra pas. | merchant: boon |
| `tower_shop_poor_line` | Not enough coins. Win another floor and come back. | Pas assez de pièces. Gagnez un étage de plus et revenez. | merchant: cannot afford (replaces the marks version) |
| `tower_shop_bought_line` | Coins counted, dust swept. It is yours. | Pièces comptées, poussière balayée. C’est à vous. | merchant: after buying (replaces the marks version) |
| `tower_shop_sworn_line` | You wear their colours; the price is halved, and he does not look up. | Vous portez leurs couleurs : le prix est divisé par deux, et il ne lève pas les yeux. | merchant: sworn half price |
| `tower_shop_leave_line` | The candle gutters behind you. Climb well. | La chandelle vacille dans votre dos. Montez bien. | merchant: leaving |

Size: S. Tag: quick win once Core confirms the keys it uses; the Dart block can be generated from these tables.
