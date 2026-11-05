# The Tower: design pictures, phase 0b (pictures only, UX-2)

For `docs/proposals/the-tower-wave.md` (phase 0b). Nothing is built; no version.
Every sheet shows, left to right: **direction A in French at 360 px, A in
English at 412 px, direction B in French at 360 px, B in English at 412 px**,
so the longest French text meets the narrowest phone and the English meets the
widest. Real game content (clans, races, professions, the Slum Thug and Bone
Warden with their heads, the knuckle wrap, antidote and knucklebone art, the
silver chest). Smallest text is 11.5 px (the 11 px minimum holds). The mock is
`docs/ux-shots/tower/tower_designs_mock.dart.txt` (a throwaway test).

## Two directions

- **A, inside today's look**: ink panels, gold accent, rounded cards, the
  fight board as it is, the climb shown as a 30-tick bar under the title (a
  taller tick on floors 10, 20 and 30).
- **B, bolder**: the same fonts and cards but stone-dark with an ember accent,
  square frames, the climb as a **vertical ladder** down the left edge (the
  floor you are on lit, the boss floors wider), a banner on the menu.

## The screens (files in `docs/ux-shots/tower/`)

1. `1-menu.png`: the entry beside Continue and New game. A: one more card of
   the family with a tower mark and "30 floors · one fight each". B: a banner
   that stands apart from the story's buttons.
2. `2-start.png`: race, profession, clan (locked ones greyed with a lock), the
   starter kit and a "Begin the climb" button; the note that nothing is taken
   from the main save.
3. `3-floor.png`: the fight screen with the floor counter and the ladder; the
   board is a stand-in for today's board (nothing changes inside the fight).
4. `4-reward.png`: the pick-1-of-3 reward, the same card as the loot dialog's
   recommended design A (`docs/proposals/loot-dialog-designs.md`) in "choose
   one" mode; the card in hand is ringed, the others dim.
5. `5-boss.png`: floor 10: a red "FLOOR 10 · BOSS" band, the boss card framed in
   red, its one-line rule under its health bar.
6. `6a-death.png`, `6b-victory.png`: the end of a run: the floor reached, the
   marks earned and the total, a few counters, what a win unlocked, and two
   buttons (marks and unlocks; climb again).
7. `7-marks.png`: the marks balance, then unlocks by kind (races and
   professions, clans, kit) with cost, "Buy" when affordable, "Owned" when held.

## Recommendation

**A's panels with B's vertical ladder.** The ladder is the one idea worth the
extra look: it shows 30 floors and three boss gates at a glance and makes the
Tower feel like a place, where a 30-tick bar under the title is easy to miss.
Everything else is better kept in today's look: the fight, reward and marks
screens must read like the rest of the game, and B's ember accent next to the
fight's own gold and red costs contrast on the board. For the menu, B's banner
is the better entry; A's card is the safer one (it stays beside the story's
buttons without shouting).

## What the pictures do not settle

- Names and strings are placeholders for Narrative's phase 0c (the Tower's
  floors, the marks, the unlocks).
- The fight board is a stand-in; the real floor screen needs Core's engine
  note to say what a floor carries (an affix line, an ally, the floor's flavour).
- The end screen's counters (dice rolled, bosses beaten) are guesses at what
  the run state will hold; each one needs Core to keep it.
- Phone-size check: all screens fit 360 px without scrolling except the start
  screen and the marks screen, which scroll by design.
