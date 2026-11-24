# P4 draft: meet the Mire Courts and the Grey Vigil before they matter

**Why** (story review 3.2, 6.2, 7.1): the Mire's NPCs are seven in chapter 4 and one in chapter 2; the Vigil's are seven in chapter 5 and one in chapter 6; both are throne claimants and both carry intrigues that hook in chapter 3 (`the_returned`, `hooded_lantern`, `unwatched_hour`). The player meets the people a chapter or two after the story has begun to ask about them.

**What is already in the data (so the drafts are small):**
- **Sister Ysolde** (`keeper_apothecary_row`, "Mire Courts apothecary", chapter 2, `saltmouth_wharf`) is already the Saltmouth apothecary, but the scene `2015_apothecary` never names her or the Courts.
- The Vigil's sergeant in `3005_clan_vigil_1` ("an orc with one ear and the patience of a headstone", chapter 3) is unnamed and nobody above her is. **Edda Grey** (`edda_grey`, "Watch-Captain of the Ridge", chapter 5, `rimewell`) is the Vigil's captain and her want is the premise of `unwatched_hour`.

**Size:** S for the four changes below (three text edits, one new scene, two NPC records). **Needs Core:** only to confirm `placeId` (`ashen_quarter_gate` exists in `geography.json`) and the camp/hub lists. **Needs the user's choice:** none beyond approving.

## 1. Mire: Ysolde named at Apothecary Row (chapter 2)

### `2015_apothecary`: append two paragraphs

- **Slots in:** the existing node (the Saltmouth hub `2015` already offers it, hidden by `hub_2015_apothecary`)
- **Reads:** nothing new
- **Sets:** `met_ysolde` (add to the existing `flagsToAdd` of the choice that leaves it, or set on entry; the node has one choice, “Back to the market”)
- **Also:** `npcs.json` `keeper_apothecary_row`: set `metNodes` to `["2015_apothecary"]` (so the codex shows her once met). The hint plants `the_returned`: its Clue is `2015_child_tongue`, “Follow the child who is talking to the gulls”.

**EN**

> Behind the counter a woman in a sister’s grey boiled fever-bark in a pot as wide as a bath. She did not ask what I wanted. She asked what hurt, and waited, and when I told her she nodded as if I had said something worth a copper.

> “Sister Ysolde,” she said, ladling. “The Mire Courts sell honest bark on this wharf, and the Courts hear every word said over it.” She looked at the gulls on the roof, then at me. “If a child ever comes to you talking to them, the Courts would like to know before the Inquisition does.”

**FR**

> Derrière le comptoir, une femme en gris de sœur faisait bouillir de l’écorce à fièvre dans une marmite large comme une baignoire. Elle ne demanda pas ce que je voulais. Elle demanda ce qui me faisait mal, et attendit, et quand je le lui dis elle hocha la tête comme si j’avais dit quelque chose qui valait un sou.

> « Sœur Ysolde, dit-elle en servant. Les Cours du Marais vendent de l’écorce honnête sur ce quai, et les Cours entendent chaque mot qu’on dit dessus. » Elle regarda les mouettes sur le toit, puis moi. « Si un enfant vient un jour vous parler comme elles, les Cours voudraient le savoir avant l’Inquisition. »

**Choices**

- EN “Back to the market” / FR “Retourner au marché” → `2015`, sets `met_ysolde`

## 2. Mire: a chapter 3 scene at the Spire (the Returned)

The Hook of `the_returned` is `3005_spire_takings` (Inquisitors lead children up the stairs). The Mire should answer it in the same hub, so the player hears whose children they are.

### `3005_ysolde_letter`: Ysolde’s message

- **Slots in:** the `3005` hub: add a choice “Take a sister’s message down to the camp” (EN) / « Porter à la sœur un message au camp » (FR) with `showIfFlags: ["hub_3005_spire_takings"]`, `hideIfFlags: ["hub_3005_ysolde_letter"]`, `next_id: "3005_ysolde_letter"` (the usual `hub_<id>` flag convention)
- **Reads:** `hub_3005_spire_takings`; `met_ysolde` is optional (a callback line changes the first sentence)
- **Sets:** `hub_3005_ysolde_letter`, `ysolde_told` (or `ysolde_not_told`); a `politics.standing` of `{"mire": 1}` on “Tell her” is Core’s to size

**EN**

> Sister Ysolde’s runner found me at the ash-market with a folded leaf and no name. “From the sister at Saltmouth,” he said. “She asks one thing: were they children of the fen, or of the coast?”

> I had watched the stairs. I knew what I had seen: pale children in grey, led up in pairs, each one looking at a gull that was not there. I could tell the runner, or I could keep it.

**FR**

> Le coureur de sœur Ysolde me trouva au marché des cendres avec une feuille pliée et sans nom. « De la sœur de Bouche-de-Sel, dit-il. Elle ne demande qu’une chose : étaient-ce des enfants du marais, ou de la côte ? »

> J’avais vu les marches. Je savais ce que j’avais vu : des enfants pâles, en gris, menés deux par deux, chacun regardant une mouette qui n’était pas là. Je pouvais le dire au coureur, ou le garder.

**Choices**

- EN “Tell him what you saw” / FR “Lui dire ce que vous avez vu” → `3005`, sets `ysolde_told`
- EN “Keep it; the Courts can learn their own news” / FR “Le garder ; les Cours apprendront leurs nouvelles” → `3005`, sets `ysolde_not_told`

Echo for later (optional, 2 lines, Narrative): a `flag_callbacks` line on `5200_clan_mire_1` (the first Mire clan scene, chapter 4) that reads `ysolde_told` ("The sister at Saltmouth had sent word ahead.") or `ysolde_not_told` ("Nobody had told them. They had found out the way the Courts find out everything.").

## 3. Vigil: the captain named (chapter 3)

Two text edits and one NPC move, no new scene. The Vigil's captain is **Edda Grey** (`edda_grey`, "Watch-Captain of the Ridge", chapter 5, `rimewell`; want: "the hour held, every hour, and the post never dark", which is the premise of `unwatched_hour`).

- **`3005_clan_vigil_1`**, after “Their sergeant was an orc with one ear and the patience of a headstone.” add:
  - EN: “Edda Grey, the Watch-Captain of the ridge, had sent her down.”
  - FR: « Edda Grey, capitaine de veille de la crête, l’avait envoyée là. »
- **`3100_new_moon`** (the Clue of `unwatched_hour`), after the old woman's “Every month someone is listening to the dark.” add:
  - EN: “Edda Grey has kept that post thirty-eight years,” she added. “She has never once looked away.”
  - FR: « Edda Grey tient ce poste depuis trente-huit ans, ajouta-t-elle. Elle n’a jamais détourné les yeux. »
- **`npcs.json`**: `edda_grey` → `chapter: 3`, `placeId: "ashen_quarter_gate"`, `metNodes: ["3005_clan_vigil_1"]`.
- **Reads/sets:** none new.

## What this changes in the review's numbers

- Mire: first named face moves from chapter 4 to chapter 2 (Ysolde, already an NPC) with a chapter 3 follow-up.
- Vigil: first named face moves from chapter 5 to chapter 3 (Edda Grey), named in `3005_clan_vigil_1` and again in `3100_new_moon`.
