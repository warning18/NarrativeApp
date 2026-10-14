# Level-up paths: names and flavour (Narrative)

Answers `docs/proposals/level-up-offers.md` (Core, `claude/core-2`). Ten paths, ids as in Core's table. Text fields only: Core's `training_paths.json` keeps its ids, gains, professions and races. Each name reads as a title on a card; each line is one sentence, short enough for a card, and says what the playstyle feels like rather than what the numbers are (the chips show those).

| Id | name | name_fr | blurb | blurb_fr |
|---|---|---|---|---|
| `bruiser` | The Bruiser | Le Cogneur | You take the blow to give back a worse one. | Vous encaissez le coup pour en rendre un pire. |
| `duelist` | The Duelist | Le Duelliste | A step ahead, and the point already there. | Un pas d’avance, et la pointe déjà arrivée. |
| `warden` | The Warden | Le Rempart | You stand where the others can’t be reached. | Vous tenez la place d’où l’on ne peut atteindre les autres. |
| `juggernaut` | The Juggernaut | Le Colosse | Nothing wears you down; you wear it down. | Rien ne vous use ; c’est vous qui usez le reste. |
| `arcanist` | The Arcanist | L’Arcaniste | The words do the work; you only mind the cost. | Les mots font le travail ; vous ne surveillez que le prix. |
| `zealot` | The Zealot | Le Zélote | Faith is a lantern, and you carry it into the dark. | La foi est une lanterne, et vous la portez dans le noir. |
| `skirmisher` | The Skirmisher | L’Escarmoucheur | In, out, and gone before the answer. | Dedans, dehors, et parti avant la réponse. |
| `hunter` | The Hunter | Le Chasseur | The long watch, and the one clean shot. | La longue veille, et le seul tir net. |
| `envoy` | The Envoy | L’Émissaire | Words first; the blade is for when they fail. | Les mots d’abord ; la lame, pour quand ils échouent. |
| `brawler` | The Brawler | Le Bagarreur | Strength first, and the rest can catch up. | La force d’abord ; le reste suivra. |

## Ready to paste (`training_paths.json` text fields)

```json
{
  "bruiser": {
    "name": "The Bruiser",
    "name_fr": "Le Cogneur",
    "blurb": "You take the blow to give back a worse one.",
    "blurb_fr": "Vous encaissez le coup pour en rendre un pire."
  },
  "duelist": {
    "name": "The Duelist",
    "name_fr": "Le Duelliste",
    "blurb": "A step ahead, and the point already there.",
    "blurb_fr": "Un pas d’avance, et la pointe déjà arrivée."
  },
  "warden": {
    "name": "The Warden",
    "name_fr": "Le Rempart",
    "blurb": "You stand where the others can’t be reached.",
    "blurb_fr": "Vous tenez la place d’où l’on ne peut atteindre les autres."
  },
  "juggernaut": {
    "name": "The Juggernaut",
    "name_fr": "Le Colosse",
    "blurb": "Nothing wears you down; you wear it down.",
    "blurb_fr": "Rien ne vous use ; c’est vous qui usez le reste."
  },
  "arcanist": {
    "name": "The Arcanist",
    "name_fr": "L’Arcaniste",
    "blurb": "The words do the work; you only mind the cost.",
    "blurb_fr": "Les mots font le travail ; vous ne surveillez que le prix."
  },
  "zealot": {
    "name": "The Zealot",
    "name_fr": "Le Zélote",
    "blurb": "Faith is a lantern, and you carry it into the dark.",
    "blurb_fr": "La foi est une lanterne, et vous la portez dans le noir."
  },
  "skirmisher": {
    "name": "The Skirmisher",
    "name_fr": "L’Escarmoucheur",
    "blurb": "In, out, and gone before the answer.",
    "blurb_fr": "Dedans, dehors, et parti avant la réponse."
  },
  "hunter": {
    "name": "The Hunter",
    "name_fr": "Le Chasseur",
    "blurb": "The long watch, and the one clean shot.",
    "blurb_fr": "La longue veille, et le seul tir net."
  },
  "envoy": {
    "name": "The Envoy",
    "name_fr": "L’Émissaire",
    "blurb": "Words first; the blade is for when they fail.",
    "blurb_fr": "Les mots d’abord ; la lame, pour quand ils échouent."
  },
  "brawler": {
    "name": "The Brawler",
    "name_fr": "Le Bagarreur",
    "blurb": "Strength first, and the rest can catch up.",
    "blurb_fr": "La force d’abord ; le reste suivra."
  }
}
```

## The offers' titles

| Where | EN | FR |
|---|---|---|
| A level-up offer (the three paths) | Choose your training | Choisissez votre entraînement |
| The Tome of Insight's small offer | A moment of insight | Un éclair de lucidité |
| The character sheet's list of paths taken (prefix) | Training | Entraînement |

The small offer's three single gains need no names of their own: each is labelled by its stat, as the stat chips are.
