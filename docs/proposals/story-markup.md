# Story markup: what Narrative writes, what the game does for them

For Narrative, and for UX's story text display (v1.470). The story text has a tiny markup, and everything else is automatic. Nothing in the data changes shape: it is the same `description` / `description_fr` strings.

## What you write

| You write | The game shows |
|---|---|
| `**the key fact**` | the words in **bold** |
| a blank line (`\n\n` in the JSON) | a new paragraph |
| a single line break (`\n`) | a line break inside the paragraph (use it for verse and lists only) |

That is all. No `*italic*`, no `_`, no `#`, no HTML: they would show as typed.

### Bold
- For the **key facts a reader must not lose**: a number (`**forty crowns**`), an object that matters (`**the Hooded Lantern**`), a deadline (`**by the third bell**`), a debt or a promise. Think of what a player would write on a sticky note.
- A few a scene, not a few a paragraph. Not whole sentences. Not names (see below: they are coloured already).
- Same markup in the French text, around the French words.
- A bold run stays inside one paragraph. An unclosed `**` is shown as typed, so a slip is easy to see.

### Paragraphs
- A paragraph of **two to four sentences** (about 60 words at most) reads well on a phone. The longest scenes today are 400 words in one block: please split them at a change of place, speaker or beat.
- Only 1 scene out of 440 has a blank line today, so every long scene is a candidate.

## What is automatic: names

**Do not mark names.** The game colours them wherever they appear in a scene's text, from the data it already has:

| Kind | From | Colour (one each, readable on both themes) |
|---|---|---|
| People | `npcs.json`, `companions.json` | warm gold-orange |
| Places | the geography (places, districts, buildings, landmarks) | tide blue |
| Clans | factions (clans) and sub-clans | violet |

Rules, so you can write for them:
- A name matches as **whole words**, the **longest first**, as written (capitals matter: "Alster" is coloured, "alster" is not), in the display name of the language of the text (French text uses the French name).
- **A leading article is not part of the name**: "The Lantern Dominion" is matched as "Lantern Dominion", and "La Main ouverte" as "Main ouverte". The **short names of the clans** in `factions.json` (`short`: Dominion, Vigil, Compact, Crows, Penitents, Open Hand...) match too.
- **People:** only proper names are coloured. A record that is only a description ("The archivist", "A Crow with no name") is left alone. A person's first name alone is coloured when it is a record of its own (a companion's name, "Vane", "Lysa"); otherwise ask for an alias in the record.
- A word that is also a plain word (the Pit, the Mire, the Choir, the Giants, the oni) is on the game's **do-not-colour** list (`storyNamesIgnore`, in `lib/data/story_names.dart`); tell UX if a common word turns coloured by accident.
- Names inside `**bold**` stay coloured and bold.

## What the reader sees

- The text **writes itself out**, quickly (a short scene in about two seconds). One tap shows it all; the next tap continues as today. With "reduce motion" or the animations-off setting the text is shown at once. The choices appear once the text is complete.
- The same display in the story player and in the Journey's scene view (the full page and the sheet).
- Spoken narration (TTS) reads the text **without** the `**` signs.

## Where it applies

`description` and `description_fr` of a scene, the lines read on the way in (preludes), the echo lines (`flag_callbacks`) and the alignment epilogue. Only the scene's own text writes itself out; those others appear with it. Not choice texts, names of things, or the UI strings. Marking a scene up does not make a place you have read look unread again (the key ignores the `**` signs; adding blank lines does change the text).
