# Tower briefs 6, 7 and 8 (pictures only)

Ink and tarot look, at 360 and 320, English and French, plus 320 FR at 1.3x text (`<brief>-<width>-<lang>.png`). Rules and numbers are Core's (`docs/simulation/tower-briefs-6-7-8-spec.md`); the words are Narrative's (`docs/narrative/drafts/tower-offers-and-briefs.md`). The look is mine; each guess is marked "guess" on the sheet. `test/ux_tower_briefs_678_test.dart` draws them (`UX_SHOTS=<dir>`).

- **6, coins** (`6-coins-*`): the coin chip in the floor header (gold, in-run only); the spoils line "+2 coins" with an Elite tag; the card table with a × on each boon card (Banish · 4 under it) and a Reroll · 3 button (greyed and "Not enough coins." when poor), with the confirm for a banish; the merchant (wallet in coins, salve 4, bundle 5, boon 10; a second stall at the sworn half price); the end screen with "Coins left: 9 (lost)" in small type.
- **7, heat** (`7-heat-*`): a picker of four rows on the start screen (0, Embers, Flame, Pyre), the picked one ringed, the locked ones dimmed with their padlock and "Win the top at … to open", each open one with its flames and "Marks +n %"; two states (heat 1 just opened; all open with a lower one picked); the floor header's flame chip; the end screen's "Heat 2 · ×1.5 marks" and "Pyre is open".
- **8, daily and records** (`8-daily-*`): the Daily climb panel (the date, the day's hero, "One attempt a day", the button) and, once played, the result and "The stairs reset at dawn"; the records card (best run with its flames, the best daily) and its empty state; the "Daily" chip in the header; the end screen's "New record" with Art's stamp and the old record struck.

## For the user's choice
Core's decisions (earning table, stall in coins, boon price, merchants' places, heat factors and floors, marks bonus, a picker that can go down, one attempt a day, what the record holds, best daily ever, the daily hero) are in the spec; the pictures follow the recommended side of each.

## Notes
- The pixel face reads a 5 close to an S (Maps' note), so the numbers here use the prose face; the build should do the same where a 5 matters (a price, "+25 %").
- Coins use a gold painted coin (a guess; Art could draw a small coin glyph), the flame is the Material flame in orange, outside the semantic red.
