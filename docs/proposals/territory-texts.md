# Territory, fall and alignment hunters: the words (Narrative, proposal)

The words for Core's plan `docs/proposals/territory-power-nemesis.md` (branch `claude/core-2`, with the user's addendum). English then French. Placeholders in braces are Core's to fill: `{clan}` `{attacker}` `{winner}` `{loser}` `{place}` `{seat}` `{gold}` `{n}`. Clan names come from `factions.json` (`name`, `nameOf`, `short`); French agrees with the clan, never the player (*vous*, no gendered forms). Docs only, no version.

**Contents:** 1. claim lists; 2. places changing hands; 3. the crisis; 4. the fall; 5. alignment hunters; 6. nemesis quests (outline).

---

## 1. The six claim lists

Each list is ordered: the first claim is the one a clan takes first. Place ids are from `geography.json`. Where a clan already holds places, I picked claims that extend what it already is; the three that hold nothing get a foothold that fits the story.

| Clan | Holds today | Claims, in order | Why |
|---|---|---|---|
| **Dominion** | Candlehold, Lantern Hall, Spire of Judgment, Black Hold, Spire Stair | 1. `saltmouth_landward_gate` 2. `reliquary_quarter` 3. `white_anchorage_chapel` | The Inquisition already searches the caravans at the Landward Gate. The Reliquary Quarter is the Dominion's own holy things. The Stern Chapel was built by crusaders. |
| **Crows** | Lower Town, Wharf, Card Row | 1. `saltmouth_lantern_alleys` 2. `alster_high_quay` 3. `wracks_end` | Lantern Alleys are already their buyers' back ways; the High Quay is where vessels that should not float tie up; Wrack's End is wreckers and salvage. |
| **Compact** | Emberwick, Cinder Row | 1. `ashen_quarter_ash_market` 2. `saltmouth_yard` | The Ash-Market is where their forge street sells; the Ship-breaker's Yard is iron and hulls. Two claims only: the Compact is small and makes, it does not conquer. |
| **Vigil** | nothing | 1. `rimewell` 2. `ashen_quarter_gate` 3. `hollow_shore_battlefield` | A watch takes the halt before the tear, the gap in a wall, and the strand where the Host met the tear. All places to *watch from*. |
| **Mire** | nothing | 1. `kindly_hill` 2. `drowned_cloister_nave` 3. `drowned_cloister_ossuary` | Kindly Hill first, as Core drafted: the fen's oldest neighbour. The Mire's secrets live where the water is deepest. |
| **Penitents** | nothing | 1. `ashen_quarter_wall_of_names` 2. `white_anchorage_chapel` 3. `greyhithe` | They carry what they burned: the Wall of Names, a chapel, a village the tear ate. |

