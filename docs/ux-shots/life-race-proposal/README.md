# Review of the character choice and the life choices (proposal, pictures first)

Screens: "A Life Before This One" (`origin_stories_screen.dart`) and "Race &
Profession" (`race_profession_screen.dart`, `race_profession_cards.dart`).
Pictures: `race-profession-{dark,light}.png`, `life-before-this-one-{dark,light}.png`
(412 wide; left the real screen today, right a mock-up: the chips and the
disabled button are real renders of the patched widgets, the rest is drawn over
the real screen). 360 would not change the layout (the cards already wrap).

## What I found (the Manager's notes, checked)
- The five race icons are four square tiles and one flag (the Human): the set
  does not read as one set. The step cards show a "?" until a pick (they do show
  the picked icon after it).
- The stat and trait pills are round; everything else on the screen is square.
- The disabled "Start New Game" button is dark grey on a near-black ground, with
  no word on what is missing. It looks like a hole.
- The title says "Race & Profession" while the steps say "People" and
  "Calling": wording is Narrative's, flagged. (The "&amp;" in the Manager's note
  is not in the app; the title renders "Race & Profession".)
- The life header band is the same code-drawn house in rain for every memory.

## Ranked by impact vs cost
| # | Change | Who | Cost | Impact |
|---|---|---|---|---|
| 1 | Disabled Start button readable, with the line that says what is missing | UX (a style, one string: Narrative may reword) | tiny | high: it is the screen's one action |
| 2 | The screen's stat and trait pills with the 1.908 pixel-step chip shape | UX | small (same shape as 1.908) | medium |
| 3 | Step cards: a dashed empty slot to fill instead of the "?" | UX | tiny | medium |
| 4 | Human icon as a square tile like the other four (or one common pixel frame around all five) | Art (1 icon) or UX (frame) | tiny | medium: the first impression of the set |
| 5 | Life header band: the light follows the age (morning, dusk, night), still the code house | UX | small | medium |
| 6 | A painted band per memory (240x100, as Art's story bands) | Art (6 bands, plus the race and calling variants of memories 2 and 4), UX wires them | medium | high for the life screen |
| 7 | Life answer cards: pixel chips and glyphs, then pixel frames | UX, with items 3, 4 and 8 of the UI list | with those | medium |
| 8 | "Choose my whole life at random": a pixel dice glyph and a filled secondary style | UX | tiny | low |

UX-only first batch: 1, 2, 3, 5, 8 (one small PR, about 150 lines, no Art).
Waits on Art: 4 (one icon), 6 (the bands).
