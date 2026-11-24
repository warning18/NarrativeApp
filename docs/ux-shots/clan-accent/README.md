# The clan accent (pictures only, the user's idea)

"Could the player's best clan relation set the accent colour (red for now)?" Drawn at 360 px on the real screens (`test/ux_clan_accent_shots_test.dart` takes them; `gen.py` recolours them: `python3 gen.py <base-dir> <out-dir>`). Start with `sheet-floor.png`.

- `sheet-home.png`, `sheet-floor.png`, `sheet-fight.png`: the home menu, a Tower floor with the tarot pick, a Tower fight, each in today's red and the six clans (`factions.json` colours, adjusted as in `contrast.png`).
- `contrast.png`: each raw colour on ink black and on paper, paper text on the raw fill, and the proposed fill and line.
- `change-fade.png` / `.gif`: the moment of change, a 400 ms fade when the toast fires (Tower) or at the next screen (story).

## What switches, what stays red
**Switches (the accent):** the button that goes on (New Game, Take, Roll Dice) and the home menu's paint-edged buttons and their left bar; ribbons and tabs; the held card's frame; the current rung of the ladder.
**Stays semantic red:** health and damage bars (yours and the foe's), the boss rungs and danger band, the weakness mark and ×3, a low-health warning, delete and failure. Nothing in a warning ever takes the clan colour.

## Contrast (WCAG)
Paper text must read on the fill (4.5+); a frame or accent text on ink black wants 3+ (4.5 where it is text).
- Today's red: paper text on it 5.3, as a frame on ink black 3.2.
- Raw clan colours fail paper-on-fill for **Vigil 2.8, Compact 3.4, Mire 3.4, Penitents 1.7** (and are marginal for Dominion 5.1, Crows 5.4 which pass). So each clan gets two values: a **fill** darkened until paper text reads 4.5 (Vigil #676C75, Compact #985B34, Mire #33774E, Penitents #7D683C) and a **line** lightened until 4.5 on ink black where needed (Dominion #4378CE, Crows #CE4958).

## Problems to decide
1. **Crows' colour is today's red**: #B0303F next to #C1121A. A Crows leader would make the accent and the semantic red nearly the same, which is exactly what rule 3 forbids. My proposal: Crows uses a rose-crimson #CE4958 line and its darker fill, and the semantic red is not touched; or leave Crows out of the accent (red stays) and accept it.
2. **Vigil (grey) and Penitents (sand)** read as neutral: a grey button looks disabled (the Load button is grey today), and a pale-sand held frame is close to an unheld grey one. Proposal: those two keep their fill but add a 1 px paper outline on the button, and the held frame is 2 px wider; or they use their clan's second colour if Narrative has one.
3. **The home menu's paint edges and the story's best clan**: shown on all five buttons, it is a lot of colour at once. Proposal: only the one primary button and the left bar take it; the edges of the others stay today's red.
4. **Dark mode only**: these are ink-theme screens; the other (themed) screens keep Material's colours, so this applies to the ink kit and does not recolour the app.

Build, if the user chooses it: one `inkAccent` on a provider (leading clan or red), the ~40 non-semantic uses of `inkRed` read it, the semantic ones stay `inkRed`. Needs Core's provider of the leading clan.
