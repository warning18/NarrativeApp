# Vica, the guide dog: the companion every hero gets (Narrative, proposal)

Status: **proposal, no data change.** Docs only; built after the user's OK on this note. Settled by the user: the dog is **Vica**, she is the tutorial's guide and **the only dog of the game** (she does not appear in chapter 1 outside the tutorial animations), and she is **the mandatory companion**: every hero gets her, there is no quest and no way to refuse her, and she is how the game guarantees a party (difficulty is balanced for "hero plus Vica"). Other companions are bonuses that replace her later; she is always there if the party would otherwise be empty. Core's part (#568): `ranger` class, her own hound die, approval 1 / −1 / 0, a duo with Liora; Core's entry says she joins automatically.

## 1. What the tutorial's dog is

She speaks in the first person, cheerfully ("Woof! I'm {name}… I trot along each time the story moves on"), and is unnamed by default: `{name}` is the name the player sets in Settings, falling back to "your companion". So Vica is a friendly, show-you-around dog.

**Her sprite** (`assets/visuals/companion/dog_companion_animations`): a **small, sturdy, flat-faced dog, white with black patches, black upright ears**, short legs: a bulldog or terrier type. The story must not contradict it, so Vica is exactly that, not a lean or sand-coloured hunting dog.

## 2. When she arrives: the end of the desert, before Saltmouth

The flow, read from the story file:

1. The Lark crashes in the Waste (965 → 1100), then two land crossings (the wreck → the Sleeper's Face → the White Wells).
2. At the White Wells the hero chooses a road south (`1000`, `1001` or `1002`, the origin endings; each "Proceed to Chapter 2", each grants the heirloom piece).
3. **2001, "[CHAPTER 2: SALTMOUTH]":** "Ten days with the salt caravan… On the eleventh morning the dunes gave up, and Saltmouth came up out of the haze."

**Saltmouth is the city after the desert.** "Just before reaching the city, almost dead from being lost" is the last leg of those ten days: the caravan's tenth day. The arrival is therefore one new scene **between the origin endings and 2001**, in the id space of chapter 1: **`1005_vica`**. The three origin endings point to it instead of 2001 (links only; their text, flags and banner grants are unchanged), and it leads to 2001, whose opening still reads true (the caravan, ten days, the eleventh morning).

## 3. The scene `1005_vica` (6 beats; grim, then warm)

1. On the tenth day the south wind stood up and the dunes began to move. The camels bolted and the water-skins went with them; I ran after the nearest, and the sand closed behind me like a door.
2. I do not know how long. The sun was a white coin. Every dune was the same dune and my own tracks were gone. I sat down, because walking in circles cost more than sitting.
3. *(the turn)* Something moved at the edge of my eye: a dog, small and square, white with black patches under the dust, flat-faced, ears standing up like a bat's. She looked at me the way you look at a decision. She turned, took three steps, and looked back.
4. I followed because I had nothing left to argue with. She stopped at every crest and waited for me, and at dusk, on the last ridge, she sat.
5. *(warm)* Below us were the caravan's fires, and past them a line of white walls and a stone giant standing in the sea. The caravan master was shouting a word into the wind: "**Vica!** Vica, the sand's guide; she comes to whoever the storm is about to bury."
6. She came down the ridge to him, and then she turned and came back to me. Whatever the salt-cutters say about her, she had made up her own mind.

For a hero whose sister lived (`lysa_survived`), one extra line: Lysa's voice somewhere behind the wall of sand, calling a name; for one who lost her (`lysa_lost`), none.

### What the player chooses (no way to refuse)

All three end with **Vica joining the party** at the choice, then 2001:

- **"Follow her down."** She starts steady.
- **"Pour what is left in your flask into your hand for her."** She starts devoted (`vica_shared`).
- **"Count some coins into the sand for her."** The hero gives her money, which a dog cannot use. She looks at the coins, looks at the hero, and sits down on them, as one sits on a fool's argument, with a sigh through her nose. She starts **wary of the hero's stupidity** (`vica_paid`), a gently comic beat. No coin is actually spent (no `goldMod`); the line is only flavour.

Nothing else differs; the starting standing is Core's number, set by these flags. The choices are short lines, no cost, no check.

## 4. Chapter 1 loses its dog: the warhound of scene 270 becomes a war-hawk

There is **one dog**. Chapter 1 has a second one today: the grey warhound caught in razor wire in Weaver's Alley (`companion_hound`), who follows the hero and is whistled for in 820, 823 and 891. It must stop being a dog, with every choice, outcome and flag still working. The smallest rewrite: **it becomes an Inquisition war-hawk**, and its dead handler a falconer. A bird is freed from wire, hops to a shoulder, answers a whistle, takes a Warden across the eyes, and dives at a porter's hat; every beat of the hound is kept, and nobody mistakes it for Vica.

**The flags keep their ids and change meaning** (`companion_hound`, `hound_left`, `hound_wardens`, `hub_891_hound`). Renaming would break any save that already holds them and two tests that read `companion_hound` as a string; the ids are internal.

| Scene | The one-line change (EN and FR; no choice, outcome or flag changes) |
|---|---|
| **270** | "a lean grey warhound, one ear reduced to ribbons, foam at its jaws" → "a grey war-hawk, one wing torn, its beak open"; the handler becomes "an Inquisition falconer, white on his sleeve", "a leash gone slack" → "a jess"; "hound/dog" → "hawk/bird"; the prompt "What becomes of the beast and its handler?" keeps its words. The three choices' texts do not change. `facing: plague_hound` (the dog portrait) is removed: no portrait. |
| **300** (two callbacks) | `companion_hound`: "had fallen into step three paces behind me" → "had hopped to my shoulder, where some dead falconer had trained it to ride"; `hound_left`: "the dog tested it again" → "the bird". |
| **820** | choice "Whistle for the hound" → "Whistle for the hawk" / « Siffler le faucon ». Same `showIfFlags`, same `hound_wardens`. |
| **823** (callback) | "a grey blur taking the nearest Warden by the throat" → "…across the eyes"; "the dog sat afterward, panting" → "the hawk perched afterward on a broken rail". |
| **891** | choice "Whistle for the hound" → "Whistle for the hawk"; its callback: "the hound had gone ahead into the crowd… nosing at my hand… trip a porter" → "the hawk had gone ahead over the crowd… came back to my glove, dived once at a porter's hat, and settled on my shoulder". |

Nothing else in chapters 1 to 3 mentions the dog (105 and 2001 have a simile each; Saltmouth's "plague hound" is an enemy, not a companion).

**Risk:** text only. No choice, flag, reward or number moves, so **no story pin, no simulator tuple and no test count changes** (Core has nothing to re-pin for this part). The two tests that mention `companion_hound` only read the flag's id. The French lint and `qa_story_fr` run on the new text. The tutorial's walking dog is UI and is not touched.

## 5. The Settings name

The player's own name for her still applies to the tutorial and the walking strip; in the story she is Vica (a clash only shows for a player who renamed her, and the story's name is the salt-cutters' name for her). **Approved:** `tut_guide_default_name` = **Vica / Vica** (one string, EN and FR), so the unnamed tutorial dog is already Vica. No `{dog}` token.

## 6. What Core's entry needs from me

`companionName`: **Vica** / **Vica**; no `recruitQuestId`; `requiredHouseId`: empty; approval 1 / −1 / 0; a duo with Liora: **The Hunt / La Battue**. The join is on the closing choice of `1005_vica` (any of the three).

### The lines (action beats, EN / FR)

| Field | EN | FR |
|---|---|---|
| `critLine` | Vica lunges, jaws closing on the gap. | Vica bondit, les mâchoires se referment sur la brèche. |
| `dodgeLine` | Vica is already three paces to the left. | Vica est déjà trois pas plus loin sur la gauche. |
| `fightStartLine` | Vica drops low and watches the foe, not you. | Vica se tapit et guette l’ennemi, pas vous. |
| `packLine` | Vica counts them with her nose, then stands beside you. | Vica les compte au flair, puis se place à vos côtés. |
| `koLine` | Vica drags herself between you and the next blow. | Vica se traîne entre vous et le prochain coup. |
| `chestLine` | Vica sniffs the lid and sits, waiting for you to open it. | Vica flaire le couvercle et s’assoit, attendant que vous l’ouvriez. |
| `devotedLine` | Vica walks ahead for the first time, and looks back to see you follow. | Vica marche devant pour la première fois et se retourne pour voir si vous suivez. |
| `warnLine` | Vica stops three paces ahead and will not walk on until you look at her. | Vica s’arrête trois pas devant et ne repart pas avant que vous la regardiez. |
| `leaveLine` | Vica sits down in the road, and does not follow. | Vica s’assoit au milieu de la route et ne suit plus. |

**Walk lines:** "Vica keeps her pace to yours, a hand’s breadth from your knee." / « Vica règle son pas sur le vôtre, à un souffle de votre genou. » · "Vica stops at every corner and waits for you to choose." / « Vica s’arrête à chaque angle et attend que vous choisissiez. » · "Vica sniffs the air and looks at you." / « Vica hume l’air et vous regarde. »

**Remarks:** kindApproved "Vica presses against your leg and does not move for a while." / « Vica se serre contre votre jambe et ne bouge plus pendant un moment. » · cruelDisapproved "Vica stops three paces ahead and will not walk on until you look at her." · checkPassed "Vica had already turned her head toward the right door." / « Vica avait déjà tourné la tête vers la bonne porte. » · checkFailed "Vica sat down in the road and looked at you, patiently." / « Vica s’assit en travers du chemin et vous regarda, patiemment. » · approved "A short bark, once, like a lamp being lit." / « Un aboiement bref, une fois, comme une lampe qu’on allume. » · disapproved "Vica turns away to watch the road behind." / « Vica se détourne pour guetter la route derrière vous. »

### A loyalty scene idea (the camp, once her standing is high)

*The wind.* One dusk at the cove the wind comes up off the sand-road. Vica goes still, faces it, and walks out; she comes back with a lost camp child (or a goat), the mirror of the hero's desert. She walks **ahead** of the hero to the fire for the first time.

## 7. Scenes that show Vica beside the hero (for UX)

None before `1005_vica` (chapter 1 has no dog; the war-hawk of 270 is a bird). From her arrival: every scene that opens as the **street** or a **room**, the **page** scenes of chapters 2 to 8 and the hub maps (as the mark's companion), in **fights** and the **camp** as any companion. **Absent (to confirm with UX and Core):** the cathedral ceremony (`4999_standard`, `4999_drawn`), the chair chapel of the Reliquary Quarter (`6010_lysa_*`, `6010_clement_refused`), the Candlehold throne scenes (`7520_*`, `7590_*`), and the ending.

## 8. Risks

- `1005_vica` is a new scene: `chapter_one_test` (the scene count and the White Wells links), the world map's scene list, the city-plan and the simulator pins (it moves the dice, as every added scene has) all need the usual updates, as with the page turns. The hawk edits move no pin.
- The three origin endings change their `next_id` only; their banner grants are untouched.
- Core: the guarantee that she is in the party when it would be empty, her fight and duo, and the join on a choice. None of it is Narrative's.

## 9. Decisions for the user

1. **The war-hawk** (section 4): the freed creature of Weaver's Alley becomes an Inquisition hawk and its handler a falconer, in five scenes, text only. Or another creature (a ferret, a cat)? A hawk answers a whistle, which keeps 820 and 891 as they are.
2. **The third desert choice** (section 3): coins for a dog; she starts wary of the hero's stupidity. Fine?
