# The Forge, reworked (UX mock, for the user to approve)

Pictures: `docs/ux-shots/forge-sheet-mock.png` (the sheet, today and reworked) and
`docs/ux-shots/forge-moment-mock.png` (the forging in four beats). Mock test:
`test/ux_forge_mock_test.dart`. The rule is Core's: `docs/proposals/forge-roll.md`
on `claude/core-forge-roll` (the forge's own d20; modifiers with their sources;
total 1–4 Flawed −1, 5–14 Sound, 15–19 Fine +1, 20+ Masterwork +2; a flaw loses
nothing). Nothing here is built.

## The sheet
- **Dagny speaks first**: her line sits at the top in a quote strip with her name,
  so the place has a voice (today the sheet has none).
- **The ore hint is one line** with an icon, not a paragraph.
- **"Your roll: d20 + 3"** with each modifier and its source as a chip ("Dwarf hero
  +2", "Friends of the Pact +1"), and one bar of the four tiers with their odds
  (here 5 / 50 / 25 / 20 %). The player reads the gamble before taking it.
- **Each piece shows its main number for each tier** (Armor 1 · 2 · 3 · 4, coloured
  by tier), so the result is known before the roll, not only after.
- **"5/3" is said**: "Iron ore · you carry 5 · needs 3", a green tick or a red
  cross, and the same for gold. A piece that cannot be forged says why on its
  button ("Short of 2 iron ore") instead of a dead "Forge".
- The button says what it does: "Forge it: roll the d20".

## The forging moment (four beats, about four seconds, a tap skips)
1. **The strike**: hammer down on the anvil, sparks, and the d20 (the game's
   `D20Roll`, the same die as the crossings) tumbles.
2. **It lands**: the face, then each modifier slides in under it with its source,
   then the total and the tier strip with a marker.
3. **The tier is read**: the word (FINE) in the tier's colour, the sparks take that
   colour and grow with the tier (a flaw dims them, a masterwork burst is gold);
   one line says what the tier does. A camp roll house's reroll replays beats 1–3.
4. **The piece, before and after**: the piece's card with the tier prefix in its
   name ("Fine Iron-Shod Boots"), main number 2 → 3, other numbers unchanged, the
   resale price 45 → 56, what was spent, then "Take it" / "Forge another". This
   replaces today's "Forged: …" notice.

Reduced motion: beats 1–2 are skipped; the card of beat 4 shows at once with the
roll written out ("13 + 2 + 1 = 16, Fine").

## What UX needs from Core to build it
The d20 face, each modifier with its label and value, the total, the tier, the
piece before and after (stats and resale price), and the odds per tier for the
sheet's bar (Core's rule is pure, so the sheet can ask it for the odds).

## Not decided here
Core's three questions to the user (does a flaw lose the materials, does a
masterwork add a sign, does the dwarf bonus apply at any forge) change only the
words on beats 3–4, not the layout.
