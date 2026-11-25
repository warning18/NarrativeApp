# Tower: Heat and Coins wording (EN / FR), draft for Core and UX

Draft only, nothing is in `app_strings.dart`. Wording for the user-approved Heat and Coins screens (UX's sheets in `docs/ux-shots/tower-heat/` and `tower-coins/` on `claude/ux-2-tower-clans-3`, Core's `tower-heat.md` and `tower-coins.md` on `claude/core-tower-designs`). Keys are proposals beside the `tower_heat_*` and `tower_coins_*` keys already drafted in `tower-offers-and-briefs.md`; where a key there is superseded, it says so below.

**No figure in the text where Core may tune it.** UX's placeholders quoted “5% stronger”, “8% instead of 15%”, “floor 18”, “5 coins”, “6 potions”, “floor 12”, “+2 standing”: every line below says the same thing in words (“a little harder”, “less”, “sooner”, “coins in hand”), so Core can retune a lever without touching a string. Numbers that remain are `{n}`, `{heat}` or `{perk}` slots filled by the code.

French terms: `gardien`, `boss`, `affixe`, `Élite`, `rareté`, `faveur` (boon), `retirage` (reroll), `atout` (perk), `apparence` (look), `galon` (trim), `pièces` (coins), `Marques de cendre` (marks). The five heat names are Braises, Fumée, Flamme, Bûcher, Cendre. FR passes the lint rules (no-break spaces before `: ; ! ? %` and `«»`, curly ’, vous without a gendered participle).

## A. Heat: the five levels and their curses

| key | EN | FR |
|---|---|---|
| tower_heat_0 | The plain climb | L’ascension simple |
| tower_heat_0_line | Today’s climb, as the Tower made it. | L’ascension du jour, telle que la Tour l’a faite. |
| tower_heat_1 | Embers | Braises |
| tower_heat_1_line | Every foe hits a little harder. | Chaque adversaire frappe un peu plus fort. |
| tower_heat_2 | Smoke | Fumée |
| tower_heat_2_line | Wardens and bosses carry one affix more. | Les gardiens et les boss portent un affixe de plus. |
| tower_heat_3 | Flame | Flamme |
| tower_heat_3_line | You recover less after a floor, and Elites turn up more often in the upper Tower. | Vous récupérez moins après un étage, et les Élites se montrent plus souvent dans la haute Tour. |
| tower_heat_4 | Pyre | Bûcher |
| tower_heat_4_line | Some boons are gone from the stairs, and the late oath keeps you waiting. | Des faveurs ont disparu de l’escalier, et le serment tardif se fait attendre. |
| tower_heat_5 | Ash | Cendre |
| tower_heat_5_line | The upper Tower is fiercer still, and a gift turns the rival clans harder against you. | La haute Tour est plus féroce encore, et un don braque plus fort les clans rivaux contre vous. |

`tower_heat_1_line` replaces the earlier draft's (“Foes hit a little harder; marks come a little faster”): the marks bonus is already printed on the row (“Marks ×1.25”), so the curse line says only the curse.

## B. Heat: picker, chip, curse list, end screen

| key | EN | FR |
|---|---|---|
| tower_heat_locked | Win the top at {heat} to open | Gagnez au sommet (niveau {heat}) pour ouvrir |
| tower_heat_marks | Marks ×{n} | Marques ×{n} |
| tower_heat_chip_label | {heat} | {heat} |
| tower_heat_curses_title | Curses in force this climb | Malédictions en vigueur durant cette ascension |
| tower_heat_curse_new | new | nouvelle |
| tower_heat_end | {heat} · marks ×{n} | {heat} · marques ×{n} |
| tower_heat_opened | {heat} is open | Niveau ouvert : {heat} |
| tower_heat_record | Your best climb | Votre meilleure ascension |
| tower_heat_ash_done | Ash conquered | Cendre conquise |

`tower_heat_opened` keeps its earlier FR (“Niveau ouvert : {heat}”) because the heat names differ in gender (Flamme, Cendre are feminine; Braises plural): the form never needs an agreement. `tower_heat_marks` and `tower_heat_end` take `{n}` as the multiplier Core computes (1.25 … 2.25), so FR shows the same figure.

## C. Coins: the eight perks

| key | EN | FR |
|---|---|---|
| tower_perk_purse | Purse | Bourse |
| tower_perk_purse_line | Start the climb with coins in hand. | Commencez l’ascension avec des pièces en poche. |
| tower_perk_deep_pockets | Deep pockets | Poches profondes |
| tower_perk_deep_pockets_line | Room for one more potion in the bag. | De la place pour une potion de plus dans le sac. |
| tower_perk_early_word | Early word | Mot d’avance |
| tower_perk_early_word_line | The late oath comes sooner. | Le serment tardif vient plus tôt. |
| tower_perk_old_friend | Old friend | Vieil ami |
| tower_perk_old_friend_line | One clan of the climb starts out thinking better of you. | Un clan de l’ascension vous estime déjà davantage au départ. |
| tower_perk_second_wind | Second wind | Second souffle |
| tower_perk_second_wind_line | After a warden or a boss, you get your breath back. | Après un gardien ou un boss, vous reprenez votre souffle. |
| tower_perk_keen_eye | Keen eye | Œil vif |
| tower_perk_keen_eye_line | The first boon is a rarity better. | La première faveur est d’une rareté supérieure. |
| tower_perk_free_hand | Free hand | Main libre |
| tower_perk_free_hand_line | Your first reroll of each climb costs nothing. | Votre premier retirage de chaque ascension ne coûte rien. |
| tower_perk_fourth_card | Fourth card | Quatrième carte |
| tower_perk_fourth_card_line | The first boon tables show one card more. | Les premières tables de faveurs montrent une carte de plus. |

