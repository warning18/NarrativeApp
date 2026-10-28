# Vica, the guide dog, as a companion (Narrative, proposal)

Status: **proposal, no data change.** Docs only; built after the user's OK on this note. Settled by the user: the dog is named **Vica**, she is **the same dog as the tutorial's guide**, and she is a normal companion found in Saltmouth (the second big town) through a quest, replaceable by the story's other companions, no alignment gate. Core's part (#568): `ranger` class, her own hound die, approval 1 / −1 / 0, a duo with Liora. Quest numbers and the ally id stay Core's.

## 1. What the tutorial's dog is today

- She **speaks in the first person**, cheerfully: "Woof! I'm {name}. The first time you find something new, I'll show you around." … "And that's me! I trot along each time the story moves on. The arrow tucks me away."
- She is **unnamed by default**: `{name}` is the player-set `companionNameProvider` (Settings), and `tut_guide_default_name` falls back to "your companion" / « votre compagnon ». She is a guide first, by voice.
- She trots across the screen (the walking strip) from the first page of the game.

So Vica must be a friendly, eager, show-you-around dog, and her name is Vica unless the player renamed her in Settings.

## 2. One dog: the grey warhound of Weaver's Alley

The story already has a dog (scene 270): *a lean grey warhound*, one ear in ribbons, caught in razor wire beside her dead Inquisition handler. "Cut it free" sets `companion_hound`; she walks three paces behind, fights the Wardens on a whistle (820/823) and works the quay crowd (891). Then nothing, once the Lark lifts (960). **That dog is Vica.** The tutorial's cheerful guide is what she is once she is fed and trusted; the wire is the worst day of her life.

### The line of her story

1. **Alster (270):** freed (`companion_hound`), left (`hound_left`) or her handler stripped. Unchanged, except she is a *she*, and the foam is hunger and thirst, not rabies (see the edits).
2. **The Lark lifts (960):** a new line for a player who freed her: she does not come aboard; "the dog sat at the foot of the gangway and watched the sky". Whoever freed her or not, the Inquisition holds the quay that night.
3. **Saltmouth:** the Inquisition ships its tracker hounds down the coast; Renn keeps a grey warhound with a ribbon ear in the **rotting hulk** at the Ship-breaker's Yard, chained, used to find "deportees". Her brass collar tag reads VICA.
4. **The quest:** the player gets her out. A player who freed her in Alster is **recognised**: she answers the dead handler's whistle (the same whistle as 820). Anyone else gets a fresh start with a stranger.

Whether the player freed her in Alster or never met her, Vica ends up the same dog in the same camp.

## 3. Where, and the 5-open rule

**The Ship-breaker's Yard**, in the rotting hulk. The Yard has 4 entries (3 open) today; Vica's quest makes it 4 open, inside "at most 5 open quests per place". It appears after the Wharf's first job is taken (`showIfFlags: hub_2015_dockside`) so it never competes with the opening list.

## 4. The quest `q_ch2_vicas_walk` (side, short, a Flag objective)

1. **Hear:** the yard hands say Renn's men keep a grey tracker in the rotting hulk and never feed her.
2. **Go in.** Three ways, no fight:
   - **Pay the guard** (a little gold): she is handed over on a short chain.
   - **Slip the chain at night:** no gold, a flag that Renn's men may notice (read by nothing else).
   - **Show the dead handler's whistle** (only if `companion_hound`): she comes at once; the guard does not stop her.
3. **Read the tag:** VICA. The player says it; she looks up.
4. **She joins.** The player may fold a paper boat with the Tide-Kin for the handler she lost (optional, in the camp loyalty scene).
5. **No alignment gate.** The way chosen only sets how she starts: devoted (the whistle, or the paid way), steady, wary.

## 5. The small edits to chapter 1 (all text and one callback; no choice, outcome or flag changes)

| Scene | Edit |
|---|---|
| 270 | "it" → "she" / « elle », EN and FR; "foam gathering at its jaws in a way that argued either rabies or several very bad days" → hunger and thirst (not a disease), so the cheerful guide is not a rabid dog; the callback "I had no name for it yet" → "for her". The `companion_hound` / `hound_left` flags and choices are unchanged. |
| 300, 820, 823, 891 | "the dog / the hound" → "she"; no text otherwise. |
| 960 | one new `flag_callback` on `companion_hound`: she does not board; the quay. |
| 2015 (Saltmouth hub) | one new row for the quest (replaces nothing; the Yard stays at 4 open). |
| new scenes | `2015_vica` (the hulk), `2015_vica_pay`, `2015_vica_slip`, `2015_vica_whistle`: three to four, one page each. |
| `hound_left` | read by the new quest only as a recognition line ("I had not looked back"); no other effect. |

## 6. What Core's entry needs from me

- `companionName`: **Vica** / **Vica**. `recruitQuestId`: `q_ch2_vicas_walk`. `requiredHouseId`: empty. Approval 1 / −1 / 0.
- A duo technique with Liora: **The Hunt / La Battue**.
- The default for `tut_guide_default_name` and the unnamed dog: **Vica / Vica** (Core's call, one string). A player who typed another name in Settings keeps it for the tutorial and the strip; the story always says Vica.

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

**Remarks** (`companion_remarks.json`): kindApproved "Vica presses against your leg and does not move for a while." / « Vica se serre contre votre jambe et ne bouge plus pendant un moment. » · cruelDisapproved "Vica stops three paces ahead and will not walk on until you look at her." · checkPassed "Vica had already turned her head toward the right door." / « Vica avait déjà tourné la tête vers la bonne porte. » · checkFailed "Vica sat down in the road and looked at you, patiently." / « Vica s’assit en travers du chemin et vous regarda, patiemment. » · approved "A short bark, once, like a lamp being lit." / « Un aboiement bref, une fois, comme une lampe qu’on allume. » · disapproved "Vica turns away to watch the road behind." / « Vica se détourne pour guetter la route derrière vous. »

### A loyalty scene idea (the camp, once her standing is high)

*The whistle.* At dusk at the cove Vica sits at the water as she sat on the quay. The player whistles the dead handler's call, and instead of coming back she **walks ahead** and stops at the edge of the camp, the guide she was trained to be. It is the first time she leads; the player follows her to the fire. Optional: fold a paper boat for the handler with the Tide-Kin.

## 7. Scenes that show Vica beside the hero (for UX, once she is seated)

None before she joins, except in chapter 1 for a player who freed her.

- **Chapter 1, only with `companion_hound`:** 270 (when freed), 300 (the street), 820 and 823 (the cells), 891 (the quay). She is absent from 960 (she stays on the quay).
- **After `q_ch2_vicas_walk`, while she is in the party:** every scene that opens as the **street** or a **room**, and the **page** scenes of chapters 2 to 8 and the hub maps (as the mark's companion), with these **exceptions where she is absent**: the Black Hold cells (800–823; the story is past them, but note the hound is in 820/823 as a flag-only beat), the cathedral ceremony (`4999_standard`, `4999_drawn`), the chair chapel of the Reliquary Quarter (`6010_lysa_*`, `6010_clement_refused`), the Candlehold throne scenes (`7520_*`, `7590_*`), the ending. These are to confirm with UX and Core.
- In **fights** and the **camp**, her place is the companion's, as for the others.

## 8. Decisions for the user (the wording, not the premise)

1. **Vica is cheerful in the tutorial and starved in the wire.** The edits above make 270 soft enough (hunger, not rabies) for one dog; does the user want her grimmer in Alster and warmer in Saltmouth, as written, or warmer from the start?
2. **A player who renamed her in Settings:** the story says Vica; the tutorial and the strip keep the player's name. Fine?
3. **The quest in the rotting hulk, tied to Renn's pound,** or a gentler find (a stray at the Yard, no Renn)?
