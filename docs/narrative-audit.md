# Narrative audit

First audit by the Narrative session, taken on `origin/main` at v1.254.0
(76c8773). Nothing in the game was changed; this file is the only output.
**Status:** P1-3, P1-4, P2-1, P2-2 and the four silent shopkeepers of P2-3
were fixed in #171. P1-2 (the quest chain, the chapter label and the missing
chapter 7 quest), the chapter-end headers, the `hopeful` mood tag, the
English apostrophes and the proposals for moods, themes and achievements are
in the follow-up PR; the options Core and the user decide on are in
`docs/narrative-proposals.md`. P1-1 (the dormant intrigues, five of them) was done in #179 and the NPC
voices of 4C in the PR after it (the rest of P2-3). P2-4 and the other P3 items wait.

Every id below can be looked up as written: a story node in
`assets/Cleaned_Narrative_DAG.json`, a quest in `quests.json`, and so on.

## 1. The world and the arc

**The setting.** In this world power is *worn, not held*. The Lantern
Dominion's Inquisition sews its saints into white standards; the painted
elves carry sigils on skin and bark; the stone-marked dwarves cut theirs
into steel; the inked orcs carry it under scars; the voidkin carry a power
nobody made. A **tear** has opened in the sky, and the **Shroud**, a
banner in six pieces, is the one thing that can open it wider or turn
time back. The narrator is the player's character, telling it afterwards
in a dry, wry first-person voice (the prologue, node `0`, sets it).

**The powers.** `factions.json` has 13: six clans (Lantern Dominion, Grey
Vigil, Cinder Compact, Mire Courts, Salt Crows, Ashen Penitents), two
otherworld powers (Choir, Pit), four tribes (giants of Highhearth, oni,
Tide-Kin, Kindly Ones) and the lost Open Hand. Their stories come out in
52 NPCs, 8 companions, 8 intrigues and 26 politics events.

**The arc.** The story graph has 385 nodes and 915 choices.

| Ch | Where | What happens | Piece of the Shroud |
|---|---|---|---|
| 1 | Alster (nodes `0`–`1xxx`; three origin openings `1000`–`1002`) | The Dominion burns the player's home and takes their sister Lysa; the player flees with the heirloom. | 1. `heirloom_shroud` |
| 2 | Saltmouth (`2xxx`) | A smugglers' port. The player builds the *Rusty Eel* and leaves. Most companions are met here. | none |
| 3 | The Ashen Coast, cove camp `3001`, Spire of Judgment | The camp, the Ashen Quarter, Emberwick; climb the Spire, end the High Warden. | 2. `warden_standard` |
| 4 | The Hollow Court (`4999_camp`, `5xxx`) | Wrack's End, Drowned Cloister; the Court's Inquisitor and the second ledger. | 3. `moon_shard_shroud` |
| 5 | The Shroud's Truth (`6xxx`) | Rimewell, Reliquary Quarter, Highhearth, the Dead Heart. | 4. `reliquary_thread` |
| 6 | The Hollow Shore (`7001`–`7300`) | White Anchorage, Greyhithe, the White Fleet's grave. | 5. `white_fleet_sail` |
| 7 | The Lantern Throne (`7400`–`7590`) | Back at the cove with five pieces; Candlehold, the Houses, the throne is filled. | none |
| 8 | Beyond the Tear (`7800`+) | Muster the Host, cross the tear, face the Sovereign (`7003`). | 6. `sovereign_mantle` |
| End | `7004`/`7005*` | Four epilogues, ending on the night before the invasion (New Game+). | |

From chapter 3 the game is a hub-and-loop: places are entered by travel,
not by story edges, so they are legitimate roots of the graph.

**Where each chapter stands.** Chapters 1–6 are written, voiced and
translated end to end, with hubs, clan scenes, house scenes and quest
givers. Chapters 7 and 8 are written as story but are thin as *game
content*: they have a camp scene and a main quest, but no side quests, no
NPC roster to speak of (one NPC, `tear_herald`, is chapter 8) and
`activityGoal`/`questGoal` of 0.

## 2. What was checked, and what is clean

- **Story graph.** All 385 `id` fields match their keys. Every
  `next_id`, `failNextId` and `loseNextId` resolves (apart from the
  `EXIT` sentinel, which the engine treats as an end marker). Starting
  from node `0`, the hub places, camps and `6010_gate`, **every node is
  reachable**. No node lacks choices, none has a duplicate description.
  (`lib/data/story_graph_integrity.dart` already guards much of this.)
