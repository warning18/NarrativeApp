# Tower Heat: five named levels, a curse each (pictures only, no build)

`heat-<412|360>-<en|fr>.png` (start with `heat-412-en.png`): one sheet each, in the Tower's ink. Rules and names are Core's (`docs/proposals/tower-heat.md` on `claude/core-tower-designs`): Embers, Smoke, Flame, Pyre, Ash; marks x1.25 to x2.25. The curse lines are my placeholders for Narrative to word. `test/ux_tower_heat_shots_test.dart` draws them (`UX_SHOTS=<dir>`). The build would be v2.9.1+1077 (after Core's v2.9.0).

1. **The door's picker**: six rows (0 and the five levels): the level's flames (as many as its number), its name, its curse in one line, "Marks x1.25"; the picked one ringed in its colour; the locked ones dimmed with a padlock and "Win the top at Smoke to open". Two states: Embers just opened; all open with Flame picked. Hidden until Embers opens.
2. **The curse list** (opened from the chip): every curse in force, the newest tagged "new"; at Flame (three) and at Ash (all five).
3. **The header chip**: the level's number and its name, in the level's colour, for the whole run.
4. **The end screen**: "Flame · marks x1.75", "Pyre is open", and the badge on the record (five flames, as many lit as the best climb's level).
5. **Ash conquered**: the Tower's door block with a pale ash trim and a glow; without it for comparison. There is no Tower banner yet, so I draw the door's title block (a guess).

## Guesses
- The flame takes the level's colour, amber to deep orange, then pale ash at 5: never red, which stays the warning (the accent decision).
- One row a level rather than a grid: it holds at 320.
- The pixel face reads a 5 like an S, so numbers here are in the prose face.
