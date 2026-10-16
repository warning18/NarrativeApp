# Chapters 1 and 2 in order, and what each scene can carry (Narrative, for Core's feature ladder)

For `docs/proposals/feature-ladder.md`. This is the play order of the two chapters (the main path, Alster then the desert then Saltmouth), what each scene already does mechanically (read from the choices: a fight, a check, a payment, an item, a politics change…), and which scene could carry the introduction of a feature. **Nothing here is built.** Node ids are the story file's.

## Chapter 1

| # | Scene (node) | Where | What it already has | Could introduce |
|---|---|---|---|---|
| 1 | The Blind Beggar's back room (100) | the tavern | the first choices; gold; alignment | **the first choice with a cost**; the wage-in-advance tables set up the fights |
| 2 | The bouncer, the looter, the door (105) | the tavern | the first fights | **combat and the die** (three fights of different weight to pick from) |
| 3 | The tables (106, 110, 120) | the tavern | fights that pay in advance | **gold and loot**, taken fight by fight; the first "this pays, this costs" |
| 4 | Waking in the sawdust (115, 125) | the tavern | healing after a loss | **resting and recovering** (a wound you can see; Lysa is not here yet, a barmaid or the rope of the street will do) |
| 5 | Alster's lower town (250) | the street | a quest unlock; two ways on | **the Journey map** (two places to go) and **the quest list** (the first quest) |
| 6 | The Stone Bridge (260, 261) | the bridge | a toll you can pay or fight | **paying a price** against **a fight** (the same toll, two ways) |
| 7 | The alley (270) | the street | a beast and a handler; alignment | **alignment** (cut it free, strip the gear, leave): the first choice that is plainly good or ill |
| 8 | Our house (300, 400) | the street | Vane, the first big fight; Lysa | **a boss**; **a choice that matters** (charge, run, kneel) |
| 9 | The ruins (450, 470) | the street | healing; the heirloom piece is found | **the Banner** (the first piece of the Shroud); **items** |
| 10 | The Black Hold (800, 816) | the cell | the sack: a dagger, the drawing, the torturer's instruments, the bone die | **inventory and equipment**; **the die** is literally in the sack |
| 11 | The Wardens' hall (820, 822, 823) | the Hold | a fight, a lie (a check) | **ability checks** (the lie at 822) |
| 12 | The undercroft (840, 850, 855) | the sewers | a check, the Rat Matriarch fight or a feeding | **a check against a fight** again; the second boss-weight foe |
| 13 | The High Quay (891, 895, 896–898) | the quay | one thing to grab; a forged manifest (a check); gold | **a shop in miniature** (one item among five, chosen fast); **a fail state** that costs |
| 14 | The Lark (960, 965) | the ship | a choice of what to protect | **a story choice about a person** (shield Lysa, or the cloth) |
| 15 | The crash and the dunes (1100, 1101, 1120, 1125, 1130) | the desert | a luck check on the tear; a heat check twice; a payment at the stone face | **land travel** (`landRouteId` is already on these choices): the exploration screens; **survival** (the heat); **luck** |
| 16 | The thieves' camp (1140) | the dunes | a check, fights, gold | **stealth versus fight** (slip past, take it back, go round) |
| 17 | The White Wells (1200, 1210) | the oasis | a rest; a cloaked woman, a quest, a politics change; the origin epilogues (1000, 1001, 1002) give the piece | **resting at a safe place**; **the Open Hand** (the cloaked woman); the three origins |

## Chapter 2

