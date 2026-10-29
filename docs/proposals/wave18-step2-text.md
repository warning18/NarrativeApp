# Wave 18, step 2: Narrative's answers (towns, attack news, epilogue lines)

Answers to Core's `docs/proposals/wave18-step2.md` (items 1, 2 and 4). Text and story only, no numbers. Names are the game's own (`factions.json`, `geography.json`). French follows the lint (non-breaking space before `: ; ! ?` and inside « »).

## 1. The other big towns (item 2)

### The Ashen Quarter

Three districts have no holder. `factions.json` `claims` and `seat` give them directly, and the chapter 3 scenes agree:

| District | Holder | Why |
|---|---|---|
| The Quarter Gate (`ashen_quarter_gate`) | The Grey Vigil | its claim; the Last Watch keeps the way in |
| The Ash-Market (`ashen_quarter_ash_market`) | The Cinder Compact | its claim; the stalls and the runners are trade |
| The Wall of Names (`ashen_quarter_wall_of_names`) | The Ashen Penitents | their claim and their seat (`penitents.seat`) |
| Cinder Row | The Cinder Compact | already so |
| The Spire Stair | The Lantern Dominion | already so |

That leaves the Compact on 2, and the Vigil, the Penitents and the Dominion on 1 each: nobody is near 3 of 5, so the town starts open and the Compact leads. Good for a town the player passes in chapter 3.

**The lock:** the **Spire Stair**, opened by finishing **`q_ch3_reckoning_wall`** (taken and fought at the Wall of Names, scenes `3005_wall`, `3005_wall_fight`). The Tribunal does not let anyone up its stair who has not first answered at the Wall. Core: check the quest can be finished before the Stair is the only way on in chapter 3; if it cannot, use `q_ch3_ashen_oath` (taken at the Gate) with `opensOn: accepted`.

- `lockedText` EN: "The Tribunal’s guards turn back anyone who has not answered at the Wall of Names."
- `lockedText_fr`: « Les gardes du Tribunal refoulent quiconque n’a pas d’abord répondu au Mur des Noms. »

### The Black Reliquary

Clans that belong there, from the chapter 5 scenes (`6010_clan_dominion_2` in the tribunal chapel, `6010_clan_compact_3` in the hammer chapel, `q_ch5_penitents_confession`, the Wickwarden’s candles) and from `claims` (the Dominion claims `reliquary_quarter`): the **Lantern Dominion**, the **Cinder Compact**, the **Ashen Penitents** and the **Grey Vigil**.

| District | Holder | Why |
|---|---|---|
| The Reliquary Quarter | The Lantern Dominion | its claim; the Tribunal chapel |
| The Chapels of the Chair | The Cinder Compact | the hammer chapel is theirs (scene evidence; swap with the Dominion if Core wants a Dominion majority) |
| Last Lantern Street | The Ashen Penitents | the widow’s candles, one for each person the tear took: their rite |
| The Frost Line | The Grey Vigil | the Vigil’s rimewell country; they hold the line against what the tear sends |
| The Dead Heart | **none** | the tear hangs in the open there; no clan holds it, and none should be able to take it by power |

So the town stays open (1, 1, 1, 1 and a district no clan holds). If Core’s "3 of 5" rule needs the Dead Heart to count, treat it as never held; a clan can then win the town with 3 of the other 4. No lock is proposed here: `q_ch5_the_dead_heart` already gates the square by story.

### The Lantern Alleys

Leave them with the Mire. The alleys are the Crows’ by claim, but a hand-over is better as an event the player causes than as a starting state. I have no objection to Core measuring the Crows version, but I would not choose it for the story.

## 2. Attack news (item 1)

New strings. Placeholders: `{clan}` the attacker, `{holder}` the old holder, `{district}`, `{town}`. In French the old holder after « à » needs the clan’s `nameTo_fr` form ("à la Veille Grise"); Core passes it as `{holderTo}`.

| Key (suggested) | EN | FR |
|---|---|---|
| `district_attack_news` | {clan} marches on {district}. {holder} has two days. | {clan} marche sur {district}. {holder} a deux jours. |
| `district_attack_won` | {clan} took {district} from {holder}. | {clan} a pris {district} à {holderTo}. |
| `district_attack_held` | {district} held. {clan} turned back. | {district} a tenu bon. {clan} a rebroussé chemin. |
| `district_attack_defended` | You held {district} against {clan}. | Vous avez défendu {district} contre {clan}. |
| `district_attack_joined` | You marched with {clan} against {holder}. | Vous avez marché avec {clan} contre {holder}. |
| `district_attack_ignored` | You stood aside. {clan} came for {district}. | Vous êtes resté à l’écart. {clan} est venu pour {district}. |

The siege remark (the `districtAttacked` kind, beyond the existing line): companion lines are better written once the kind exists in `companion_remarks.json`; until then three plain lines for the placeholder set:

- EN: "Smoke over {district}. Somebody has come to collect." / "{clan} will not wait for a second night." / "Whatever you meant to do there, do it before they arrive."
- FR: « De la fumée sur {district}. Quelqu’un est venu encaisser. » / « {clan} n’attendra pas une seconde nuit. » / « Ce que vous comptiez faire là-bas, faites-le avant leur arrivée. »

## 3. Epilogue lines (item 4)

One line per big town and cause. Placeholders: `{clan}`, `{town}`. Alster stays quiet (no line).

| Town | Cause | EN | FR |
|---|---|---|---|
| Saltmouth | war | {clan} took Saltmouth by force, one quay at a time. | {clan} a pris Bouche-de-Sel par la force, un quai après l’autre. |
| Saltmouth | influence | {clan} won Saltmouth without a blow: debts, favours, and patience. | {clan} a gagné Bouche-de-Sel sans un coup : dettes, faveurs et patience. |
| Saltmouth | seat | Saltmouth was {clan}’s from the start, and stayed so. | Bouche-de-Sel était à {clan} dès le début, et l’est restée. |
| The Ashen Quarter | war | {clan} took the Ashen Quarter from the ash up. | {clan} a pris le Quartier des Cendres à même la cendre. |
| The Ashen Quarter | influence | {clan} took the Ashen Quarter by being the one who stayed. | {clan} a pris le Quartier des Cendres en étant celui qui est resté. |
| The Ashen Quarter | seat | The Ashen Quarter was {clan}’s own, and it kept it. | Le Quartier des Cendres était à {clan}, qui l’a gardé. |
| The Black Reliquary | war | {clan} took the Reliquary street by frozen street. | {clan} a pris le Reliquaire rue gelée après rue gelée. |
| The Black Reliquary | influence | {clan} held the Reliquary because the dead would trust no one else. | {clan} a tenu le Reliquaire, parce que les morts ne se fiaient à nul autre. |
| The Black Reliquary | seat | The Reliquary was {clan}’s before the tear, and the tear did not change that. | Le Reliquaire était à {clan} avant la déchirure, et la déchirure n’y a rien changé. |
| Any big town | no holder | No clan holds {town}. It answers to no one. | Aucun clan ne tient {town}. Elle ne répond à personne. |

French agreement ("gardé", "restée") shows only by town, so the FR strings are written per town, not as one template.

## What I will do next

Nothing else is needed from me on these four asks unless Core wants a reword. If Core builds the strings, the placeholder keys can use the suggested names above; I reword in `app_strings.dart` and never rename keys.
