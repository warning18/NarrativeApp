# Level-up offers: training by playstyle (Wave 7, item 1)

Core's design, for UX (the sheet) and Narrative (names, flavour). Nothing
built yet.

## What changes

Today a level-up gives **5 stat points** (and +20 max health on its own), spent
one by one on the Level Up screen ("+1 Point"), or left for later. In their
place, a level-up brings **one training offer**: three **paths**, each a bundle of
stat gains pointing at a playstyle; the player takes one. There is no "decide
later": the offer stays on the table until a path is taken, as a clan offer
does. The +20 max health a level gives stays as it is.

## Balance: each bundle is worth today's 5 points

The exchange today, per point: **+1 base damage**, **+1 base armor**,
**+10 max health**, **+1** of any other stat (strength, dexterity,
constitution, intelligence, wisdom, perception, luck, charisma). Every bundle
adds up to exactly **5 points** at that rate (a test checks it), so a level is
worth what it was; only the free spread goes.

## The paths (data: `assets/gamedata/training_paths.json`, Core's)

Ten paths, ids fixed, names and flavour placeholders for Narrative:

| Id | Playstyle | Gains (5 points) | Leans to |
|---|---|---|---|
| `bruiser` | hits hard, takes hits | +1 damage, +20 max health, +1 strength, +1 constitution | warrior |
| `duelist` | precise, quick | +1 damage, +2 dexterity, +1 perception, +1 luck | rogue, ranger |
| `warden` | stands in front | +2 armor, +10 max health, +1 constitution, +1 wisdom | warrior, cleric |
| `juggernaut` | outlasts | +1 armor, +30 max health, +1 constitution | warrior, dwarf |
| `arcanist` | spells and skills | +2 intelligence, +2 wisdom, +1 perception | mage |
| `zealot` | faith and grit | +1 armor, +10 max health, +2 wisdom, +1 charisma | cleric |
| `skirmisher` | in and out | +2 dexterity, +1 perception, +1 luck, +10 max health | rogue, ranger |
| `hunter` | the long watch | +1 damage, +2 perception, +1 dexterity, +1 wisdom | ranger |
| `envoy` | words over blades | +2 charisma, +1 wisdom, +1 intelligence, +1 luck | (any) |
| `brawler` | strength first | +2 strength, +1 damage, +1 constitution, +10 max health | warrior, orc |

A record:

```json
"bruiser": {
  "name": "The Bruiser", "name_fr": "…",
  "blurb": "…", "blurb_fr": "…",
  "icon": "fist",
  "gains": {"baseDamage": 1, "maxHealth": 20, "strength": 1, "constitution": 1},
  "professions": ["warrior"],
  "races": []
}
```

`gains` uses the session's own stat names (`baseDamage`, `baseArmor`,
`maxHealth`, `strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`,
`perception`, `luck`, `charisma`). `professions` and `races` only weight the
draw (below); any path can come to anyone.

## The draw (pure, seeded like offers.dart)

Three different paths each time:
1. **Your calling**: drawn among the paths that lean to the character's
   profession or race (weighted toward the paths taken before, so a build keeps
   its line).
2. **Your habit**: the path closest to the stats the character has raised most
   so far (its gains weighted against the character's growth); a different one
   from the first.
3. **A turn**: any other path, at random, so a build can change course.

The three are drawn once and kept (a save holds them), so closing the app never
redraws them.

## The session

- `pendingTraining` (int): training offers due, one per level gained
  (replaces `statPoints`).
- `trainingOffer` (list of 3 path ids, or empty): the offer on the table.
- `trainingTaken` (map path id → times): what the character has taken, for the
  draw's "habit" and for the character sheet ("Bruiser ×3, Warden ×1").
- `takeTraining(pathId)`: applies the gains, counts it, draws the next offer if
  more are due.
- **Old saves**: unspent `statPoints` become offers: every 5 points one offer
  due; a remainder (1 to 4 points, from a Tome of Insight) becomes one small
  offer (below).

## Tome of Insight (today: 1 free stat point)

It brings a **small offer**: three single gains (+1 of one stat, or +10 max
health), each from one of the character's three likeliest paths. Same sheet,
one point instead of five.

## Autoplay and the simulator

They take the first path of each offer (the calling), so builds follow the
profession, as their stat-raising does today (`autoplay_build.dart`); the balance
tests stay in reach.

## For UX

The Level Up screen and the pop-up after a fight show the three paths as cards
(name, icon, the gains as chips, a line of flavour), one tap to pick, as the
clan offer dialog does. The character sheet can list the paths taken.

## For Narrative

The ten names and one line of flavour each (EN/FR); the small offer's title.