- **References.** Every quest `nextQuestID`, reward item, reward ally,
  target enemy and target item exists. Every `unlockQuestId`,
  `grantItemId`, enemy id and `launchZoneId` in the graph exists. Every
  NPC `metNodes` entry exists, every NPC `shopId` exists. Every companion
  `recruitQuestId` exists; the one `requiredHouseId` (Kelda) exists.
- **Flags.** About 140 flags are read but never set by a graph choice;
  the ones I traced are all set elsewhere (quest turn-in `flag`, a
  politics event, or code that builds the name: `origin_*`, `house_*`,
  `host_*`, `pledged_*`, `intrigue_*_stage_*`). I found none that is
  genuinely dead.
- **Text tokens.** `{name}`, `{race}`, `{profession}`, `{companion}`,
  `{sigil}`, `{lost}` are the only tokens in the story and all are filled
  by `lib/data/narration_tokens.dart`. `{sigil}` and `{profession}` appear
  only inside race- or profession-keyed variants, with matching French
  articles. No TODO/lorem/placeholder text anywhere.
- **French coverage.** Every node, choice, quest, NPC, companion, remark,
  intrigue stage and achievement has French. No line with English leaking
  into it. `dialogueLines` / `lines` pair up 1:1. `app_strings.dart` has
  2,933 keys, all with a French value, no duplicates; 22 random entries
  read naturally ("Touchez…", correct non-breaking space before `:` `!`).
- **Tone.** No slang or modern register in the story text. The voice is
  consistent.

## 3. Problems, in priority order

### P1 — real gaps a player can hit

**P1-1. Five of the eight intrigues have no story content.**
`intrigues.json` defines eight plots with six written stages and outcomes
each, but only the first two are ever advanced by the game:

| Intrigue | Stages played | Where |
|---|---|---|
| `hooded_lantern` | 1–5 and the outcome | `2015_informant_*`, `3002`, `5010_letter`, `6010_thread`, `7100_log`, `7200_orders` |
| `dying_lantern_bearer` | 1–5 and the outcome | `2005`, `3005_envoys`, `5100_vote`, `6100_knife`, `7100_chaplain`, `7200_throne` |
| `broken_charter` | stage 3 only | `politics_events.json` `coal_stops` |
| `double_ledger`, `the_returned`, `admiraltys_silence`, `relic_road`, `unwatched_hour` | **none** | — |

The Intrigues tab in play mode only lists a plot once its stage is above
0, so the player never sees them, but their outcomes (e.g. `the_returned`
→ Liora leaves) can never fire, and the premise and NPC hooks already
written (`wharf_informant`, `orsabet_vell`, `keeper_smugglers_vault`…) lead
nowhere. Also: four stage anchors name an NPC who first appears *after*
the stage's own chapter: `wharf_informant` and `crape_courier` (ch 2, stage
chapter 1), `fleet_helmsman` (ch 6, stage chapter 1 of `admiraltys_silence`),
`orsabet_vell` (ch 5, stage chapter 3 of `unwatched_hour`).

**P1-2. Chapter labels and the quest chain do not match the chapters.**
- `q_ch6_beyond_the_tear` is `chapter: 6`, but it is unlocked at node
  `7800` and is the main quest of chapter **8** (`chapters.json` `ending`).
  Its id and chapter number belong to a layout from before chapters 7 and
  8 existed. Whether chapter 6's quest goal (`questGoal: 1`) counts it is a
  question for Core.
- `q_ch5_the_dead_heart.nextQuestID` is `q_ch6_beyond_the_tear`, which
  skips the whole of chapters 6 and 7. `q_ch6_the_white_fleet` points at it
  too, so the target has two predecessors.
- There is **no quest for chapter 7**, although `chapters.json` `ch7` has
  a main-quest title ("Take the Lantern Throne") and hint, and the story
  has a whole throne campaign (`7500`, `7510_*`, `7590_*`).

**P1-3. The Shroud's pieces are counted inconsistently.** The pieces come
in the order heirloom (1), `warden_standard` (2, ch 3), `moon_shard_shroud`
(3, ch 4), `reliquary_thread` (4), `white_fleet_sail` (5),
`sovereign_mantle` (6), and the chapter 5 and 6 hints and node `7001`
count this way. But the **chapter 4 hint** (`chapters.json` `ch4`,
`mainQuestHint`: "keeps the **second** piece") and node `5010` ("the
Shroud's **second** piece was waiting for the water to go down") call
chapter 4's piece the second. It is the third. (`docs/chapter-flow-roadmap.md`
also calls it "the Court's twin"; the data id is `moon_shard_shroud`.)

**P1-4. Two docs describe a game that no longer exists.**
- `docs/chapter-flow-roadmap.md` is headed "status after v1.149". Its
  table ends at chapter 6 plus an "End" row at `7400`; today `7400` is
  chapter 7 (the Lantern Throne), `7800` is chapter 8, and the throne
  system, the Houses and the Host are not mentioned.
