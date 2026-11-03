# Narrative: improvements within the story and wording

From the Narrative session to the manager. Scope: `assets/Cleaned_Narrative_DAG.json`, the story data in `assets/gamedata/` (quests, chapters, NPCs, companions and remarks, intrigues, politics events, achievements) and the EN/FR wording of the game data. **No new story content and no code in this proposal**; where an item needs code, it says so. Every number below was counted on `main` at v1.696 with a script (the counts are reproducible; the script is a few lines of Python over the DAG).

Ranked by value over effort. Items marked **[removes]**, **[tightens]** or **[fixes]** are the kinds the user asked for.

## What I looked for and did not find

Said first, so nobody pays for work that is not needed.

- **Unreachable nodes: none to remove.** Of 479 nodes, 23 are never the target of a choice; 22 of them are entered by the game (the prologue `0`, `6010_gate`, and the three groups `loyal_*` (8), `names_*` (6), `price_*` (6)) and the last, `270`, is the parked alley (item 6). QA's L3 reached 0 statically unreachable scenes and the flag dataflow (`docs/qa/blocking-nodes.md`) shows 0 dead ends.
- **Quests nobody can finish, achievements that cannot be earned: none found.** All 19 achievement ids are referenced by code or data; the 51 quests pass QA's cross-reference audit. I did not run the simulator for this; that is QA's L3.
- **Duplicate or near-identical scenes: no two scenes share the same text.** The repeats that exist are on purpose (item 3).
- **Companion remarks: clean.** 280 remarks, no repeated line, none above 140 characters.

## Ranked items

### 1. Shorten the long choice labels [tightens] — value high, effort medium

The new panel and stage show the label in a bubble; the bubble wraps at about 46 characters.

- **106 English labels** and **348 French labels** (of 1,156 choices) are over 46 characters; **53 French labels** are over 60.
- Concentrated in a few hubs, so the work comes in batches: `3005` (7 EN, 5 FR over 60), `6010` (7, 5), `2015` (6, 3), `7004` (6), `5010` (4), `7200` (4), `1150_vica`, `6010_confession_later`, `7002_price`.
- What the player notices: bubbles that read at a glance instead of three wrapped lines at 320 px, in French above all.
- Risk: **labels are pinned by tests** (`chapter_one_test`, `story_direction_test`, several `*_test` that look a choice up by its text). I would change labels hub by hub and run the files that mention the hub, as I did for the percussive pass. The label stays the same *meaning*; no choice, flag or number changes.
- Effort: about 450 short rewrites, EN and FR together; two or three PRs.

### 2. Tighten the callbacks that are still too long [tightens] — value medium, effort low

- **41 English callbacks are over the 150-character cap** the percussive style sets; 36 of them are the nine long ones on each of the four journey endings (`7005`, `7005_seeker`, `7005_dawn`, `7005_crown`), 3 more are in `7002_betrayal` (2) and `7001` (1), and 2 elsewhere. The ending ones run 340 to 470 characters each: they carry the "for one season I had ..." payoff per clan.
- These were left long on purpose in v1.631 because each is a reveal payoff. They can still lose a third without losing the payoff (one image, the clan's own name, the dated detail).
- What the player notices: the last page of the game stops reading as a list of nine paragraphs.
- Risk low (no test pins them); effort one PR, 36 rewrites EN/FR.

### 3. Stop repeating the epilogue four times [tightens] — value medium, effort low (text) / needs code for the full fix

- The four endings each carry the same ~900-character paragraph block ("It was the Shroud that did it, in the end ...", the tide going out, "I woke there. I remembered ...") plus the **same seven long callbacks** (about 3,000 characters, four times).
- Across the DAG, **50 callback texts are used in more than one scene, about 34,000 characters of duplicates** (the other group is the thirteen "who held the Lantern Hall" lines repeated on the five `7510_*` scenes).
- Text-only fix: none that removes the repetition, because the engine needs the text on each scene. The saving is in the player's eyes, not the file: the endings are read once per run, so the repetition is invisible in play. **I would not spend effort here** unless Core wants a shared-callback mechanism (code). Listed for completeness; **recommend: skip.**

### 4. Scenes still over their budget [tightens] — value medium, effort medium

- **35 scenes are over 800 characters** (the percussive page cap), **22 French scenes over 1,000**. The longest: the four endings (1,632 to 2,055 characters), `6010_record` (1,271), `5004` (1,150), `4999_camp` (1,099), `470` (1,086).
- The endings and `6010_record` are reveals (cap about 1,000 allowed). The rest (`5004`, `4999_camp`, `470` and about 25 more) can be cut or split into two pages with a page-turn.
- What the player notices: fewer walls of text on a small phone (`ux_story_room_test` keeps the room to about four lines; these scenes scroll).
- Risk: pinned phrases (`story_direction_test`), page-turn rules. Effort: 25 to 30 scenes, one or two PRs.

### 5. Consistency of names between EN and FR and across the French [fixes] — value medium, effort very low

- **"Porte-Clé" appears once against 31 "Porte-Clef(s)"** (one callback of `6010`: "au prix d’un Porte-Clé"). One word to fix.
- **"Garde-Mèche" / "Garde-Mèches"**: used both ways (25 and 22 uses); I fixed two singular slips in v1.631 but have not audited every use for number. A pass would take minutes.
- **"Porte-Aiguille" appears once against 2 "Porte-Aiguilles"**; the singular and the plural of the Stitchers should be checked as a pair.
- Effort: a single small PR for the whole consistency list; I would also read the guide strings (`tut_*`) against the game's vocabulary in the same pass, which I have **not yet done**.

### 6. The parked Weaver's Alley (`270`) [removes] — value low, effort low

- `2015_signaller` (v1.642) replaced the alley as a playable scene; `270` is left parked and unreachable, and 17 test files mention it (`chapter_one_test`, `story_rules_test`, `qa_story_blocking_test`, `first_journey_test`, the Alster place tests and others).
- Removing `270` removes one dead node and its exemptions, but **17 test files would need editing** (Core/QA files). Value is hygiene only. Recommend: do it with the next QA test pass, not on its own.

### 7. Narrator tics [tightens] — value low, effort medium

- In 47,600 words of scene text: "as if" 52 times, "the way" 86, "I did not" 28, "quite" 14, "rather" 11. They are the narrator's voice, not errors; a handful of clusters (more than three in one chapter) could be varied. **I would not start this**: it risks flattening the voice the user approved. Listed so it is on the record.

### 8. More spoken replies [adds a line, not a story] — value low, effort low

- After #677 and #680 I looked at the stage fight choices facing a person with a sprite: **the ones left are mostly actions** (taking a strongbox, holding a gate) where the choice text already reads as an answer. I found no further batch worth a PR; I will say so in the replies message rather than open one.

## What I would build, in order

1. **Item 5** (names, one tiny PR, no risk).
2. **Item 1** in batches, hub by hub, starting with `3005`, `6010`, `2015` (the three hubs the panel shows most).
3. **Item 2** (36 ending callbacks).
4. **Item 4** (25 to 30 scenes), after item 1 so the labels and texts do not collide in the same files.
5. Items 3, 6 and 7: skip or wait for a code decision.

## What this proposal does not cover

- I did not read the 11 intrigues, the 28 politics events, the 80 NPC entries or the 6 chapter blurbs line by line in this pass; only the DAG and the companion remarks were scanned with counts. If you want them in scope, I would add them to item 5 (names and tone) after the DAG items.
- No new content: no scenes, no quests, no characters.
