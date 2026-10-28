> **Status: BUILT in v1.602 (#575).** This note is kept as the record of the story side of Vica. What changed during the build, compared with the text below:
>
> - **The arrival** is the scene `1150_vica`, at the end of the second desert crossing (between 1140 / 1140_spotted and 1200), not before 2001. She joins through Core's `joinNodeIds` (1150_vica, with 1200 as the fallback); the choices set her mood with `approvalMods` (vica +9 for the shared water, −8 for the coins), not a `recruitAllyId`.
> - **Chapter 1's dog** became **a signal-lantern** (option A below): scenes 270, 300, 820, 823 and 891, plus two similes (105, 820); the flags keep their ids.
> - **Vess** moved to chapter 2 as proposed (1210 no longer unlocks her quest; the Saltmouth hub row no longer hides on `met_vess`; the quest is chapter 2).
> - **The coin choice** costs **10 gold** (`goldMod: -10`, `pays: true`), she bites it, finds it is not food, and starts wary (`vica_paid`).
> - `tut_guide_default_name` is "Vica"; her remarks (25 rows) and her lines at fifteen scenes are in; the simulator pins were re-pinned. Core's part is `guide-dog-companion.md`.
> - Two Core tests were adjusted afterwards: `road_moves_world_view_test` (one scene further) and `road_hazards_test` (1000 draws per road).

# Vica, the guide dog: the companion every hero gets (Narrative, proposal)

Status: **proposal, no data change.** Docs only; built after the user's OK on this note. Settled by the user: the dog is **Vica**, she is the tutorial's guide and **the only dog of the game** (she does not appear in chapter 1 outside the tutorial animations), and she is **the mandatory companion**: every hero gets her, there is no quest and no way to refuse her, and she is how the game guarantees a party (difficulty is balanced for "hero plus Vica"). Other companions are bonuses that replace her later; she is always there if the party would otherwise be empty. Core's part (#568): `ranger` class, her own hound die, approval 1 / −1 / 0, a duo with Liora; Core's entry says she joins automatically.

## 1. What the tutorial's dog is

She speaks in the first person, cheerfully ("Woof! I'm {name}… I trot along each time the story moves on"), and is unnamed by default: `{name}` is the name the player sets in Settings, falling back to "your companion". So Vica is a friendly, show-you-around dog.

**Her sprite** (`assets/visuals/companion/dog_companion_animations`): a **small, sturdy, flat-faced dog, white with black patches, black upright ears**, short legs: a bulldog or terrier type. The story must not contradict it, so Vica is exactly that, not a lean or sand-coloured hunting dog.

## 2. When she arrives: the end of the desert walk after the crash

The user's wish: she appears **at the end of the desert walk after the Lark crashes**: a few steps off, the hero is lost, nearly dies, and she shows the way. The flow, read from the story file:

1. 965 → **1100** (the wreck), then the land crossing `crash_to_sleeper` → **1120**, 1125, 1130 (the Sleeper's Face), **1140** (the looters' camp; also **1140_spotted**).
2. The choices of 1140 (three) and 1140_spotted (two) take the land crossing `sleeper_to_wells` and arrive at **1200, the White Wells** ("The lights were an oasis").
3. At the Wells, the origin endings **1000 / 1001 / 1002** ("Proceed to Chapter 2"), then 2001 and Saltmouth.

The arrival is one new scene, **`1150_vica`**, at the **end of the second crossing**: the five choices of 1140 and 1140_spotted point to it instead of 1200 (their `landRouteId: sleeper_to_wells`, flags and text are unchanged; the crossing plays, then this scene), and `1150_vica` leads to 1200. It is in the id space of chapter 1, location `white_wells` (the dunes at the Wells' edge). **She joins on its closing choice, so she is in the party for the White Wells, Vess's meeting, the origin endings and everything after.** The origin endings and 2001 are untouched (the earlier plan for `1150_vica` before 2001 is withdrawn).

## 3. The scene `1150_vica` (6 beats; grim, then warm)

1. I left the Face with the first stars, and had gone perhaps two hundred paces when the dunes closed behind me like a door. The wind had already taken my tracks.
2. I do not know how long. The sun was a white coin, then it was not there. Every dune was the same dune and my mouth was sand. I sat down, because walking in circles cost more than sitting.
3. *(the turn)* Something moved at the edge of my eye: a dog, small and square, white with black patches under the dust, flat-faced, ears standing up like a bat's. She looked at me the way you look at a decision. She turned, took three steps, and looked back.
4. I followed because I had nothing left to argue with. She stopped at every crest and waited for me, and she did not once look at the sky.
5. *(warm)* The lights came up out of the dark all at once: a hollow in the dunes, palms, and a scatter of white clay huts glowing like loaves in an oven. She sat down at the edge of the light and would not go any further without me.
6. I called her Vica. I could not have told you why; the word came up out of the heat like the name of an old friend, and she turned her head as if it had been said before.

### What the player chooses (no way to refuse)

All three end with **Vica joining the party**, then 1200:

- **"Follow her down."** She starts steady.
- **"Pour what is left in your flask into your hand for her."** She starts devoted (`vica_shared`).
- **"Count some coins into the sand for her."** The hero gives her money, which a dog cannot use. She bites a coin, finds it is not food, and looks at the hero with great patience: she keeps her but starts **wary of the hero's stupidity** (flag `vica_paid`), a gently comic beat. **The money is really lost: 10 gold**, a fixed cost (`goldMod: -10`, `pays: true`). Ten is the size of chapter 1's small purses (the quay's +10, the strip-the-handler +15), so it stings without hurting a poor hero; Core confirms. A hero with less than 10 gold simply does not see this choice (the `pays` rule) and still has the other two.

Nothing else differs; the starting standing is Core's number, set by these flags. The choices are short lines.

## 4. Chapter 1 loses its dog: two ways

There is **one dog**. Chapter 1 has a second one today: the grey warhound caught in razor wire in Weaver's Alley (`companion_hound`), who follows the hero and is whistled for in 820, 823 and 891. It must stop being a dog, with every choice, outcome and flag still working, text only. Both ways below edit the same five scenes and keep the flags' ids (`companion_hound`, `hound_left`, `hound_wardens`, `hub_891_hound`) with a new meaning: renaming would break old saves and the two tests that read `companion_hound` as a string.

### A. A signal-lantern in the wire (recommended)

**In the wire:** a **Dominion signal-lantern**, a hooded brass lantern with a shuttered flare, still burning, caught in the razor wire beside its dead bearer (an Inquisition signaller, white on his sleeve). **Cut it free** = take it; it hangs on the hero's belt. **The whistle becomes raising the lantern**: the shutter opens on a white flare that dazzles.

| Scene | The one-line change (EN and FR; no choice, outcome or flag changes) |
|---|---|
| **270** | "a lean grey warhound, one ear in ribbons, foam at its jaws" → "a hooded brass lantern, its shutter bent, still burning in the wire"; the handler becomes "an Inquisition signaller"; "a leash" → "a lanyard"; "its eyes found mine… the patience of something starved" → "its small flame held steady, patient as something that has been left burning". The prompt "What becomes of the beast and its handler?" → "of the lantern and its bearer"; the choice lines keep their words ("Cut it free" works for a lantern). `facing: plague_hound` removed: no portrait. |
| **300** (2 callbacks) | `companion_hound`: "gave up the dog… had fallen into step three paces behind me" → "gave up the lantern… hung from my belt, still warm"; `hound_left`: "the wire had sung once as the dog tested it again" → "a small light still burned in the alley behind me". |
| **820** | "Whistle for the hound" → "Raise the lantern" / « Lever la lanterne ». Same `showIfFlags`, same `hound_wardens`. |
| **823** (callback) | "a grey blur taking the nearest Warden by the throat" → "a white flare that took the nearest Warden full in the eyes"; "the dog sat afterward, panting" → "the lantern hung from my belt, ticking as it cooled". |
| **891** | choice "Whistle for the hound" → "Raise the lantern"; its callback: "the hound had gone ahead into the crowd… trip a porter" → "the flare opened the crowd on the steps like a hand through water; I relieved a dropped purse of its previous owner's claim". |

It is a lantern, which the Dominion world already has everywhere (Vane's hooded black one is the Inquisitor's; this is a signaller's), and it cannot be mistaken for Vica.

### B. A wounded courier in the wire

**In the wire:** a young **Inquisition courier** (a runner, hurt, not hostile), caught in the razor wire with her escort dead beside her. **Cut her free**: she owes the hero and **walks three paces behind**, as couriers walk behind the one they carry for. **The whistle** is the courier's own brass signal whistle: **blow it** and she comes.

| Scene | The one-line change (EN and FR; no choice, outcome or flag changes) |
|---|---|
| **270** | "a lean grey warhound… foam at its jaws" → "a young Inquisition courier, a runner, her coat torn on the wire, hurt but awake"; the handler becomes "her escort, a sergeant of the Inquisition"; "a leash" stays a "strap". `facing` removed. The prompt: "What becomes of the girl and her escort?" The choices keep their words. |
| **300** (2 callbacks) | `companion_hound`: "had fallen into step three paces behind me, where some dead handler had trained it to walk" → "…where couriers are taught to walk behind whoever they carry for. I had no name for her yet"; `hound_left`: "the wire had sung once as the dog tested it again" → "somewhere in the alley a voice had said one word, and I had not looked back". |
| **820** | "Whistle for the hound" → "Blow the courier's whistle" / « Souffler dans le sifflet du courrier ». Same flags. |
| **823** (callback) | "taking the nearest Warden by the throat" → "…shouting that the Inquisitor-General wanted the Wardens at the north stair; the nearest turned, and my dagger did the rest"; "the dog sat afterward" → "she waited afterward, breathing hard". |
| **891** | choice "Whistle for the courier" with her callback: "she went ahead through the queue on the steps with a courier's pass and came back with a purse". |

It keeps the whistle literally and makes the helper a person, but it is **a second character** the player may expect to meet again (the hub flag line), and it needs the most rewriting.

### Which I recommend

**A, the signal-lantern.** It changes the fewest *meanings* (an object has no future in the story, so nothing is promised), cannot be confused with Vica, and fits the Dominion's lanterns. B keeps the whistle but creates a person the story would owe a return.

**Risk (both):** text only. No choice, flag, reward or number moves, so **no story pin, simulator tuple or test count changes** (Core has nothing to re-pin for this part). The two tests that mention `companion_hound` read only the flag's id. The French lint and `qa_story_fr` run on the new text. The tutorial's walking dog is UI and is not touched.

### Why chapter 1 changes at all (three lines for the user)

Scene 270 **as written today already has a dog**: the grey warhound caught in razor wire (cutting it free sets the flag `companion_hound`), who then follows the hero through scenes 300, 820, 823 and 891. Since the user wants **one dog only, and none in chapter 1**, those five scenes must stop showing a dog; that is the whole reason chapter 1 is touched, and no scene is added there. **The cheapest honest answer is still A** (the lantern): about ten phrases in five scenes, text only, no choice, flag or outcome changes. Deleting the warhound would be dearer: scene 270 would lose its three-way choice (its flags are read in four other scenes and two tests).

## 4b. One companion at the start: Vess moves to chapter 2

Today Vess is recruited at the end of chapter 1. The data: her quest `q_ch1_vess_in_the_dark` (a Flag objective on `void_banner_bearer`, which the three origin endings set) is unlocked either at the Wells (`1210`, a cloaked woman by the far well, for a hero with the tear's mark) or in Saltmouth (`2015_vess`, from the hub row "Face the cloaked figure trailing you"). Unlocked at the Wells, it completes at the origin endings: she joins the party at the end of chapter 1. Unlocked in Saltmouth, it completes at once: she joins in chapter 2.

**The smallest change: only the Saltmouth path unlocks the quest.**

| Where | The change |
|---|---|
| `1210` ("Go back to the fire") | remove `unlockQuestId: q_ch1_vess_in_the_dark`; keep `met_vess`. She still says "I will find you on the other side of the sand"; nothing joins. |
| hub `2015`, row "Face the cloaked figure trailing you" | `hideIfFlags` loses `met_vess` (it keeps `hub_2015_vess`), so a hero who met her at the Wells also gets the scene. `showIfFlags: void_banner_bearer` stays. |
| `2015_vess` "Hear her out" | unchanged: it unlocks the quest, and with `void_banner_bearer` already held the objective completes at once: Vess joins in chapter 2, after Saltmouth is reached, like Kelda, Sable and Liora. |
| `quests.json` | `q_ch1_vess_in_the_dark`: `chapter` 1 → 2 (the id stays, so saves and the simulator keep working). |

**What reads Vess in chapter 1:** `1200` (the row "Answer the cloaked woman" hides on `met_vess`), `1210`, `2001` (a line: she "had joined the caravan on the second night", flavour that still reads true: she walks apart from it), `3002` (a line on his name). No chapter spine beat, world-map scene or story pin reads her in chapter 1. **The ally acknowledgment lines** (`lib/data/ally_acknowledgments.dart`, Core's file) have a Vess line for several scenes; they only fire when she is in the party, so they simply start later.

**Old saves:** a save where the quest was already taken keeps its quest and companion, and the objective is unchanged. A save that met her at the Wells and has not taken the quest sees the Saltmouth row now (previously hidden). A save that took her at the Wells and is still in chapter 1 would, if it later reaches Saltmouth, see the row and "Hear her out" again: the quest unlock is a no-op, the +5 Vigil standing would repeat (small; Core may guard it).

**What Core must change:** the party rule (the party starts with Vica only, Vica is guaranteed when the party would be empty); the simulator's competent policy and `sim_companions_test` / `sim_competent_test` pins (Vess now joins in chapter 2: the tuple moves); any test that expects Vess's chapter. **Vica needs ally acknowledgment lines** in the same file (one per scene where the others have one, from chapter 2 on): I can write them in the build PR.

## 5. The Settings name

The player's own name for her still applies to the tutorial and the walking strip; in the story she is Vica (a clash only shows for a player who renamed her, and the story's name is the salt-cutters' name for her). **Approved:** `tut_guide_default_name` = **Vica / Vica** (one string, EN and FR), so the unnamed tutorial dog is already Vica. No `{dog}` token.

## 6. What Core's entry needs from me

`companionName`: **Vica** / **Vica**; no `recruitQuestId`; `requiredHouseId`: empty; approval 1 / −1 / 0; a duo with Liora: **The Hunt / La Battue**. The join is on the closing choice of `1150_vica` (any of the three).

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

None before `1150_vica` (chapter 1 has no dog; scene 270 holds a lantern or a courier, see section 4). From her arrival: every scene that opens as the **street** or a **room**, the **page** scenes of chapters 2 to 8 and the hub maps (as the mark's companion), in **fights** and the **camp** as any companion. **Absent (to confirm with UX and Core):** the cathedral ceremony (`4999_standard`, `4999_drawn`), the chair chapel of the Reliquary Quarter (`6010_lysa_*`, `6010_clement_refused`), the Candlehold throne scenes (`7520_*`, `7590_*`), and the ending.

## 8. Risks

- `1150_vica` is a new scene: `chapter_one_test` (the scene count and the White Wells links), the world map's scene list, the city-plan and the simulator pins (it moves the dice, as every added scene has) all need the usual updates, as with the page turns. The chapter 1 edits (either way) move no pin.
- The three origin endings change their `next_id` only; their banner grants are untouched.
- Core: the guarantee that she is in the party when it would be empty, her fight and duo, and the join on a choice. None of it is Narrative's.

## 9. Decisions for the user

1. **Chapter 1's creature** (section 4): the signal-lantern (A, recommended) or the wounded courier (B)?
2. **The coin choice** (section 3): 10 gold really lost, with Vica wary of the hero's stupidity. Fine, or another amount?