| # | Scene (node) | Where | What it already has | Could introduce |
|---|---|---|---|---|
| 18 | The caravan and the rats (2000, 2001) | the gate | a swarm fight | **a group fight** (the first with more than one foe) |
| 19 | The landward gate (2005) | the gate | the Inquisition's queue; a politics change | **standing with a power** (the Inquisition, first sight) |
| 20 | The market (2010, 2010_crane, 2010_liora, 2011) | the wharf | stalls, a crane, Liora on the roof (a quest) | **shops** (the stalls); **a companion** (Liora's quest) |
| 21 | Smugglers' Wharf (2015 and its houses) | the wharf | the hub: 31 choices; shops, quests, the clans' houses, informants | **the clans** (the Crows' key, the Salt Ledger's tenth, the Drowned Debt's chain); **the shop**; **side quests**; **a hub** |
| 22 | The gate ambush and Vane's tunnel (2020, 2021, 2030) | gate, wharf | fights; gold; a quest | **a risky shortcut** with a price |
| 23 | Vane's insult (2040, 2040_paid) | the wharf | a fight or a payment | **a payment you can choose not to make** |
| 24 | The cordon (2050, 2070) | the wharf | a storm drain; a check; healing | **a second check** (cut Vane's purse loose) |
| 25 | The ship-breaker's yard (2900) | the yard | a payment; a zone launch; the hull to repair | **the ship** (buy the Eel, work it off, patch the hull); **a zone** (the first fight-in-a-place you choose) |
| 26 | The Eel is fixed (2900_boat_fixed) | the yard | who sails; a politics change | **crew and allies** (who comes) |
| 27 | The crossing (2999) | the sea | the order to give | **the sea** (the chapter's end; the manager's note puts the sea after chapter 2) |

## Candidate hooks from your three examples

- **Lysa patching your wound for rest and camp.** She is only with the player from scene 14. On the lost branch there is no Lysa. For rest, scene 4 (waking in the sawdust) is the natural first rest: a wound, a place to sit, and it works whether or not she lives. The **camp** itself first appears in chapter 3, which is where it belongs.
- **The Blind Beggar's back room for the first shop.** The back room has a cage for the house's money and four tables; it is a gambling den, not a shop. A shop in chapter 1 is better at the High Quay (scene 13), where the player has one thing to grab, and where the armory has been looted: a stall-keeper in the chaos is believable. The first proper **shop** is at the wharf (scene 20/21).
- **A Crow's offer for the clans.** The Crows' key (2015_house_keyholders) is the first clan job in the game and fits. But the Inquisition at the gate (scene 19) is the first power the player stands with.

## Where there is no natural beat

I would add, if the ladder needs them:
1. **A line** in scene 5 pointing at the quest list ("I had not been given a quest in my life; the street was offering one").
2. **A small scene** between 12 and 13 for **skills/levelling**: a dock-trainer or a ranger who offers to teach one move (a good place for the first skill choice).
3. **A line** at 20 for **gifts and clan offers**, which the user's specialisation work depends on: the first clan's suitor appearing at the Wharf.

Tell me which features you want carried where, and I will say which of the above are lines and which are scenes.

---

# Review of the draft ladder, and the words (answer to `feature-ladder.md`)

## Rows I would change (nodes read wrongly)

**The story forks in chapter 1, and two forks skip scenes.**
1. **The win at the house skips the Black Hold.** Node 400 leads to 450 → 470 → 891 when you win, and to 800 → 816 → 820… → 840–855 → 470 when you run, kneel or lose. Both come together at **470** (the ruins) and go on to **891** (the High Quay). So rows 11 (816), 12 (820/822) and 13 (a trainer "between 850 and 891") would only be seen by a player who *lost* the fight. Fix: **row 11 → 470** (the bundle and the warm bone die are there on both paths), **row 12 → 895** (the forged manifest, a check for everyone; 822 and 840 are an earlier first check for the lost path, which is harmless since checks are open), **row 13 → a new scene between 470 and 891** (see below), so every player passes it.
2. **260 and 270 are alternatives.** From 250 the player takes the Stone Bridge (260) *or* the Weaver's Alley (270), and both go on to 300. Rows 8 (pay or fight) and 9 (alignment) are therefore one branch each. Row 8 is open, so no harm. For alignment, introduce it at **400**, where both paths meet and the first moral choice sits (run −2, kneel +2); 270 stays a preview for those who take the alley.
3. **110 and 120 are optional.** From 106 the player can go to 110, 120 or straight to 250. Rows 3 and 5 should not hang on those nodes: use the derived conditions you already have ("first fight won after the tutorial"). Place rules are a street thing, not a tavern one; the first street fight is **260** (bridge branch) or **400** (everyone). I would start place rules at 400, or at 260 for the bridge, and leave 105–120 without them as you propose.
4. **Row 16 (1120) is the heat, not the face.** 1120 is the walk with three Constitution checks (the skill challenge, as you say); the Sleeper's Face is 1130. Reason in the story: the heat, not the climbing.
5. **Row 6 (first level-up)** has no scene; the unlock moment is UX's.

## Lines and scenes

| Row | Node | A line, or a scene? |
|---|---|---|
| 2, 4, 8–10, 14–19, 20, 22, 24, 25, 28 | as the ladder has them | nothing from me: the scene already says it |
| 7 | 250 | **a line** (below) |
| 11 | 470 | **a line**: one sentence on the bundle, and that the die is warm |
| 12 | 895 | nothing: the manifest check is the scene |
| 13 | between 470 and 891 | **a scene** (below) |
| 21 | 2005 | **a line** (below) |
| 23 | 2015 | **a scene**, a small one (below) |

## The words

**Row 7, a line for 250** (an extra paragraph, shown always):
- EN: Someone had chalked a list on the brick by the stairs: jobs, names, a price for each. The Inquisition had not found the time to scrub it. I took the list for something I would be coming back to.
- FR : Quelqu’un avait tracé à la craie une liste sur la brique, près de l’escalier : des travaux, des noms, un prix pour chacun. L’Inquisition n’avait pas encore trouvé le temps de l’effacer. Je pris cette liste pour quelque chose à laquelle je reviendrais.

**Row 11, a line for 470** (after "the old bone die had gone warm as well"):
- EN: I put the cloth, the die, and what the searchers had missed into one bundle, and found I knew exactly what I was carrying, and how little room there was for it.
- FR : Je mis le tissu, le dé et ce que les fouilleurs avaient laissé dans un seul baluchon, et je sus exactement ce que je portais, et le peu de place qu’il restait.

**Row 13, a new scene `890_trainer`** (location `alster_high_quay`; both 470 choices go here, and it leads to 891). Sets `feat_skills`:
- EN: A drill-sergeant of the Crusade’s old militia was running the morning line on the quay approach, thirty people in odd armour hitting sandbags, because the Inquisition did not shoot anyone who was doing something so plainly useful. She looked at the way I stood. “Somebody taught you the first half,” she said. “I have time to show you the second, and the Lark will not lift for another hour.”
- FR : Une sergente de l’ancienne milice de la Croisade menait la ligne du matin sur l’approche du quai, trente personnes en armures dépareillées frappant des sacs de sable, car l’Inquisition ne tirait sur personne qui faisait quelque chose d’aussi manifestement utile. Elle regarda ma façon de me tenir. « Quelqu’un vous a appris la première moitié, dit-elle. J’ai le temps de vous montrer la seconde, et l’Alouette ne lèvera pas avant une heure. »
- Choices: *Learn the strike* (offers the attack skill) / *Learn the guard* (offers the defence skill) / *Ask for neither, and go on* (nothing; the offer waits). Flags: `feat_skills`, `trainer_strike`, `trainer_guard`, `trainer_skipped`. Core attaches the actual skill offer to the first two.

**Row 21, a line for 2005** (an extra paragraph, shown always):
- EN: Saltmouth belonged to someone, and the gate made a point of saying whom: the Inquisition’s masks on the wall, the Crows’ tally-boys down the queue, the Compact’s marks on the carts. I began, without meaning to, to keep a tally of who held what. Sets `feat_politics`.
- FR : Saltmouth appartenait à quelqu’un, et la porte tenait à le dire : les masques de l’Inquisition sur le mur, les gamins à tablettes des Corneilles le long de la file, les marques du Pacte sur les charrettes. Je me mis, sans l’avoir voulu, à tenir le compte de qui tenait quoi.

**Row 23, a new scene `2015_crow_offer`** (a hub choice on first visit, `showIfFlags` none, hidden by `hub_2015_crow_offer`; sets `feat_clans`):
- EN: A Crow tally-boy had been following me down the Wharf with a slate, not hiding it. “You have the look of someone who is about to be asked,” she said. “It is our custom to say so first. The clans watch what a stranger does, and when you have done enough of it, one of them will make you an offer: a gift, a way of fighting, a name to carry. Not today. When you have earned it. You should know the offer is coming, and that you may say no.”
- FR : Une gamine des Corneilles, une ardoise à la main, me suivait le long du Quai sans s’en cacher. « Vous avez l’air de quelqu’un à qui on va faire une proposition, dit-elle. Chez nous, on le dit d’abord. Les clans regardent ce qu’un étranger fait, et quand vous en aurez fait assez, l’un d’eux vous fera une offre : un don, une façon de combattre, un nom à porter. Pas aujourd’hui. Quand vous l’aurez méritée. Il faut que vous sachiez qu’elle viendra, et que vous pouvez refuser. »
- Choices: *Ask what the Crows would want* / *Ask who else will ask* / *Say you are no one’s*. Each sets `feat_clans`.

## Your four questions for the user
I have no objection to any of them from the story side. The Crow scene says the offer is for later and may be refused, which fits either answer to question 1. If the clans' offers wait until Saltmouth (question 1), the Crow's words are the reason in the story; if they stay at level 2, I would drop the sentence "Not today".
