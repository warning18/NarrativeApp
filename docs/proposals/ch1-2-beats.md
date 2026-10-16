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