- `docs/quest-progress-tracking.md` opens "Not implemented" and talks of
  15 quests (9 Kill, 4 Fetch, 2 Talk). There are 39 quests (24 Kill, 13
  Flag, 2 Fetch, 2 Talk), and objective tracking exists
  (`lib/data/quest_objectives.dart`, `test/quest_objectives_test.dart`,
  `test/quest_tracking_test.dart`), including a `Flag` type the doc does
  not know. The doc should become a short description of what shipped.

### P2 — inconsistencies a careful reader will notice

**P2-1. "Saltmouth" is translated 12 times and left in English 3 times.**
French says *Bouche-de-Sel* (9 times in the story text, 3 in `npcs.json`) except in:
`Cleaned_Narrative_DAG.json` node `3005` `flag_callbacks[7].fr`;
`quests.json` `q_ch2_leave_saltmouth` `npcDialogueText_fr`;
`politics_events.json` `scaffold_wages_after` `news_fr`. (Core's
`ports.json`, `geography.json`, `items.json`, `chart_worlds.dart` and
`world_map.dart` use Bouche-de-Sel; the other proper nouns — Candlehold,
Highhearth, Rimewell, Wrack's End, the Eel — are deliberately kept in
English and are consistent.)

**P2-2. French typography is mixed.**
- 24 places use a plain space instead of a non-breaking one before `? ! : ;`
  or `»`/`«` (883 are correct). Nodes: `3001`, `3001_camp`, `3005` (4),
  `4999_camp` (5), `5010`, `5010_tobin` (2), `6001`, `6002_camp` (3),
  `6010`, `6010_malrik`, `6010_thread`, `7001` (3).
- Apostrophes: straight `'` and curly `’` are mixed in both languages
  (story French: 825 straight, 2,091 curly; `companion_remarks.json`
  French: 239 straight, 3 curly; `companions.json` French: 44 straight, 0
  curly). "Wrack's End" is straight in `npcs.json` (2) and curly in the
  other 17 places.
- Narration clips are keyed by a hash of the exact text (see
  `assets/narration/README.md`), so any wording or punctuation change
  invalidates the recording. `assets/narration/en` and `fr` are empty today,
  so **now is the cheapest moment** to normalise this.

**P2-3. Some NPCs have almost nothing to say.**
- Four shopkeepers have no `dialogueLines` and no `states`:
  `keeper_blind_beggar_stall`, `keeper_shieldwrights_hall`,
  `keeper_sharpweave_den`, `keeper_wayfarer_caravan` (the last also has an
  empty `placeId`).
- Thirteen `keeper_*` NPCs have empty `metNodes` and `metFlags`; that is
  fine: `npcDiscovered` (`lib/data/quest_tracking.dart`) lists a keeper once
  their shop is found.
- Only 3 NPCs use `dialogueLines` (`lysa`, `old_harker`, `sister_ines`);
  the other 49 speak only through flag-dependent `states`. Only 10 of the
  385 story nodes have a speaker other than the Narrator. The people are
  well described and almost never talk.

**P2-4. Intrigue stage chapters vs. where the scene plays.** For
`hooded_lantern`, `dying_lantern_bearer` the "Clue" is declared chapter 1
but plays in the Harbor in chapter 2 (nodes `2015_informant_*`, `2005`). The
Intrigues tab shows the stage name, not the chapter, so nothing breaks;
change the declared chapter to match, or move the clue earlier.

### P3 — small things

- **Naming.** "Bannière du Vide" (`ship_looks.json` line 552, a Core file)
  vs. "Néant" for the Void everywhere else. "Hearth-Stone" in the quest
  title `q_ch5_hearth_stone` vs. "hearth-stone" in prose (fine as a title,
  noted for consistency). "Hollow" is carrying a lot: Hollow Court, Hollow
  Shore, Hollow Court Inquisitor, the hollow reflections; "Lantern" too
  (Dominion, Bearer, Docks, Throne, Hooded Lantern, First Lantern).
  Intentional echoes, but easy to confuse in French dialogue.
- **Chapter headers.** Chapter 1 has no `[CHAPTER 1…]` card (the origin
  cards `[ORIGIN: …]` stand in), chapter 2 is the only one with a
  `[CHAPTER 2 END]`, and the chapter 4 header sits on `4999_camp` rather
  than an arrival node. Node numbering does not follow chapters (`6001` is
  chapter 5, `7001` is chapter 6, `7400`/`7800` are 7/8); the table in
  section 1 is the key.
