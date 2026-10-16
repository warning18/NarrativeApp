# The feature ladder: chapters 1–2 as the onboarding (proposal)

The user's request: *"Try to build the 2 first chapters so that you discover most new features one by one in game."*

This proposal is Core's, with Narrative's beats (`docs/proposals/ch1-2-beats.md`, branch claude/narrative-38) and UX's unlock moment (section 5). **Nothing is built yet:** the user sees this first. The building would then split into PRs: Core's gating, Narrative's beats, UX's unlock moments.

## 1. Where things stand today

The full inventory, with file references, is in the appendix. In short:

- **Already gated well:**
  - from chapter 2: detours, road hunters, provisions, the chapter offer and chapter conditions, every shop (`minChapter` ≥ 2);
  - from chapter 3: the camp, and with it the boat, the forge, skill crafting and the materials' use.
- **Open from the first minute:**
  - clan offers and signs (the first level-up brings one; the mage and the cleric start with one);
  - the Quests list;
  - the Clans & Politics screen (the ⚖ button) and the world map;
  - Inventory, Skills, the codexes, Achievements and the Journal.
- **Introduced all at once:**
  - the first fights (105–120) bring the die, rerolls, nudges, the chest, place rules and battlefield conditions together;
  - Smugglers' Wharf (2015) brings shops, eight quests, three companions to recruit and the first standing changes in one hub.

## 2. The ladder

