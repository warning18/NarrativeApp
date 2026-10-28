# The guide dog as a companion (Narrative, proposal)

Status: **proposal, no data change.** Docs only. The user's wish: the tutorial's guide dog (its sprite exists) becomes a normal companion, found in the second big town through a quest, replaceable by the story's other companions, no alignment gate. Core sets the numbers and the build.

## What the story already has

- **A dog in chapter 1.** In Weaver's Alley (scene 270) the player meets *a lean grey warhound* in razor wire, its Inquisition handler dead beside it. "Cut it free" sets `companion_hound`; the hound walks "three paces behind" as its handler trained it, fights the Wardens on a whistle (820/823) and works the High Quay crowd (891). Nothing mentions it after the Lark lifts (960). "Leave them both" sets `hound_left`.
- **The companions** (`companions.json`, 8): Kelda, Sable, Liora in Saltmouth (chapter 2), Vess (1), Maren, Grosh (3), Tobin (4), Malrik (5). Each has a `raceId`, a `professionId` and a recruit quest.
- **The walking dog** in the app (`walking_companion_strip.dart`) is the neutral dog sprite.

## 1. Which town, and where in the flow

The first big town is Alster (chapter 1). The **second is Saltmouth** (chapter 2), through its hub `2015`.

Place: **the Ship-breaker's Yard**, in the rotting hulk. The Yard has 4 entries today (3 open at the start), so the dog makes it 4 open: inside the "at most 5 open quests per place" rule. It is also the place where the player later buys the Rusty Eel, so every run passes it. The quest appears on the hub after the Wharf's first job is taken (a `showIfFlags` on `hub_2015_dockside`), so it never competes with the opening list.

## 2. Who the dog is

**Name: Wick.** A lamp's wick is what leads you in the dark; it fits the Lantern Dominion, the Tide-Kin's paper boats and a guide's job in one syllable, and it matches the companions' short names (Kelda, Sable, Vess).

Who it belonged to: **Ormund, a blind rope-maker of the Yard**, "deported" by Renn's men over the landing toll the winter before. Wick led him along the quays every day for nine years. It came back alone, and keeps his cot in the hulk.

## 3. The quest: `q_ch2_wicks_walk` (side, short; objective: a Flag)

1. The yard hands say the grey dog in the hulk lets no one near; Ormund's cot is the only place it sleeps.
2. The player goes in. Three ways, none a fight:
   - **Walk his walk**: take Ormund's rope from the cot and walk the quay route; the dog follows at his pace, three paces ahead, not behind.
   - **Feed it and wait**: costs a little gold and a watch; it comes in the end, warier.
   - **Take it by the scruff**: it comes, but starts at lower standing.
