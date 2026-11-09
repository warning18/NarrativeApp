# Narrative: ideas, round 3

From the Narrative session to the manager, for the user. Scope: the story, quests, characters, dialogue, EN and FR wording, the Tower's names. **New items only**: nothing here repeats a list, a merged item or a held one. Removing, simplifying and trimming come first. Every number was counted by script on `main` at v1.863; no story edit is made by this note.

I also looked for these and found nothing worth a PR, so nobody pays for work that is not needed: dead callbacks (a line whose flag is set only after the scene), quests with a flag no scene sets, NPCs or titles that nothing names, pass-through "Continue" scenes (two exist), stale labels in the French.

## Ranked, my recommendation first

### 1. Spell the English one way — recommended

- **What:** the English mixes British and American spellings. In the story data: *harbour* 64 against *harbor* 40, *colour* 13 against *color* 1, *favour* 31 against *favor* 1, *honour* 5 against *honor* 1, *armour* 2 against *armor* 5. The bulk is British (*grey* 204, *gray* 0), and the game's own strings also mix (*Harbor* 14 against *harbour* 5, *Armor* 4 against *armour* 1). Pick one (I recommend British, since it is already the majority and matches *grey*) and make the story data and the strings follow.
- **Why:** a reader sees "harbor" in one scene and "harbour" in the next; it reads as an error, not a voice.
- **Size:** S to M (about 45 replacements in the story data, about 20 more in `app_strings.dart`, which UX and Core also edit).
- **Risk:** tests pin some words (`district_places_test` pins "The harbor master’s office"); each hit is listed with its test before it moves. French is not touched.
- **The player notices:** nothing at first; the text stops flickering between two spellings.

### 2. Bold only the sharpest fact of a scene

- **What:** 668 passages in the story are bold (**like this**), which is 5,744 words, **12.2 % of all scene text**, about 14 bold passages per 1,000 words. A scene carries one to three; 6 carry four or more. Keep one bold fact per scene (the reveal, the number, the name that matters later) and unbold the rest. Reveals (the endings, `6010_record`, the ledger) keep their bold.
- **Why:** when one word in eight is bold, bold no longer says "remember this", and a small phone page looks like a ransom note.
- **Size:** M (about 389 scenes, English and French together; a script proposes the one to keep, I read each).
- **Risk:** some tests pin phrases with their `**`; the lines that mark a flag or a clue must keep their bold so the reader still sees them. Low for the story.
- **The player notices:** calmer pages, and the bold left is what matters.

### 3. Give the six follow-up visits their own closing buttons

- **What:** six scenes where an NPC comes back with a deal end with the same two buttons, "Accept what they offer" (+20 gold) and "Say your goodbyes": `3005_dorran_later`, `5010_imeh_later`, `6010_brannoc_later`, `7100_orsabet_later`, `7100_ghrem_later`, `7800_nkem_later`. Reword each pair to what that person is actually offering (a name back, a rope, a thanks), keeping the gold and the flag.
- **Why:** the buttons are the one formula in otherwise specific scenes, and they read as a menu.
- **Size:** S (12 labels, English and French).
- **Risk:** low; labels are pinned by a few tests, which I update and list.
- **The player notices:** each return visit ends on a line from that scene.

### 4. Retire two lines that can never play

- **What:** two Vess remarks (`choice_960_1_vess`, `choice_960_2_vess`) are filed under choices `960#1` and `960#2`, and say "You could have made him scream" and "Making them pay", about an Inquisitor on a pier. Scene `960` today is the burning Lark, and its second and third choices are "Keep the cloth dry" and "Shield Lysa"; no choice anywhere says "end it quickly" or "make him pay", and Vess does not join until chapter 2. They are leftovers of an older scene.
- **Why:** dead data, and the first of them would be the wrong line if the keys were ever reused.
- **Size:** S (delete four strings, English and French). **Risk:** none found; `companion_remarks_test` counts remarks, so its number moves by two.
- **The player notices:** nothing.

### 5. Re-time eight intrigue clues that point at someone met in another chapter

- **What:** each clan intrigue is a six-step plot, and each step names the person who gives it. Eight steps name someone the game places in a different chapter: for example *The Admiralty’s Silence*, "Reveal", chapter 5, is given by the Last Lantern’s keeper, who is a chapter-6 person; *The Lantern-Bearer’s Will*, "Reveal", chapter 6, is given by the crape courier, a chapter-2 person; *The Double Ledger* has a chapter-3 and a chapter-6 step given by chapter-2 and chapter-3 people.
- **Why:** a clue can arrive before the player has met its giver, or long after. Either re-time the step to the giver's chapter or give the step to a person met then.
- **Size:** M (eight steps in `intrigues.json`, English and French, and a read of where each giver is met). **Risk:** the intrigue stages are read by Core's politics code; I change only the text and `npcId`, never a stage number, and list each one.
- **The player notices:** the clues arrive from people they have already met.

### 6. Tighten the three longest quest-giver speeches

- **What:** 17 of the 51 quest-giver speeches are over 250 characters, 10 over 300 (the quest card carries the speech as written). The longest are Tobin (439), Vess (422), Liora (385). Cut those three to about 300 and leave the rest.
- **Why:** they are the longest block of text on the quest card, over the percussive cap that the scenes already keep.
- **Size:** S (three speeches, English and French). **Risk:** they double as the companions' first voice, so I cut by removing a sentence, never by reworking the voice; I stop at three and show before and after.
- **The player notices:** quest cards that read in one glance.

## What I would do first

1. **Item 1**, after the user picks British or American.
2. **Item 3** and **item 4** together, one small PR (14 strings).
3. **Item 2**, if the user wants calmer pages; it is the biggest read.
4. **Items 5 and 6** at the manager's order.

## What this note does not do

- No new scenes, quests or characters.
- Nothing from the earlier lists (labels, callbacks, long scenes, page breaks, hub rows, revisit text, prices, stanceLeader).
