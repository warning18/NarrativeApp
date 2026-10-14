# Level-up offers: training by playstyle (Wave 7, item 1)

Core's design, for UX (the sheet) and Narrative (names, flavour). Built:
`lib/data/training.dart`, `lib/screens/training_picker.dart`.

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

`statPoints` stays the currency: a level still brings 5, a full offer costs
5, a small offer 1. So old saves need no conversion: their unspent points
simply come back as offers.

- `trainingOffer` (list of 3 choices, or empty): the offer on the table, each
  choice its path id, gains and points. Kept in the save, so closing the app
  never redraws it; one of the wrong size (points gained or spent since) is
  drawn anew.
- `trainingTaken` (map path id → times): the full offers taken, for the
  draw's "habit" and the character sheet.
- `ensureTraining(paths)`: the offer on the table, drawn if needed.
- `takeTraining(index)`: applies the gains (max health heals as much),
  spends the points, counts the path.

## Tome of Insight (today: 1 free stat point)

It brings a **small offer**: three single gains (+1 of one stat, or +10 max
health), each from one of the character's three likeliest paths. Same sheet,
one point instead of five.

## Autoplay and the simulator

They take the choice that raises the build's stat (`autoplay_build.dart`'s
`statToRaise`), else the first (the calling), so builds follow the
profession as before.

## For UX

The Level Up screen and the pop-up after a fight show the three paths as cards
(name, icon, the gains as chips, a line of flavour), one tap to pick, as the
clan offer dialog does. The character sheet can list the paths taken.

## For Narrative

The ten names and one line of flavour each (EN/FR); the small offer's title.
