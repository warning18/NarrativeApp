# Clans: one "stands for" line each (Narrative)

For UX's clan gift popin (Wave 7 D, board 16). A few words on each faction's orientation or playstyle, EN and FR, written from the factions' own mottoes and intros (`assets/gamedata/factions.json`), so the line says what the clan *wants of you*, not what it has. They do not depend on the design the user picks. Core adds the field to `factions.json` (suggested key `stands_for` / `stands_for_fr`) once the design is chosen. The first six are the clans proper; the rest are for any offer screen that shows the other kinds too.

| Id | Faction | Faction (FR) | stands_for | stands_for_fr |
|---|---|---|---|---|
| `dominion` | The Lantern Dominion | Le Dominion de la Lanterne | Law, order, one flame over all | La loi, l’ordre, une seule flamme sur tous |
| `vigil` | The Grey Vigil | La Veille Grise | Watchfulness, duty, the long watch | La vigilance, le devoir, la longue veille |
| `compact` | The Cinder Compact | Le Pacte des Cendres | Craft, restraint, blades by invitation | L’art, la retenue, des lames sur invitation |
| `mire` | The Mire Courts | Les Cours du Marais | Patience, courtesy, secrets kept | La patience, la courtoisie, les secrets gardés |
| `crows` | The Salt Crows | Les Corneilles de Sel | Coin, contracts, the long game | Les pièces, les contrats, le long jeu |
| `penitents` | The Ashen Penitents | Les Pénitents de Cendre | Penance, ash, burdens carried | La pénitence, la cendre, les fardeaux portés |
| `choir` | The Choir | Le Chœur | Vows, light, a promise kept | Les vœux, la lumière, la parole tenue |
| `pit` | The Pit | La Fosse | Clauses, prices, nothing free | Des clauses, des prix, rien de gratuit |
| `giants` | The giants of Highhearth | Les géants de Haut-Âtre | Stone, signs, once and for good | La pierre, les signes, une fois pour toutes |
| `oni` | The oni | Les oni | Bells, blood, cup for cup | Les cloches, le sang, coupe pour coupe |
| `tidekin` | The Tide-Kin | Les Gens de la Marée | Tides, calls, the drowned remembered | Les marées, les appels, les noyés qu’on n’oublie pas |
| `kindly` | The Kindly Ones | Les Bienveillants | Treaties, patience, every minute owed | Les traités, la patience, chaque minute due |
| `open_hand` | The Open Hand | La Main Ouverte | Old blood, the sealed word, your own hand | Le vieux sang, la parole scellée, votre propre main |

## Board 16's other question: gauge or word?

A **word**. Alignment here is a lean (`lean` is -1, 0 or 1 in the data and a clan's `minAlignment`/`maxAlignment` gate offers), not a quantity the player earns or spends, and a gauge would suggest that more is better. A word keeps it a statement about who the character has been (the app already has the alignment words); the gift popin can show where the player stands against the clan's range in words, e.g. "You lean to the Vigil" / "Vous penchez vers la Veille". If UX wants a gauge anyway, label both ends with those words rather than numbers.