3. On the walk the dog **stops at Renn's toll post** on Tern Row, where Ormund was taken: a line that makes Tern's Toll mean more (optional flag `wick_found_post`, read by nothing else).
4. It joins. A Tide-Kin hand at the Yard lights a paper boat for Ormund; the player may add one.
5. **No alignment gate**: every hero can do it. The choice only sets how the dog starts (devoted, steady, wary: the way a companion's standing starts).

## 4. In the camp: a first loyalty scene (wave 17 style)

*The boat for Ormund.* At the cove camp, once Wick's standing is high, the dog sits at the water's edge at dusk, as it sat on the Yard slip. The player may fold a paper boat and light it. Good: Wick walks **ahead** of the player for the first time, the guide it was. It is the scene where the dog first leads instead of following, and the tutorial's pointing dog becomes a story fact.

## 5. Remarks (`companion_remarks.json`), EN / FR, as beats, not speech

The dog cannot speak; the remark panel can show an action line. Samples for the usual triggers:

- **kindApproved:** "Wick presses against your leg and does not move for a while." / « Wick se serre contre votre jambe et ne bouge plus pendant un moment. »
- **cruelDisapproved:** "Wick stops three paces ahead and will not walk on until you look at it." / « Wick s’arrête trois pas devant et ne repart pas avant que vous le regardiez. »
- **checkPassed:** "Wick had already turned its head toward the right door." / « Wick avait déjà tourné la tête vers la bonne porte. »
- **checkFailed:** "Wick sat down in the road and looked at you, patiently." / « Wick s’assit en travers du chemin et vous regarda, patiemment. »
- **approved:** "A short bark, once, like a lamp being lit." / « Un aboiement bref, une fois, comme une lampe qu’on allume. »
- **disapproved:** "Wick turns away to watch the road behind." / « Wick se détourne pour guetter la route derrière vous. »

Leave/warn/devoted lines (`leaveLine` and the others) would also be actions.

## 6. Its entry, in line with Core's note (#568)

Core's part gives the dog `raceId: ""`, `professionId: ranger` and its own **hound die**, so no companion without a profession is needed (I had asked; withdrawn). `approvesGood / approvesEvil / approvesProfit` are 1 / −1 / 0, so Wick rarely leaves. Core also builds a duo technique with **Liora** (the ranger, "the hunt"); I name it **The Hunt / La Battue**. Liora is also at Saltmouth, so the two can be found within the same chapter.

Name: `companionName` Wick / Wick (the same in French). Quest `q_ch2_wicks_walk` (`recruitQuestId`); its numbers and the reward ally id are Core's.

### The lines the entry needs (all as action beats, EN / FR)

| Field | EN | FR |
|---|---|---|
| `critLine` | Wick lunges, jaws closing on the gap. | Wick bondit, les mâchoires se referment sur la brèche. |
| `dodgeLine` | Wick is already three paces to the left. | Wick est déjà trois pas plus loin sur la gauche. |
| `fightStartLine` | Wick drops low and watches the foe, not you. | Wick se tapit et guette l’ennemi, pas vous. |
| `packLine` | Wick counts them with its nose, then stands beside you. | Wick les compte au flair, puis se place à vos côtés. |
| `koLine` | Wick drags itself between you and the next blow. | Wick se traîne entre vous et le prochain coup. |
| `chestLine` | Wick sniffs the lid and sits, waiting for you to open it. | Wick flaire le couvercle et s’assoit, attendant que vous l’ouvriez. |
| `devotedLine` | Wick walks ahead for the first time, and looks back to see you follow. | Wick marche devant pour la première fois et se retourne pour voir si vous suivez. |
| `warnLine` | Wick stops three paces ahead and will not walk on until you look at it. | Wick s’arrête trois pas devant et ne repart pas avant que vous le regardiez. |
| `leaveLine` | Wick sits down in the road, and does not follow. | Wick s’assoit au milieu de la route et ne suit plus. |

### Walk lines (the dog crossing the screen, one per mood)

- "Wick keeps its pace to yours, a hand’s breadth from your knee." / « Wick règle son pas sur le vôtre, à un souffle de votre genou. »
- "Wick stops at every corner and waits for you to choose." / « Wick s’arrête à chaque angle et attend que vous choisissiez. »
- "Wick sniffs the air and looks at you." / « Wick hume l’air et vous regarde. »

### Remarks (`companion_remarks.json`)

The six in section 5, plus `kindApproved` and `cruelDisapproved` which are already there; Core's approval tuning needs nothing else from me.

## 7. Decisions for the user

1. **Wick is a new dog, not the chapter 1 hound.** Alternative: it **is** the hound of 270. A player who cut it free finds it again in Saltmouth (it followed the caravan's tracks: "three paces behind" is the old training); a player who left it gets a second chance. The hound has a dead handler already, so Ormund would be dropped. I recommend the new dog: the ch1 hound is one scene's gift and may already be gone from many saves, and Wick's story gets its own place at the Yard. Say if you would rather they be one dog.
2. **The name:** Wick, or another.
3. **No gate, but the start differs** (walk / feed / force): fine?
