# A percussive house style (pilot, chapter 1)

The user asked: *condense the text so it is more percussive and less narrative; complexity should come with the story; limit the narration so the player's attention holds.* This note is the pilot: a style, a length budget taken from chapter 1 as it is, six before/after scenes in [`percussive-samples.md`](percussive-samples.md), and what a rewrite touches. **No data has changed.** The user decides before anything is rewritten.

## The style, in eight rules

1. **Short sentences.** Chapter 1 averages 20.6 words a sentence (median 18). Aim for 13 on average, with one long sentence in a scene allowed for rhythm.
2. **Concrete verbs.** "The wall went in brick-dust and fire", not "the wall disappeared in a cloud of brick-dust and fire that…".
3. **One image, not three.** One simile or one adjective stack per scene at most. The rest decorates and is cut.
4. **One beat per paragraph.** Two to four short paragraphs. A paragraph is a thing that happens, not a view.
5. **The choice arrives sooner.** The clue the choice depends on sits in the last third; no scene-setting paragraph before the first thing that happens.
6. **Keep what carries the story:** names, clues, stakes, the **bold** phrases, the words the flag callbacks and later scenes pick up (the trapdoor, the cloth, the hands, the lantern, Vica's name coming out of the heat).
7. **Keep one dry line per scene.** The narrator's voice is half the book; it goes from three asides to one, not to none.
8. **Complexity comes with the story, not in the telling.** The lore is not flattened: it is spread, one new fact per scene instead of three. A scene that carries two new names loses one to the next scene.

What does not change: choices, labels (a changed label moves the simulator's pinned run), outcomes, flags, rewards, numbers, the scene graph, the companions' remarks (already short: 530 lines, average 56 characters, longest 140).

## Length budget, from chapter 1 today

52 scenes, 6,851 words, 139 flag callbacks (3,574 words more). Kinds are read from the data: a scene that opens a fight counts as a fight intro even when it is a long page (800, the Black Hold).

| Kind | Scenes | Average now | Longest now | Sentences now | Budget (characters) | Budget (sentences) |
|---|---|---|---|---|---|---|
| Page scene (default view) | 21 | 846 | 470: 1,573 | 8.0 | **600**, hard cap 800 | 6 |
| Fight intro | 16 | 562 | 800: 1,443 | 5.4 | **400**, hard cap 600 (a Black Hold or boss page: 800) | 4 |
| Side or result scene (one way on) | 11 | 658 | 0: 1,115 (the prologue) | 5.9 | **400**, hard cap 600 (the prologue: 800) | 4 |
| Continue page | 3 | 347 | 100_dice: 474 | 2.7 | **300** | 3 |
| Street or room scene | 1 | 397 | 890_trainer: 397 | 4.0 | **300** | 3 |
| Flag callback line | 139 | 126 | 293 | 1 | **90**, hard cap 150 | 1 |
| Companion remark | 530 | 56 | 140 | 1 | unchanged | 1 |

Callbacks matter as much as the scenes: on a page scene the callbacks that can append average 636 characters, and across the game the callbacks are 29,871 words against 53,402 for the scenes. What the player reads is the scene plus every callback whose flag they hold.

The six samples come out EN −26% and FR −23% in total. A full pass at these budgets is about 30% on scenes and 35% on callbacks.

## What a rewrite touches

- **Narration audio:** nothing to regenerate. `assets/narration/` holds only its README (16 KB, no recordings are shipped). Clips are recorded on the device and keyed by a hash of the paragraph's exact text, so a changed paragraph is simply a new clip when someone records it; shorter text also costs less to record.
- **Tests that pin story text:** `chapter_one_test` (6 phrase checks: the trapdoor, "Who could want…", the lantern), `story_direction_test` (12), and single checks in the nemesis, hunter, clan-crisis, expedition and sub-node tests. Those phrases are kept or the tests are updated in the same PR. Nothing in the engine reads a text length.
- **French lint:** `french_data_lint_test` and `qa_story_fr_test` (non-breaking space before `: ; ! ?`, inside « », curly apostrophes, « vous »). Every rewrite is written in both languages and checked by them; the samples already follow the rules.
- **Real-font layout:** `qa_story_text_real_font_test` lays out the longest scenes at 360 and 320 px; shorter text only helps it.
- **Simulator and pins:** the naive run's hash covers the choices taken (their labels), not the scene text, so a text-only rewrite moves no pin and no band. Choice labels are not touched.
- **Story and journey pins** (`first_journey_test`, the scene lists) read node ids and page turns, not text: unchanged.
- **Risks:** a callback that starts mid-sentence ("Lysa had pulled me…") must still follow the shortened scene; the bold clue phrases (several are tested or read by callbacks) must stay word for word where something depends on them; the narrator's irony is thinner after the cut.

## Cost for the whole game

478 story scenes, 53,402 words of scene text and 29,871 words of callbacks in English, and the same again in French: about 83,000 words per language to rewrite by hand, about 166,000 in all, with a read-through and the lint after each pass.

| Part | Scenes | Scene words (EN) |
|---|---|---|
| Chapter 1 (ids under 2000) | 52 | 6,851 |
| Chapter 2 | 70 | 6,994 |
| Chapter 3 | 66 | 6,927 |
| Chapter 4 | 4 | 733 |
| Chapter 5 | 71 | 7,220 |
| Chapter 6 | 89 | 9,139 |
| Chapter 7 and later | 106 | 12,888 |
| Other ids | about 20 | |

At the budgets above the scene text falls from about 53,000 to about 37,000 words and the callbacks from about 30,000 to about 19,000.

Proposed order, one PR each (each with before/after counts per scene): **chapter 1** (52 scenes and 139 callbacks), **chapter 2**, **chapter 3**, then chapters 4–5, 6, and 7 on. Chapters 1 to 3 are 39% of the scene text and are where the player's attention is won or lost. Nothing starts before the user's OK on the six samples.