**Conflicts to know about**
- `white_anchorage_chapel` is claimed by both the Dominion (3rd) and the Penitents (2nd). That is intended: a built-in quarrel over one chapel. The Penitents reach it first (lower tier needed), and the Dominion then contests it.
- Kindly Hill is held by the Kindly (a minor holder), so the Mire's first claim is a taking from a non-clan. Core decides whether that needs a news line of its own (see 2c).
- **Seats.** Seats can now fall. Proposed seat for each clan: Dominion `candlehold`; Crows `saltmouth_wharf`; Compact `emberwick`; Vigil `rimewell` (it holds nothing today, so its seat appears when it takes its first claim); Penitents `ashen_quarter_wall_of_names`; Mire: none placed yet, since "nobody from outside has been told where they sit". **Asked of Core:** one hidden district for the Mire (suggested id `mire_court`, name *The Mire's Court* / *La Cour du Marais*, not on the map until the Mire is Friendly with you, blurb to come from me).

---

## 2. Places changing hands: the news lines

Shown in the news feed and the clan log. Two variants each, picked by place id hash, so the feed does not repeat.

### 2a. A place taken (power)

| EN | FR |
|---|---|
| {clan} hold {place} now. | {clan} tiennent {place} désormais. |
| The banners over {place} have changed: it is {clan}'s now. | Les bannières ont changé sur {place} : c’est à {clan} désormais. |

Use `nameOf`-style phrasing where the clan name is singular in French (*La Veille grise tient…*). Core: `{clan}` should be the short name with its article (*le Compact*, *les Corbeaux*); `factions.json` needs an `article` field if it does not have one, and I will add it.

### 2b. A place taken in war ({winner} from {loser})

| EN | FR |
|---|---|
| War: {winner} took {place} from {loser}. | Guerre : {winner} a pris {place} à {loser}. |
| {loser} lost {place} to {winner}, and neither side is pretending it was an accident. | {loser} a perdu {place} au profit de {winner}, et personne ne fait semblant d’y voir un accident. |

### 2c. A place taken from a minor holder

| EN | FR |
|---|---|
| {place} has new masters. {clan} did not ask. | {place} a de nouveaux maîtres. {clan} n’a rien demandé à personne. |

### 2d. A seat falls (not your main clan)

| EN | FR |
|---|---|
| {clan} has fallen: {winner} holds {seat}. | {clan} est tombé : {winner} tient {seat}. |
| {seat} is {winner}'s. {clan} has no place left to stand. | {seat} est à {winner}. {clan} n’a plus un pouce de terrain. |

French agreement is with the clan noun (*La Veille grise est tombée*). Core can pass a gender code with the clan (`m`, `f`, `mp`, `fp`); the lines above show the masculine, and I will give the full set once Core says how it wants the parameter.

### 2e. The clan log line (shorter)

- EN: *{place}: {loser} → {winner}.*
- FR : *{place} : {loser} → {winner}.*

---

## 3. The crisis: your main clan's seat is threatened

One shared template (clan colour comes from the clan, not a text per clan).

**Title.** EN: *{clan} sends for you.* / FR : *{clan} vous fait appeler.*

**Body.**
- EN: A rider finds you on the road at dusk. {attacker} is at the gates of {seat}, and {clan} has nothing left to hold them with but you. “It is not a command. It is the last thing we have to ask.”
- FR : À la nuit tombante, un messager vous rejoint sur la route. {attacker} est aux portes de {seat}, et {clan} n’a plus que vous pour les retenir. « Ce n’est pas un ordre. C’est la dernière chose qu’il nous reste à demander. »

### The three choices

| Choice | EN button | FR button |
|---|---|---|
| Defend | Defend {seat} | Défendre {seat} |
| Pay | Pay {gold} gold | Payer {gold} pièces d’or |
| Pay (materials) | Send timber and stone | Envoyer bois et pierre |
| Refuse | Refuse | Refuser |

### The outcomes

- **Defend, win**
  - EN: You hold the gate until {attacker}'s hunter breaks. The seat stands, and {clan} remembers who stood on it.
  - FR : Vous tenez la porte jusqu’à ce que le chasseur de {attacker} cède. Le siège tient, et {clan} se souviendra de qui s’y tenait.
- **Defend, lose** (the seat falls)
  - EN: You are carried off the field. By morning, the banner over {seat} is {attacker}'s.
  - FR : On vous emporte hors du champ. Au matin, la bannière sur {seat} est celle de {attacker}.
- **Pay, held**
  - EN: The gold goes out through the postern. {attacker} takes the money and a smaller prize, and {seat} stands one more season.
  - FR : L’or sort par la poterne. {attacker} prend l’argent et un lot de moindre prix, et {seat} tient une saison de plus.
- **Pay, held (materials)**
  - EN: The wagons roll in with timber and cut stone, and the breach is mended before the second assault.
  - FR : Les chariots entrent chargés de bois et de pierre taillée, et la brèche est réparée avant le second assaut.
- **Refuse**
  - EN: “Then we understand each other.” {clan} does not argue. {seat} falls within the week, and the way they look at you changes.
  - FR : « Alors nous nous comprenons. » {clan} ne discute pas. {seat} tombe dans la semaine, et la façon dont on vous regarde change.
- **Standing log, defend/refuse** (`standing_cause_*`)
  - EN: *Held the seat* / *Refused the seat*; FR : *Siège défendu* / *Siège abandonné*.

---

## 4. The fall

### 4a. The news line (your main clan)

- EN: **{clan} has fallen.** {winner} holds {seat}.
- FR : **{clan} est tombé.** {winner} tient {seat}.

### 4b. The choice scene (a fallen clan is your main clan)

**Title.** EN: *The banner comes down.* / FR : *La bannière descend.*

**Body.**
- EN: The last banner over {seat} is folded. {winner}'s people stand in the yard, and {clan}'s survivors look at you the way you look at a road that has ended. “You do not have to follow us into the dark,” they say. “But nobody will think the worse of you if you do.”
- FR : La dernière bannière sur {seat} est pliée. Les gens de {winner} sont dans la cour, et les survivants de {clan} vous regardent comme on regarde une route qui s’arrête. « Vous n’avez pas à nous suivre dans le noir, disent-ils. Mais personne ne vous en voudra si vous le faites. »

| Choice | EN | FR |
|---|---|---|
| a) | Bend the knee to {winner} | Plier le genou devant {winner} |
| b) | Stay of {clan} | Rester de {clan} |

