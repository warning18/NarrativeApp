# The Tower: the names (Narrative, phase 0c)

A note only: no data, no strings, no version. English and French, in the game's voice, as short as the 320 px screens allow. Where a name already exists in the game it is reused, with its key. French keeps the game's rules: « vous », a no-break space before `: ; ! ?`, curly apostrophes. Core prices and orders; I only name.

## The Tower

| | English | French |
|---|---|---|
| Name | **The Ashen Tower** | **La Tour de Cendre** |
| Menu entry | The Tower | La Tour |
| Menu sub-line | Thirty floors, no story. | Trente étages, sans histoire. |
| Tagline (start screen) | Thirty floors. One way up. | Trente étages. Un seul chemin. |
| Floor counter | Floor {n} of 30 | Étage {n} sur 30 |

Why "Ashen": it echoes the Ashen Coast and the Ashen Penitents without taking a story place (the Spire has its own name), and ash is what a run leaves.

## Bands and the 30 floor titles

No floor tells a story; each is a place-feel. A boss floor ends each band.

**The Lower Stairs / Les Escaliers bas** (1 to 10): damp, rope, rust, a little light.

| # | English | French |
|---|---|---|
| 1 | The Foot of the Stair | Le Pied de l’escalier |
| 2 | Ash Landing | Le Palier de cendre |
| 3 | The Wet Steps | Les Marches mouillées |
| 4 | Cinder Turn | Le Tournant des braises |
| 5 | The Half-Lit Flight | La Volée mi-éclairée |
| 6 | Rope and Rust | Corde et rouille |
| 7 | The Sallow Landing | Le Palier blême |
| 8 | The Drip Hall | La Salle des gouttes |
| 9 | The Last Low Step | La Dernière Marche basse |
| 10 | The Gatehouse (boss) | La Loge du portier (boss) |

**The Middle Halls / Les Salles du milieu** (11 to 20): long rooms, candles, salt, cold hearths.

| # | English | French |
|---|---|---|
| 11 | The Long Gallery | La Longue Galerie |
| 12 | Hall of Hooks | La Salle des crochets |
| 13 | The Salt Corridor | Le Couloir de sel |
| 14 | Candle Row | La Rangée de chandelles |
| 15 | The Cold Hearth | L’Âtre froid |
| 16 | The Tally Room | La Salle des comptes |
| 17 | The Flooded Hall | La Salle inondée |
| 18 | The Quiet Chapel | La Chapelle muette |
| 19 | The Narrow Door | La Porte étroite |
| 20 | The Great Hall (boss) | La Grande Salle (boss) |

**The Crown / La Couronne** (21 to 30): wind, bells, lamps, open air.

| # | English | French |
|---|---|---|
| 21 | The Bell Stair | L’Escalier des cloches |
| 22 | The Lamp Ledge | La Corniche des lampes |
| 23 | The Windward Steps | Les Marches au vent |
| 24 | Grey Battlements | Les Créneaux gris |
| 25 | The Open Roof | Le Toit ouvert |
| 26 | The Thin Air | L’Air mince |
| 27 | The Last Rail | La Dernière Rampe |
| 28 | The Lantern Gallery | La Galerie de la lanterne |
| 29 | The Top Stair | La Dernière Volée |
| 30 | The Summit (boss) | Le Sommet (boss) |

## The three bosses

Existing records in `enemies.json`, so Core's table can use them as they are; the lines are one sentence each, shown on the boss floor's banner.

| Floor | Foe (key) | English | French |
|---|---|---|---|
| 10 | The Legate’s Champion (`inquisition_legate`) / Le Champion du légat | He holds the gatehouse in the name of a pact sealed in blood. | Il tient la loge au nom d’un pacte scellé dans le sang. |
| 20 | Hesk Morrow, Grand Master (`claimant_morrow`) / Hesk Morrow, Grand Maître | He keeps the Great Hall, and asks only that you do not stop. | Il garde la Grande Salle et ne demande qu’une chose : que vous ne vous arrêtiez pas. |
| 30 | The Sovereign (`void_sovereign`) / Le Souverain | He waits where the stair runs out, under a crown the tear wore first. | Il attend là où l’escalier s’arrête, sous une couronne que la déchirure a portée la première. |

(If Core prefers another foe for a floor, only the foe name changes; the line is rewritten the same day.)

## Marks and unlocks

| | English | French |
|---|---|---|
| Name of the marks | **Ash Marks** | **Marques de cendre** |
| Earned line | You earn {n} Ash Marks. | Vous gagnez {n} marques de cendre. |
| Screen title | Marks and unlocks | Marques et déblocages |
| Cost label | {n} marks | {n} marques |

Ten unlocks, in the order they would be bought (cheapest first; Core sets the prices). Each is an existing game name; the line is what a start gets.

| # | Kind | English (key) | French | Line (EN / FR) |
|---|---|---|---|---|
| 1 | die | Flame Die (`flame_die`) | Dé de flamme | Begin with a Flame Die. / Commencer avec un Dé de flamme. |
| 2 | clan | The Salt Crows (`crows`) | Les Corneilles de Sel | Begin under the Salt Crows. / Commencer auprès des Corneilles de Sel. |
| 3 | item | Knight’s Bulwark (`shield_t5`) | Rempart du chevalier | Begin with a Knight’s Bulwark. / Commencer avec un Rempart du chevalier. |
| 4 | profession | Cleric (`cleric`) | Clerc | Begin as a Cleric. / Commencer en Clerc. |
| 5 | die | Tide Die (`tide_die`) | Dé de marée | Begin with a Tide Die. / Commencer avec un Dé de marée. |
| 6 | clan | The Grey Vigil (`vigil`) | La Veille Grise | Begin under the Grey Vigil. / Commencer auprès de la Veille Grise. |
| 7 | item | Silvered Longsword (`sword_t4`) | Épée longue argentée | Begin with a Silvered Longsword. / Commencer avec une Épée longue argentée. |
| 8 | profession | Ranger (`ranger`) | Rôdeur | Begin as a Ranger. / Commencer en Rôdeur. |
| 9 | clan | The Cinder Compact (`compact`) | Le Pacte des Cendres | Begin under the Cinder Compact. / Commencer auprès du Pacte des Cendres. |
| 10 | die | Tearglass Die (`tearglass_die`) | Dé de verre-larme | Begin with a Tearglass Die. / Commencer avec un Dé de verre-larme. |

(Which races, professions and clans are open at the start is Core's; I assumed Cleric and Ranger are closed, so they are bought. Swap any row for another existing name without changing the shape.)

## End of a run

| | English | French |
|---|---|---|
| Death | The stair keeps what you could not carry. You reached floor {n}. | L’escalier garde ce que vous n’avez pu porter. Vous avez atteint l’étage {n}. |
| Victory | The top. No door, only sky, and the whole climb behind you. | Le sommet. Pas de porte, seulement le ciel, et toute la montée derrière vous. |

## Menu entry and buttons

| Use | English | French |
|---|---|---|
| Start a run | Climb | Gravir |
| Resume | Continue the climb | Reprendre l’ascension |
| New run after an end | Climb again | Gravir de nouveau |
| Take a reward | Take | Prendre |
| Go on | Next floor | Étage suivant |
| Marks screen | Marks | Marques |
| Unlocks screen | Unlocks | Déblocages |
| Leave a run | Leave the Tower | Quitter la Tour |
| Leave, confirmation | Leave the Tower? The climb ends and earns its marks. | Quitter la Tour ? La montée s’arrête et rapporte ses marques. |
| Back | Back to the menu | Retour au menu |
