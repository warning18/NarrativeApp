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
"The stair behind the well" (about 500 characters): the Houses’ chalk mark
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
- **Rewards into the story:** none. Core's rule is that the Tower gives
  the story only text, achievements and scene flags (never power, and not
  titles, which carry effects). So the return line, the achievement and
  the remark are the whole reward.

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
  objectives that read the floor reached (UX-2's "climb to floor N" button
  on the quest card). Their reward is text only: a line, a scene flag and
  an achievement, never gold, XP or an item (Core's rule).
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

- **QA:** a guard that every door has its scene, its clan and its two
  languages (P2, P3).

(Core's, UX-2's and Art's answers to my first draft are folded into
phase 2 below.)

## Phase 2: folded with Core, UX-2 and Art

**Rules from Core that bind all three** (`tower-integration-core.md`): the
story hero never climbs and no Tower power enters the story; the Tower has
one profile shared by several story saves, so any grant is once per
profile; **story → Tower** may give marks or an early clan unlock only;
**Tower → story** may give text, achievements and scene flags only (no
titles, no gold, no items). Core's two light links, which I add to P2 and
P3, cost one Core PR each:

- **D1, story to Tower:** a story event (a clan sworn, a chapter boss)
  grants Tower marks or an early unlock of that clan, once per profile. I
  write the line the story shows when it happens ("The Crows have
  vouched for you at the stair").
- **D2, Tower to story:** floors 10, 20 and the top set scene flags and
  achievements. This *is* my best-floor flag; it fits as Core designed it.
- **D3, the first oath:** the clan the hero swore in the story is offered as
  the Tower's first oath, instead of the door's own clan (the door's clan
  stays the default for a hero with none). It needs no new text from me
  beyond one line per clan.

**Where the player meets a door (UX-2's list):** the sphere pin (cheap, a
landmark), a "Tower" card among the town's places (the start screen under
the night palette), a "climb to floor N" button on a quest card, and a
chapter-strip line that names the door. No new screen.

| | P1: a name on the map | P2: a door in the story | P3: the stair in the arc |
|---|---|---|---|
| **The player sees** | seven pins with names on the sphere; a sentence in each town | the sphere pins, plus a Tower card in the seven towns' place views (the "door scene" is its one-paragraph read), a chapter-strip line, a story line on return | all of P2, plus quests with a "climb" button, seven recovered names changing the ledger scenes, a finale offer at Candlehold |
| **Narrative** | 7 door names and lore lines, 7 town sentences, 1 achievement: S, 1 PR | + 7 door scenes and return callbacks, 3 remarks, 7 to 8 achievements, 3 to 7 NPC lines, D1 lines: M, 1 to 2 PRs | + 7 quests, 8 NPCs, about 15 remarks, 4 ledger callbacks, ending callbacks, a finale scene: L, 3 PRs |
| **Core** | 1 small PR, if the 7 pins open the one existing Tower (no per-door runs); `tower_sites.json` names | 3 PRs: (1) `towerId` on the run, `bestFloorByTower`, old saves read as Alster's; (2) D1 grant + D3 first oath; (3) D2 flags | 4 PRs: P2's three, plus a quest objective that reads a floor and a names count flag; only side quests and ledger text, no Tower-gated main step |
| **UX-2** | the sphere pin (small) | + the Tower card in the place view, the chapter-strip line: 1 PR | + the quest-card button: 1 small PR more |
| **Art** | 5 generations (one generic tower, a code tint per place), pins hand-drawn (0) | the minimal set, 8 to 12 generations (1 exterior, 1 icon, 2 strips, wardens reused); the place-card thumbnail is cut from the generic exterior (0) | 36 to 51 if the 8 NPCs get figures, plus a finale strip (the full set without figures is 20 to 35) |
| **Risk** | none | low to medium: the hubs are long; every door scene is one folded row under the page cap; the three below | medium to high: the 4% step margin (to be re-measured), the shared ending text, the names stay text only, and the Candlehold finale stays optional |

**Three risks to write into P2 and P3 (from Core's check):**

- **(a) Flags are profile-wide.** The Tower's best floor belongs to the
  profile, not to a story save, so a new story save on a profile that has
  already climbed starts with the door flags set. Every return line and
  every door remark must read right at *any* chapter: either written so it
  does not assume the hero has just come down, or gated on the flag *and*
  the chapter. I write them that way (the hook "I came down with the sound
  of somebody else's boots still in my head" works at any point).
- **(b) D1 pays once per profile.** The first save to reach the event gets
  the marks or the clan unlock; later saves do not. The line says so in the
  story's voice ("The stair remembers you already") so a second save is
  not promised what it will not get.
- **(c) All of it is text, flags and achievements**, because no simulator
  sees it: the playthrough simulator and the Tower bot never read a door
  scene, so nothing here can stall a run or move a band.

**My recommendation: P2, built on P1.** It gives the user what they asked
(the towers part of the system, met in the towns, on the map and in the
chapter strip) with no power crossing and no new fight path.
Core's D1 and D2 are the two small links that make it feel joined up, and
D3 makes the first oath the hero's own. P3 stays open for later on the
same doors; Option B (the story hero climbs) is not proposed.