### 4c. Bending the knee

**The oath (one template).**
- EN: *I came to you with another banner. That banner is down. I swear to yours, and I will carry yours as I carried theirs.*
- FR : *Ma bannière est tombée. Je jure sur la vôtre, et je la porterai comme j’ai porté la première.*

**The tithe line.** EN: {winner} takes its tithe: a fifth of your gold, once. / FR : {winner} prélève sa dîme : un cinquième de votre or, une seule fois.

**Clan log.** EN: *Sworn to {winner}, after the fall of {clan}.* / FR : *Juré à {winner}, après la chute de {clan}.*

### 4d. Staying of a fallen clan

**Clan tab label.** EN: *Fallen* / FR : *Tombé* / *Tombée* (agrees with the clan, via the same gender code as 2d).

**Short description (clan tab, for the player).**
- EN: {clan} has no place left to stand. You keep its ways, but you swear to no one, and {winner} will not forget you stayed.
- FR : {clan} n’a plus un pouce de terrain. Vous gardez ses usages, mais vous ne jurez à personne, et {winner} n’oubliera pas que vous avez gardé la foi.

**The survivors' suitor line** (when one of the fallen clan's offers comes on a road).
- EN: One of {clan}'s survivors finds you in the dust. “We are few, but we are still {clan}. We still have something to give.”
- FR : Quelqu’un de {clan}, un de ceux qui restent, vous retrouve dans la poussière. « Nous sommes peu, mais nous sommes toujours {clan}. Nous avons encore quelque chose à donner. »

**The pledge line (your banner rises).**
- EN: {clan}'s survivors come to your banner and kneel. “We have none of our own. We will keep yours.”
- FR : Les survivants de {clan} viennent à votre bannière et s’agenouillent. « Nous n’en avons plus. Nous garderons la vôtre. »

**The clan rises again (ends the state).**
- EN: {clan} has taken a place back. The banner is up again over {place}.
- FR : {clan} a repris pied. La bannière flotte de nouveau sur {place}.

---

## 5. The alignment hunters

### 5a. The six

