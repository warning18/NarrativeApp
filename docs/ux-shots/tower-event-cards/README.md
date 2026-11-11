# Tower floor-event cards (pictures of a prototype, never merged)
Mock data shaped like Core's `TowerEventView` (claude/core-events, docs/proposals/tower-snakes-and-ladders.md). `prototype.patch` + `tower_event_card.dart.txt` are the prototype; `shot_test.dart.txt` draws the pictures (`UX_SHOTS=<dir>`).
1. **Setback** (cards screen, above the cards): test of strength, the odds as a number and a bar (d20 + modifier against DC), what a pass and a fail give (potion, fall to floor N), setbacks left.
2. **Rival** (floor screen, before the fight): win within N rounds, skip to floor M; otherwise the ordinary fight.
3. **Shortcut** (floor screen, before the fight, PR 2): the Elite in place of the ordinary fight, win skips k floors, losing ends the run; **Take the stair** / **Take the door**.
4. **Fell** (next floor): the result line (roll and total against the DC), the revisit line "this floor pays nothing", and the rail's red arrow down from floor 14 to 12.
5. **Skipped**: the result line and the rail's gold arrow up to the landing floor.