- **Mood / theme.** Mood `suspense` is used on 4 nodes (`891`, `895`, `2001`,
  `3020`) where the rest use `tense` (72 nodes). `ui_theme: docks` covers
  `candlehold_gates` (a cliff city), `cove_camp` and `hollow_shore`. Both
  are Core/UX mappings; noted only so nobody authors against them blindly.
- **`q_first_blood`** has no `unlockQuestId`; it is started by
  `questIDToProgress` in node `260`. Works, but it is the only quest that
  starts that way, which is easy to miss.
- **Achievements.** Only 7, all about companions, quests and shops. None
  for the story (a piece of the Shroud, an intrigue outcome, an ending).

## 4. Where the story could go next

Ordered by how much of the game already exists to support them.

**A. Finish the five dormant intrigues** (fixes P1-1). Each already has a
premise, six staged beats and outcomes; what is missing is one scene per
stage in the graph (`politics.intrigue` steps on existing hub or clan nodes)
and the NPC to anchor it. `the_returned` (fen children who see through the
Shroud) would also give Liora's "leaves" outcome a story. *Needs:* Narrative
only for the writing; Core to review outcome numbers. No new mechanic.

**B. Give chapters 7 and 8 a game around the story** (fixes P1-2).
Re-number or re-label `q_ch6_beyond_the_tear`, add the missing chapter-7
main quest and three or four side quests around Candlehold and the Houses,
and a handful of NPCs (Lantern-Bearer's court, the Herald's heralds).
*Needs:* Core to decide what ch7/ch8 `questGoal`/`activityGoal` mean (today
0), whether the chapter field of a quest drives the chapter card, and to
set rewards.

**C. Let the people talk.** Give the major NPCs (Imeh, Brannoc, Orsabet,
Ghrem, Nkem, Dorran, the High Warden) a first-person voiced exchange in the
node where they are met, using the existing `speaker` field, and move the
state-only NPCs onto proper `dialogueLines`. The speaker labels live in
`lib/data/narration_tokens.dart` (`_speakerLabels`), which is a few lines of
Core-owned code per new speaker. *Needs:* a few `_speakerLabels` entries
(allowed as a string-text change); UX only if portraits per speaker are
wanted.

**D. Companion loyalty scenes.** Eight companions have a recruit quest, barks
and approval lines (`devotedLine`, `warnLine`, `leaveLine`) but no
personal scene after recruitment. One short, choice-bearing scene per
companion in the camp, offered when approval crosses a threshold, would pay
off the existing approval system. *Needs:* **Core** for the trigger (a camp
scene offered at a given approval/chapter); **UX** only for how the offer
looks.

**E. New Game+ as story.** The epilogue turns time back to the night
before the invasion, but the retelling is the same. A second-pass
prologue and NPCs who half-remember (keyed on an NG+ flag and on which
ending and which intrigue outcomes carried over) would make the loop a
reason to replay rather than a reset. *Needs:* **Core** for the NG+ state
(which flags survive), **UX** for a distinct prologue card; the writing is
Narrative's.

## 5. First fix batch (done in this PR)

All text/data, all Narrative-owned: P1-3 (piece count, also in the
Lantern Docks lead, which now says "next piece"), P1-4 (the two docs), P2-1
(3 French strings), P2-2 (24 no-break spaces; every French apostrophe in the
story files made curly; "Wrack's End" in `npcs.json`) and four
shopkeepers' lines (P2-3: standing-based lines for Hesta Brann and Needle, in
the shape the other keepers use, flag-based ones for the cellar-boy and
Old Pell). P1-2 needs Core's answer on chapter numbering before it is
touched. English apostrophes are still mixed and were left alone.

## 6. Limits of this audit

- I did not read all 385 node texts end to end; structure, references,
  French coverage and wording were checked by script and by sampling the
  openings and the key hinge scenes (`0`, `100`, `400`, `800`, `1000`,
  `2001`, `2999`, `3001`, `3020`, `4999_standard`, `5004`, `6004`, `7001`,
  `7003`, `7400`, `7800`).
- French was sampled (22 UI strings and the Saltmouth/typography scans),
  not proofread.
- `flutter` and `dart` were not available in the session that wrote the
  fixes, so the data was checked with scripts that mirror
  `test/french_data_lint_test.dart` (no-break spaces, tutoiement) and a
  JSON parse of every file touched; CI is the real test. The lint test
  skips the story graph's bare `fr` keys (it only reads keys ending in
  `_fr` or `Fr`), which is how the 24 plain spaces got through.
- `CLAUDE.md` is not on `main` yet (PR #168 on the manager's branch), so
  the ownership rules were taken from the briefing.
