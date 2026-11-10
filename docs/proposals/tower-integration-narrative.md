# The towers in the story: three propositions (Narrative, phase 1)

Docs only: no quest, scene, string or data changes before the user picks.
English hooks only; French follows on the pick. Built on Core's
`tower-in-each-town.md` (7 towers, options A, B and C), `the-tower-names.md`
and the Tower's actual shape in `lib/data/tower/` (30 floors, own hero,
own save, six tower clans: `dominion`, `vigil`, `compact`, `mire`, `crows`,
`penitents`).

## What the three share: why the towers exist

The story has no towers today (one "tower" word in a bell-tower line). So
the first job is a fact the world can hold. I propose one lore base for
all three propositions, **"seven doors, one stair"**, because it explains
what Core already built:

- **One stair, seven doors.** Before the Charter, the Houses of the
  Dominion found that the tear is not only a wound but a *stair*: it runs
  through the world, and at seven places it comes up to street level. At
  each they built a stump of a tower around the door, to count who went in
  (the Tally Room, the Gatehouse, the Bell Stair are already floor names in
  `the-tower-names.md`). It is the same Ashen Tower from every door, which
  is why every tower has the same 30 floors, the same bosses, and one
  shared set of marks and unlocks.
- **Who climbs is a reflection.** The Hollow Shore already has reflections
  that wear faces the Void took (chapter 6 and 7). The stair makes one of
  *you*: a fresh hero with a few unlocks, who dies without cost to the
  real one. This is the in-world reason for "its own hero, its own save,
  nothing taken from the story", so no rule has to bend.
