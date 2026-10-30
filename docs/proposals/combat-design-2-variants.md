# Combat design 2 (Cartes compactes), two variants (UX-2, pictures only)

The user chose design 2 with changes: (a) no big sprite figures on the cards; (b) the icons (the
"V" disc, portrait discs, ring crops, enemy and ally icons) become the sprite HEAD, a crop of the
real sprite (Vica's dog head, the hero's head, the enemy's head; an ally with no sprite keeps its
disc); (c) the dice board takes most of the fight screen; (d) dice are thrown and tumble each roll
before settling; (e) a locked die leaves the board and sits small in a "kept" row below it.
Pictures in `docs/ux-shots/combat2/`: `variant-A.png`, `variant-B.png` (each: pre-fight, a roll in
flight, two dice locked below, then the four frames of one throw), `sprite-heads.png` (the three
head crops, cut from the existing sprite files; no new art).

- **A, kept strip.** HP and mana in two twin cards on top; the board is the middle half of the
  screen at full width (392 px); locked dice go into one strip directly under the board.
- **B, kept tray + side rail.** HP and mana in a left column of heads, the enemy as a banner, the
  board on the right over the full height (292 px wide); locked dice go into a small tray under
  the board with their effect readable (who, what) and a count (2/3).

The throw (both): launch from the bottom with a trail (0.15 s), tumble in the air with the shadow
on the ground (0.35 s), land and bounce on the final face (0.3 s), settle and label (0.3 s), about
1.1 s. A tap during the flight lands them at once; reduced motion places them with no flight.

Core: nothing to change. This is look and motion only (positions come from the view; the set of
locked dice stays the same state), `fight_dice_rules.dart` is not touched. Core confirmed the board holds at most 4 dice (player + 2 seated companions, 4 with the Barracks
Annex): A fits 4 dice of 64 px in a row; B (292 px) fits 4 dice of 58 px as 2 x 2.

Recommendation: A (the wider board is worth more than the side rail on a phone).

## Round 3: variant A with the user's changes (A')
The user likes A and the throw; asks for bigger cards, one per player / companion, so bonuses
and maluses show, as small icons with a pop-in explaining them on tap.
`docs/ux-shots/combat2/variant-A2-cards-icons.png` (a roll in flight, two dice kept, the pop-in
open on Vica's poison, the icon legend); the 8 icons (9 x 9 pixel, one colour each) are in
`docs/ux-shots/combat2/icons/`: poison, stun, weaken, block, parry, shelter, fury, target.
- Three cards of 70 px on the left (head, name, HP, icons with a corner number = turns or value,
  damage and armour), the enemy in a column on the right with its own icons; the board goes from
  420 to 346 px tall (4 dice of 64 px still fit).
- Tap an icon: a pop-in under the card (effect, who, turns left, what it does); tap elsewhere closes.
- Core: nothing to change (same data: statusEffects, block, parry, Fury / Watchfire, the telegraph).
  To write before building: the pop-in texts (EN + FR) with the exact numbers; Fury, Parry and
  Watchfire already have texts in the game (fury_tip, parry_tip, watchfire_tip), Poison, Stun,
  Weaken, Block and Shelter do not.
