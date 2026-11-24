# Draft: chapter 7's night before and the stair

**Why** (story review 4.2, 5.2, plus Wave 4 brief 6): chapter 7's main road is six scenes and about 700 words with two fights (`7400` → `7500` → `7510_<clan>` → `7515_rest` → `7520_<rival>` → `7590_<winner>`), and the chapter-6 decisions are shown only in the ending. Two scenes fix both without a third fight: a night scene where the party is present, and a stair scene where the player's earlier choices come to the landing and look at them.

**Size:** S each (about 110 words plus callback lines). **Needs Core:** (1) add `7516_eve` and `7517_stair` as two new beats of the chapter 7 spine (`lib/data/chapter_spine.dart`, between the `7510_*` set and the `7520_*` set); (2) add both ids to the scene list of the Candlehold landmark in `lib/data/world_map.dart` (next to `7520_vane`, line 687); (3) nothing else (no new keys or rules). **Needs the user's choice:** none beyond approving.

## The fight on the stair: none, by default

**Recommendation to Core: place no fight on the stair.** Chapter 7 already has two (the assault's optional `*_force` fight in `7510_*`, and the rival in `7520_*`); the stair is the quiet before the last one, and its job is to make the player's past visible. If the user still wants a third, make it **optional and earned**: a "last guard" on the stair offered only to players who took the forced route (`way_force` is set by the fight choice of `7510_*`), a single `white_soldier` pair as in `7510_dominion`, with an exit that skips it for everyone else. Not by default.

## Wiring

- **`7515_rest`**: its three choices (one per rival, each with `politicsIf` on `dominion_leader_<x>` or `throne_<x>`, each healing 999 and giving `potion_major` and setting `rest_before_hall`) become **one** choice: “Sleep, and climb at dawn” → `7516_eve`, keeping `healAmount: 999`, `grantItemId: "potion_major"` and `flagsToAdd: ["rest_before_hall"]`, with no `politicsIf`.
- **`7516_eve`** (new): one choice, “Sleep, and climb at dawn” → `7517_stair`. Optional hub for the P3 second beats (see below).
- **`7517_stair`** (new): three choices carrying the old gating: each “Climb the last flight” → `7520_vane` / `7520_morrow` / `7520_tallis`, with the same `politicsIf` as the three `7515_rest` choices had.
- Reads only flags that already exist (the eight loyalty outcomes; twelve earlier choices).

## `7516_eve`: the night before

- **Slots in:** after `7515_rest`, before `7517_stair`. `location: "candlehold_gates"`, `context_taxonomy.mood: "solemn"`.
- **Reads:** the sixteen loyalty flags (`kelda_gate_held` … `malrik_book_shut`), as callbacks. **Sets:** nothing.
- **`callback_cap`: 5** (a priority tie keeps the file's order, so the five shown are the first five fired; put the loyalty lines of the companions in the party first if you want them to win).

**EN**

> Night came down the cliff terrace by terrace, until every clan’s fire had settled into the shape it would keep till morning. Below the landing someone was singing about a lantern, badly, and nobody told them to stop.

> I could not sleep, and I was not the only one. Those who had walked with me this far had drifted to the fire one by one, and none of us said why. Nobody wants to be alone on the last night before a Hall.

**FR**

> La nuit descendit la falaise terrasse par terrasse, jusqu’à ce que le feu de chaque clan ait pris la forme qu’il garderait jusqu’au matin. Sous le palier, quelqu’un chantait une chanson de lanterne, mal, et personne ne lui dit de se taire.

> Je ne pouvais pas dormir, et je n’étais pas le seul. Ceux qui avaient marché avec moi jusque-là avaient dérivé vers le feu un à un, sans que nul dise pourquoi. Personne ne veut être seul la dernière nuit avant une Salle.

**Choice:** EN “Sleep, and climb at dawn” / FR « Dormir, et monter à l’aube » → `7517_stair`.

**`flag_callbacks`** (each one line; the cap keeps the scene short):

```json
[
  {
    "flag": "kelda_gate_held",
    "en": "Kelda sat with her back to a wall and her shield across her knees, the gate-tags buried and her mind, for once, on the next gate.",
    "fr": "Kelda était assise le dos au mur, son bouclier en travers des genoux, les plaques de la porte enterrées et l’esprit, pour une fois, sur la prochaine porte."
  },
  {
    "flag": "kelda_gate_left",
    "en": "Kelda sat apart with the cord of tags in her fist, as she had since the palisade, and did not offer to bury them.",
    "fr": "Kelda était assise à l’écart, la cordelette de plaques dans le poing, comme depuis la palissade, et ne proposa pas de les enterrer."
  },
  {
    "flag": "sable_marker_kept",
    "en": "Sable flipped the old marker between her fingers and bet herself it would land right. It did.",
    "fr": "Sable faisait sauter le vieux jeton entre ses doigts et se pariait à elle-même qu’il retomberait bien. Il retomba bien."
  },
  {
    "flag": "sable_marker_torn",
    "en": "Sable had nothing in her hands for once, and did not know what to do with them. She folded them, then undid them.",
    "fr": "Pour une fois, Sable n’avait rien dans les mains, et ne savait qu’en faire. Elle les croisa, puis les défit."
  },
  {
    "flag": "maren_names_read",
    "en": "Maren said the Court’s names under her breath, as she had every night since she read them, and added one of ours.",
    "fr": "Maren dit à mi-voix les noms de la Cour, comme chaque nuit depuis qu’elle les avait lus, et en ajouta un des nôtres."
  },
  {
    "flag": "maren_roll_burned",
    "en": "Maren had no list to say. She said nothing, and the silence was as full as the list would have been.",
    "fr": "Maren n’avait plus de liste à dire. Elle ne dit rien, et le silence était aussi plein que la liste l’aurait été."
  },
  {
    "flag": "liora_watch_shared",
    "en": "Liora took the first watch and woke me for the second without being asked twice.",
    "fr": "Liora prit le premier quart et me réveilla pour le second sans qu’on le lui demande deux fois."
  },
  {
    "flag": "liora_watch_left",
    "en": "Liora took every watch, and the dawn found her still at the rail, frost in her hair.",
    "fr": "Liora prit tous les quarts, et l’aube la trouva encore au parapet, du givre dans les cheveux."
  },
  {
    "flag": "vess_voice_answered",
    "en": "Vess hummed something low to herself, a tune I had not heard, and the dark around the landing seemed to listen politely.",
    "fr": "Vess fredonna quelque chose de grave pour elle-même, un air que je ne connaissais pas, et le noir autour du palier sembla écouter poliment."
  },
  {
    "flag": "vess_voice_stilled",
    "en": "Vess sat very quiet, one hand flat on the stone, listening to a silence she had made.",
    "fr": "Vess restait très calme, une main à plat sur la pierre, à écouter un silence qu’elle avait fait."
  },
  {
    "flag": "grosh_debt_paid",
    "en": "Grosh sat whittling a spoon, a free orc with no paper on anything, a little lost and a little pleased.",
    "fr": "Grosh taillait une cuillère, un orque libre sans papier sur rien, un peu perdu et un peu content."
  },
  {
    "flag": "grosh_debt_kept",
    "en": "Grosh counted coins by the fire and did not look up. The debt was his, and so was the counting.",
    "fr": "Grosh comptait des pièces près du feu sans lever les yeux. La dette était à lui, et le compte aussi."
  },
  {
    "flag": "tobin_letter_sent",
    "en": "Tobin had sent his letter, and sat with the lightness of a man who has set something down.",
    "fr": "Tobin avait envoyé sa lettre, et restait là avec la légèreté de qui a posé quelque chose."
  },
  {
    "flag": "tobin_stays",
    "en": "Tobin murmured the old office to himself, as he did when he had decided to stay.",
    "fr": "Tobin murmurait l’ancien office pour lui-même, comme lorsqu’il avait décidé de rester."
  },
  {
    "flag": "malrik_book_read",
    "en": "Malrik was writing in the black book by the fire and, for once, let me see that he was.",
    "fr": "Malrik écrivait dans le petit livre noir, près du feu, et pour une fois me laissa voir qu’il écrivait."
  },
  {
    "flag": "malrik_book_shut",
    "en": "Malrik kept the black book shut on his knee and his eyes on the fire, a clerk with nothing to enter.",
    "fr": "Malrik gardait le petit livre noir fermé sur son genou et les yeux sur le feu, un clerc sans rien à inscrire."
  }
]
```

**With the P3 second beats built** (`docs/narrative/drafts/p3-companion-second-beats.md`): for each companion add a choice “Sit with <name>” → `beat2_<c>`, `showIfFlags: ["<c>_loyal_done", "ally_<c>"]`, `hideIfFlags: [that beat's two outcome flags]`, and make those scenes return to `7516_eve` (not `7400`). The night scene then becomes the hub of the party's last conversations, and the callback lines above are the fallback for the ones not taken.

## `7517_stair`: the Stair of Tongues

- **Slots in:** after `7516_eve`, before the three `7520_*` rival scenes. `location: "candlehold_lantern_hall"`, `mood: "solemn"`.
- **Reads:** twelve earlier choice flags, as callbacks. **Sets:** nothing.
- **`callback_cap`: 6**; priorities favour the choices that cost the most (3 = the biggest, 1 = a small thing).

**EN**

> The Stair of Tongues climbed the cliff in eight flights, one for each House, and at dawn every landing was crowded. It had never held so many. Word had gone ahead of me, as it does: whoever the Throne would take, whoever was coming up.

> They did not cheer. They watched, the way a harbour watches a ship it cannot tell is friend or creditor. I knew some of the faces.

**FR**

> L’Escalier des Langues montait la falaise en huit volées, une par Maison, et à l’aube chaque palier était bondé. Il n’avait jamais porté tant de monde. La nouvelle m’avait précédé, comme elle le fait : qui le Trône prendrait, qui montait.

> Ils n’acclamèrent pas. Ils regardaient, comme un port regarde un navire dont il ne sait pas s’il est ami ou créancier. Je reconnaissais certains visages.

**Choices** (three, each with the `politicsIf` of the old `7515_rest` choice for that rival):

- EN “Climb the last flight” / FR « Monter la dernière volée » → `7520_vane` (`anyFlags: ["dominion_leader_vane", "throne_vane"]`)
- the same → `7520_morrow` (`anyFlags: ["dominion_leader_morrow", "throne_morrow"]`)
- the same → `7520_tallis` (`anyFlags: ["dominion_leader_tallis", "throne_tallis"]`)

**`flag_callbacks`** (a person on the stair for each choice the player made; none shows a clan or a number, only a face):

```json
[
  {
    "flag": "refugees_aboard",
    "en": "A woman on the third landing held up a child. I knew the child: one of a hundred on a boat built for twenty.",
    "fr": "Sur le troisième palier, une femme leva un enfant. Je connaissais l’enfant : l’un des cent sur une barque faite pour vingt.",
    "priority": 3
  },
  {
    "flag": "refugees_left",
    "en": "Someone on the stair called out the name of the wharf, once. Nobody had to say what for.",
    "fr": "Quelqu’un, dans l’escalier, cria une fois le nom du quai. Nul n’eut besoin de dire pourquoi.",
    "priority": 3
  },
  {
    "flag": "tern_row_spared",
    "en": "A lantern-maker from Tern Row lit one at the rail as I passed, and did not say why.",
    "fr": "Une faiseuse de lanternes de la Rangée des sternes en alluma une au garde-corps à mon passage, et ne dit pas pourquoi.",
    "priority": 2
  },
  {
    "flag": "reckoning_wall_saved",
    "en": "One of the Ashen Quarter’s wall-keepers stood on the fifth landing, a chalk-stub in her hand, and nodded once.",
    "fr": "Une gardienne du mur des noms du Quartier des Cendres se tenait sur le cinquième palier, un bout de craie à la main, et hocha la tête une fois.",
    "priority": 2
  },
  {
    "flag": "court_woken",
    "en": "One of the Court’s sleepers, awake and shaved and wrapped in a borrowed cloak, nodded as I went by.",
    "fr": "L’un des dormeurs de la Cour, éveillé, rasé et enveloppé d’un manteau d’emprunt, hocha la tête à mon passage.",
    "priority": 3
  },
  {
    "flag": "court_never_woke",
    "en": "The Court’s sleepers had never woken. I climbed past the places on the stair where their families stood.",
    "fr": "Les dormeurs de la Cour ne s’étaient jamais éveillés. Je montai devant les marches où se tenaient leurs familles.",
    "priority": 3
  },
  {
    "flag": "pact_refused",
    "en": "The legate’s white sail was a smudge at the harbour mouth, going the other way.",
    "fr": "La voile blanche du légat n’était plus qu’une tache à l’entrée du port, qui partait dans l’autre sens.",
    "priority": 2
  },
  {
    "flag": "camp_given",
    "en": "The cove’s fire-keeper stood at the rail with no camp left to keep, and saluted anyway.",
    "fr": "La gardienne du feu de la crique se tenait au garde-corps, sans camp à garder, et salua quand même.",
    "priority": 3
  },
  {
    "flag": "flagship_burned",
    "en": "Soot from the flagship still lay in the creases of my hands. Nobody on the stair mentioned it.",
    "fr": "La suie du vaisseau amiral dormait encore dans les plis de mes mains. Personne, dans l’escalier, n’en parla.",
    "priority": 1
  },
  {
    "flag": "false_lamps_out",
    "en": "A pilot from the wrecker coast stood at the rail with a lamp in his hand, and held it up for me.",
    "fr": "Un pilote de la côte des naufrageurs se tenait au garde-corps, une lampe à la main, et la leva pour moi.",
    "priority": 2
  },
  {
    "flag": "greyhithe_names_read",
    "en": "Greyhithe’s eldest was on the stair, leaning on a stranger, the page in her sleeve.",
    "fr": "L’aînée de Greyhithe était dans l’escalier, appuyée sur un inconnu, la page dans sa manche.",
    "priority": 3
  },
  {
    "flag": "standard_cut_living",
    "en": "On the step above the harbour, someone had set a white cloth folded square. I did not touch it.",
    "fr": "Sur la marche au-dessus du port, quelqu’un avait posé un linge blanc plié en carré. Je n’y touchai pas.",
    "priority": 1
  }
]
```

## What this adds to the chapter

- Two scenes (about 220 words of fixed text, plus at most 11 callback lines of 15 to 25 words), no fight, no new rule: the main road goes from six scenes to eight.
- The review's finding that chapter 6 and 7 decisions are seen only at the end is answered twice: the loyalty outcomes on the night, and twelve choices from chapters 2 to 6 on the stair.
- A player who took the quiet routes sees different faces from one who forced the gates (the callbacks read the choices, not the route), so the climb reads differently on a second run.