One new thing every one to three scenes, each with a reason in the story, and nothing introduced twice. **Node** is where it is introduced. **Unlock** is what opens it: a flag `feat_<id>` set by the scene (Narrative's `flagsToAdd`), or a condition Core derives.

### Chapter 1: Alster to the White Wells

| # | Node | Feature | Reason in the story | Unlock |
|---|---|---|---|---|
| 1 | 0 | The character: profession, stats, starting die. **Journey tab only**, with the Character Overview | Making the character | Open |
| 2 | 105 | **The fight and the die**: rolling, three rolls a round, the lucky die | The bar fight (tutorial fight) | Open (already the tutorial fight) |
| 3 | the first fight won after 105 (110, 120 or 260) | **The spoils chest and loot**, potions | A fight pays | Derived: first fight won after the tutorial (110 and 120 are optional) |
| 4 | 115 / 125 | **Rest and heal** | Waking in the sawdust (works with or without Lysa) | Open (story heals) |
| 5 | 260 (the bridge) or 400 | **Place rules** (the street's rules: the town guards' whistle) and nudges (Luck) | Fighting in the street, not the bar | Place rules off before the first street fight (derived) |
| 6 | first level-up | **Level-up: the training pick** (the stat picks of #47) | About 100 XP: after two or three fights | Level 2 reached. **No clan offer yet**: it waits (§3) |
| 7 | 250 | **The Journey map's quest pins and the Quests list** | The banner's errand, and a line pointing at the list (Narrative) | `feat_quests` at 250. The Quests entry is hidden before |
| 8 | 260 (one branch of 250) | **Pay or fight** (gold as a choice) | The bridge toll; the alley (270) is the other branch | Open, so a branch that skips it loses nothing |
| 9 | 400 | **A boss** (phases, the boss bar), and **alignment**: the first moral choice, where the branches meet | Vane at the family house | Open; the alignment meter shows from here |
| 10 | 470 | **The Inventory page**, and the dice loadout | The bundle and the warm die, on both paths (Vane won: 400 → 450 → 470; lost or fled: 800 → … → 470) | `feat_inventory` (Narrative's line at 470); the Pages tab of Character hidden before |
| 11 | 890_trainer (new, between 470 and 891) | **Skills and the first skill choice** (a story offer of skills only, no clan): strike, guard, or neither | A trainer on the way to the High Quay (Narrative's scene) | `feat_skills`; the Skills screen and its radar entry hidden before. The mage and cleric's starting skill offer moves here |
| 12 | 895 | **Ability checks** (a stat roll) | The forged manifest at the High Quay, for everyone. The Black Hold's checks (820 / 822) come earlier on the lost path | Open |
| 13 | — | (the Black Hold, 800–855, is the lost path's own: its fights and checks stay as they are) | | |
| 14 | 891 | **Gear and equipping** | The High Quay's free sword or shield | Open (the gear is granted here) |
| 15 | 1100 | **Land crossings** | The crash in the desert | Open (already `landRouteId`) |
| 16 | 1120 | **The skill challenge** (several checks in a row) | The heat walk to the Sleeper's Face (three Constitution checks) | Open |
| 17 | 1140_spotted | **Battlefield conditions** (the ambush) | Spotted on the cliff path | Conditions rolled only from here (`feat_conditions`) |
| 18 | 1200 / 1210 | **Resting at a safe place**, and the Open Hand's mention | The White Wells | Open |
| 19 | 1000 | **The Shroud card** (the banner's first piece) | The chapter's end | Open (already shown once a piece is held) |

### Chapter 2: Saltmouth

| # | Node | Feature | Reason in the story | Unlock |
|---|---|---|---|---|
| 20 | 2001 | **Provisions on the road** | The road to Saltmouth is long | Already from chapter 2 |
| 21 | 2005 | **Standing, and the Clans & Politics screen** (⚖) | The Inquisition's gate: who holds the city | `feat_politics` at 2005; the ⚖ button hidden before |
| 22 | 2015 (first visit) | **The first shop** and the Town page | The Wharf's market | Already from chapter 2 (`unlockShopId`) |
| 23 | 2015 (a Crow's line) | **The clans' offers and signs, and patrons**: the waiting offers are given now | The first clan suitor (Narrative's line) | `feat_clans`. Offers banked since level 2 open here, one at a time |
| 24 | 2015 (the board) | **Side quests and turn-in choices** | Kelda, the informant, the scaffold | Open (from 2015) |
| 25 | 2010_liora | **Companions and approval** | Liora | Open |
| 26 | first chapter-2 road | **Detours** | The road between the gate and the Wharf | Already from chapter 2 |
| 27 | first chapter-2 ambush | **Rival hunters and the mercy card** | The Dominion's hunters (the story nemesis) | Already from chapter 2 |
| 28 | 2900 | **Expeditions, and the ship** (buying the Eel) | The yard | Already (`launchZoneId`, `eel_owned`) |

### Waits for chapter 3 or later

- The camp, the boat at sea, the forge and the smithing sheet, skill crafting, and spending materials. Materials still drop in chapter 1, with a one-line note on what they are for.
- Sea battles (chapter 4) and the nemesis's quest (chapter 4).
- The Host (chapter 8) and the Throne war (chapter 7). The Throne tab inside Clans & Politics stays, read-only.
- Titles and reinforcements come naturally once standing moves (chapter 2 at the earliest). They need no gate, only an unlock moment the first time they appear.
- The codexes (Bestiary, People, Lands), Achievements and the Journal show their entry once they have their first entry: the first foe (105), the first person (100). This is already mostly true.

## 3. What Core builds (gating)

- **`lib/data/feature_unlocks.dart`:**
  - an enum of the gated features;
  - each one's unlock: a flag `feat_<id>`, or a derived condition (level 2, the first fight won after the tutorial, a chapter);
  - `unlockedFeatures(session)` and `newlyUnlocked(session)` (unlocked and not yet acknowledged; an `acknowledgedFeatures` list in the session).
- **The gates themselves:**
  - hide the Quests entry, the Inventory page, the Skills screen and the ⚖ button until their feature opens;
  - place rules and battlefield conditions stay off in fights until theirs;
  - the clan offers queue silently from level 2 and open at `feat_clans`. The level's training pick is not held back.
- **Old saves:** every feature whose node lies before the save's chapter is unlocked on load, and acknowledged, so nothing pops up mid-game. A save in chapter 1 keeps the ladder from where it stands.
- **The simulator:** it plays the ladder as written. It reports the win-rate change, which is expected to be small: chapter 1 fights lose place rules and conditions until 120 and 1140.
- **A test:** walking chapters 1–2 in story order, each feature unlocks exactly once and at its node, and none is open before.

## 4. What Narrative writes (beats)

From `ch1-2-beats.md`:
Narrative's review and words (EN and FR) are in `ch1-2-beats.md` (claude/narrative-38, c7455fb), "Review of the draft ladder, and the words":
- a line at **250** pointing at the quest list (row 7);
- a line at **470** for the bundle and the die (row 10);
- the scene **890_trainer**, between 470 and 891 (both 470 choices go there), setting `feat_skills` (row 11);
- a line at **2005** setting `feat_politics` (row 21);
- the scene **2015_crow_offer**, a hub choice on the first visit, setting `feat_clans` (row 23). Its "Not today" goes if the clan offers stay at level 2;
- the `feat_*` flags on the carrying choices (or on the node's entry);
- a sentence where a feature needs its reason said: the ⚖ at 2005 ("who holds this city"), the sack at 816.

Nothing hangs on Lysa alone: a player on the lost branch meets every feature too.

## 5. What UX designs (the unlock moment)

UX's answer will go here. The ask:
- a small card or pulse on the tab or button that appears ("New: Inventory", one line on what it does, a link to its tutorial topic);
- locked entries hidden, or calmly greyed with a line ("Opens in Saltmouth"), never an error;
- one moment at a time, never two on the same scene;
- under reduced motion, no pulse: the card alone.

Core gives them `newlyUnlocked` and an `acknowledge(feature)`.

## 6. For the user to decide

1. **Clan offers wait until Saltmouth (#23)?** This is the biggest change: today the first level-up brings one. The alternative keeps them at level 2, with the clans named by the Crow there.
2. **The mage and cleric's starting skill offer moves to the trainer scene (#13)?** They would play the first fights with their starting spells only.
3. **Place rules and battlefield conditions held back** until the first street fight (260 or 400) and 1140, or left as they are?
4. **Hidden or greyed** for locked entries?

## 7. What is built (Core, v1.421)

The user approved §6 as recommended:
- the clans' offers wait until Saltmouth;
- the mage's and cleric's starting skill moves to the trainer;
- place rules come from the second fight won after the lesson (120 on the full path), and conditions from the ambush at 1140;
- locked entries are hidden, and appear with UX's card.

**`lib/data/feature_unlocks.dart`:**
- `GameFeature`: chest, placeRules, conditions, levelUp, quests, inventory, skills, politics, clans.
- Each feature has its `feat_*` flag (or a deed: level 2 for levelUp), its chapter, `featureUnlocked`, `unlockedFeatures` and `newlyUnlockedFeatures`.
- A feature is open in any case once the story is past its chapter.
- **Off the ladder,** everything is open and nothing is new. A game is on the ladder only if it carries `feature_ladder`, which a new game sets. That is the old-save migration: a save from before the ladder has every feature open, and no card pops up.

**The session:**
- `acknowledgedFeatures` (saved);
- `ladder` and `featureOpen(f)`;
- `acknowledgeFeature(id)`;
- `noteFightWonOnLadder`: the chest's flag on the first fight won after the lesson, the place rules' flag on the next;
- `learnTrainerSkill` (`trainer_strike` / `trainer_guard`): the first skill of the character's own trees that hits, or that holds.

**The gates:**
- `ensureOffer` draws no offer before the clans open; the offers bank, and the Character tab's dot ignores them meanwhile.
- A new game has no starting offer.
- The lesson's fight (105) gives no chest.
- A fight plays the Tide (unmarked) until place rules open, and rolls no condition until conditions open; a story's forced condition stands.

**For UX:**
- `unlockedFeaturesProvider` and `newlyUnlockedProvider` (ids, in the ladder's order);
- `isFeatureUnlocked(ref, id)`;
- the session's `acknowledgeFeature(id)`.

**The simulator:** `featureLadder: true` plays it (no starting offer, the offers waiting, the trainer's skill). It is off by default, so the measured curves stay comparable. The win rates with it on are in the PR.

## Appendix: the inventory (main, v1.415)

Chapters come from the node id: under 2000 is chapter 1, under 3000 chapter 2 (`lib/data/chapter_grid_layout.dart`). Every tutorial topic plays the first time its screen opens (`TutorialTrigger`) and can be replayed from Other → Tutorials.

| Feature | Where | Gate today | First used |
|---|---|---|---|
| Fights, dice, rerolls | Fight screen | Open | 105 (tutorial fight, lucky die) |
| Nudges | Fight | One per 3 Luck (`combat/dice_tamper.dart`) | First fight, with Luck ≥ 3 |
| Spoils chest, loot, potions | Fight's end | Open | 105 |
| Place rules (town guards…) | Fight omen | By stage; a city's guards in Alster | 110 / 120 |
| Battlefield conditions | Fight | 25% roll, not in the tutorial fight | 110 / 120; forced ambush at 1140_spotted |
| Skills and tiers | Character → Skills | Learned from offers only; mage and cleric start with one | Creation, then each level-up |
| Training picks (stats) | Character → Level up | Level `level×100` XP; 5 points a level | After 2–3 chapter-1 fights |
| Clan offers, signs, patrons | Character → Gifts; offer dialog | Sources: start, level, boss, tome, story, chapter (chapter from ch 2) | First level-up |
| Gear | Character → Inventory | Open | 891 (granted sword or shield); loot from 105 |
| Rest and heal | Story choices | Open | 115 / 125; 1200 |
| Provisions | Road rules | From chapter 2 | 2001; bought from 2015 |
| Camp | Camp tab | Chapter 3 and `camp_founded`; the tab shows locked | 3001 |
| Journey map, District | Journey tab | Open | 0 |
| Town view | Journey | A city plan, not in a room | 250 |
| Town page (port) | Other | Standing in a port settlement | 2015 |
| World map | App bar | Open | 0 |
| Detours | Roads | From chapter 2 (`sub_node_engine.dart`) | First chapter-2 change of place |
| Expeditions | Expedition screen | Zones are chapter 2 | 2900 |
| Land crossing | Crossing screen | Open | 1100 |
| Ability checks / challenge | Story | Open | 820 / 1120 |
| Quests | Other → Quests | Open; main quests auto-accept | 250, 260 |
| Turn-in choices | Turn-in dialog | Per quest | Chapter-2 quests from 2015 |
| Shops | Shop screen; Other → Shops | Every shop `minChapter` ≥ 2 | 2015 |
| Standing, relations ring | App bar ⚖ | Open, read-only | First change at 2015_kelda |
| Titles | Gifts | From offers or standing tiers | Chapter 2 at the earliest |
| Shroud card | Character → Pages | Once a piece is held | 1000 |
| Companions | Camp roster; story bubble | Recruited by quests | Hound 270, Lysa 400; allies from 2015 (Vess at 1210 if void-marked) |
| Approval | Camp roster | Allies only | Chapter 2 turn-ins |
| Forge, smithing, skill crafting | Camp houses | Built in camp | Chapter 3+ |
| Materials | Inventory | Drop from chapter-1 foes | 110 / 260; first spent in camp |
| Ship and sea | Harbour, voyages | `camp_founded`; the Eel at 2900 | 2900; sea battle at 5100 (ch 4) |
| Rival hunters, mercy | Road ambush | Roads at rest from chapter 2 | Chapter 2 |
| Nemesis quest | Quest | The Dominion's opens at chapter 4 | Chapter 4 |
| Reinforcements | Fight log | A clan at Friend+ or Hunted | Chapter 2 at the earliest |
| The Host / Throne | Host sheet / Clans tab | The story musters it | Chapter 7–8 |
| Bestiary, People, Lands | Other | Foes met, people met, open | 105 / 100 / 0 |
| Achievements, Journal | Other | Open | — |
| Spells and mana | Character → Mana | Mage and cleric start with spells | First fight |

**The main screen:**
- Bottom tabs: Journey, Character, Camp, Other.
- Dots: Character (points, an offer), Camp (a house you can afford), Other (a quest to turn in).
- The app bar's world map, ⚖, language and settings buttons are open from the start.

**The chapter 1–2 walk** (chapter 1 forks: 106 may skip the optional bar fights; 250 leads to 260 *or* 270, which meet at 300; 400 won goes 450 → 470, lost or fled goes through the Black Hold 800–855 → 470; both meet at 470 → 891): 0 → 100 → 105 → 106 (110 / 120 / 250) → 115 / 125 → 250 → 260 → 270 → 300 → 400 (Vane) → 800 / 816 → 820 / 822 → 840–855 (undercroft) → 470 → 891 (High Quay) → 895 → 960 → 965 → 1100 → 1120 → 1130 → 1140 → 1200 / 1210 → 1000 → 2001 → 2005 → 2010 / 2020 → 2015 (the Wharf hub, 30 choices) → … → 2900 (yard) → 2999 (the crossing) → 3001.
