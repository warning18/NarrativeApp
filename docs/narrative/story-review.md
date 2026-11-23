# Story review: pull, pacing, choices, characters, onboarding, reading

Written by the Narrative session on `origin/main` f528428d (v1.992), 23 November 2026.
**A report only: nothing in the game was changed.** It answers the manager's request
for the story to get the same pass as UX (ease of use) and Core (mechanics, hooks).

## How this was done, and what it cannot say

- **Measured** from the data: every node of `assets/Cleaned_Narrative_DAG.json` (479),
  the flags the choices set and the places that read them, `quests.json` (51),
  `intrigues.json` (11), `companion_remarks.json` (278 records), `companions.json` (9),
  `npcs.json` (80), `chapters.json`, `detour_scenes.json` (64), and the choice-weight
  rule of `lib/data/story_plates.dart`. The scripts were throwaway; every number can be
  recomputed from those files.
- **Read** (prose judged, not counted): the prologue and chapter 1 end to end, every
  chapter's opening and closing scene, the four endings, two companion loyalty scenes
  (Kelda, Malrik) and about forty other scenes.
- **Not done: nobody played it.** The camp-loop chapters (3 to 6) carry a lot of their
  story outside the DAG (detours, expedition steps, NPC lines, politics events,
  quests), and how that *feels* over eight activities needs a play session. Where a
  claim depends on that it is marked **needs play**.
- **Chapter numbers.** Scene ids do not follow the chapter numbers: 1xxx is chapter 1,
  2xxx chapter 2, 3xxx chapter 3, 4xxx and 5xxx chapter 4 (the Hollow Court), 6xxx
  chapter 5, 7001 and 71xx to 73xx chapter 6, 74xx to 77xx chapter 7, and 7800, the
  70xx endings, `names_*` and `price_*` chapter 8. The eight `loyal_*` scenes are
  camp scenes and are counted apart. The tables use the chapter numbers of
  `chapters.json`.

## 1. In short

**What works.** The voice is the story's best asset and it is consistent (a dry,
first-person narrator telling it afterwards). Scenes are short (median 94 words, two to
three paragraphs), sentences average 13 to 16 words, French runs only 2 to 7% longer
than English, and no choice label is over 49 characters. The opening hooks hard: a
fight on the fourth scene, the sister taken on the tenth, the trapdoor the house was
built over on the twelfth. The flags are alive: 666 of the 673 flags a choice sets are
read somewhere, and each of the four endings reads 20 to 27 of them (`7005*`); the
Muster (`7800`) has 70 echoes and shows at most ten, chosen by priority.

**What does not work yet.** Six things, each with a proposal in section 8.

1. **The mystery threads move in lock-step, then come due together, and the codex
   labels them wrongly.** Six of the eleven intrigues fire Clue (Saltmouth, ch 2) →
   Hook (3) → Turn (4) → Reveal (5) → Crisis (6) → **Choice (6, the same chapter)**;
   five of those Choices are in the Hollow Shore's `71xx`/`72xx` scenes. The codex
   (`intrigues.json`, shown by `clans_politics_screen.dart`) says the Clue is in
   chapter 1 and the Choice in chapter 7.