- **Each door has a keeper, and the keeper is a clan.** The first oath of a
  climb (Core's `TowerSite` clan) is the clan that holds that door. Draft
  table (Narrative's, to be checked against each town's intrigue steps):

  | # | Town | Door | Clan | Why |
  |---|---|---|---|---|
  | 1 | Alster | the well-head stair | `dominion` | the Houses built it; Alster's static ruler |
  | 2 | Saltmouth | the harbour-light stair | `crows` | the Salt Crows run the wharf |
  | 3 | The Ashen Quarter | the slag-stack stair | `compact` | Cinder Row's forges burn beside it |
  | 4 | The Drowned Cloister | the drowned belfry | `mire` | the fen keeps what goes down |
  | 5 | The Black Reliquary | the reliquary spire | `penitents` | they carry its relics |
  | 6 | The White Anchorage | the flagship's mast-stair | `vigil` | the Vigil counts the dead there (chapter 7) |
  | 7 | Candlehold | the First Lantern's stair | `dominion` | the Throne's own door; the top of the stair |

  Six clans for seven doors: Candlehold repeats the Dominion on purpose,
  as the door the Houses never closed.
- **The summit already has its line.** Floor 30's boss is the Sovereign,
  "under a crown the tear wore first" (`the-tower-names.md`). A town tower
  does not need a new ending; each door just reaches the same top.

## Proposition 1: a name on the map (lore only, lightest)

**Why:** the user asked for the towers to belong to the world. This adds
the fact and the names, and nothing else.

**How the hero meets the first one:** in Alster, a line on the town's hub
and the chart label of the well-head stair. No scene, no choice.

**What a climb means for the story:** nothing. The Tower stays "thirty
floors, no story"; the story save never sees it.

**What changes in my files:**
- 7 door names and one lore line each (EN/FR) for Core's `tower_sites.json`
  and the sphere (names and wording only).
- The seven towns' descriptions in `geography.json` gain one sentence
  about their stair (wording, not numbers; Core owns the file).
- 1 achievement in `achievements.json`: "Seven Doors" (reach floor 10 at
  every door). No quest, NPC, remark or intrigue.

**Hooks:**
- *Alster hub row text:* "A stair-head behind the well, bricked to the
  waist. The Houses counted who went down it, and stopped counting."
- *Saltmouth chart label:* "The harbour-light stair: the Crows say it pays
  no tax and returns nothing."

**Size:** S (one PR, about 30 strings). **Risk:** none. **The player
notices:** the towers on the sphere have places and names; the story reads
the same.

## Proposition 2: a door in the story (recommended)

**Why:** a tower with a name is a menu item; a tower the story *shows you*
is part of the world. The story offers each door, and takes what the climb
says back, with no numbers moved.

**How the hero meets the first one:** Alster's hub gets one optional scene,
"The stair behind the well" (about 500 characters): the Keyholders' mark
on a bricked door, a pensioner who watches it, a choice **Climb** or **Not
today**. *Climb* hands over to the Tower mode on that door with the
reflection hero (Core's option A; the Tower's back button returns to the
story hub). The scene is optional and off the main path, so no playthrough
stalls and the simulator can ignore it.

**What a climb means for the story:**
- **Scenes:** one door scene per town, opened by the chapter's hub (7),
  plus one return line per door (callbacks on the best floor reached: 10,
  20, 30), written as callbacks, never as new nodes.
- **NPCs:** the door's watcher is an existing NPC where one fits
  (`npcs.json` `states` lines), or one new NPC per door for the three towns
  without (Saltmouth, Reliquary, Candlehold), each with 1 to 3
  `dialogueLines`.
- **Companions:** one door remark each for three companions of different
  temper (Kelda, Sable, Vess), `choiceKey` on the door scene; the rest
  stay silent.
- **Achievements:** 7, one per door ("The Well-Head Stair, floor 10"),
  alongside Proposition 1's "Seven Doors".
- **Intrigues:** untouched.
- **Rewards into the story:** none by default. If Core wants one (a title
  or a one-time item per door), Core sets it; I write the line.

**What changes in my files:** `Cleaned_Narrative_DAG.json` (7 door scenes,
choices carry a `towerId` field Core adds), `npcs.json`,
`companion_remarks.json`, `achievements.json`, 7 hub-row texts, the same
names as Proposition 1. Core adds one read-only hook: the best floor per
door becomes a story flag the callbacks read.

**Hooks:**
- *Saltmouth, "The harbour-light stair":* "The light on the mole has not
  been lit since the tear. A Crow's tally-boy sits under it with a slate.
  *Up costs nothing,* he says. *Coming down is the part we charge for.*"
- *Return line at floor 10, any door:* "I came down with the sound of
  somebody else's boots still in my head. They were mine. They had gone
  further."
- *Kelda's remark at the Ashen Quarter door:* "I walked a wall for twenty
  years. Never a stair that went the wrong way."

**Size:** M (7 scenes, about 7 hub rows, 3 remarks in all, 3 to
7 NPC lines, 8 achievements; EN and FR together; 1 or 2 PRs). **Risk:**
low to medium: the hubs are long (7200 has 53 incoming choices), so each
door scene must be one row, folded when read; I keep every scene under the
page cap. **The player notices:** seven optional doors in the story that
open the Tower, and a line from the story when they come back.

## Proposition 3: the stair in the arc (deepest)

**Why:** the story's last chapters already ask what the tear is for. This
makes the stair the answer, and makes climbing it part of how the story
ends.

**How the hero meets the first one:** as in Proposition 2 (a door scene in
Alster), but the first climb also gives the story a **name**: the stair's
tally at floor 10 is a list of the people the tear took, and the hero
reads one name from it.

**What a climb means for the story:**
- **Seven names, one per door** (reaching floor 10), feed the chapter 7
  "names" scenes (`names_clerk`, `names_throne`, `names_kin`,
  `names_choice`), which gain callbacks that read how many names the hero
  has recovered (0, 1 to 3, 4 to 7), so the ledger scenes change with the
  climbs.
- **A thread, not a new chapter:** an NPC, "the Stair-Warden" (a reflection
  who has been climbing since the Charter), shows at each door with 2 to 3
  lines, and her fate is told in the epilogue pages (callbacks on the four
  shared ending scenes, written once, not four times).
- **Chapter 8, "Beyond the Tear":** reaching floor 30 at Candlehold, the
  Sovereign's own door, is offered as an optional last scene before the end.
- **Quests:** 7 short quests (one per door, "Count the stair at X"), with
  objectives that read the floor reached; Core sets the rewards.
- **Companions and intrigues:** 9 remarks across the doors; the Open Hand
  intrigue gets a sixth-step line (the clan that never was has a stair of
  its own).
- **If Core builds option B** (the story hero climbs short towers), this
  proposition's quests become the B climbs themselves; nothing I write
  changes, only the hand-off.

**What changes in my files:** the DAG (7 door scenes, 4 ledger callbacks, a
Candlehold finale scene, callbacks on the 4 endings), `quests.json` (7),
`npcs.json` (8), `companion_remarks.json` (about 15), `achievements.json`
(8), `intrigues.json` (1 line). Core: a per-door best floor as flags, a
count flag for the names.

**Hooks:**
- *The Alster tally, floor 10:* "The list was not in order. It was in the
  order they had gone down. I read one name, and it was a stranger's, and
  I knew it was mine to say aloud somewhere."
- *The Stair-Warden at the Anchorage:* "You are the third reflection of you
  that has stood here. The others were more sensible."
- *Candlehold, floor 30 offer:* "The First Lantern throws its light down a
  stair that was never a stair. At the top, a crown the tear wore first."

**Size:** L (about 40 scenes' worth of text across scenes, callbacks and
remarks, EN and FR; 3 PRs). **Risk:** medium to high: the main path is
long (the playthrough simulator already has a 4% step margin), ledger and
ending scenes have shared text, and a mistake here touches every ending.
**The player notices:** the climbs change what the end of the story says.

## What I recommend

**Proposition 2.** It does what the user asked (the towers part of the
system) without touching the main path or any number, and it reuses
Core's option A exactly. Proposition 1 is its floor: ship it first, since
the names and lore are shared. Proposition 3 can follow later, on the same
doors, if the user wants the climbs to matter to the ending.

## What I need from the others

- **Core:** does a story scene hand off to a chosen tower (a `towerId` on a
  choice), and can the best floor per door become a story flag? (P2, P3)
  Is a story-side reward wanted at all?
- **UX-2:** where a door scene appears in a hub (one folded row), and how
  the sphere shows a door the story has already offered.
- **Art:** one picture per door only if the user picks P2 or P3 (7 small
  exteriors: well-head stair, harbour-light stair, slag stack, drowned
  belfry, reliquary spire, flagship mast, First Lantern stair).
- **QA:** a guard that every door has its scene, its clan and its two
  languages (P2, P3).
