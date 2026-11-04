# Draft: callback cap priorities and revisit lines (Narrative)

A note only: no story data changes until Core's fields (`priority`, `callback_cap`, `revisit_description`, `revisit_description_fr`) exist; the data PR follows (v1.815 provisional).

## Caps

| Scene | callback_cap | Callbacks | By priority (count) |
|---|---|---|---|
| `7800` | 10 | 70 | p5: 7, p4: 3, p3: 11, p2: 16, p1: 13, p0: 20 |
| `7004` | 10 | 31 | p4: 8, p3: 2, p1: 21 |
| `7001` | 8 | 26 | p4: 3, p2: 1, p1: 22 |
| `7400` | 8 | 23 | p4: 1, p3: 9, p2: 1, p1: 12 |
| `7500` | 8 | 22 | p4: 1, p3: 12, p1: 9 |

Priority rules (higher is kept first): 5 throne winner of the clan; 4 crown, banner, the fate of Lysa; 3 claims, pledges, backed throne, rival, the will, Inquisition pact, Dominion split; 2 one-line companion beats (gate, marker, names, roll, watch, voice, debt, letter, Tobin, Malrik); 1 everything else (other hosts); 0 the twenty "houses" lines on `7800`. Ties: file order. The four `7005` endings stay uncapped.

## Revisit lines (EN / FR)

One short line per hub, used from the second entry on. They repeat facts the hub's first text already told; none adds a fact.

| Hub | EN | FR |
|---|---|---|
| `2015` | Back on the wharf. The patrols kept their tidy ranks and the merchants their trade. I still owed Vane something worth his while. | De retour sur le quai. Les patrouilles gardaient leurs rangs propres, les marchands leur commerce. Je devais encore à Vane de quoi l’intéresser. |
| `6010` | The Reliquary Quarter again, frost on the cobbles in summer. The dead heart still lay ahead. | Le Quartier des Reliquaires de nouveau, le givre sur les pavés en plein été. Le cœur mort restait devant moi. |
| `7200` | Greyhithe again: nets in hand, grey in every face, and nobody agreeing on where they had been. | Grisegrève de nouveau : les filets à la main, le gris sur tous les visages, et personne d’accord sur l’endroit d’où ils venaient. |
| `3005` | The Ashen Quarter again, a day’s walk from the camp, and the Spire’s gates still shut past its last street. | Le Quartier des Cendres de nouveau, à une journée de marche du camp, et les portes de la Flèche toujours closes au bout de la dernière rue. |
| `4999_camp` | The cove again. The wall stood, the fires were lit, and the Stair could wait until I was harder to kill. | La crique de nouveau. Le mur tenait, les feux brûlaient, et l’Escalier pouvait attendre que je sois plus difficile à tuer. |
| `5010` | The drowned cloister again: black water at the knee, candles on every ledge, the Court deeper still. | Le cloître noyé de nouveau : l’eau noire aux genoux, des chandelles sur chaque corniche, la Cour plus bas encore. |
| `7100` | The White Anchorage again, hulls roofed with their own sails, and the crusaders a year into thinking it over. | Le Mouillage Blanc de nouveau, des coques couvertes de leurs propres voiles et des croisés depuis un an à y réfléchir. |
| `5100` | Wrack’s End again, clinging to the cliff like weed, its lamps set where no honest pilot would want a light. | Bout-du-Varech de nouveau, accroché à la falaise comme le goémon, ses lampes posées où nul pilote honnête ne voudrait de lumière. |
| `6100` | Rimewell again: frost on the well in summer, and the chapel bell ringing on its own at the hour the tear opened. | Puits-de-Givre de nouveau : du givre sur le puits en plein été, la cloche de la chapelle sonnant seule à l’heure où la déchirure s’était ouverte. |
| `3100` | Emberwick again, in the lee of the slag heaps, the kilns smoking, and nobody here with a use for a banner. | Braiseval de nouveau, à l’abri des terrils, les fours fumant, et personne ici qui ait l’usage d’une bannière. |
| `2900` | The yards again: ribs on the slips, and the Rusty Eel at the end of the row on her blocks. | Les chantiers de nouveau : des membrures sur les cales, et le Rusty Eel au bout de la rangée, sur ses étais. |
| `5200` | The Kindly Hill again, green out of the grey fen, and always a summer evening inside. | La Colline des Bienveillants de nouveau, verte au milieu du marais gris, et toujours un soir d’été à l’intérieur. |
| `6200` | Highhearth again: the giants’ hall, forty living where there had been four thousand, and a fire nobody had let go out. | Haut-Âtre de nouveau : la salle des géants, quarante vivants là où ils avaient été quatre mille, et un feu que personne n’avait laissé s’éteindre. |
| `7515_rest` | The harbour steps again, the cliff lit above me, every clan’s fire on its own terrace. The Hall could wait. | Les marches du port de nouveau, la falaise éclairée au-dessus de moi, le feu de chaque clan sur sa terrasse. La Salle pouvait attendre. |
| `7800` | The cove again, the fires grey, the Host mustering on the shingle, the tear twice as wide. | La crique de nouveau, les feux gris, l’Ost se rassemblant sur les galets, la déchirure deux fois plus large. |