2. **The biggest choices are almost never witnessed by the companions.** Of the 52
   "major" choices, 44 have no companion reaction (all seven throne claims, the 14
   throne-winner choices, ten of the banner-piece choices, nine clan claims and
   pledges, the two Open Hand claims, the two choices at Vica's scene).
3. **Companions are thin between recruit and finale.** Each of the eight story
   companions has two authored scenes (recruit, loyalty); the loyalty choice is paid
   at the Muster (chapter 8) and nowhere between. Vica has one scene and **no
   story-choice line at all**; Vess has 5, Grosh 6.
4. **The Mire Courts and the Grey Vigil are met late.** Each clan has eight NPCs
   (`npcs.json`, `clan`), but the Mire's are seven in chapter 4 and one in chapter 2,
   the Vigil's seven in chapter 5 and one in chapter 6; both are throne claimants in
   chapter 7, and the intrigues that carry them (`the_returned`, `hooded_lantern`)
   hook in chapter 3, a chapter or two before the player meets the people.
5. **The bone die is opened and never closed.** Five uses in the prologue, warm in the
   trapdoor scene, the idol in chapter 1; then nothing until the ending, which does
   not mention it.
6. **The last two chapters' decisions are seen only at the end.** Chapters 6 and 7 set
   127 flags; 84 are read only in the chapter that set them and 43 only in the ending.

## 2. The numbers by chapter

"Fight %" is the share of choices that start a fight. Weight follows `choiceWeightOf`
(plates). Chapters 3 to 6 are camp-loop chapters (eight activities and one or two
quests before the main quest opens: `chapters.json`), so their DAG is the frame, not
the whole story.

| ch | name | nodes | words | choices | fight % | major / weighty / plain | words per scene (mean / median) | scenes over 150 words | page breaks |
|---|---|---|---|---|---|---|---|---|---|
| 0 | prologue and origins | 38 | 3 502 | 85 | 20 | 0 / 23 / 62 | 92 / 90 | 5 | 1 |
| 1 | the flight (now "The Burning City") | 14 | 1 600 | 30 | 10 | 5 / 3 / 22 | 114 / 129 | 3 | 0 |
| 2 | Saltmouth | 71 | 6 280 | 170 | 11 | 0 / 64 / 106 | 88 / 86 | 3 | 0 |
| 3 | The Spire of Judgment | 66 | 6 108 | 144 | 15 | 0 / 61 / 83 | 93 / 95 | 2 | 0 |
| 4 | The Hollow Court | 75 | 6 796 | 163 | 7 | 5 / 60 / 98 | 91 / 85 | 5 | 3 |
| 5 | The Shroud's Truth | 89 | 8 280 | 204 | 11 | 7 / 78 / 119 | 93 / 86 | 4 | 2 |
| 6 | The Hollow Shore | 54 | 5 452 | 139 | 4 | 8 / 62 / 69 | 101 / 109 | 3 | 0 |
| 7 | The Lantern Throne | 27 | 3 009 | 108 | 46 (see 4.2) | 21 / 57 / 30 | 111 / 110 | 2 | 0 |
| 8 | Beyond the Tear, the endings, `names_*`, `price_*` | 37 | 4 937 | 97 | 11 | 6 / 58 / 33 | 133 / 122 | 6 | 0 |
| camp | the eight `loyal_*` scenes | 8 | 941 | 16 | 0 | 0 / 16 / 0 | 118 / 117 | 0 | 0 |

Two readings. Chapters 2 and 3 have **no major choice at all**: their weight is carried
by 61 to 64 "weighty" ones (alignment, approval, items, quest offers), and the story's
real turns sit in chapters 4 to 8. And the chapter 3 to 6 weight is spread evenly (60
to 78 weighty choices a chapter): nothing there is bigger than anything else, which is
what makes the camp-loop chapters read as one long middle.

## 3. Pull: what makes the player want the next scene, quest, chapter

### 3.1 Chapter openings and closings (read)

| chapter | what ends it | what it promises | verdict |
|---|---|---|---|
| prologue → 1 | the Lark falls (`965`), the wreck on the dunes (`1100`) | who survived, the tear as a thing you can touch | strong: a question per scene |
| 1 → 2 | the old woman at the White Wells: "Keep that covered", and a city to find a ship (`1200`) | a named destination (Saltmouth), a named object (the Grey Shroud), a danger | strong |
| 2 → 3 | `2999`, three weeks at sea toward the Inquisition's mother-house | the enemy's seat, a landfall | strong, though it is a choice of how to sail rather than a hook scene |
| 3 → 4 | the Spire's gates shut (`3005`); the standard moves toward the player (`4999_drawn`) | the Cathedral, the standard that answers the Bundle | good |
| 4 → 5 | the Hollow Court's ledger: "I found my parents' names on the second page" (`5004`); the Open Hand struck through; "the Unmaking" | the player's own past | **the best reveal in the game** |
| 5 → 6 | the Shroud was sewn as a warning, cut into six, the sixth kept by the tear (`6002`) | what the whole chase is for | strong |
| 6 → 7 | five pieces laid out by the fire, "the sixth was on the far side of the tear" (`7400`) | cross the tear, or claim the Throne | strong |
| 7 → 8 | the tear answers the crowning; a herald walking before it "crying a name" (`7800`) | the final confrontation | strong |

The chapter hooks are the strongest part of the pull: each is pointed (a named place,
object or dated clue) and each is paid in the next chapter or the one after. Nothing
here needs fixing.

### 3.2 The intrigue threads (measured and verified in two places)

Eleven intrigues, six stages each. The table gives the chapter the codex *labels* for
each stage (`intrigues.json`, `stages[].chapter`, shown on the Clans and politics
screen) and the chapter where the stage *fires* (the choices and events whose
`politics.intrigue` sets it, read from the DAG and `politics_events.json`):

| intrigue | labelled Clue / Hook / Turn / Reveal / Crisis / Choice | fires: Clue / Hook / Turn / Reveal / Crisis / Choice |
|---|---|---|
| hooded_lantern | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / **8** (`7002_orders`) |
| dying_lantern_bearer | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / 8 |
| double_ledger | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / **6** (`7200_ledger`) |
| the_returned | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / 6 (`7200_returned`) |
| admiraltys_silence | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / 6 |
| relic_road | 1 / 3 / 4 / 5 / 6 / 7 | 2 / 3 / 4 / 5 / 6 / 6 (`7200_fourth_piece`) |
| broken_charter | 2 / 3 / 4 / 4 / 5 / 7 | 2 / 3 / 4 (event, ch 2) / 4 / 5 / 6 (`7100_charter_choice`) |
| unwatched_hour | 3 / 5 / 5 / 6 / 6 / 7 | 3 / 5 / 5 / 6 / 6 / 6 (`7200_stitcher`) |
| lanternbearers_will | 5 / 6 / 6 / 6 / 6 / 6 | 5 / 6 / 6 / 6 / 6 / 6 |
| taken_names | 7 / 7 / 8 / 8 / 8 / 8 | all 8 |
| hosts_price | 8 / 8 / 8 / 8 / 8 / 8 | all 8 |

- **The labels are wrong in two places.** The Clue fires in Saltmouth (`2015_*`, chapter
  2) and is labelled chapter 1; the Choice fires in chapter 6 (or 8) and is labelled
  chapter 7. Display only, nothing reads it, but the codex tells the player the wrong
  chapter for the first and the last stage.
- **Chapter 2 is not silent.** Six Clues fire in the Saltmouth scenes (`2015_informant_*`,
  `2015_route_sold`, `2015_child_tongue`, `2015_bundle`, `2015_dominion_blades`).
  (My first draft said the opposite, from the labels.)
- **Crisis and Choice arrive together.** For six intrigues the Crisis (`7100_*`,
  `7200_*`) and the Choice are one or two scenes apart in the Hollow Shore, so five
  decisions of the same size (`7200_ledger`, `7200_returned`, `7200_fourth_piece`,
  `7200_stitcher`, `7100_charter_choice`) come in one chapter after four chapters of
  setup, and two more (`7002_orders` and its sibling) in the ending.
- **The identical cadence blurs the threads.** The same chapter for every stage makes
  the six threads feel like one beat repeated in six costumes.

### 3.3 Open threads by chapter

"Mentions" are DAG scenes (plus callbacks) naming the thing; the other data files
(quests, NPCs, intrigue stages) add more where noted.

| thread | opened | advanced | paid | verdict |
|---|---|---|---|---|
| **Lysa** (the sister) | 0: taken, then rescued or lost | 1: eight scenes echo the choice; 3: `3005_lysa`, her price; 4: `5100_lysa_raid`, `_mask`; 5: `6010_lysa*` (six outcomes) | 8: `lysa_fallen` in the ending | **best-spaced thread**: a beat every one or two chapters |
| **Aurel Vane** (Inquisitor-General) | 0: `400`, "he knew exactly who I was" | 3: his envoy (`3005_envoys`, `3005_lysa_price`); 5: the will "names neither Vane, nor Morrow, nor Tallis" (`6100_will_scribe`) | 7: 15 scenes (`7520_vane`, `7810`), and the politics events `the_throne_filled` and `the_hand_hunted` | **no scene, intrigue stage or politics event shows him in chapters 4 or 6** (checked in `intrigues.json` and `politics_events.json`); his npc `want` ("the tear for a door and your blood for its key") is stated at chapter 1 and the DAG gives it back only at chapter 7 |
| **A second Vane** | 2: a scarred quartermaster at the Saltmouth shipyards, "this Vane had a ledger and a scar, not a lantern" (`2010`, 18 scenes in all) | | | a deliberate echo, and it works; but it means "Vane" has two faces in the first two chapters (see 7.1) |
| **The mother's oath / the cloth** | 0: "that is ours" (knocked twice on the floor), her name and the player's on the cloth in the Inquisition's list (`816`) | 4: the player's parents' names in the Hollow Court ledger, "the Unmaking", a date nine years before (`5004`); 5: the cloth's origin (`6002`) | 8: the Open Hand claim, `truth_told` | **paid** by the chapter 4 reveal; the mother herself is not named or seen again |
| **The Grey Shroud (six pieces)** | 1: "the Grey Shroud" named by the old woman | banner pieces granted in 0, 4, 5, 6; five laid out at `7400` | 8: the whole cloth in the ending, "undo the night the door was made" | **strong** and countable (six) |
| **The bone die** | 0: five uses, warm in `470` and `816`; 1: `1130`, the sign on the idol | none | none between 2 and 8; no ending scene mentions it | **opened and never closed.** The prologue frames the story as told "at many card tables since"; the ending returns to the card room but not to the die |
| **The tear** | 0 to 1 (touch it, `1100`) | 5: 26 scenes, 6: 19 | 8: 20 | strong, concentrated where it matters |
| **Hesk** (the neighbour) | 0: the old man next door, "his house taken with ours" | 2, 4: single mentions; his mother is an npc in chapter 4 | 7: 17 scenes | **long gap, big payoff**: about seven chapters between a mention and its answer |
| **The Sovereign** (final enemy) | **8**: first named in the DAG at `7810` (and `7003`, `7005_crown`); in `quests.json`, the ch. 8 main quest | the herald "crying a name" at `7800` is the only earlier hint | 8 | **verified in the data:** every source that names the Sovereign is a chapter 8 source (`chapters.json` ending hint, the `tear_herald` npc, the boss `void_sovereign`, the quest, the `sovereign_crown` item); the antagonist is introduced as the finale begins |
| **Vica** (companion) | 1: `1150_vica`, the desert meeting, 2 scenes | none | none | **dropped**: one scene, no recruit quest, no loyalty scene, no story-choice line |

**Flags.** Of the 650 flags that a story choice sets and something reads, 449 (69%)
are read only in the chapter where they were set (plumbing for the next scenes); 201
echo in a later chapter; 40 echo three or more chapters later (12 of them from the
prologue and chapters 1 to 2, 22 from chapters 4 and 5). The sixteen loyalty flags
(`loyal_*`) are set in the camp and read only at the Muster. Chapters 6 and 7 set 127
flags: 43 are read after their own chapter (all in the ending) and 84 only within it,
so **the last two chapters' decisions show up once, at the end**.

### 3.4 How soon each promise pays

- Within the scene or the next: nearly all choices (a `reply` line, alignment, standing).
- Within the chapter: the camp-loop quests and the intrigue Reveals.
- **Three chapters or more:** 40 flags, the mother's thread (to chapter 4), Hesk,
  the Dominion succession (`dying_lantern_bearer`: Clue in chapter 2, Choice in chapter 8), the loyalty
  scenes (camp to chapter 8).
- **Never:** the bone die, Vica, and the one dead flag the DAG sets and nothing reads,
  `open_hand_6` (set at `7002_banner`; the other six unread flags are the tutorial's
  `feat_*`, read by code).

## 4. Pacing

### 4.1 A typical first run (measured and read)

The shortest path from the first scene to the White Wells (`1200`) is 24 scenes; the
"always take the first option" path is 27. About 3 000 words, ten to twelve minutes of
reading, with 6 or 7 fights on it:

| scenes | what happens | fights |
|---|---|---|
| 1 to 4 (`0` to `105`) | the prologue, choose your origin, the dice den collapses, the first fight at scene 4 | 1 |
| 5 to 8 (`106` to `261`) | optional loot rooms, the proclamation, the Stone Bridge, a toll or a fight | 0 to 1 |
| 9 to 12 (`300` to `470`) | your street, Vane takes Lysa, the house falls, the boss fight, the trapdoor, the Shroud | 1 |
| 13 to 18 (`890_trainer` to `965`) | the ship, the quay, three skill checks, the storm | 0 |
| 19 to 27 (`1100` to `1200`) | the wreck, the desert (travel plus checks), the idol, Vica, the oasis | 1 to 2 |

The beat order is right: hook, loss, object, flight, wreck, a quiet stretch, a
destination. Two spots to check in play, neither fixed: scenes 5 to 8 can be skipped
almost entirely (`110` and `120` are optional side rooms, and their fall-backs `115` and
`125` repeat one label five and four times: "Crawl out into the street", "Get up and go
home", which are per-origin variants of one choice but read as repetition in a list),
and the desert stretch (`1120` to `1140`) is a walk of travel and checks with one story
beat in the middle (the offering at the idol, which pays a callback from the prologue).

### 4.2 Long stretches without story (measured, partly needs play)

- **Chapter 7 looks like a fight chapter and is not.** 50 of its 108 choices start a
  fight (46%), but 42 of those are three scenes (`7520_vane`, `7520_morrow`,
  `7520_tallis`) that each offer fourteen *alternative* fights, one per claim the
  player made; the player takes one. The real load of chapter 7 is not fights but
  **decisions**: the seven claims, the pledges, the Throne. (The intrigue Choices
  fall in the chapter before, 3.2.)
- **Chapters 3 to 6, the camp loop.** Before each main quest the player does eight
  activities and one or two quests (`chapters.json`). The authored scenes that carry the
  chapter between those are the arrival scene, the camp scene and the main quest's
  place. Whether each activity delivers a *story* beat depends on the 64 detour scenes:
  the pool available to a chapter is 32 to 37 scenes for chapters 3 to 6 and 17 for
  chapter 2, so a player who plays every chapter fully sees about one scene per draw
  with little repetition. **Needs play** to know how that reads over eight activities
  in a row.
- **Chapter 4's body is the Hollow Court (5xxx), 75 scenes, 7% fights**: the quietest
  chapter in the game, which suits the reveal it carries.

### 4.3 Info dumps and repeats

- **No scene is an info dump.** The longest are the endings: `7005_dawn` 378 words,
  `7005_seeker` 337, `7005_crown` 322, `7005` 292. All four split at `[EPILOGUE]` into
  two pages of 114 to 200 words (`7005_crown` is the longest page), so a phone shows at most about 200 words at once.
  Chapter 5's `6010_record` (222) is the one non-ending scene over 200.
- **Onboarding spike.** `3005_envoys` (152 words) introduces three Dominion leaders
  (Grand Master Morrow, Cassian Oriel, Maud Tallis) at once; the three then carry the
  `dying_lantern_bearer` intrigue and seventeen to nineteen scenes of chapter 7.
- **Repeats.** Chapter 7 reuses one shape seven times (a claim, a trial, a throne scene)
  by design.

## 5. Choices: do weighty and major choices change something the player sees?

Method: `choiceWeightOf` of `story_plates.dart` applied to all 1 156 choices: 52 major,
482 weighty, 622 plain.

### 5.1 What is shown

- **Alignment, standing, approval, items, quests:** shown at once (plates, the clan
  cards, the journal).
- **Flags:** 666 of the 673 are read somewhere; 311 only by a callback paragraph
  ("echoes"), 268 only by a later choice's visibility, the rest by both or by a gated
  scene.
- **The ending:** `7005` and its three variants read 20 to 27 flags each: the Throne
  winner, the pledges, the banner stood vigil for, Lysa, the truth told or kept. The
  Muster (`7800`) has 70 callbacks, shown at most ten, picked by priority (the Throne
  winner 5, pledges 3, the companions' loyalty lines 2, the host 1, the 20 house lines
  0): a deliberate and good design.

### 5.2 What is not shown

1. **Major choices with no companion reaction: 44 of 52.** Seven throne claims (`7500`
   choices 7 to 13); fourteen throne-winner choices (`7590_*`); ten banner-piece
   choices (heirloom `1000/1001/1002`, mantle `7003` ×2, white-fleet sail `7300`,
   reliquary thread `6010_thread` ×3, warden's standard `4999_standard`); nine clan
   claims and pledges of chapters 5 to 7 (`6010_clan_*`, `6100_clan_*`, `7100_clan_*`,
   `7200_clan_*`); the two Open Hand claims (`7002_banner`); the two approval choices
   at Vica's scene (`1150_vica`). Companions react to 21 story choices today
   (`companion_remarks.json`, `trigger: choice`), and **only 8 of them are among the
   52 major choices**.
2. **Heard from few.** The 21 keyed choices carry 72 remark records, 3.4 of the nine
   companions per key. By companion: Maren 13, Kelda 12, Tobin 10, Sable 9, Liora 9,
   Malrik 8, Grosh 6, Vess 5, **Vica 0**. A player who brings Vica and Vess to a scene
   where only Kelda, Maren and Tobin have a line will hear the room go quiet.
3. **Hidden politics.** Choices with `politics.hidden` show no plate effect and read as
   plain unless they also do something visible. That is intended and should stay a
   minority; the hidden fraction by chapter was **not measured** and is worth counting
   when the plate redesign is judged.
4. **Chapters 6 and 7 pay at the very end** (3.3): the player will not see the effect of
   the Reed Gate (`7400_reed`) or the Herald's petition until `7800`.

## 6. Characters

### 6.1 The companions

| companion | scenes | recruit | loyalty beat | story-choice lines | verdict |
|---|---|---|---|---|---|
| Kelda | 2 (`2015_kelda`, `loyal_kelda`) | ch 2, hold the gate | the dog-tags: "we held the gate for nine hours" | 12 | clear want, clear wound; best written |
| Sable | 6 (`2015_sable*` ×5, `loyal_sable`) | ch 2, the wager | the marker, kept or torn | 9 | strong recruit scene, then silence |
| Liora | 5 (`2010_liora`, `2015_liora*`, `loyal_liora`) | ch 2, the watch | the watch shared or left | 9 | fine |
| Vess | 2 | a ch 1 quest, met in `2015_vess` | the voice answered or stilled | **5** | the thinnest after Vica |
| Maren | 2 | ch 3, her penance | the names read or burned | 13 | clear |
| Grosh | 2 | ch 3, his price | the debt paid or kept | 6 | clear (the hall's debt is concrete) |
| Tobin | 3 | ch 4, the vigil | the letter sent or he stays | 10 | clear |
| Malrik | 2 | ch 5, his cut | the book read or shut | 8 | clear, the sharpest voice |
| Vica | 1 (`1150_vica`) | a story join node | **none** | **0** | dropped |

- **Wants and arcs.** Each of the eight has a want stated in one sentence (money, penance,
  a debt, a watch, a letter) and the loyalty scene turns it into one decision. That is
  clean but it is the *only* turn: recruit (chapters 2 to 5) → loyalty (the camp) → the
  Muster (chapter 8). There is no beat in chapter 6 or 7, where the player is most
  invested and the party is largest.
- **Reaction to the player.** Every companion has the same 22 to 23 general remark
  records (approved, disapproved, check passed, camp built, risky, drink, walk; Vica
  26) plus their story-choice lines. The general ones make a companion present in the
  loop; the keyed ones make them feel *about* the story; the second kind is missing
  for the biggest choices (5.2).
- **Approval moves.** Choices touch companion approval 61 times (Kelda 9, Liora 9,
  Maren 8, Vess 7, Grosh 6, Tobin 6, Malrik 6, Sable 5, Vica **2**; the wildcard `*` 7
  times): Vica is both under-written and under-wired.

### 6.2 Key NPCs

- All 80 NPCs in `npcs.json` have a `want` (one sentence). That is the data's best
  practice and the reason the Saltmouth and Spire scenes read as populated.
- By `clan`: Dominion 10, Crows 8, Penitents 8, Compact 8, Mire 8, Vigil 8, so each of
  the six clans has a cast. **The casts arrive in different chapters**: the Dominion's
  in 1 to 3, the Compact's in 2 to 3, the Crows' in 2 to 4, the Penitents' in 3 (seven
  of eight), the Mire's in 4 (seven of eight), the Vigil's in 5 (seven of eight).
- **Antagonists.** Vane is a clear villain with a one-line want but is absent from the
  scenes of chapters 4 and 6; the Sovereign is introduced late (3.3); the three Dominion
  leaders arrive in one scene (4.3). The Hollow Court's own villain is the ledger,
  which suits the reveal.

## 7. Onboarding, and reading ease

### 7.1 Is the lore introduced gradually?

- **Yes, at the start.** The prologue gives one rule ("power is not held; it is worn"),
  one enemy (the Inquisition), one object (the cloth), one place, in 24 scenes. New
  proper names per scene average under one until chapter 2 (counted as new capitalised
  names).
- **Clans by first DAG scene.** The Inquisition: scene 0. The Compact and the Crows:
  Saltmouth (chapter 2). The Penitents: a mention in chapter 2, then chapter 3. The
  Vigil and the Choir: chapter 3 in a scene, but the Vigil's NPCs only from chapter 5.
  The Mire Courts: `5200_clan_mire_1`, in chapter 4. The Open Hand: a mention in
  chapter 2, then the chapter 4 reveal. So the player has **not met the Mire's or the
  Vigil's people before chapter 4 or 5**, and meets the first clan *choice* (the clan
  cards' claims, chapters 5 to 6) within a chapter or two of each.
- **Spikes (new names in one scene):** `3005_envoys` (9: Morrow, Oriel, Tallis and the
  Quarter), `7520_vane` (5), `5100_clan_dominion_1` (5), `5200_house_barkbleeders`
  (5), `3005_clan_compact_1` (5: Emberwife, Tribunal, House). All are clan or house
  scenes: a clan's *house* and *place* arrive in the same paragraph.
- **Two Vanes.** Chapter 2's quartermaster Vane (18 scenes) is a deliberate echo of
  the Inquisitor-General, and the line that explains it is good, but the Inquisitor
  appears in only three scenes in the prologue; for a player who has just met the
  name once, it is an echo of a thing barely established.
- **Jargon.** The coined terms (the tear, the Shroud, the Lantern, the Host, the Unmaking,
  the Wickwardens, the Open Hand) are used consistently and each is glossed where it
  first matters; the biggest cost is the **Dominion's titles** (Voice, Regent, Eldest,
  Lantern-Bearer, Lantern-Throne, First Lantern, the Order), which the player meets
  in `3005_envoys` and `7400_herald` and needs in chapter 7.

### 7.2 Reading ease

| measure | result | on a phone |
|---|---|---|
| words per scene | median 94; mean 88 to 138 by chapter | good |
| paragraphs per scene | 2.3 on average | good |
| sentences | mean 13 to 16 words by chapter; 90th percentile 25 to 31; the longest 59 words (`7810`) | fine; chapter 8 averages 20.7 words, the heaviest reading in the game |
| longest scenes | the four `7005` endings (292 to 378 words), split in two pages at `[EPILOGUE]`; `6010_record` 222 | acceptable; the only scenes to scroll |
| choice labels | mean 33, longest 49 characters (rule: 55) | good |
| bold passages | one per scene (guarded by `story_bold_budget_test`) | good |
| French vs English | 1.02 to 1.07 of the English word count | no layout risk |
| EN / FR names | two variants across the data: `La Route des pèlerins` / `…des Pèlerins`; `Le` / `La Porte-Clef` | negligible (to fix in a text PR) |

## 8. Proposals, ranked

Ranked by impact for cost. **Needs Core / needs UX** says who has to do their part.

### P1. Fix the codex's chapter labels (impact medium, cost very low, **quick win**, size S)
*Brief.* In `intrigues.json` the Clue of eight intrigues is labelled chapter 1 and fires
in chapter 2, and the Choice of the lock-step ones is labelled chapter 7 and fires in
chapter 6 (chapter 8 for the two Lantern-Bearer intrigues). Set each stage's `chapter`
to where it fires (3.2). Display only: `IntrigueStage.chapter` is read by the Clans
and politics screen and nowhere else (`lib/data/factions/intrigues.dart:21`,
`clans_politics_screen.dart:1608`). Mine alone; no Core or UX change.

### P1b. Spread the Hollow Shore's five intrigue decisions (impact high, cost high, **needs the user's choice**, size L)
*Brief.* Five decisions of the same weight (`7200_ledger`, `7200_returned`,
`7200_fourth_piece`, `7200_stitcher`, `7100_charter_choice`) land within the chapter
that also carries the Crisis stages and the clan trials. The alternative is to let two
of them (the charter, the Admiralty) resolve a chapter earlier, at their Reveal, which
means moving or duplicating DAG scenes and re-routing flags: a story restructure, not
a wording change, and it would change what the Muster and the endings echo. **Needs
the user's choice** (is the pile-up a climax or a glut?), then Core for the simulator
re-run. I do not recommend it before a play session says the chapter drags.

### P2. Companions react to the biggest choices (impact high, cost medium, size M, **quick win** for text, Core confirms the firing)
*Brief.* Add story-choice lines for the 44 major choices that have none, grouped into
about a dozen new keys (the seven throne claims, the throne winner, the banner pieces,
the clan pledges); and bring the 21 existing keys up to all nine companions (72 of a
possible 189 lines are written; about 117 missing, **Vica's 21 first**). The text is
Narrative's (EN, FR; the voices exist and are consistent). The keys match a flag a
choice already sets or `nodeId#index` (`lib/data/companion_remarks.dart:22`, read by
`story_choice_flow.dart:671`), so **no code is needed**; a party member with no line
for a key falls back to a general remark, which is why coverage by companion matters.

### P3. A second beat per companion, in chapter 6 or 7 (impact high, cost medium to high, size L, **needs the user's choice**)
*Brief.* Each of the eight gets one short scene (60 to 90 words, a camp scene like
`loyal_*`, offered at Friendly and above, with one decision whose echo is added to the
Muster). It closes the long gap between the loyalty choice and the finale and raises
the stake of keeping the party. Vica gets the same *plus* a recruit scene and a loyalty
scene, so she stops being the one orphan. **Needs Core** to add the scene ids to the
camp scene list (`world_map.dart`) and the unlock rule; the text is Narrative's.

### P4. Meet the Mire Courts and the Grey Vigil before they matter (impact medium, cost low to medium, size M, **quick win**)
*Brief.* The Mire already has one chapter 2 face (`keeper_apothecary_row`, Saltmouth):
give that keeper a line that names the Courts, and add one Mire scene in chapter 3.
For the Vigil, move one of its seven chapter 5 NPCs to chapter 3 (or add one at the
Spire's camp), so each clan has a face before its intrigue hooks. Text and `npcs.json`
(Narrative); **needs Core** only if an NPC needs a place id.

### P5. Give Vane a presence in chapters 4 and 6 (impact medium, cost low, size S, **quick win**)
*Brief.* One short scene or letter in each of chapters 4 and 6 in which Vane acts (a
writ, a seal, a message left for the player); his want is stated at chapter 1 and the
scenes show it again only at chapter 7. Two 80 to 100 word scenes plus a
`flag_callbacks` line each. Text only.

### P6. Introduce the Sovereign before the finale (impact medium, cost low, size S, **quick win**)
*Brief.* Every source that names the Sovereign is a chapter 8 source (3.3). Add one
line to `7001` (the Hollow Shore's rumour) and one to `7400` (the herald's seal) so the
name has been heard once before `7810`. Text only.

### P7. Close the bone die (impact low to medium, cost very low, size S, **quick win**)
*Brief.* One sentence in each of the four `7005*` endings that returns to the die: the
endings are set in the card room, and the die has been the narrator's thread for the
whole story. Text only; the four endings already carry 20 to 27 callbacks, so this is
one more.

### P8. Break the Dominion's titles up (impact low to medium, cost low, size S, **quick win**)
*Brief.* Introduce Morrow, Oriel and Tallis in three scenes of chapter 3 (Morrow in
`3005_envoys`, the other two as a rumour in the camp and a letter at the Spire) instead
of one scene with nine names. Text only; `3005_envoys` stays and is trimmed.

### P9. Show the Muster's cap to the player (impact low, cost medium, size M, **needs the user's choice**, needs UX and Core; no pictures needed)
*Brief.* The Muster has 70 echoes and shows ten; the other sixty exist in the data. A
"what the host remembers" list the player can open from the scene (the full 70, in
priority order) lets every choice be seen once. **Needs UX** (how it shows) and **Core**
(the list is read from the callbacks). Narrative supplies nothing new.

### P10. Small fixes folded into the next text PR (impact low, cost very low, size S, **quick win**)
Unify `La Route des pèlerins` / `Pèlerins` and `Le` / `La Porte-Clef`; add a closing line
to `7002_banner`'s Open Hand claim so `open_hand_6` is read (or drop the flag).

## 9. Asks and open questions

- **For the manager:** P1b and P3 need Core; P9 needs UX and Core. P1, P2, P4, P5, P6, P7,
  P8 and P10 are mine alone and can go in the order of the ranking.
- **For a play session:** chapters 3 to 6 over eight activities (does each carry a
  beat?), and the Hollow Shore (do five intrigue decisions in one chapter read as a
  climax or a pile-up?). I have not played these; the numbers above only locate where
  to look.
- **No change was made** to any file except this one.

## 10. How this review was checked (the three passes)

- **Pass 1, find.** The draft of 23 November: scripts over the DAG, quests, intrigues,
  remarks, NPCs and flags, plus a read of the hooks, the prologue and the endings.
- **Pass 2, verify.** Each finding re-checked against the data or the code. What it
  killed or changed:
  - "Chapter 7 is a fight chapter" (46% of choices): an artefact of three scenes with
    fourteen alternative fights each. Removed as a finding (4.2).
  - "Chapter 2 has no intrigue stage" and "Choices land in chapter 7": the stage
    `chapter` in `intrigues.json` is a display label; the stages actually fire in
    chapter 2 (Clue) and chapter 6 (Choice). The finding became the label bug (P1)
    and the pile-up in chapter 6 (P1b); the first proposal (fill chapter 2) was dropped.
  - "31 of 52 major choices have no remark": the real figure is 44 (only 8 of the 21
    remark keys sit on major choices).
  - "Each clan has 3 to 7 NPCs, the Mire five": by `clan` each has 8 (Dominion 10); the
    real gap is *when* they arrive (Mire chapter 4, Vigil chapter 5).
  - "Vane appears in chapter 2 eighteen times": a namesake (a quartermaster).
  - Scene counts by chapter were first taken from the id's first digit; redone with the
    real mapping (ids 4xxx and 5xxx are chapter 4, 6xxx chapter 5, and so on) and with
    the `loyal_*`, `names_*`, `price_*` scenes placed.
  - Confirmed with evidence: the Sovereign named only in chapter 8 sources, Vane absent
    from chapters 4 and 6 in the scenes, intrigue stage data and politics events, the
    bone die absent from chapters 2 to 8, Vica with 0 story-choice lines.
- **Pass 3, fresh eyes at the seams.** Checked where my findings touch other areas:
  `IntrigueStage.chapter` (Core's `lib/data/factions/intrigues.dart`) is display only;
  companion choice remarks need no code (`companion_remarks.dart`); the Muster's cap
  is priority-ordered on purpose (`story_node.dart:1002`), so it is not a finding;
  the 7005 endings split in pages at `[EPILOGUE]` (`narration_pages.dart:12`), so
  their length is not a finding; the French names are consistent (two variants).
- **Tests, three times in a row.** The area's 29 files (story rules, graph, markup,
  bold budget, plates, nemesis, payments, enemy refs; quest validation, objectives,
  rewards, hints, politics, tracking, nemesis, main-quest lock; French data lint,
  French address, `app_strings` French typography, `qa_story_fr`; companion remarks,
  remark story, narration pages, text placeholders, chapter eight, choice shape,
  politics events): 199 tests, **all passed in all three runs, identical results, no
  flaky test**. Times 64 s (cold compile), 35 s, 32 s.
- **Self-review.** Each proposal re-read for proportion: P1b is not recommended before
  a play session; P9 is last because the cap is deliberate; P3 is the only large text
  job and is marked as the user's choice.