Perks are chosen at the door and worn for the climb (how many at a time is Core's number and appears in no line); the lines state the effect without a figure, which Core can tune (the start purse, the bag size, the oath floor, the standing, the healing, the card count).

## D. Coins: the five trims and the Ash trim

| key | EN | FR |
|---|---|---|
| tower_trim_moth | Moth trim | Galon de mite |
| tower_trim_stitch | Stitch trim | Galon de fil |
| tower_trim_brass | Brass trim | Galon de laiton |
| tower_trim_bone | Bone trim | Galon d’os |
| tower_trim_lamp | Lamp trim | Galon de lampe |
| tower_trim_ash | Ash trim: earned at Ash, never sold | Galon de cendre : gagné à Cendre, jamais vendu |

Names only (the trims are looks, no power). The Ash trim's label is UX's own phrase, translated.

## E. The marks screen, the door's slots, the stall

| key | EN | FR |
|---|---|---|
| tower_marks_tab_unlocks | Unlocks | Déblocages |
| tower_marks_tab_perks | Perks | Atouts |
| tower_marks_tab_looks | Looks | Apparences |
| tower_perk_worn | Worn | Porté |
| tower_perk_worn_n | Worn {n} | Porté {n} |
| tower_perk_owned | Owned | Possédé |
| tower_perks_hint | Perks are chosen at the door and worn for the whole climb. | Les atouts se choisissent à la porte et se portent durant toute l’ascension. |
| tower_perk_next | Next perk: {perk}, {n} more marks | Prochain atout : {perk}, encore {n} marques |
| tower_tree_full | Every unlock is owned: the tree is full. Marks now buy perks and looks. | Tout est débloqué : l’arbre est plein. Les marques achètent désormais des atouts et des apparences. |
| tower_door_perks | Perks for this climb | Atouts pour cette ascension |
| tower_door_slot | Slot {n}: choose | Emplacement {n} : choisir |
| tower_stall_coins_only | Coins only. The Tower takes no silver. | Des pièces seulement. La Tour ne prend pas l’argent. |
| tower_stall_salve | Salve | Onguent |
| tower_stall_salve_line | Heals a good part of your health. | Rend une bonne part de vos forces. |
| tower_stall_potions | Potion bundle | Lot de potions |
| tower_stall_potions_line | A few for the bag. | Quelques-unes pour le sac. |
| tower_stall_boon | A boon | Une faveur |
| tower_stall_boon_line | A skill, a die or a spell, your pick of three. | Une compétence, un dé ou un sort, au choix parmi trois. |

The stall lines replace the earlier draft's `tower_shop_*` salve and potion lines only where UX's sheet shows them as item captions (salve, potions, boon); the story lines (`tower_shop_salve_line` …) stay as the merchant's talk. The stall's prices (4 / 5 / 15 coins) are Core's and never appear in the text.

## F. The end tally labels

| key | EN | FR |
|---|---|---|
| tower_end_fell | You fell on floor {n} | Vous tombez à l’étage {n} |
| tower_end_floors | Floors | Étages |
| tower_end_wardens | Wardens | Gardiens |
| tower_end_bosses | Bosses | Boss |
| tower_end_refusals | Refusals | Refus |
| tower_end_heat | Heat: {heat} ×{n} | Niveau : {heat} ×{n} |
| tower_end_first_win | First win at this heat | Première victoire à ce niveau |
| tower_end_banked | Ash Marks banked | Marques de cendre mises de côté |
| tower_end_coins_lost | Coins left: {n} (lost) | Pièces restantes : {n} (perdues) |

`tower_end_coins_lost` repeats the earlier draft's `tower_coins_lost`; use whichever key Core has already pasted. The “Next perk” line is `tower_perk_next` above.

## Notes

- All keys are new proposals; none renames an existing key.
- “Atout” is the one word for perks everywhere (tab, door, end line), “apparence” for looks.
- Coins are “pièces”, marks are “marques”: the two currencies never share a word.

## G. The stall's three placeholder strings (claude/core-coins, b0301edf)

| key | EN | FR |
|---|---|---|
| tower_merchant_body | Salves, potions and the odd boon by candlelight, paid in Tower coins. Nothing here leaves the Tower, and neither do the coins. | Onguents, potions et parfois une faveur, à la lueur d’une chandelle, payés en pièces de la Tour. Rien d’ici ne quitte la Tour, pas même les pièces. |
| tower_merchant_price | {n} coins | {n} pièces |
| tower_merchant_price_one | {n} coin | {n} pièce |

`tower_merchant_body` now names the boon (the stall sells one since the coins change) and says the coins end with the climb, in words, no figure. The two price strings were already correct (plural and singular, EN and FR; the FR `pièce` takes no no-break space); I keep them as they are: a price chip wants the plain form, and `tower_coins_name` (“Tower coins”, « Pièces de la Tour ») carries the flavour.

## H. Pyre's line, reworded (Core #1173)

Pyre now removes its reward floors' prizes and makes foes tougher on the upper floors. One line says both, no figure. The key is `tower_heat_4_line` in this draft (the manager calls it `tower_heat_pyre_line`: use whichever key Core already has).

| key | EN | FR |
|---|---|---|
| `tower_heat_4_line` / `tower_heat_pyre_line` | Floors that once rewarded you give nothing, and foes are tougher in the upper Tower. | Des étages qui vous récompensaient ne donnent plus rien, et les adversaires sont plus coriaces dans la haute Tour. |

This replaces section A's Pyre line (“Some boons are gone from the stairs, and the late oath keeps you waiting”). Ash's line (“fiercer still”) still follows on from it.