| Side | Fighter | Verdict | Note |
|---|---|---|---|
| Good → hunts Evil | **Vigil candle-bearer** (`vigil_candlebearer_ysel`, align 25) | **confirm** | counts the dead, keeps faith; hunts a hand that has killed too many |
| Good → hunts Evil | **Masked Penitent** (`masked_penitent`, 15) | **confirm** | a penitent hunts what it has burned in itself |
| Good → hunts Evil | **Inquisition soldier** (`inquisition_soldier`, now 10) | **replace with Halvard** (`vigil_spearman_halvard`, 30) | I moved the soldier to 10 last release (paid by the heresy found), so he reads Neutral to Perception, and a “good order” should read Good. Halvard is +30 and already has a cry. Keep the soldier as a clan hunter only. |
| Evil → hunts Good | **Cultist acolyte** (`cultist_acolyte`) | **confirm** | a novice of the void cults |
| Evil → hunts Good | **Hollow Court zealot** (`hollow_court_zealot`) | **confirm** | prays to the tear in the Church's own words |
| Evil → hunts Good | **Void stalker** (`void_stalker`) | **confirm** | follows the Shroud's trail, strikes when sure |

Core: the evil three need `alignment` between −25 and −35 so the mercy read (Perception) says *Evil* and not *Neutral*.

### 5b. Battle cries (for the three that lack one)

| Fighter | EN | FR |
|---|---|---|
| Cultist acolyte | “The tear is kind. It sent me to carry you home.” | « Le déchirement est bon. Il m’envoie vous ramener chez vous. » |
| Hollow Court zealot | “Light, and law, and the hollow. You are on the wrong side of the third.” | « La lumière, la loi, le vide. Vous êtes du mauvais côté du troisième. » |
| Void stalker | *(no words; a sound like a door opening in a wall)* | *(aucun mot ; un bruit de porte qui s’ouvre dans un mur)* |

### 5c. Ambush lines (alignment hunters), by side

These replace the generic template when `hunterAlignment` is set. `{name}` is the fighter, `{cry}` the battle cry.

**Good orders hunting an Evil character**
- EN: {name} was waiting where the road bends. You have left too many dead behind you for the light to ignore, and this one has come to settle it. {cry}
- FR : {name} attendait au tournant. Vous avez laissé trop de morts derrière vous pour que la lumière l’ignore, et ce chasseur est venu régler le compte. {cry}

(*Ce chasseur* is neutral for a hunter whose gender we do not fix.)

**Evil forces hunting a Good character**
- EN: {name} steps out of the dark where the road bends. You have kept your hands clean, and the dark has noticed. {cry}
- FR : {name} sort de l’ombre au tournant. Vous avez gardé les mains propres, et l’ombre l’a remarqué. {cry}

**Hunting a Neutral character, from the good side**
- EN: {name} blocks the road. “You have not chosen,” {name} says, “and both sides have noticed. I am only the first to say it.” {cry}
- FR : {name} barre la route. « Vous n’avez pas choisi, dit {name}, et les deux camps l’ont remarqué. Je ne suis que le premier à vous le dire. » {cry}

**Hunting a Neutral character, from the evil side**
- EN: {name} is sitting in the road as though it had been there for years. “You have not chosen. We do not mind. Chosen ones are so much less amusing.” {cry}
- FR : {name} se tient au milieu de la route, comme depuis des années. « Vous n’avez pas choisi. Cela nous est égal. Les élus sont tellement moins amusants. » {cry}

---

## 6. The nemesis quests (outline, for PR 5)

One per main clan: a short quest, the nemesis's champion as the boss, and the break beat (a flag the quest sets). Names and one-line pitch only; I will write each in full when PR 5 is near.

| Clan | Champion | Pitch |
|---|---|---|
| Dominion | **High Lantern-Bearer Orsolya Keld** | the First Lantern's own warden; she keeps the list of every oath |
| Crows | **Captain Mireille Sable** | the Crows' collector, who has never lost a debt |
| Compact | **Master Hollis Reck** | the Charter's last hammer; the table's rule made flesh |
| Vigil | **Watch-Captain Edda Grey** | the Vigil's eyes on the ridge; she has not looked away in thirty-eight years |
| Penitents | **The Ash Confessor** | the Penitents' voice, who burned her face to hear better |
| Mire | **The Heron Queen's Hand** | the Court's courtesy, armed |

Names are epicene or fixed in French (no gendered forms for the champions beyond their given titles). Core sets the numbers on the boss curve.
